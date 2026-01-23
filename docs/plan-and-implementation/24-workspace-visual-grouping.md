# 🗂️ Workspace Visual Grouping - Agrupar Janelas na Barra

**ID**: 24  
**Status**: ⏱️ Planejado  
**Complexidade**: 🟡 Média  
**Tempo Estimado**: 3-4h

---

## 📋 Resumo

Adicionar separação visual entre janelas de diferentes workspaces na barra, facilitando identificação rápida de qual janela pertence a qual workspace.

Inclui também remoção do ícone pacman (󰮯) dos workspaces ocupados.

---

## 🎯 Problema Atual

### Visualização Atual

```
Barra de Workspaces:
┌────┬─────────────────────────────────────┐
│ 1  │ [Firefox] [Terminal] [VSCode]       │ ← Todas misturadas
│ 2  │ [Spotify] [Discord]                 │
│ 3  │                                     │
└────┴─────────────────────────────────────┘

Difícil distinguir: Firefox está no WS 1 ou 2?
```

### Problemas

1. Janelas de workspaces diferentes ficam lado a lado sem separação
2. Ícone pacman (󰮯) aparece em workspaces ocupados (redundante)
3. Workspace ativo não tem destaque visual suficiente

---

## 🎨 Solução Proposta

### Visualização Nova

```
Barra de Workspaces:
┌────┬─────────────────────────────────────┐
│ 1  │ ┌──────────────────────────────┐   │ ← Borda ao redor
│    │ │ [Firefox] [Terminal] [VSCode]│   │
│    │ └──────────────────────────────┘   │
│ 2  │ ┌─────────────────┐                │
│    │ │[Spotify][Discord]│                │
│    │ └─────────────────┘                │
│ 3  │                                     │
└────┴─────────────────────────────────────┘

Agora fica claro: Firefox/Terminal/VSCode estão no WS 1
```

### Features

- ✅ Container visual ao redor das janelas de cada workspace
- ✅ Espaçamento maior entre workspaces
- ✅ Remover ícone pacman (󰮯)
- ✅ Highlight do workspace ativo

---

## 📂 Arquivos a Modificar

### 1. `modules/bar/components/workspaces/Workspace.qml`

**Principal modificação**: Envolver janelas em container

**Localização das Janelas**: Linha ~37-60 (Repeater de janelas)

```qml
// ANTES:
Repeater {
    model: root.wsWindows
    delegate: WindowButton { /* ... */ }
}

// DEPOIS:
StyledRect {
    id: windowsContainer
    
    visible: root.hasWindows
    color: "transparent"
    border.color: root.activeWsId === root.ws ? 
        Colours.palette.m3primary : 
        Colours.palette.m3outline
    border.width: root.activeWsId === root.ws ? 2 : 1
    radius: Appearance.rounding.small
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: Appearance.spacing.tiny
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.tiny
        spacing: Appearance.spacing.tiny
        
        Repeater {
            model: root.wsWindows
            delegate: WindowButton { /* ... */ }
        }
    }
}
```

---

### 2. `config/BarConfig.qml`

**Modificação**: Remover ícone pacman

```qml
// ANTES:
property string occupiedLabel: "󰮯"  // Pacman ghost
property string activeLabel: "󰮯"

// DEPOIS:
property string occupiedLabel: ""  // Sem ícone extra
property string activeLabel: ""
```

**Ou adicionar config**:
```qml
property bool showOccupiedIcon: false  // Toggle on/off
```

---

### 3. `modules/bar/components/workspaces/Workspace.qml` (label)

**Modificar label do workspace** (se usar ícone):

```qml
// Linha ~37-49: Workspace label
StyledText {
    text: {
        if (root.activeWsId === root.ws) {
            return Config.bar.workspaces.activeLabel
        }
        if (root.isOccupied && Config.bar.workspaces.showOccupiedIcon) {
            return Config.bar.workspaces.occupiedLabel
        }
        return root.label
    }
    // ...
}
```

---

## 🎨 Design Detalhado

### Container Styles

#### Workspace Inativo

```qml
StyledRect {
    color: "transparent"
    border.color: Colours.palette.m3outline  // Cinza sutil
    border.width: 1
    radius: Appearance.rounding.small  // 4-8px
    opacity: 0.6
}
```

#### Workspace Ativo

```qml
StyledRect {
    color: Colours.tPalette.m3primaryContainer  // Fundo leve
    border.color: Colours.palette.m3primary  // Azul accent
    border.width: 2
    radius: Appearance.rounding.small
    opacity: 1.0
}
```

#### Workspace Vazio

```qml
// Sem container, apenas número
StyledText {
    text: root.ws
    color: Colours.palette.m3onSurface
    opacity: 0.4
}
```

---

### Espaçamento

```qml
// Entre workspaces
Layout.spacing: Appearance.spacing.medium  // 16px

// Dentro do container
anchors.margins: Appearance.spacing.tiny  // 4px

// Entre janelas
spacing: Appearance.spacing.small  // 8px
```

---

## 🔧 Implementação Passo a Passo

### Fase 1: Remover Ícone Pacman (15 min)

