# 40. Peripheral Battery Card no Dashboard

**Status**: 📋 Planejado  
**Prioridade**: Média  
**Complexidade**: Média

---

## 📋 Requisitos

### RF-40.1: Card de Bateria de Periféricos
- Exibir bateria de até 3 periféricos:
  - **Mouse** (2.4GHz ou Bluetooth) - apenas 1
  - **Teclado** (2.4GHz ou Bluetooth) - apenas 1  
  - **Headphone/Earbuds** (Bluetooth) - apenas 1
- Layout: 3 círculos horizontais lado a lado
- Cada círculo tem ícone central e borda colorida representando nível de bateria

### RF-40.2: Visual
- Ícone centralizado dentro de cada círculo
- Barra de bateria como arco na borda do círculo (anel)
- Gap na parte inferior do anel
- Cores por nível: verde (>60%), amarelo (30-60%), vermelho (<30%)

### RF-40.3: Posicionamento
- Ao lado do card User (OS, WM, uptime)
- Redimensionar card Media para liberar espaço

---

## 🔍 Análise Técnica

### Fonte de Dados

**Bluetooth devices** (via `Quickshell.Bluetooth`):
```qml
import Quickshell.Bluetooth

// Lista de dispositivos
Bluetooth.devices.values

// Propriedades de cada device:
device.name           // string
device.icon           // string: "input-mouse", "input-keyboard", "audio-headset"
device.connected      // bool
device.batteryAvailable // bool
device.battery        // real (0.0 - 1.0)
```

**Identificação por tipo** (já existe em `utils/Icons.qml`):
```qml
function getBluetoothIcon(icon: string): string {
    if (icon.includes("headset") || icon.includes("headphones")) return "headphones";
    if (icon.includes("mouse")) return "mouse";
    if (icon.includes("keyboard")) return "keyboard";
    return "bluetooth";
}
```

### Layout Atual do Dashboard

```
┌─────────────────────────────────────────────────────────────────┐
│ Row 0:                                                          │
│   Weather (col 0-1) │ User (col 2-4) │ Media (col 5, rowspan 2) │
├─────────────────────────────────────────────────────────────────┤
│ Row 1:                                                          │
│   DateTime (col 0) │ Calendar (col 1-3) │ Resources (col 4)     │
└─────────────────────────────────────────────────────────────────┘
```

### Layout Proposto

```
┌─────────────────────────────────────────────────────────────────────┐
│ Row 0:                                                              │
│   Weather (col 0-1) │ User (col 2-3) │ Peripherals (col 4) │ Media │
├─────────────────────────────────────────────────────────────────────┤
│ Row 1:                                                              │
│   DateTime (col 0) │ Calendar (col 1-3) │ Resources (col 4) │ Media │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📐 Implementação

### Fase 1: Criar Componente PeripheralBattery

**Arquivo**: `modules/dashboard/dash/Peripherals.qml`
```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import qs.utils
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Shapes

Row {
    id: root
    
    anchors.fill: parent
    padding: Appearance.padding.normal
    spacing: Appearance.spacing.normal
    
    // Encontrar dispositivos conectados por tipo
    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected)
    
    readonly property var mouseDevice: connectedDevices.find(d => 
        d.icon.includes("mouse")
    ) || null
    
    readonly property var keyboardDevice: connectedDevices.find(d => 
        d.icon.includes("keyboard")
    ) || null
    
    readonly property var audioDevice: connectedDevices.find(d => 
        d.icon.includes("headset") || d.icon.includes("headphones") || d.icon.includes("audio")
    ) || null
    
    BatteryRing {
        device: root.mouseDevice
        icon: "mouse"
        fallbackText: qsTr("Mouse")
    }
    
    BatteryRing {
        device: root.keyboardDevice
        icon: "keyboard"
        fallbackText: qsTr("Keyboard")
    }
    
    BatteryRing {
        device: root.audioDevice
        icon: "headphones"
        fallbackText: qsTr("Audio")
    }
    
    component BatteryRing: Item {
        id: ring
        
        property var device: null
        property string icon: "bluetooth"
        property string fallbackText: ""
        
        readonly property bool hasDevice: device !== null
        readonly property bool hasBattery: device?.batteryAvailable ?? false
        readonly property real batteryLevel: device?.battery ?? 0
        
        // Cor baseada no nível
        readonly property color batteryColor: {
            if (!hasBattery) return Colours.palette.m3outline;
            if (batteryLevel > 0.6) return Colours.palette.m3primary;      // Verde
            if (batteryLevel > 0.3) return Colours.palette.m3tertiary;     // Amarelo
            return Colours.palette.m3error;                                 // Vermelho
        }
        
        implicitWidth: Config.dashboard.sizes.peripheralRingSize
        implicitHeight: Config.dashboard.sizes.peripheralRingSize
        
        opacity: hasDevice ? 1 : 0.3
        
        Behavior on opacity {
            Anim {}
        }
        
        // Fundo do anel (track)
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            
            ShapePath {
                fillColor: "transparent"
                strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                strokeWidth: Config.dashboard.sizes.peripheralRingThickness
                capStyle: ShapePath.RoundCap
                
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: (ring.width - Config.dashboard.sizes.peripheralRingThickness) / 2
                    radiusY: (ring.height - Config.dashboard.sizes.peripheralRingThickness) / 2
                    startAngle: 135    // Gap embaixo (começa em 135°)
                    sweepAngle: 270    // 270° de arco (gap de 90° embaixo)
                }
            }
        }
        
        // Anel de bateria (preenchido)
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            visible: ring.hasBattery
            
            ShapePath {
                fillColor: "transparent"
                strokeColor: ring.batteryColor
                strokeWidth: Config.dashboard.sizes.peripheralRingThickness
                capStyle: ShapePath.RoundCap
                
                PathAngleArc {
                    centerX: ring.width / 2
                    centerY: ring.height / 2
                    radiusX: (ring.width - Config.dashboard.sizes.peripheralRingThickness) / 2
                    radiusY: (ring.height - Config.dashboard.sizes.peripheralRingThickness) / 2
                    startAngle: 135
                    sweepAngle: 270 * ring.batteryLevel  // Proporcional à bateria
                }
                
                Behavior on strokeColor {
                    CAnim {}
                }
            }
        }
        
        // Ícone central
        MaterialIcon {
            anchors.centerIn: parent
            
            text: ring.icon
            color: ring.hasDevice ? ring.batteryColor : Colours.palette.m3outline
            font.pointSize: ring.width * 0.35
            
            Behavior on color {
                CAnim {}
            }
        }
        
        // Tooltip com nome e porcentagem
        ToolTip {
            visible: mouseArea.containsMouse && ring.hasDevice
            text: ring.hasBattery 
                ? `${ring.device.name}: ${Math.round(ring.batteryLevel * 100)}%`
                : ring.device?.name ?? ring.fallbackText
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
    }
}
```

### Fase 2: Adicionar Config de Tamanhos

**Arquivo**: `config/DashboardConfig.qml`

Adicionar:
```qml
property real peripheralRingSize: 50
property real peripheralRingThickness: 4
```

### Fase 3: Modificar Dash.qml

**Arquivo**: `modules/dashboard/Dash.qml`

#### 3.1 Reduzir columnSpan do User
```qml
// DE:
Rect {
    Layout.column: 2
    Layout.columnSpan: 3
    // ...
    User { }
}

