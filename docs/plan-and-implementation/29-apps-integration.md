# 🔧 Apps Integration - Integrar Programas no Control Center

**ID**: 29  
**Status**: ⏱️ Planejado  
**Complexidade**: 🟡 Média  
**Tempo Estimado**: 4-6h

---

## 📋 Resumo

Novo painel "Apps" no Control Center com botões para abrir configuradores e utilitários externos (qpwgraph, EasyEffects, nwg-displays, etc).

---

## 🎯 Objetivos

- Painel categorizado (Audio, Display, System, Share)
- Botões grid para launch rápido
- Verificar se app está instalado (mostrar/esconder botão)

---

## 📋 Lista de Apps

| Categoria | App | Comando | Descrição |
|-----------|-----|---------|-----------|
| **Audio** | qpwgraph | \`qpwgraph\` | PipeWire graph editor |
| **Audio** | EasyEffects | \`easyeffects\` | Audio effects |
| **Display** | nwg-displays | \`nwg-displays\` | Display manager |
| **Display** | Font Scaling | \`font-scaling-manager\` | Font DPI manager |
| **System** | System Monitor | \`gnome-system-monitor\` | Resource monitor |
| **System** | Logs | \`gnome-logs\` | System logs viewer |
| **Share** | LocalSend | \`localsend_app\` | File sharing (local) |
| **Share** | Snapdrop | \`firefox snapdrop.net\` | File sharing (web) |
| **Share** | Packet | \`packet\` | Packet tracer |

---

## 📂 Estrutura de Arquivos

### 1. `modules/controlcenter/apps/AppsPane.qml`

\`\`\`qml
import qs.components
import qs.components.controls
import qs.services
import QtQuick
import QtQuick.Layouts

ScrollView {
    ColumnLayout {
        spacing: Appearance.spacing.large
        
        // Audio Category
        SectionLabel { text: qsTr("Audio") }
        
        GridLayout {
            columns: 2
            columnSpacing: Appearance.spacing.normal
            rowSpacing: Appearance.spacing.normal
            
            AppButton {
                name: "qpwgraph"
                icon: "graphic_eq"
                command: ["qpwgraph"]
                description: "PipeWire Graph"
            }
            
            AppButton {
                name: "EasyEffects"
                icon: "tune"
                command: ["easyeffects"]
                description: "Audio Effects"
            }
        }
        
        // Display Category
        SectionLabel { text: qsTr("Display") }
        
        GridLayout {
            columns: 2
            
            AppButton {
                name: "nwg-displays"
                icon: "monitor"
                command: ["nwg-displays"]
                description: "Display Manager"
            }
            
            AppButton {
                name: "Font Scaling"
                icon: "format_size"
                command: ["font-scaling-manager"]
                description: "Font DPI"
            }
        }
        
        // System Category
        SectionLabel { text: qsTr("System") }
        
        GridLayout {
            columns: 2
            
            AppButton {
                name: "System Monitor"
                icon: "monitoring"
                command: ["gnome-system-monitor"]
                description: "Resource Monitor"
            }
            
            AppButton {
                name: "Logs"
                icon: "article"
                command: ["gnome-logs"]
                description: "System Logs"
            }
        }
        
        // Share Category
        SectionLabel { text: qsTr("Sharing") }
        
        GridLayout {
            columns: 2
            
            AppButton {
                name: "LocalSend"
                icon: "share"
                command: ["localsend_app"]
                description: "Local File Sharing"
            }
            
            AppButton {
                name: "Snapdrop"
                icon: "lan"
                command: ["firefox", "https://snapdrop.net"]
                description: "Web File Sharing"
            }
        }
    }
}
\`\`\`

### 2. `modules/controlcenter/apps/AppButton.qml` (Component)

\`\`\`qml
import qs.components
import qs.services
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root
    
    required property string name
    required property string icon
    required property list<string> command
    required property string description
    
    // Verificar se app está instalado
    readonly property bool installed: {
        var proc = Quickshell.execSync(["command", "-v", command[0]])
        return proc.exitCode === 0
    }
    
    visible: installed
    
    Layout.preferredWidth: 200
    Layout.preferredHeight: 100
    
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.medium
    
    StateLayer {
        id: stateLayer
        anchors.fill: parent
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            
            onEntered: stateLayer.state = "hovered"
            onExited: stateLayer.state = "normal"
            onPressed: stateLayer.state = "pressed"
            onReleased: stateLayer.state = "hovered"
            
            onClicked: {
                Quickshell.execDetached(root.command)
            }
        }
    }
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.small
        
        MaterialIcon {
            text: root.icon
            size: 32
            color: Colours.palette.m3primary
            Layout.alignment: Qt.AlignHCenter
        }
        
        StyledText {
            text: root.name
            font.pixelSize: 14
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        StyledText {
            text: root.description
            font.pixelSize: 11
            opacity: 0.7
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
\`\`\`

### 3. Modificar `modules/controlcenter/PaneRegistry.qml`

\`\`\`qml
// Adicionar import
import "./apps" as Apps

// Adicionar entry
Pane {
    id: "apps"
    name: qsTr("Apps")
    icon: "apps"
    component: Apps.AppsPane {}
}
\`\`\`

---

## 🔧 Implementação

### Fase 1: AppButton Component (1-2h)

\`\`\`bash
# 1. Criar component
mkdir -p modules/controlcenter/apps
nano modules/controlcenter/apps/AppButton.qml

# 2. Implementar:
#    - Layout
#    - Verificação de instalação (command -v)
#    - MouseArea com hover/press
#    - Launch via execDetached
\`\`\`

### Fase 2: AppsPane (2-3h)

\`\`\`bash
# 1. Criar pane
nano modules/controlcenter/apps/AppsPane.qml

# 2. Adicionar categorias
#    - Audio
#    - Display
#    - System
#    - Share

# 3. Popular com AppButtons
\`\`\`

### Fase 3: Integração (30 min)

\`\`\`bash
# Modificar PaneRegistry
nano modules/controlcenter/PaneRegistry.qml

# Adicionar pane "Apps"
\`\`\`

### Fase 4: Testes (1h)

- [ ] Pane aparece no Control Center
- [ ] Botões aparecem (apenas apps instalados)
- [ ] Clicar abre app
- [ ] Hover/press states funcionam

---

## 🧪 Casos de Teste

### Teste 1: App Instalado

\`\`\`bash
# Se qpwgraph instalado:
command -v qpwgraph  # Retorna path
# Botão deve aparecer e funcionar
\`\`\`

### Teste 2: App Não Instalado

\`\`\`bash
# Se nwg-displays NÃO instalado:
command -v nwg-displays  # Retorna vazio
# Botão NÃO deve aparecer
\`\`\`

### Teste 3: Launch

\`\`\`bash
# Clicar em "qpwgraph"
# qpwgraph deve abrir
ps aux | grep qpwgraph
\`\`\`

---

## 🔗 Referências

- **qpwgraph**: https://github.com/rncbc/qpwgraph
- **EasyEffects**: https://github.com/wwmm/easyeffects
- **nwg-displays**: https://github.com/nwg-piotr/nwg-displays
- **LocalSend**: https://localsend.org/

---

**Próximo**: Marcar como ✅ após implementar!
