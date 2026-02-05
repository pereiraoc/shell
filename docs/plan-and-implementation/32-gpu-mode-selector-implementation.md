# 32. GPU Mode Selector - Implementação

**Status**: ✅ Completo  
**Data**: 2026-02-04  
**Tempo**: ~4h

---

## Objetivo

Implementar seletor de modos de GPU na barra do Caelestia Shell, permitindo alternar entre Integrated/Hybrid/Dedicated via interface gráfica.

---

## Arquitetura

### Backend: GpuModeService

**Arquivo**: `services/GpuModeService.qml`  
**Tipo**: Singleton

**Properties**:
- `currentMode: string` - Modo atual (integrated/hybrid/asusmuxdgpu/unknown)
- `available: bool` - Se supergfxctl está instalado
- `switching: bool` - Se há troca de modo em progresso

**Signals**:
- `modeChanged(string newMode)` - Emitido quando modo muda
- `switchFailed(string error)` - Emitido em erro
- `switchSuccess(string newMode)` - Emitido em sucesso

**Functions**:
- `getModeName(mode)` - Retorna nome legível ("Integrated", "Hybrid", "Dedicated")
- `getModeIcon(mode)` - Retorna nome do Material Icon
- `getModeDescription(mode)` - Retorna descrição do modo
- `switchMode(mode)` - Executa `supergfxctl -m Mode`

**Implementação**:
```qml
// Check availability
Process {
    id: checkProcess
    command: ["which", "supergfxctl"]
    running: !hasRun
    onExited: exitCode => {
        root.available = (exitCode === 0)
        if (root.available) {
            Qt.callLater(() => queryProcess.running = true)
        }
    }
}

// Query current mode
Process {
    id: queryProcess
    command: ["supergfxctl", "-g"]
    stdout: SplitParser {
        onRead: data => {
            const mode = data.trim().toLowerCase()
            root.currentMode = mode
        }
    }
}
```

**Fix crítico**: Usar `SplitParser` para ler stdout, não acessar `process.stdout` diretamente (retorna null).

### Frontend: GpuMode Popout

**Arquivo**: `modules/bar/popouts/GpuMode.qml`

**Estrutura**:
```qml
Column {
    StyledText { text: "GPU Mode: Hybrid" }
    StyledText { text: "Balanced performance..." }
    
    StyledRect { // Container dos botões
        Row {
            ModeButton { mode: "integrated"; icon: "memory" }
            ModeButton { mode: "hybrid"; icon: "swap_horiz" }
            ModeButton { mode: "asusmuxdgpu"; icon: "developer_board" }
        }
        
        StyledRect { id: indicator } // Indicador deslizante
    }
    
    StyledText { text: "Requires logout to apply" }
}
```

**Estados do indicador**:
- `"memory"`: x=0 (Integrated)
- `"swap_horiz"`: x=center (Hybrid)
- `"developer_board"`: x=right (Dedicated)

**Animação**: `Anim {}` com curva emphasizedDecel

### Bar Icon

**Arquivo**: `modules/bar/components/StatusIcons.qml`

**Adição**:
```qml
WrappedLoader {
    name: "gpumode"
    active: GpuModeService.available
    
    sourceComponent: MaterialIcon {
        animate: true
        text: "memory"
        color: root.colour
        fill: 1
    }
}
```

**Posição**: Antes do ícone de bateria

### Popout Registration

**Arquivo**: `modules/bar/popouts/Content.qml`

```qml
Popout {
    name: "gpumode"
    sourceComponent: GpuMode {}
}
```

---

## Material Icons Usados

| Modo | Icon | Descrição |
|------|------|-----------|
| Integrated | `memory` | Chip (representa iGPU) |
| Hybrid | `swap_horiz` | Setas horizontais (alterna GPUs) |
| Dedicated | `developer_board` | Placa GPU (dGPU dedicada) |

---

## Bugs Corrigidos

### 1. Process stdout null
**Sintoma**: `TypeError: Cannot call method 'trim' of null`  
**Causa**: Acessar `process.stdout` após `exited` retorna null  
**Fix**: Usar `SplitParser` dentro de `stdout:` property