```bash
# Método 1: Via config do usuário
nano ~/.config/caelestia/shell.json

# Adicionar:
{
  "bar": {
    "workspaces": {
      "occupiedLabel": "",
      "activeLabel": ""
    }
  }
}

# Método 2: Modificar código
nano config/BarConfig.qml
# Mudar occupiedLabel e activeLabel para ""
```

---

### Fase 2: Adicionar Container (2-3h)

#### Passo 1: Modificar Workspace.qml

```qml
// Localizar Repeater de janelas (linha ~50-60)

// Envolver em:
StyledRect {
    id: windowsContainer
    
    visible: root.hasWindows
    color: root.activeWsId === root.ws ? 
        Colours.tPalette.m3primaryContainer : 
        "transparent"
    
    border.color: root.activeWsId === root.ws ? 
        Colours.palette.m3primary : 
        Colours.palette.m3outline
    border.width: root.activeWsId === root.ws ? 2 : 1
    
    radius: Appearance.rounding.small
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.margins: Appearance.spacing.tiny
    
    // Animação de transição
    Anim on border.width {
        duration: 150
    }
    
    Anim on border.color {
        duration: 150
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.tiny
        spacing: Appearance.spacing.small
        
        Repeater {
            model: root.wsWindows
            delegate: WindowButton {
                // Código existente
            }
        }
    }
}
```

#### Passo 2: Ajustar Espaçamento

```qml
// Em Workspaces.qml (parent)
RowLayout {
    spacing: Appearance.spacing.medium  // Aumentar espaçamento
    
    Repeater {
        model: /* ... */
        delegate: Workspace { }
    }
}
```

#### Passo 3: Testar

```bash
# Rebuild
cmake --build build
sudo cmake --install build

# Reiniciar
killall quickshell
quickshell -c caelestia --daemonize

# Testar:
# 1. Abrir janelas em WS 1
# 2. Mudar para WS 2, abrir mais janelas
# 3. Verificar containers visuais
# 4. Mudar de WS, verificar highlight
```

---

## 🧪 Testes

### Checklist

- [ ] Pacman removido dos workspaces
- [ ] Container aparece ao redor das janelas
- [ ] Workspace ativo tem borda colorida
- [ ] Workspaces inativos têm borda sutil
- [ ] Workspace vazio não tem container
- [ ] Espaçamento entre workspaces adequado
- [ ] Animações suaves (150ms)
- [ ] Layout não quebra com muitas janelas

### Casos de Teste

#### Teste 1: Workspace com 1 Janela
```bash
# WS 1: Abrir Firefox apenas
# Resultado: Container pequeno ao redor do Firefox
```

#### Teste 2: Workspace com Múltiplas Janelas
```bash
# WS 1: Firefox, Terminal, VSCode
# Resultado: Container engloba todas
```

#### Teste 3: Workspace Vazio
```bash
# WS 3: vazio
# Resultado: Apenas número "3", sem container
```

#### Teste 4: Mudar Workspace
```bash
# WS 1 → WS 2
# Resultado: Container de WS1 fica cinza, WS2 fica azul
```

---

## 🐛 Troubleshooting

### Container Não Aparece

**Debug**:
```qml
StyledRect {
    id: windowsContainer
    visible: root.hasWindows
    
    Component.onCompleted: {
        console.log("Container visible:", visible)
        console.log("Has windows:", root.hasWindows)
        console.log("Window count:", root.wsWindows.length)
    }
}
```

---

### Layout Quebrado

**Causa**: Container muito grande ou spacing excessivo

**Solução**: Ajustar margins/spacing
```qml
Layout.maximumWidth: parent.width * 0.8
Layout.preferredHeight: parent.height - 8
```

---

### Performance Ruim

**Causa**: Muitas animações simultâneas

**Solução**: Reduzir duração ou desabilitar
```qml
Anim on border.width {
    duration: 100  // De 150 para 100ms
    easing.type: Easing.OutQuad
}
```

---

## 📊 Alternativas

### Opção 1: Separador Vertical

Ao invés de container, usar linha vertical:

```qml
Rectangle {
    width: 2
    height: parent.height
    color: Colours.palette.m3outline
    visible: index < (repeaterModel.count - 1)
}
```

### Opção 2: Cor de Fundo

Ao invés de borda, usar cor de fundo:

```qml
StyledRect {
    color: root.activeWsId === root.ws ? 
        Colours.tPalette.m3primaryContainer : 
        Colours.tPalette.m3surfaceVariant
    border.width: 0
    radius: Appearance.rounding.medium
}
```

---

## ✅ Checklist de Conclusão

- [ ] Código modificado (Workspace.qml, BarConfig.qml)
- [ ] Pacman removido
- [ ] Container implementado
- [ ] Estilos para ativo/inativo/vazio
- [ ] Animações adicionadas
- [ ] Testado com 1 janela
- [ ] Testado com múltiplas janelas
- [ ] Testado com workspace vazio
- [ ] Testado mudança de workspace
- [ ] Performance OK (sem lag)
- [ ] Documentação atualizada

---

## 🔗 Referências

- **Hyprland Workspaces**: https://wiki.hyprland.org/Configuring/Workspaces/
- **Qt Layouts**: https://doc.qt.io/qt-6/qml-qtquick-layouts-rowlayout.html
- **Material Design**: https://m3.material.io/components/lists/overview

---

**Próximo**: Marcar como ✅ no `99-pendencias.md` após implementar!