// PARA:
Rect {
    Layout.column: 2
    Layout.columnSpan: 2  // Reduzido de 3 para 2
    // ...
    User { }
}
```

#### 3.2 Adicionar card Peripherals
```qml
// Novo card após User
Rect {
    Layout.row: 0
    Layout.column: 4
    Layout.preferredWidth: peripherals.implicitWidth
    Layout.fillHeight: true
    
    radius: Appearance.rounding.normal
    
    Peripherals {
        id: peripherals
    }
}
```

#### 3.3 Ajustar coluna do Media
```qml
// DE:
Rect {
    Layout.row: 0
    Layout.column: 5
    // ...
    Media { }
}

// PARA:
Rect {
    Layout.row: 0
    Layout.column: 5  // Mantém
    // ...
    Media { }
}
```

---

## 📁 Arquivos a Criar/Modificar

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `modules/dashboard/dash/Peripherals.qml` | Criar | Componente dos 3 anéis |
| `config/DashboardConfig.qml` | Modificar | Adicionar sizes |
| `modules/dashboard/Dash.qml` | Modificar | Layout com novo card |

---

## 🎨 Design Visual

```
┌────────────────────────────────────────┐
│         Peripherals Card               │
│                                        │
│    ╭───╮    ╭───╮    ╭───╮            │
│   ╱     ╲  ╱     ╲  ╱     ╲           │
│  │  🖱️  │ │  ⌨️  │ │  🎧  │          │
│   ╲     ╱  ╲     ╱  ╲     ╱           │
│    ╰───╯    ╰───╯    ╰───╯            │
│     gap      gap      gap              │
│                                        │
│   Mouse   Keyboard  Headphones         │
└────────────────────────────────────────┘

Legenda:
- Borda colorida = nível de bateria (0-100%)
- Gap embaixo = 90° sem preenchimento
- Ícone central = tipo do dispositivo
- Cor: verde (>60%), amarelo (30-60%), vermelho (<30%)
- Opacidade 30% = dispositivo não conectado
```

---

## 🔍 Detecção de Dispositivos 2.4GHz

**Nota**: Dispositivos 2.4GHz (USB dongle) geralmente aparecem como dispositivos HID no sistema, não via Bluetooth API. Para suportá-los:

**Opção 1**: Usar UPower (já usado no projeto)
```qml
import Quickshell.Services.UPower

// UPower pode detectar dispositivos com bateria via USB
UPower.displayDevice  // Bateria principal
// Outros devices podem ser listados
```

**Opção 2**: Verificar via D-Bus UPower
```bash
upower -e  # Lista todos os dispositivos
upower -i /org/freedesktop/UPower/devices/mouse_*
```

**Implementação futura**: Se necessário, criar service que monitora UPower para dispositivos adicionais.

---

## ✅ Critérios de Aceitação

- [ ] Exibir 3 anéis lado a lado (Mouse, Teclado, Audio)
- [ ] Anel mostra nível de bateria como arco colorido
- [ ] Gap de 90° na parte inferior de cada anel
- [ ] Ícone centralizado em cada anel
- [ ] Cor varia por nível (verde/amarelo/vermelho)
- [ ] Dispositivos desconectados aparecem com opacidade reduzida
- [ ] Tooltip mostra nome e porcentagem
- [ ] Card posicionado ao lado do User card
- [ ] Layout do dashboard mantém proporções corretas

---

## 🔗 Dependências

- `Quickshell.Bluetooth`: Já usado no projeto
- `QtQuick.Shapes`: Para desenhar os arcos (já usado em Media.qml)
- UPower: Para dispositivos 2.4GHz (investigação futura)
