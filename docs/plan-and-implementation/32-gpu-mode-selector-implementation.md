# 32. GPU Mode Selector - Implementação

**Status**: ✅ Completo  
**Data**: 2026-02-05  
**Tempo Total**: ~10h (incluindo debugging e refinamentos)

---

## Sumário

- [Objetivo](#objetivo)
- [Comportamento do supergfxctl](#comportamento-do-supergfxctl)
- [Conceitos Chave](#conceitos-chave)
- [Arquitetura](#arquitetura)
- [Arquivos](#arquivos)
- [UX e Estados Visuais](#ux-e-estados-visuais)
- [Bugs Corrigidos](#bugs-corrigidos)
- [Comandos Úteis](#comandos-úteis)
- [Lições Aprendidas](#lições-aprendidas)

---

## Objetivo

Implementar seletor de modos de GPU na barra do Caelestia Shell, permitindo alternar entre Integrated/Hybrid/Dedicated via interface gráfica com:
- Indicador visual do modo REAL (activeMode) vs CONFIGURADO (configuredMode)
- Timer de tempo restante durante operações lentas (~60s)
- Badge vermelha indicando operações lentas antes de clicar
- Confirmação antes de executar (click duplo)
- Indicação clara de ação necessária (logout/reboot)

---

## Comportamento do supergfxctl

### Modos Disponíveis

| Modo | Nome UI | Descrição | Comando |
|------|---------|-----------|---------|
| `Integrated` | Integrated | Intel iGPU only | `supergfxctl -m Integrated` |
| `Hybrid` | Hybrid | Intel iGPU + NVIDIA dGPU | `supergfxctl -m Hybrid` |
| `AsusMuxDgpu` | Dedicated | NVIDIA dGPU only (MUX) | `supergfxctl -m AsusMuxDgpu` |

### Comandos

```bash
supergfxctl -g          # Get configured mode (NOT real active!)
supergfxctl -P          # Get pending mode ("Unknown" = none)
supergfxctl -m Mode     # Set mode (CASE-SENSITIVE!)
supergfxctl -S          # Get power status
```

### ⚠️ Case-Sensitivity

O comando `-m` requer capitalização **exata**:
- ✅ `supergfxctl -m Integrated`
- ✅ `supergfxctl -m Hybrid`
- ✅ `supergfxctl -m AsusMuxDgpu`
- ❌ `supergfxctl -m integrated` (falha!)
- ❌ `supergfxctl -m asusmuxdgpu` (falha!)

### Tempos de Operação (MEDIDOS)

| Transição | Tempo | Ação Necessária |
|-----------|-------|-----------------|
| Hybrid → Integrated | **~60s** 🐢 | Logout |
| Integrated → Hybrid | **~60s** 🐢 | Logout |
| Qualquer → Dedicated | **0s** ⚡ | Reboot |
| Dedicated → Qualquer | **0s** ⚡ | Reboot |

**Por quê?**
- Hybrid ↔ Integrated: Precisa ligar/desligar a NVIDIA (~55-60s)
- Qualquer ↔ Dedicated: Apenas marca pending, MUX switch acontece no reboot

---

## Conceitos Chave

### activeMode vs configuredMode vs pendingMode

```
┌─────────────────────────────────────────────────────────────┐
│ activeMode    = Modo REAL rodando agora                     │
│                 (detectado via nvidia-smi)                  │
│                 Só muda após logout/reboot                  │
├─────────────────────────────────────────────────────────────┤
│ configuredMode = O que supergfxctl -g retorna              │
│                  Muda IMEDIATAMENTE após -m                 │
│                  É o ponto de partida para próximo switch   │
├─────────────────────────────────────────────────────────────┤
│ pendingMode   = configuredMode se != activeMode            │
│                 Indica mudança aguardando logout/reboot     │
└─────────────────────────────────────────────────────────────┘
```

**Exemplo prático:**
1. Boot em Hybrid → activeMode=hybrid, configuredMode=hybrid, pendingMode=""
2. Clica em Integrated (2x) → operação ~60s
3. Após operação → activeMode=hybrid (ainda!), configuredMode=integrated, pendingMode=integrated
4. UI mostra: "GPU Mode: Hybrid" + "Pending Logout to Integrated"
5. Usuário faz logout e login
6. Agora → activeMode=integrated, configuredMode=integrated, pendingMode=""

### Detecção do Modo Real

`supergfxctl -g` retorna o modo **configurado**, não o real. Para detectar o modo REAL:

```bash
nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null
```

- Se funciona → NVIDIA ativa → **activeMode = hybrid** (ou dedicated após reboot)
- Se falha → NVIDIA off → **activeMode = integrated**

### Fluxo de Confirmação

1. **Primeiro click**: Mostra "Click again to confirm X" + indicador muda para cor terciária
2. **Segundo click (mesmo botão)**: Executa a operação
3. **Click em outro botão**: Muda confirmação para o novo botão
4. **Click no modo atual (sem pending)**: Cancela confirmação
5. **Click no modo pending**: Cancela confirmação
6. **Timeout 3s**: Confirmação expira automaticamente

---

## Arquitetura

### Backend: GpuModeService

**Arquivo**: `services/GpuModeService.qml`  
**Tipo**: Singleton

#### Properties Principais

```qml
property string activeMode: ""           // Modo REAL (nvidia-smi)
property string configuredMode: ""       // Modo configurado (supergfxctl -g)
property string pendingMode: ""          // Modo pendente (config != active)
property bool available: false           // Se supergfxctl existe
property bool switching: false           // Se operação em andamento
property bool loading: true              // Se carregando estado inicial
property int switchTimeRemaining: 0      // Segundos restantes
property string targetMode: ""           // Modo sendo alternado para
property string lastError: ""            // Último erro (auto-limpa 5s)
property string pendingConfirmation: ""  // Modo aguardando confirmação
```

#### Functions

| Função | Descrição |
|--------|-----------|
| `getModeName(mode)` | "Integrated", "Hybrid", "Dedicated" |
| `getModeDescription(mode)` | "Intel iGPU only", "Intel iGPU + NVIDIA dGPU", etc |
| `getEstimatedTime(from, to)` | 0 ou 60 segundos |
| `getRequiredAction(from, to)` | "logout" ou "reboot" |
| `getActionText(action)` | "Logout required" ou "Reboot required" |
| `switchMode(newMode)` | Inicia fluxo de confirmação/execução |
| `refresh()` | Re-query estado |

### Frontend: GpuMode Popout

**Arquivo**: `modules/bar/popouts/GpuMode.qml`

#### Layout Visual

```
Estado Normal:
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │  ← activeMode (modo real)
│ Intel iGPU + NVIDIA dGPU        │  ← descrição do activeMode
│                                 │
│  ┌─────────────────────────┐    │
│  │ [○] [●] [○]             │    │  ← Botões (Int/Hyb/Ded)
│  │     ████                │    │  ← Indicador (segue pending ou active)
│  └─────────────────────────┘    │
│                                 │
│ Pending Logout to Integrated    │  ← vermelho, quando há pending
└─────────────────────────────────┘

Durante Confirmação:
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │
│ Click again to confirm Integrated│ ← cor terciária
│                                 │
│  ┌─────────────────────────┐    │
│  │ [◉] [○] [○]             │    │  ← Indicador no botão de confirmação
│  └─────────────────────────┘    │  ← cor terciária
│                                 │
│ Logout required (~60s)          │  ← vermelho se operação lenta
└─────────────────────────────────┘

Durante Switching:
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │
│ Switching to Integrated... 45s  │  ← timer countdown
│                                 │
│  ┌─────────────────────────┐    │
│  │ [○] [○] [○] (dimmed)    │    │  ← Botões bloqueados
│  │ ████ (gray)             │    │  ← Indicador cinza
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

#### Badge de Operação Lenta

Uma bolinha vermelha aparece em botões que resultariam em operação lenta (~60s):
- Aparece em **Hybrid** quando `configuredMode === "integrated"`
- Aparece em **Integrated** quando `configuredMode === "hybrid"`
- NÃO aparece em Dedicated (operações com Dedicated são sempre instantâneas)

---

## Arquivos

### Criados

| Arquivo | Descrição |
|---------|-----------|
| `services/GpuModeService.qml` | Singleton backend (~280 linhas) |
| `modules/bar/popouts/GpuMode.qml` | UI do popout (~300 linhas) |

### Modificados

| Arquivo | Mudança |
|---------|---------|
| `modules/bar/components/StatusIcons.qml` | Adicionado ícone GPU (condicional a `showGpuMode`) |
| `modules/bar/popouts/Content.qml` | Registrado popout "gpumode" |
| `config/BarConfig.qml` | Adicionado `showGpuMode: true` em `Status` |
| `modules/controlcenter/taskbar/TaskbarPane.qml` | Toggle "GPU Mode" no painel de configurações |

### Configuração

O ícone GPU pode ser habilitado/desabilitado no painel de configurações:
1. Abrir Control Center (click no relógio ou ícones de status)
2. Aba ⚙️ (Settings)
3. Seção "Taskbar" → Toggle "GPU Mode"

A configuração é salva em `~/.config/quickshell/caelestia/config.json`:
```json
{
  "bar": {
    "status": {
      "showGpuMode": true
    }
  }
}
```

### Deploy

```bash
# Copiar todos os arquivos
cp services/GpuModeService.qml ~/.config/quickshell/caelestia/services/
cp modules/bar/popouts/GpuMode.qml ~/.config/quickshell/caelestia/modules/bar/popouts/
cp modules/bar/components/StatusIcons.qml ~/.config/quickshell/caelestia/modules/bar/components/
cp modules/bar/popouts/Content.qml ~/.config/quickshell/caelestia/modules/bar/popouts/
cp config/BarConfig.qml ~/.config/quickshell/caelestia/config/
cp modules/controlcenter/taskbar/TaskbarPane.qml ~/.config/quickshell/caelestia/modules/controlcenter/taskbar/

# Reiniciar
pkill -x quickshell && quickshell -c caelestia --daemonize
```

---

## UX e Estados Visuais

### Cores do Indicador

| Estado | Cor | Significado |
|--------|-----|-------------|
| Normal | `m3primary` (azul) | Modo atual/pending |
| Confirmação | `m3tertiary` (roxo) | Aguardando segundo click |
| Switching | `m3outline` (cinza) | Operação em andamento |

### Texto de Status

| Situação | Texto | Cor |
|----------|-------|-----|
| Sem pending | (descrição do modo) | Normal |
| Aguardando confirmação | "Click again to confirm X" | Terciária |
| Switching com timer | "Switching to X... Ys" | Primária |
| Switching sem timer | "Applying X..." | Primária |
| Pending após switch | "Pending Logout to X" | **Vermelho** |
| Pending reboot | "Pending Reboot to X" | **Vermelho** |

### Ação Necessária (durante confirmação)

| Transição | Texto | Cor |
|-----------|-------|-----|
| → Dedicated | "Reboot required" | Vermelho |
| Dedicated → | "Reboot required" | Vermelho |
| Hybrid ↔ Integrated | "Logout required (~60s)" | Vermelho |

---

## Bugs Corrigidos

### 1. Process stdout null
**Causa**: Acessar `process.stdout` após `exited` retorna null  
**Fix**: Usar `SplitParser` dentro de `stdout:` property

### 2. "Unknown" tratado como modo válido
**Causa**: `-P` retorna "Unknown" quando não há pending  
**Fix**: Tratar "Unknown" e "None" como `pendingMode=""`

### 3. Case-sensitivity no comando
**Causa**: `asusmuxdgpu` precisa ser `AsusMuxDgpu`  
**Fix**: Mapeamento explícito antes de chamar supergfxctl

### 4. activeMode detectado errado
**Causa**: `supergfxctl -g` retorna modo configurado, não real  
**Fix**: Usar `nvidia-smi` para detectar se NVIDIA está ativa

### 5. Timer usando activeMode ao invés de configuredMode
**Causa**: Tempo estimado baseado no modo real, não no configurado  
**Fix**: `getEstimatedTime(configuredMode, newMode)` - supergfxctl parte do configurado

### 6. Badge não aparecia no modo "atual"
**Causa**: Badge verificava `!isCurrent`  
**Fix**: Badge ignora isCurrent, só verifica se a operação será lenta

---

## Comandos Úteis

### Debug

```bash
# Ver estado atual
supergfxctl -g && supergfxctl -P

# Verificar NVIDIA real
nvidia-smi --query-gpu=name --format=csv,noheader

# Ver logs do service
strings /run/user/1000/quickshell/by-id/*/log.qslog | grep -i gpu | tail -30

# Deploy e reiniciar
cp services/GpuModeService.qml ~/.config/quickshell/caelestia/services/ && \
cp modules/bar/popouts/GpuMode.qml ~/.config/quickshell/caelestia/modules/bar/popouts/ && \
pkill -x quickshell && quickshell -c caelestia --daemonize
```

### Medir Tempos

```bash
# Hybrid -> Integrated
time supergfxctl -m Integrated  # ~0s (apenas marca)

# Integrated -> Hybrid (a operação lenta)
time supergfxctl -m Hybrid      # ~55s

# Qualquer -> Dedicated
time supergfxctl -m AsusMuxDgpu # ~0s (apenas marca, reboot aplica)
```

---

## Lições Aprendidas

1. **`supergfxctl -g` NÃO retorna modo real**: Retorna o configurado. Usar `nvidia-smi` para detectar estado real.

2. **Tempos devem ser MEDIDOS**: Não chutar valores. A demora de ~60s é específica para Hybrid↔Integrated.

3. **activeMode vs configuredMode**: Distinção crítica. UI mostra active, lógica de tempo usa configured.

4. **Badge de aviso**: Deve usar `configuredMode` (ponto de partida real do supergfxctl).

5. **Quickshell Process API**: Sempre usar `SplitParser` para ler stdout.

6. **Case-sensitivity**: supergfxctl requer capitalização exata (`AsusMuxDgpu`).

7. **Confirmação UX**: Evita cliques acidentais em operações que demoram 60s ou requerem reboot.

---

## Referências

- Plano original: `docs/plan-and-implementation/32-gpu-mode-selector.md`
- supergfxctl: https://gitlab.com/asus-linux/supergfxctl
- Quickshell Process: https://quickshell.outfoxxed.me/docs/io/process/
- Material Symbols: https://fonts.google.com/icons