### 2. font.pointSize undefined
**Sintoma**: `Unable to assign [undefined] to double`  
**Causa**: `Appearance.font.size.tiny` não existe  
**Fix**: Mudar para `Appearance.font.size.small` (11pt)

### 3. Bluetooth - Ícones duplicados
**Sintoma**: Ícone de headphone aparece ao lado do ícone de Bluetooth  
**Causa**: `Repeater` mostra cada dispositivo Bluetooth conectado  
**Fix**: Remover `Repeater` e `ColumnLayout`, manter apenas ícone principal

**Antes**:
```qml
ColumnLayout {
    MaterialIcon { text: "bluetooth_connected" } // Principal
    Repeater { // Dispositivos conectados
        MaterialIcon { text: Icons.getBluetoothIcon(...) }
    }
}
```

**Depois**:
```qml
MaterialIcon {
    text: {
        if (!Bluetooth.defaultAdapter?.enabled) return "bluetooth_disabled";
        if (Bluetooth.devices.values.some(d => d.connected)) return "bluetooth_connected";
        return "bluetooth";
    }
}
```

---

## Comandos Úteis

```bash
# Ver modo atual
supergfxctl -g

# Mudar modo
supergfxctl -m Integrated
supergfxctl -m Hybrid
supergfxctl -m AsusMuxDgpu

# Debug Quickshell
pkill -x quickshell
quickshell -c caelestia 2>&1 | grep -i "gpu\|mode"

# Copiar arquivos para config do usuário
cp services/GpuModeService.qml ~/.config/quickshell/caelestia/services/
cp modules/bar/popouts/GpuMode.qml ~/.config/quickshell/caelestia/modules/bar/popouts/
cp modules/bar/components/StatusIcons.qml ~/.config/quickshell/caelestia/modules/bar/components/
```

---

## Testes Validados

- ✅ Detecção de supergfxctl disponível
- ✅ Query de modo atual (Hybrid)
- ✅ Ícone aparece na barra (chip/memory)
- ✅ Popout abre ao passar mouse
- ✅ 3 botões icon-only visíveis
- ✅ Indicador destaca modo atual
- ✅ Material Icons corretos
- ✅ Font size correto
- ✅ Bluetooth mostra apenas 1 ícone
- ⏸️ Switch de modo (não testado - requer logout)

---

## Arquivos Modificados

### Criados
- `services/GpuModeService.qml` (99 linhas)
- `modules/bar/popouts/GpuMode.qml` (190 linhas)

### Modificados
- `modules/bar/components/StatusIcons.qml` (adicionado GPU icon, simplificado Bluetooth)
- `modules/bar/popouts/Content.qml` (registrado popout "gpumode")

---

## Documentação Atualizada

- ✅ `docs/01-requisitos.md` - RF-06 Gaming & VR (adicionado GPU Mode Selector)
- ✅ `docs/01-requisitos.md` - RF-07 Bluetooth (adicionado ícone único)
- ✅ `docs/02-arquitetura.md` - Caelestia Shell (adicionado serviços e componentes)
- ✅ `docs/03-configuracao.md` - Seção 8 (GPU Mode Selector usage)
- ✅ `docs/plan-and-implementation/00-sequencia-implementacao.md` - Item 32 marcado completo

---

## Lições Aprendidas

1. **Quickshell Process API**: Usar `SplitParser` para ler stdout, não acessar propriedade diretamente
2. **Material Icons**: Verificar disponibilidade em `AppearanceConfig.qml` antes de usar
3. **Bluetooth UI**: Design simplificado (1 ícone) é melhor que detalhado (múltiplos ícones)
4. **Testing**: Logs com `console.log` + `grep` são essenciais para debug de services

---

## Referências

- Plano original: `docs/plan-and-implementation/32-gpu-mode-selector.md`
- supergfxctl docs: https://gitlab.com/asus-linux/supergfxctl
- Quickshell Process: https://quickshell.outfoxxed.me/docs/io/process/
- Material Symbols: https://fonts.google.com/icons
