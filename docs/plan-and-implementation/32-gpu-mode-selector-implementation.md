# 32. GPU Mode Selector - Implementação

**Status**: ✅ Completo  
**Data**: 2026-02-05 (implementação) / 2026-02-06 (bugfixes + arquitetura de persistência)  
**Tempo Total**: ~14h (incluindo debugging extenso e redesign da arquitetura)

---

## Sumário

- [Objetivo](#objetivo)
- [Arquitetura do Sistema](#arquitetura-do-sistema)
- [Comportamento do supergfxctl](#comportamento-do-supergfxctl)
- [Conceitos Chave](#conceitos-chave)
- [Arquivos de Sistema](#arquivos-de-sistema)
- [Backend QML: GpuModeService](#backend-qml-gpumodeservice)
- [Frontend QML: GpuMode Popout](#frontend-qml-gpumode-popout)
- [UX e Estados Visuais](#ux-e-estados-visuais)
- [Fluxo UX por Transição](#fluxo-ux-por-transição)
- [Bugs Corrigidos](#bugs-corrigidos)
- [Comandos Úteis](#comandos-úteis)
- [Lições Aprendidas](#lições-aprendidas)
- [Referências](#referências)

---

## Objetivo

Seletor de modos de GPU na barra do Caelestia Shell, permitindo alternar entre Integrated/Hybrid/Dedicated via interface gráfica com:
- Indicador visual do modo REAL (activeMode) vs CONFIGURADO (configuredMode)
- Confirmação antes de executar (click duplo com timeout de 3s)
- Indicação clara de "Pending Reboot to X" quando há mudança pendente
- Persistência confiável da config para sobreviver reboots
- Proteção contra carregamento indevido de módulos nvidia em modo Integrated

---

## Arquitetura do Sistema

### Por que não basta usar `supergfxctl -m`?

O daemon `supergfxd` tem limitações críticas que exigem nossa própria infraestrutura:

1. **Não persiste config para Hybrid/Integrated**: O daemon aceita `supergfxctl -m Hybrid` (exit 0), mas NÃO escreve em `/etc/supergfxd.conf`. Ele guarda o modo pendente na memória e tenta completar a troca via `WaitLogout` (monitorando a sessão systemd). Se o logout não acontece em 30s, o daemon erra e descarta a mudança.

2. **`WaitLogout` causa problemas de sessão**: Chamar `supergfxctl -m Hybrid` (de Integrated) faz o daemon interagir com a sessão logind, causando lag severo na UI. Chamar `supergfxctl -m Integrated` (de Hybrid) tenta descarregar módulos nvidia com o compositor rodando, causando crash do Hyprland (aparece tela de welcome/setup).

3. **Dedicated funciona via firmware**: O MUX switch (Dedicated/AsusMuxDgpu) é um estado de hardware armazenado no firmware ASUS. `supergfxctl -m AsusMuxDgpu` configura o MUX diretamente e retorna "Reboot required". Esse modo funciona corretamente porque não depende de logout.

4. **`nvidia_drm` impede modo Integrated**: Sem intervenção, os módulos nvidia carregam automaticamente via udev em todos os boots (por causa de `options nvidia-drm modeset=1` em `/etc/modprobe.d/supergfxd.conf`). Se carregam em modo Integrated, `supergfxd` tenta `rmmod nvidia_drm` que falha porque o módulo está registrado como driver KMS, deixando o daemon travado/não-responsivo.

### Solução: Persistência Direta + Modprobe Guard

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FLUXO DE SWITCH (TODOS OS MODOS)                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Usuário confirma switch no UI                                      │
│         │                                                           │
│         ▼                                                           │
│  gpu-mode-persist <Mode>     ← escreve em /etc/supergfxd.conf      │
│  (sudo, sem senha)              (via sudoers.d rule)                │
│         │                                                           │
│         ├── Se Dedicated envolvido (from ou to):                    │
│         │   └── supergfxctl -m <Mode>  ← configura MUX hardware    │
│         │                                                           │
│         ├── Se Hybrid ↔ Integrated:                                 │
│         │   └── (NÃO chama supergfxctl -m — evita WaitLogout)       │
│         │                                                           │
│         ▼                                                           │
│  UI mostra "Pending Reboot to <Mode>"                               │
│         │                                                           │
│         ▼                                                           │
│  Usuário reboota quando quiser                                      │
│         │                                                           │
│         ▼                                                           │
│  BOOT:                                                              │
│  1. modprobe guard lê /etc/supergfxd.conf                           │
│     - Se "Integrated": bloqueia nvidia, nvidia_drm, etc.            │
│     - Se "Hybrid"/"AsusMuxDgpu": permite nvidia normalmente         │
│  2. supergfxd inicia, lê config, faz do_mode_setup_tasks()          │
│  3. Sistema entra no modo correto                                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Comportamento do supergfxctl

### Modos Disponíveis

| Modo | Nome UI | Descrição | Tipo de Switch |
|------|---------|-----------|----------------|
| `Integrated` | Integrated | Intel iGPU only | Software (config) |
| `Hybrid` | Hybrid | Intel iGPU + NVIDIA dGPU | Software (config) |
| `AsusMuxDgpu` | Dedicated | NVIDIA dGPU only (MUX) | Hardware (firmware) |

### Comandos

```bash
supergfxctl -g          # Get mode from daemon (NOT necessarily the config!)
supergfxctl -P          # Get pending mode ("Unknown" = none)
supergfxctl -m Mode     # Set mode (CASE-SENSITIVE!)
supergfxctl -S          # Get power status (on/off/suspended)
```

### ⚠️ Case-Sensitivity

O comando `-m` requer capitalização **exata**:
- ✅ `supergfxctl -m Integrated`
- ✅ `supergfxctl -m Hybrid`
- ✅ `supergfxctl -m AsusMuxDgpu`
- ❌ `supergfxctl -m integrated` (falha!)
- ❌ `supergfxctl -m asusmuxdgpu` (falha!)

### Tempos de Operação

| Transição | Tempo do Comando | Ação Necessária |
|-----------|-----------------|-----------------|
| Hybrid ↔ Integrated | **~1s** (só persiste config) | Reboot |
| Qualquer ↔ Dedicated | **~3s** (persiste + MUX) | Reboot |

Todas as transições são instantâneas do ponto de vista do usuário. A mudança real acontece no próximo boot.

---

## Conceitos Chave

### activeMode vs configuredMode vs pendingMode

```
┌─────────────────────────────────────────────────────────────────┐
│ activeMode    = Modo REAL rodando agora                         │
│                 (detectado via nvidia-smi no boot)              │
│                 Só muda após reboot                             │
├─────────────────────────────────────────────────────────────────┤
│ configuredMode = Modo que o daemon reporta (supergfxctl -g)     │
│                  Atualizado na UI após switch bem-sucedido       │
│                  É o ponto de partida para próximo switch        │
├─────────────────────────────────────────────────────────────────┤
│ pendingMode   = configuredMode se != activeMode                 │
│                 Indica mudança aguardando reboot                │
└─────────────────────────────────────────────────────────────────┘
```

**Exemplo prático:**
1. Boot em Hybrid → activeMode=hybrid, configuredMode=hybrid, pendingMode=""
2. Clica em Integrated (2x para confirmar)
3. Config salva instantaneamente → activeMode=hybrid, configuredMode=integrated, pendingMode=integrated
4. UI mostra: "GPU Mode: Hybrid" + "Pending Reboot to Integrated"
5. Usuário reboota
6. Guard bloqueia nvidia, daemon lê config=Integrated
7. Agora → activeMode=integrated, configuredMode=integrated, pendingMode=""

### Detecção do Modo Real (activeMode)

`supergfxctl -g` retorna o modo que o daemon reporta, não necessariamente o real. Para detectar o modo REAL no boot:

```bash
timeout 5 nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null \
  && echo 'nvidia_active' || echo 'nvidia_off'
```

- `nvidia_active` → NVIDIA acessível → activeMode = Hybrid ou Dedicated (refinado via `supergfxctl -g`)
- `nvidia_off` → NVIDIA desligada/ausente → activeMode = Integrated
- Timeout 5s: necessário porque `nvidia-smi` pode travar indefinidamente se a dGPU está desligada

### Fluxo de Confirmação

1. **Primeiro click**: Mostra "Click again to confirm X" + indicador muda para cor terciária
2. **Segundo click (mesmo botão)**: Executa a operação
3. **Click em outro botão**: Muda confirmação para o novo botão
4. **Click no modo atual (sem pending)**: Cancela confirmação
5. **Click no modo pending**: Cancela confirmação
6. **Timeout 3s**: Confirmação expira automaticamente

### Software Switch vs Hardware MUX Switch

| Aspecto | Software (Hybrid ↔ Integrated) | Hardware MUX (↔ Dedicated) |
|---------|-------------------------------|---------------------------|
| O que muda | Módulos nvidia carregados ou não | Roteamento físico do display |
| Persistido em | `/etc/supergfxd.conf` | Firmware ASUS + config |
| Precisa de `supergfxctl -m` | NÃO (causaria lag/crash) | SIM (para configurar MUX) |
| Nosso código faz | Só `gpu-mode-persist` | `gpu-mode-persist` + `supergfxctl -m` |
| Condição no QML | `needsDaemon = false` | `needsDaemon = true` |

---

## Arquivos de Sistema

### `/usr/local/bin/gpu-mode-persist`

Helper script que atualiza o modo em `/etc/supergfxd.conf`. Executado com sudo sem senha.

```bash
#!/bin/bash
# Valida modo (whitelist) e atualiza JSON via python3
# Aceita: Integrated, Hybrid, AsusMuxDgpu
# Exit 1 se modo inválido
```

**Por que existe**: `supergfxd` não persiste a config para switches Hybrid/Integrated. Sem este helper, a mudança se perde no reboot.

### `/etc/sudoers.d/gpu-mode-persist`

```
pereiraoc ALL=(ALL) NOPASSWD: /usr/local/bin/gpu-mode-persist
```

Permite que o QML (rodando como usuário) chame o helper sem prompt de senha.

### `/etc/modprobe.d/gpu-mode-nvidia-guard.conf`

```bash
install nvidia     /bin/sh -c 'grep -q Integrated /etc/supergfxd.conf && exit 1 || /sbin/modprobe --ignore-install nvidia'
install nvidia_drm /bin/sh -c 'grep -q Integrated /etc/supergfxd.conf && exit 1 || /sbin/modprobe --ignore-install nvidia_drm'
install nvidia_modeset /bin/sh -c 'grep -q Integrated /etc/supergfxd.conf && exit 1 || /sbin/modprobe --ignore-install nvidia_modeset'
install nvidia_uvm /bin/sh -c 'grep -q Integrated /etc/supergfxd.conf && exit 1 || /sbin/modprobe --ignore-install nvidia_uvm'
```

**Função**: Intercepta `modprobe nvidia*`. Se a config diz "Integrated", bloqueia o carregamento (exit 1). Caso contrário, carrega normalmente.

**Por que existe**: Sem isto, `udev` carrega `nvidia_drm` automaticamente em todo boot (por causa de `options nvidia-drm modeset=1`). Uma vez carregado, `nvidia_drm` se registra como driver KMS e não pode ser descarregado — `supergfxd` tenta `rmmod` e falha, ficando travado.

### `/etc/modprobe.d/supergfxd.conf` (gerenciado pelo daemon)

```bash
# Automatically generated by supergfxd
blacklist nouveau
alias nouveau off
options nvidia-drm modeset=1
```

**Nota**: Este arquivo é reescrito pelo daemon a cada boot. NÃO editar manualmente.

### `/etc/mkinitcpio.conf` (modificações)

```bash
MODULES=(xe)    # Intel GPU driver carregado cedo no initramfs
HOOKS=(base udev autodetect microcode modconf keyboard keymap consolefont block filesystems fsck)
# NOTA: kms hook REMOVIDO — impedia controle fino de quais drivers KMS carregam
```

**Mudanças**:
- `MODULES=(xe)`: Garante que o driver Intel esteja disponível cedo no boot, especialmente em modo Integrated
- `kms` removido de HOOKS: O hook `kms` carregava automaticamente todos os drivers KMS (incluindo nvidia) cedo demais, antes do guard ter efeito

### `/etc/supergfxd.conf`

```json
{
  "mode": "Hybrid",
  "vfio_enable": false,
  "vfio_save": false,
  "always_reboot": true,
  "no_logind": false,
  "logout_timeout_s": 180,
  "hotplug_type": "None"
}
```

**Campos relevantes**:
- `mode`: Modo que o daemon aplica no boot. **Escrito pelo nosso helper**, não pelo daemon (para Hybrid/Integrated)
- `always_reboot`: `true` — faz o daemon retornar "Reboot required" em vez de tentar `WaitLogout` (que falha e causa problemas de sessão)

### `/etc/systemd/logind.conf`

```ini
[Login]
KillUserProcesses=yes
```

**Por que**: Garante que processos do usuário sejam terminados no logout/shutdown, liberando referências a módulos nvidia.

### `/etc/sddm.conf.d/10-autologin.conf`

```ini
[Autologin]
User=pereiraoc
Session=hyprland
Relogin=true
```

**Campos relevantes**:
- `Relogin=true`: Garante que o autologin funcione após logout (não só no primeiro boot). Sem isto, após logout o SDDM mostraria a tela de login ao invés de fazer autologin.

---

## Backend QML: GpuModeService

**Arquivo**: `services/GpuModeService.qml`  
**Tipo**: Singleton (~340 linhas)

### Properties

| Property | Tipo | Descrição |
|----------|------|-----------|
| `activeMode` | string | Modo REAL rodando (detectado via nvidia-smi). Valores: `"integrated"`, `"hybrid"`, `"asusmuxdgpu"`, `""` |
| `configuredMode` | string | Modo reportado pelo daemon / setado após switch |
| `pendingMode` | string | `configuredMode` se diferente de `activeMode`, senão `""` |
| `available` | bool | `true` se `supergfxctl` está instalado |
| `switching` | bool | `true` durante execução do switch (poucos segundos) |
| `loading` | bool | `true` durante detecção inicial no boot |
| `switchTimeRemaining` | int | Sempre 0 (legacy, mantido por compatibilidade com UI) |
| `targetMode` | string | Modo alvo durante switching |
| `lastError` | string | Mensagem de erro (auto-limpa após 10s via errorTimer) |
| `pendingConfirmation` | string | Modo aguardando segundo click (auto-limpa após 3s) |
| `__nvidiaDetectionResult` | string | Interno: resultado do nvidia-smi para uso em onExited |
| `switchProcess` | var | Referência ao Process dinâmico de switch |

### Signals

| Signal | Parâmetros | Descrição |
|--------|-----------|-----------|
| `modeChanged` | `string newMode` | Emitido quando modo é detectado/alterado |
| `switchFailed` | `string error` | Emitido quando switch falha |
| `switchSuccess` | `string newMode` | Emitido quando switch completa com sucesso |

### Timers

| Timer | Intervalo | Condição | Função |
|-------|-----------|----------|--------|
| `countdownTimer` | 1000ms | `switching && switchTimeRemaining > 0` | Legacy: decrementa switchTimeRemaining. Na arquitetura atual nunca ativa (switchTimeRemaining é sempre 0) |
| `confirmationTimer` | 3000ms | `pendingConfirmation !== ""` | Expira confirmação de click se usuário não confirma em 3s |
| `errorTimer` | 10000ms | `lastError !== ""` | Limpa mensagem de erro após 10s |
| `switchTimeout` | 120000ms | Manual (restart) | Safety net: se o processo de switch travar, reseta UI após 2min |
| `startupTimer` | 100ms | `true` (auto-start) | Inicia detecção no boot com delay de 100ms |

### Processos (Cadeia de Boot)

```
startupTimer (100ms)
    └─→ checkProcess: which supergfxctl
        └─→ (se disponível) detectActiveMode: timeout 5 nvidia-smi ...
            └─→ (sempre de onExited) queryProcess: timeout 5 supergfxctl -g
                └─→ loading = false, UI pronta
```

1. **checkProcess**: Verifica se `supergfxctl` está instalado. Se não, `available=false`, `loading=false`.
2. **detectActiveMode**: Roda `nvidia-smi` com timeout 5s. Resultado guardado em `__nvidiaDetectionResult` via SplitParser, processado em `onExited`. Se NVIDIA off → `activeMode="integrated"`. Se NVIDIA on → `activeMode="__nvidia_active__"` (placeholder refinado em queryProcess).
3. **queryProcess**: Roda `supergfxctl -g` com timeout 5s. Retorna o modo do daemon. Se `activeMode` era `"__nvidia_active__"`, usa o modo reportado (hybrid ou asusmuxdgpu). Seta `configuredMode`, calcula `pendingMode`, seta `loading=false`.

**Regra crítica**: `queryProcess` é iniciado SEMPRE de `detectActiveMode.onExited`, NUNCA de `SplitParser.onRead`. Iniciar um Process de dentro de SplitParser.onRead de outro Process não funciona de forma confiável no Quickshell.

### Functions

| Função | Retorno | Descrição |
|--------|---------|-----------|
| `getModeName(mode)` | string | `"integrated"→"Integrated"`, `"hybrid"→"Hybrid"`, `"asusmuxdgpu"→"Dedicated"` |
| `getModeDescription(mode)` | string | `"integrated"→"Intel iGPU only"`, `"hybrid"→"Intel iGPU + NVIDIA dGPU"`, `"asusmuxdgpu"→"NVIDIA dGPU only"` |
| `getEstimatedTime(from, to)` | int | Sempre retorna 0 (todos os switches são instantâneos + reboot) |
| `getRequiredAction(from, to)` | string | Sempre retorna `"reboot"` (todos os switches requerem reboot) |
| `getActionText(action)` | string | `"reboot"→"Reboot required"` |
| `isSlowSwitch(from, to)` | bool | Sempre retorna `false` (sem switches lentos na arquitetura atual) |
| `switchMode(newMode)` | void | Fluxo de confirmação + execução (veja abaixo) |
| `executeSwitch(newMode)` | void | Executa o switch (veja abaixo) |
| `refresh()` | void | Re-query `supergfxctl -g` para atualizar configuredMode |

### Fluxo de `switchMode(newMode)`

```
switchMode("hybrid")
    ├── Se !available || switching || loading → return (ignora)
    ├── Se newMode === activeMode && pendingMode === "" → return (já é o modo)
    ├── Se newMode === pendingMode → pendingConfirmation = "" (cancela)
    ├── Se pendingConfirmation === newMode → executeSwitch(newMode) (confirmado!)
    └── Senão → pendingConfirmation = newMode (pede confirmação)
```

### Fluxo de `executeSwitch(newMode)`

```
executeSwitch("hybrid")
    │
    ├── switching = true, targetMode = "hybrid"
    │
    ├── cmd = "Hybrid" (capitalização para supergfxctl)
    │
    ├── needsDaemon = (cmd === "AsusMuxDgpu" || activeMode === "asusmuxdgpu")
    │   │
    │   ├── true  → shellCmd = "sudo gpu-mode-persist Hybrid && timeout 15 supergfxctl -m Hybrid || true"
    │   └── false → shellCmd = "sudo gpu-mode-persist Hybrid"
    │
    ├── Cria Process com running: false (evita race condition)
    ├── Conecta handler exited ANTES de iniciar
    ├── running = true
    │
    └── onExited:
        ├── exit 0 → switching=false, configuredMode=newMode, pendingMode calculado, switchSuccess()
        └── exit ≠ 0 → switching=false, lastError="Failed to save mode", switchFailed()
```

---

## Frontend QML: GpuMode Popout

**Arquivo**: `modules/bar/popouts/GpuMode.qml` (~290 linhas)

### Layout Visual

```
Estado Normal (sem pending):
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │  ← activeMode (modo real)
│ Intel iGPU + NVIDIA dGPU        │  ← descrição do activeMode
│                                 │
│  ┌─────────────────────────┐    │
│  │ [○] [●] [○]             │    │  ← Botões (Int/Hyb/Ded)
│  │     ████                │    │  ← Indicador azul (active)
│  └─────────────────────────┘    │
└─────────────────────────────────┘

Com Pending (após switch, antes de reboot):
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │  ← activeMode (ainda Hybrid!)
│                                 │
│  ┌─────────────────────────┐    │
│  │ [●] [○] [○]             │    │  ← Indicador no pending mode
│  │ ████                    │    │  ← Indicador azul
│  └─────────────────────────┘    │
│                                 │
│ Pending Reboot to Integrated    │  ← vermelho
└─────────────────────────────────┘

Durante Confirmação:
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │
│ Click again to confirm Integrated│ ← cor terciária (roxo)
│                                 │
│  ┌─────────────────────────┐    │
│  │ [◉] [○] [○]             │    │  ← Indicador roxo (confirmação)
│  └─────────────────────────┘    │
│                                 │
│ Reboot required                 │  ← vermelho
└─────────────────────────────────┘

Durante Switching (poucos segundos):
┌─────────────────────────────────┐
│ GPU Mode: Hybrid                │
│ Applying Integrated...          │  ← cor primária
│                                 │
│  ┌─────────────────────────┐    │
│  │ [○] [○] [○] (dimmed)    │    │  ← Botões bloqueados, overlay 50%
│  │ ████ (gray)             │    │  ← Indicador cinza
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

### Cores do Indicador

| Estado | Cor | Significado |
|--------|-----|-------------|
| Normal / Pending | `m3primary` (azul) | Modo ativo ou pending |
| Confirmação | `m3tertiary` (roxo) | Aguardando segundo click |
| Switching | `m3outline` (cinza) | Operação em andamento |

### Posição do Indicador (profiles.current)

O indicador desliza entre os 3 botões com animação (BezierSpline). Prioridade:
1. Se `switching` + `targetMode` → posiciona no target
2. Se `pendingConfirmation` → posiciona no botão de confirmação
3. Se `pendingMode` → posiciona no pending
4. Senão → posiciona no `activeMode`

### ModeButton Component

Cada botão (Integrated, Hybrid, Dedicated) é um `ModeButton` com:

| Property | Tipo | Descrição |
|----------|------|-----------|
| `isCurrent` | bool | `activeMode === mode` |
| `isPending` | bool | `pendingMode === mode && pendingMode !== activeMode` |
| `isTarget` | bool | `switching && targetMode === mode` |
| `isConfirmation` | bool | `pendingConfirmation === mode` |
| `isDisabled` | bool | `switching \|\| loading` |

**Cores do ícone** (MaterialIcon, filled quando ativo):
- Disabled → `m3outline` (cinza)
- Confirmation → `m3onTertiary` (sobre roxo)
- Target / Pending → `m3onPrimary` (sobre azul)
- Current → `m3onPrimary` (sobre azul)
- Default → `m3onSurface` (neutro)

### Ícones por Modo

| Modo | Ícone Material | ID |
|------|---------------|----|
| Integrated | `memory` | Chip |
| Hybrid | `swap_horiz` | Setas |
| Dedicated | `developer_board` | Placa |

### Textos de Status

| Situação | Texto | Cor | Visibilidade |
|----------|-------|-----|-------------|
| Normal (sem pending) | `"Intel iGPU + NVIDIA dGPU"` (etc) | m3onSurface | !switching && !confirmation && !loading |
| Confirmação pendente | `"Click again to confirm X"` | m3tertiary | hasConfirmation |
| Switching | `"Applying X..."` | m3primary | switching |
| Pending reboot | `"Pending Reboot to X"` | m3error (vermelho) | hasPending && !switching && !confirmation |
| Erro | `"Failed to save mode"` ou `"supergfxd not responding"` | m3error | lastError !== "" |
| Loading | `"Loading..."` | m3onSurfaceVariant | loading |

### Texto de Ação (durante confirmação)

| Texto | Cor | Quando |
|-------|-----|--------|
| `"Reboot required"` | m3error (vermelho) | Sempre (todos os switches requerem reboot) |

---

## Fluxo UX por Transição

### Hybrid → Integrated

1. Click em Integrated: "Click again to confirm Integrated" + "Reboot required"
2. Segundo click: "Applying Integrated..." (1-2s), botões bloqueados
3. Config salva: "Pending Reboot to Integrated" (vermelho)
4. Usuário reboota quando quiser
5. Guard bloqueia nvidia, daemon lê config=Integrated
6. SDDM faz autologin, sistema em Integrated

### Integrated → Hybrid

1. Click em Hybrid: "Click again to confirm Hybrid" + "Reboot required"
2. Segundo click: "Applying Hybrid..." (1-2s), botões bloqueados
3. Config salva: "Pending Reboot to Hybrid" (vermelho)
4. Usuário reboota
5. Guard permite nvidia, daemon carrega módulos nvidia
6. SDDM faz autologin, sistema em Hybrid com NVIDIA ativa

### Qualquer → Dedicated

1. Click em Dedicated: "Click again to confirm Dedicated" + "Reboot required"
2. Segundo click: "Applying Dedicated..." (3-5s), botões bloqueados
3. `gpu-mode-persist AsusMuxDgpu` + `supergfxctl -m AsusMuxDgpu` (configura MUX hardware)
4. Config salva + MUX configurado: "Pending Reboot to Dedicated"
5. Usuário reboota
6. MUX redireciona display pela NVIDIA, daemon confirma Dedicated

### Dedicated → Qualquer

1. Click no modo alvo: confirmação + "Reboot required"
2. Segundo click: `gpu-mode-persist <Mode>` + `supergfxctl -m <Mode>` (reconfigura MUX)
3. "Pending Reboot to X"
4. Reboot aplica

---

## Arquivos QML

### Criados

| Arquivo | Descrição |
|---------|-----------|
| `services/GpuModeService.qml` | Singleton backend (~340 linhas) |
| `modules/bar/popouts/GpuMode.qml` | UI do popout (~290 linhas) |

### Modificados

| Arquivo | Mudança |
|---------|---------|
| `modules/bar/components/StatusIcons.qml` | Adicionado ícone GPU (condicional a `showGpuMode`) |
| `modules/bar/popouts/Content.qml` | Registrado popout "gpumode" |
| `config/BarConfig.qml` | Adicionado `showGpuMode: true` em `Status` |
| `modules/controlcenter/taskbar/TaskbarPane.qml` | Toggle "GPU Mode" no painel de configurações |

### Configuração do Ícone

O ícone GPU pode ser habilitado/desabilitado no painel de configurações:
1. Abrir Control Center (click no relógio ou ícones de status)
2. Aba ⚙️ (Settings)
3. Seção "Taskbar" → Toggle "GPU Mode"

Configuração salva em `~/.config/quickshell/caelestia/config.json`:
```json
{ "bar": { "status": { "showGpuMode": true } } }
```

### Arquivos de Sistema (requerem root)

| Arquivo | Tipo | Gerenciado por |
|---------|------|---------------|
| `/usr/local/bin/gpu-mode-persist` | Helper script | Manual (criado uma vez) |
| `/etc/sudoers.d/gpu-mode-persist` | Sudoers rule | Manual (criado uma vez) |
| `/etc/modprobe.d/gpu-mode-nvidia-guard.conf` | Modprobe guard | Manual (criado uma vez) |
| `/etc/modprobe.d/supergfxd.conf` | Modprobe config | supergfxd (auto-gerado) |
| `/etc/supergfxd.conf` | Daemon config | `gpu-mode-persist` + daemon |
| `/etc/mkinitcpio.conf` | Initramfs config | Manual (editado uma vez) |
| `/etc/systemd/logind.conf` | Logind config | Manual (editado uma vez) |
| `/etc/sddm.conf.d/10-autologin.conf` | SDDM autologin | Manual (editado uma vez) |

### Deploy

```bash
# QML files
cp services/GpuModeService.qml ~/.config/quickshell/caelestia/services/
cp modules/bar/popouts/GpuMode.qml ~/.config/quickshell/caelestia/modules/bar/popouts/

# Reiniciar quickshell
pkill -x quickshell && quickshell -c caelestia --daemonize
```

---

## Bugs Corrigidos

### 1. Process stdout null (2026-02-05)
**Causa**: Acessar `process.stdout` após `exited` retorna null  
**Fix**: Usar `SplitParser` dentro de `stdout:` property

### 2. "Unknown" tratado como modo válido (2026-02-05)
**Causa**: `-P` retorna "Unknown" quando não há pending  
**Fix**: Tratar "Unknown" e "None" como `pendingMode=""`

### 3. Case-sensitivity no comando (2026-02-05)
**Causa**: `asusmuxdgpu` precisa ser `AsusMuxDgpu`  
**Fix**: Mapeamento explícito antes de chamar supergfxctl

### 4. activeMode detectado errado (2026-02-05)
**Causa**: `supergfxctl -g` retorna modo configurado, não real  
**Fix**: Usar `nvidia-smi` para detectar se NVIDIA está ativa

### 5. Timer usando activeMode ao invés de configuredMode (2026-02-05)
**Causa**: Tempo estimado baseado no modo real, não no configurado  
**Fix**: `getEstimatedTime(configuredMode, newMode)` - supergfxctl parte do configurado

### 6. Badge não aparecia no modo "atual" (2026-02-05)
**Causa**: Badge verificava `!isCurrent`  
**Fix**: Badge ignora isCurrent, só verifica se a operação será lenta  
**Nota**: Badge removido na v2 (2026-02-06) — não há mais operações lentas

### 7. Loading infinito em modo Integrated (2026-02-06)
**Causa**: `queryProcess.running = true` era setado de dentro de `detectActiveMode.stdout.SplitParser.onRead`. Quickshell não inicia um Process de forma confiável quando `.running = true` é atribuído dentro de um callback de `SplitParser.onRead` de outro Process.  
**Fix**: Guardar resultado em `__nvidiaDetectionResult` via `onRead`, iniciar `queryProcess` SEMPRE de `detectActiveMode.onExited`.

### 8. Race condition no executeSwitch — signal perdido (2026-02-06)
**Causa**: `Qt.createQmlObject()` criava Process com `running: true`, e `exited.connect()` era registrado depois. Se `supergfxctl -m` falhasse instantaneamente, `exited` disparava antes do handler → `switching` ficava `true` para sempre.  
**Fix**: Criar Process com `running: false`, conectar handler, depois `running = true`.

### 9. supergfxctl -m sem timeout (2026-02-06)
**Causa**: `supergfxctl -m` sem wrapper de timeout. Se daemon travado, bloqueio indefinido.  
**Fix**: Envolver com `timeout N supergfxctl -m`.

### 10. nvidia-smi trava quando dGPU desligada (2026-02-06)
**Causa**: Em modo Integrated, `nvidia-smi` entra em uninterruptible sleep.  
**Fix**: Envolver com `timeout 5 nvidia-smi ...`.

### 11. supergfxd não persiste config para Hybrid/Integrated (2026-02-06)
**Causa**: O daemon aceita `supergfxctl -m Hybrid` (exit 0) mas guarda a mudança na memória, esperando logout via WaitLogout. Após 30s sem logout, descarta a mudança. Config nunca atualizada.  
**Fix**: Criação do helper `gpu-mode-persist` que escreve diretamente em `/etc/supergfxd.conf` com sudoers rule para execução sem senha.

### 12. nvidia_drm impede Integrated mode — daemon trava (2026-02-06)
**Causa**: `udev` carrega `nvidia_drm` automaticamente em todo boot. Em modo Integrated, `supergfxd` tenta `rmmod nvidia_drm` que falha (módulo registrado como KMS driver, sempre "in use"). Daemon fica travado/não-responsivo.  
**Fix**: Criação de `/etc/modprobe.d/gpu-mode-nvidia-guard.conf` com install hooks que bloqueiam nvidia quando config diz "Integrated". Remoção do hook `kms` de mkinitcpio e adição de `MODULES=(xe)`.

### 13. supergfxctl -m causa lag/crash de sessão (2026-02-06)
**Causa**: `supergfxctl -m Hybrid` (de Integrated) inicia WaitLogout que interage com logind, causando lag severo. `supergfxctl -m Integrated` (de Hybrid) tenta descarregar nvidia com compositor ativo, crashando Hyprland.  
**Fix**: NÃO chamar `supergfxctl -m` para switches Hybrid ↔ Integrated. Só persistir config e rebootar. `supergfxctl -m` é chamado APENAS quando Dedicated (MUX) está envolvido.

### 14. Switch de Dedicated não persiste — MUX hardware requer daemon (2026-02-06)
**Causa**: Código inicialmente não chamava `supergfxctl -m` ao sair DE Dedicated. O MUX hardware permanecia em Dedicated mesmo com config dizendo Hybrid.  
**Fix**: Condição `needsDaemon = (cmd === "AsusMuxDgpu" || root.activeMode === "asusmuxdgpu")` — chama daemon quando Dedicated está envolvido como origem OU destino.

---

## Comandos Úteis

### Debug

```bash
# Estado atual
supergfxctl -g                     # Modo reportado pelo daemon
cat /etc/supergfxd.conf            # Modo persistido (o que conta no reboot)
nvidia-smi --query-gpu=name --format=csv,noheader  # NVIDIA ativa?
lsmod | grep nvidia                # Módulos nvidia carregados?

# Logs do daemon
journalctl -b -u supergfxd --no-pager | tail -30

# Logs do quickshell (GPU)
strings /run/user/1000/quickshell/by-id/*/log.qslog | grep -i gpu | tail -30

# Verificar guard
cat /etc/modprobe.d/gpu-mode-nvidia-guard.conf

# Testar helper
sudo /usr/local/bin/gpu-mode-persist Hybrid && cat /etc/supergfxd.conf
```

### Deploy e Reiniciar

```bash
cp services/GpuModeService.qml ~/.config/quickshell/caelestia/services/ && \
cp modules/bar/popouts/GpuMode.qml ~/.config/quickshell/caelestia/modules/bar/popouts/ && \
pkill -x quickshell && quickshell -c caelestia --daemonize
```

---

## Lições Aprendidas

1. **`supergfxctl -g` NÃO retorna modo real**: Retorna o que o daemon reporta. Usar `nvidia-smi` para detectar estado real.

2. **Daemons podem não persistir config**: `supergfxd` aceita comandos e retorna sucesso, mas guarda o estado na memória. Sempre verificar se a config foi escrita de fato.

3. **Kernel modules KMS não descarregam**: `nvidia_drm` com `modeset=1` se registra como KMS driver. Uma vez registrado, referência do kernel impede `rmmod`, mesmo sem clientes userspace. Prevenção (via modprobe guard) é a única solução confiável.

4. **Hardware MUX != Software switch**: O MUX do laptop é um estado de firmware que redireciona fisicamente o display. Software switches (Hybrid/Integrated) são sobre módulos do kernel. Cada um requer tratamento diferente.

5. **Nunca iniciar Process de SplitParser.onRead**: No Quickshell, setar `Process.running = true` de dentro de `SplitParser.onRead` de outro Process não funciona. Sempre guardar resultado no `onRead` e iniciar no `onExited`.

6. **Sempre conectar handler ANTES de running = true**: Ao criar Process dinâmico com `Qt.createQmlObject`, usar `running: false`, conectar `exited`, e só depois `running = true`.

7. **Sempre usar `timeout` em comandos externos**: `nvidia-smi` e `supergfxctl` podem travar em estados edge-case. `timeout N` garante que nunca bloqueiam a UI.

8. **`supergfxctl -m` interage com a sessão**: Chamar `-m` para switches que requerem logout causa o daemon a monitorar/interagir com logind, causando efeitos colaterais (lag, crash). Para esses switches, melhor só persistir config e rebootar.

9. **Confirm antes de executar**: Click duplo previne switches acidentais em operação que requer reboot.

10. **activeMode vs configuredMode**: `activeMode` é o estado real do hardware (detectado via nvidia-smi). `configuredMode` é o que o daemon/config diz. `pendingMode` surge quando diferem. UI deve mostrar ambos claramente.

---

## Referências

- Plano original: `docs/plan-and-implementation/32-gpu-mode-selector.md`
- supergfxctl: https://gitlab.com/asus-linux/supergfxctl
- Quickshell Process: https://quickshell.outfoxxed.me/docs/io/process/
- Material Symbols: https://fonts.google.com/icons
