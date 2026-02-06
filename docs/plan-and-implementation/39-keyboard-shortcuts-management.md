# 39. Keyboard Shortcuts Management

**Status**: 📋 Planejado  
**Prioridade**: Alta  
**Complexidade**: Média

---

## 📋 Requisitos

### RF-39.1: Shortcuts Core (Não Editáveis)
- Conjunto fixo de atalhos do sistema
- Baseados na documentação oficial
- Exibidos no HelpModal
- Marcados visualmente como "Sistema" na UI

### RF-39.2: Shortcuts Customizados
- Criar novos atalhos via UI
- Definir combinação de teclas + comando
- Editar/remover atalhos existentes
- Detectar conflitos com shortcuts existentes
- Aplicar em runtime via `hyprctl keyword bind`

### RF-39.3: HelpModal
- Mostrar APENAS shortcuts core
- Manter categorias atuais
- NÃO mostrar shortcuts customizados

---

## 🔍 Análise Técnica

### Como Shortcuts Funcionam

1. **Hyprland binds** (`~/.config/hypr/hyprland.conf`):
```
bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive
```

2. **Runtime bind** (validado):
```bash
hyprctl keyword bind "SUPER,X,exec,echo test"  # Adiciona
hyprctl keyword unbind "SUPER, X"               # Remove
```

3. **HelpModal atual** (`modules/help/HelpModal.qml`):
```qml
readonly property var shortcuts: [
    { category: qsTr("Navigation"), items: [
        { keys: "Super + 1-5", action: qsTr("Switch to workspace") },
        // ... hardcoded
    ]}
]
```

### Arquitetura Proposta

```
┌─────────────────────────────────────────────────────────┐
│              ShortcutsManager (singleton)               │
├─────────────────────────────────────────────────────────┤
│  coreShortcuts: readonly []   (definição estática)      │
│  customShortcuts: []          (Config.shortcuts.custom) │
├─────────────────────────────────────────────────────────┤
│  + addCustom(keys, action, command): bool               │
│  + removeCustom(id): void                               │
│  + hasConflict(keys, excludeId?): bool                  │
│  + applyToHyprland(shortcut): void                      │
│  + removeFromHyprland(shortcut): void                   │
└─────────────────────────────────────────────────────────┘
```

---

## 📐 Implementação

### Fase 1: Configuração

#### 1.1 Criar ShortcutsConfig.qml

**Arquivo**: `config/ShortcutsConfig.qml`
```qml
import Quickshell.Io

JsonObject {
    property var custom: []
    // Formato:
    // [{ id: "uuid", keys: "Super + G", action: "Open GIMP", command: "gimp" }]
}
```

#### 1.2 Adicionar em Config.qml

**Arquivo**: `config/Config.qml`

Adicionar:
```qml
property alias shortcuts: adapter.shortcuts
```

E na função `serializeConfig()`:
```qml
shortcuts: serializeShortcuts()
```

E criar:
```qml
function serializeShortcuts(): var {
    return {
        custom: shortcuts.custom || []
    };
}
```

### Fase 2: ShortcutsManager Service

**Arquivo**: `services/ShortcutsManager.qml`
```qml
pragma Singleton

import qs.config
import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root
    
    // === Core Shortcuts (readonly, baseados na documentação) ===
    readonly property var coreShortcuts: [
        // Navigation
        { category: "navigation", keys: "Super + 1-5", action: qsTr("Switch to workspace") },
        { category: "navigation", keys: "Super + Tab", action: qsTr("Next workspace group") },
        { category: "navigation", keys: "Super + Shift + Tab", action: qsTr("Previous workspace group") },
        { category: "navigation", keys: "Alt + Tab", action: qsTr("Cycle workspaces") },
        { category: "navigation", keys: "Ctrl + Super + Tab", action: qsTr("Cycle all windows") },
        { category: "navigation", keys: "Super + D", action: qsTr("Show desktop") },
        { category: "navigation", keys: "Super + Arrows", action: qsTr("Snap window") },
        { category: "navigation", keys: "Super + Ctrl + Left/Right", action: qsTr("Focus monitor") },
        
        // Window Management
        { category: "window", keys: "Super + Q", action: qsTr("Close window") },
        { category: "window", keys: "Super + F", action: qsTr("Toggle fullscreen") },
        { category: "window", keys: "Super + V", action: qsTr("Toggle floating") },
        { category: "window", keys: "Super + Shift + 1-5", action: qsTr("Move to workspace") },
        { category: "window", keys: "Super + Shift + Arrows", action: qsTr("Move window") },
        { category: "window", keys: "Super + Alt + Q", action: qsTr("Force kill") },
        
        // Applications
        { category: "apps", keys: "Super", action: qsTr("Open launcher") },
        { category: "apps", keys: "Super + Return", action: qsTr("Open terminal") },
        { category: "apps", keys: "Super + E", action: qsTr("File manager") },
        
        // Session
        { category: "session", keys: "Super + L", action: qsTr("Lock screen") },
        { category: "session", keys: "Super + Shift + E", action: qsTr("Logout") },
        { category: "session", keys: "Super + Shift + R", action: qsTr("Reload shell") },
        
        // Screenshots
        { category: "screenshot", keys: "Super + Shift + S", action: qsTr("Screenshot region") },
        { category: "screenshot", keys: "Print", action: qsTr("Screenshot fullscreen") },
        
        // Caelestia
        { category: "caelestia", keys: "Super + Space", action: qsTr("Toggle scratchpad") },
        { category: "caelestia", keys: "Super + N", action: qsTr("New workspace group") },
        { category: "caelestia", keys: "Super + F1", action: qsTr("Show help") }
    ]
    
    // === Categorias para UI ===
    readonly property var categories: [
        { id: "navigation", name: qsTr("Navigation"), icon: "swap_horiz" },
        { id: "window", name: qsTr("Window Management"), icon: "select_window" },
        { id: "apps", name: qsTr("Applications"), icon: "apps" },
        { id: "session", name: qsTr("Session"), icon: "power_settings_new" },
        { id: "screenshot", name: qsTr("Screenshots"), icon: "screenshot" },
        { id: "caelestia", name: qsTr("Caelestia Shell"), icon: "widgets" },
        { id: "custom", name: qsTr("Custom"), icon: "tune" }
    ]
    
    // === Custom Shortcuts (do Config) ===
    readonly property var customShortcuts: Config.shortcuts?.custom || []
    
    // === Helpers ===
    function getCoreByCategory(categoryId: string): var {
        return coreShortcuts.filter(s => s.category === categoryId);
    }
    
    function normalizeKeys(keys: string): string {
        return keys.toUpperCase().replace(/\s+/g, '').split('+').sort().join('+');
    }
    
    function hasConflict(keys: string, excludeId: string = ""): bool {
        const normalized = normalizeKeys(keys);
        
        // Verificar em core
        for (const s of coreShortcuts) {
            if (normalizeKeys(s.keys) === normalized)
                return true;
        }
        
        // Verificar em custom
        for (const s of customShortcuts) {
            if (s.id !== excludeId && normalizeKeys(s.keys) === normalized)
                return true;
        }
        
        return false;
    }
    
    // === CRUD Custom ===
    function addCustom(keys: string, action: string, command: string): bool {
        if (hasConflict(keys))
            return false;
        
        const newShortcut = {
            id: Qt.uuidCreate().toString(),
            keys: keys,
            action: action,
            command: command
        };
        
        let updated = [...customShortcuts, newShortcut];
        Config.shortcuts.custom = updated;
        Config.save();
        
        applyToHyprland(newShortcut);
        return true;
    }
    
    function removeCustom(id: string): void {
        const shortcut = customShortcuts.find(s => s.id === id);
        if (shortcut) {
            removeFromHyprland(shortcut);
            Config.shortcuts.custom = customShortcuts.filter(s => s.id !== id);
            Config.save();
        }
    }
    
    function updateCustom(id: string, keys: string, action: string, command: string): bool {
        if (hasConflict(keys, id))
            return false;
        
        const oldShortcut = customShortcuts.find(s => s.id === id);
        if (oldShortcut) {
            removeFromHyprland(oldShortcut);
        }
        
        Config.shortcuts.custom = customShortcuts.map(s => 
            s.id === id ? { id, keys, action, command } : s
        );
        Config.save();
        
        applyToHyprland({ keys, command });
        return true;
    }
    
    // === Hyprland Integration ===
    function keysToHyprland(keys: string): string {
        // "Super + Shift + G" -> "SUPER SHIFT, G"
        const parts = keys.split('+').map(p => p.trim().toUpperCase());
        const key = parts.pop();
        const mods = parts.join(' ');
        return `${mods}, ${key}`;
    }
    
    function applyToHyprland(shortcut: var): void {
        const bind = keysToHyprland(shortcut.keys);
        Hypr.dispatch(`keyword bind ${bind}, exec, ${shortcut.command}`);
    }
    
    function removeFromHyprland(shortcut: var): void {
        const bind = keysToHyprland(shortcut.keys);
        Hypr.dispatch(`keyword unbind ${bind}`);
    }
    
    // Aplicar todos os custom shortcuts no startup
    Component.onCompleted: {
        for (const s of customShortcuts) {
            applyToHyprland(s);
        }
    }
}
```

### Fase 3: Atualizar HelpModal

**Arquivo**: `modules/help/HelpModal.qml`

Substituir o `readonly property var shortcuts` hardcoded por:

```qml
readonly property var shortcuts: [
    { 
        category: qsTr("Navigation"), 
        items: ShortcutsManager.getCoreByCategory("navigation").map(s => ({
            keys: s.keys, action: s.action
        }))
    },
    { 
        category: qsTr("Window Management"), 
        items: ShortcutsManager.getCoreByCategory("window").map(s => ({
            keys: s.keys, action: s.action
        }))
    },
    { 
        category: qsTr("Applications"), 
        items: ShortcutsManager.getCoreByCategory("apps").map(s => ({
            keys: s.keys, action: s.action
        }))
    },
    { 
        category: qsTr("Session"), 
        items: ShortcutsManager.getCoreByCategory("session").map(s => ({
            keys: s.keys, action: s.action
        }))
    },
    { 
        category: qsTr("Screenshots"), 
        items: ShortcutsManager.getCoreByCategory("screenshot").map(s => ({
            keys: s.keys, action: s.action
        }))
    },
    { 
        category: qsTr("Caelestia Shell"), 
        items: ShortcutsManager.getCoreByCategory("caelestia").map(s => ({
            keys: s.keys, action: s.action
        }))
    }
]
// NOTA: Custom shortcuts NÃO são incluídos aqui
```

### Fase 4: UI de Gerenciamento

#### 4.1 Criar ShortcutsSection.qml

**Arquivo**: `modules/controlcenter/settings/ShortcutsSection.qml`
```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root
    
    title: qsTr("Keyboard Shortcuts")
    icon: "keyboard"
    
    content: Column {
        width: parent.width
        spacing: Appearance.spacing.normal
        
        // Tabs
        Row {
            spacing: Appearance.spacing.small
            
            TabButton {
                id: coreTab
                text: qsTr("System")
                checked: true
                onClicked: { coreTab.checked = true; customTab.checked = false; }
            }
            TabButton {
                id: customTab
                text: qsTr("Custom")
                checked: false
                onClicked: { coreTab.checked = false; customTab.checked = true; }
            }
        }
        
        // Content
        Loader {
            width: parent.width
            sourceComponent: coreTab.checked ? coreList : customList
        }
    }
    
    // === Core Shortcuts (readonly) ===
    component coreList: Column {
        width: parent.width
        spacing: Appearance.spacing.small
        
        StyledText {
            text: qsTr("System shortcuts cannot be modified")
            opacity: 0.6
            font.pointSize: Appearance.font.size.small
        }
        
        Repeater {
            model: ShortcutsManager.categories.filter(c => c.id !== "custom")
            
            Column {
                required property var modelData
                width: parent.width
                spacing: Appearance.spacing.smaller
                
                StyledText {
                    text: modelData.name
                    font.bold: true
                    topPadding: Appearance.padding.normal
                }
                
                Repeater {
                    model: ShortcutsManager.getCoreByCategory(modelData.id)
                    
                    ShortcutRow {
                        required property var modelData
                        keys: modelData.keys
                        action: modelData.action
                        editable: false
                    }
                }
            }
        }
    }
    
    // === Custom Shortcuts (editable) ===
    component customList: Column {
        width: parent.width
        spacing: Appearance.spacing.small
        
        Repeater {
            model: ShortcutsManager.customShortcuts
            
            ShortcutRow {
                required property var modelData
                required property int index
                
                keys: modelData.keys
                action: modelData.action
                command: modelData.command
                editable: true
                
                onEditClicked: editDialog.openEdit(modelData)
                onRemoveClicked: ShortcutsManager.removeCustom(modelData.id)
            }
        }
        
        // Empty state
        StyledText {
            visible: ShortcutsManager.customShortcuts.length === 0
            text: qsTr("No custom shortcuts defined")
            opacity: 0.6
        }
        
        // Add button
        StyledButton {
            text: qsTr("+ Add Shortcut")
            function onClicked(): void {
                editDialog.openNew();
            }
        }
    }
    
    // === Edit Dialog ===
    ShortcutEditDialog {
        id: editDialog
    }
}

// === Componentes auxiliares ===
component ShortcutRow: Row {
    property string keys
    property string action
    property string command: ""
    property bool editable: false
    
    signal editClicked()
    signal removeClicked()
    
    width: parent.width
    spacing: Appearance.spacing.small
    
    StyledRect {
        width: 140
        height: keysText.implicitHeight + Appearance.padding.small * 2
        color: Colours.palette.m3surfaceContainerHigh
        radius: Appearance.rounding.small
        
        StyledText {
            id: keysText
            anchors.centerIn: parent
            text: keys
            font.family: Appearance.font.family.mono
            font.pointSize: Appearance.font.size.small
        }
    }
    
    StyledText {
        text: action
        width: parent.width - 140 - (editable ? 60 : 0) - Appearance.spacing.small * 2
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
    }
    
    Row {
        visible: editable
        spacing: Appearance.spacing.smaller
        anchors.verticalCenter: parent.verticalCenter
        
        IconButton {
            icon: "edit"
            size: Appearance.font.size.small
            function onClicked(): void { editClicked(); }
        }
        IconButton {
            icon: "delete"
            size: Appearance.font.size.small
            function onClicked(): void { removeClicked(); }
        }
    }
}

component TabButton: StyledRect {
    property string text
    property bool checked: false
    
    signal clicked()
    
    implicitWidth: label.implicitWidth + Appearance.padding.normal * 2
    implicitHeight: label.implicitHeight + Appearance.padding.small * 2
    
    color: checked ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer
    radius: Appearance.rounding.small
    
    StyledText {
        id: label
        anchors.centerIn: parent
        text: parent.text
        color: checked ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
    }
    
    StateLayer {
        radius: parent.radius
        function onClicked(): void { parent.clicked(); }
    }
}
```

#### 4.2 Criar ShortcutEditDialog.qml

**Arquivo**: `modules/controlcenter/settings/ShortcutEditDialog.qml`
```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

FloatingWindow {
    id: root
    
    property var editingShortcut: null
    property bool isNew: true
    
    function openNew(): void {
        isNew = true;
        editingShortcut = null;
        keysField.keys = "";
        actionField.text = "";
        commandField.text = "";
        conflictText.visible = false;
        visible = true;
    }
    
    function openEdit(shortcut: var): void {
        isNew = false;
        editingShortcut = shortcut;
        keysField.keys = shortcut.keys;
        actionField.text = shortcut.action;
        commandField.text = shortcut.command;
        conflictText.visible = false;
        visible = true;
    }
    
    implicitWidth: 400
    implicitHeight: content.implicitHeight + Appearance.padding.large * 2
    title: isNew ? qsTr("New Shortcut") : qsTr("Edit Shortcut")
    
    Column {
        id: content
        anchors.fill: parent
        anchors.margins: Appearance.padding.large
        spacing: Appearance.spacing.normal
        
        // Keys
        Column {
            width: parent.width
            spacing: Appearance.spacing.smaller
            
            StyledText { text: qsTr("Shortcut Keys") }
            
            KeyCaptureField {
                id: keysField
                width: parent.width
                
                onKeysChanged: {
                    const hasConflict = ShortcutsManager.hasConflict(
                        keys, 
                        editingShortcut?.id || ""
                    );
                    conflictText.visible = hasConflict && keys.length > 0;
                }
            }
            
            StyledText {
                id: conflictText
                text: qsTr("⚠ This shortcut conflicts with an existing one")
                color: Colours.palette.m3error
                font.pointSize: Appearance.font.size.small
                visible: false
            }
        }
        
        // Description
        Column {
            width: parent.width
            spacing: Appearance.spacing.smaller
            
            StyledText { text: qsTr("Description") }
            StyledTextField {
                id: actionField
                width: parent.width
                placeholderText: qsTr("e.g., Open GIMP")
            }
        }
        
        // Command
        Column {
            width: parent.width
            spacing: Appearance.spacing.smaller
            
            StyledText { text: qsTr("Command") }
            StyledTextField {
                id: commandField
                width: parent.width
                placeholderText: qsTr("e.g., gimp")
                font.family: Appearance.font.family.mono
            }
            StyledText {
                text: qsTr("Shell command to execute")
                opacity: 0.6
                font.pointSize: Appearance.font.size.small
            }
        }
        
        // Buttons
        Row {
            anchors.right: parent.right
            spacing: Appearance.spacing.small
            
            StyledButton {
                text: qsTr("Cancel")
                function onClicked(): void { root.visible = false; }
            }
            
            StyledButton {
                text: isNew ? qsTr("Create") : qsTr("Save")
                enabled: keysField.keys.length > 0 && 
                         actionField.text.length > 0 && 
                         commandField.text.length > 0 &&
                         !conflictText.visible
                
                function onClicked(): void {
                    let success;
                    if (isNew) {
                        success = ShortcutsManager.addCustom(
                            keysField.keys,
                            actionField.text,
                            commandField.text
                        );
                    } else {
                        success = ShortcutsManager.updateCustom(
                            editingShortcut.id,
                            keysField.keys,
                            actionField.text,
                            commandField.text
                        );
                    }
                    
                    if (success) {
                        root.visible = false;
                    }
                }
            }
        }
    }
}
```

#### 4.3 Criar KeyCaptureField.qml

**Arquivo**: `components/controls/KeyCaptureField.qml`
```qml
import qs.components
import qs.config
import QtQuick

StyledRect {
    id: root
    
    property string keys: ""
    property string placeholder: qsTr("Click and press keys...")
    
    implicitHeight: label.implicitHeight + Appearance.padding.small * 2
    color: Colours.palette.m3surfaceContainerHigh
    radius: Appearance.rounding.small
    
    StyledText {
        id: label
        anchors.centerIn: parent
        text: root.keys || root.placeholder
        opacity: root.keys ? 1 : 0.5
        font.family: root.keys ? Appearance.font.family.mono : Appearance.font.family.sans
    }
    
    // Indicador de foco
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Colours.palette.m3primary
        radius: parent.radius
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: root.forceActiveFocus()
    }
    
    Keys.onPressed: event => {
        event.accepted = true;
        
        let parts = [];
        
        // Modifiers
        if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl");
        if (event.modifiers & Qt.ShiftModifier) parts.push("Shift");
        if (event.modifiers & Qt.AltModifier) parts.push("Alt");
        if (event.modifiers & Qt.MetaModifier) parts.push("Super");
        
        // Key (ignorar se for apenas modifier)
        const keyName = keyToName(event.key);
        if (keyName) {
            parts.push(keyName);
            root.keys = parts.join(" + ");
        }
    }
    
    function keyToName(key: int): string {
        const map = {
            [Qt.Key_A]: "A", [Qt.Key_B]: "B", [Qt.Key_C]: "C", [Qt.Key_D]: "D",
            [Qt.Key_E]: "E", [Qt.Key_F]: "F", [Qt.Key_G]: "G", [Qt.Key_H]: "H",
            [Qt.Key_I]: "I", [Qt.Key_J]: "J", [Qt.Key_K]: "K", [Qt.Key_L]: "L",
            [Qt.Key_M]: "M", [Qt.Key_N]: "N", [Qt.Key_O]: "O", [Qt.Key_P]: "P",
            [Qt.Key_Q]: "Q", [Qt.Key_R]: "R", [Qt.Key_S]: "S", [Qt.Key_T]: "T",
            [Qt.Key_U]: "U", [Qt.Key_V]: "V", [Qt.Key_W]: "W", [Qt.Key_X]: "X",
            [Qt.Key_Y]: "Y", [Qt.Key_Z]: "Z",
            [Qt.Key_0]: "0", [Qt.Key_1]: "1", [Qt.Key_2]: "2", [Qt.Key_3]: "3",
            [Qt.Key_4]: "4", [Qt.Key_5]: "5", [Qt.Key_6]: "6", [Qt.Key_7]: "7",
            [Qt.Key_8]: "8", [Qt.Key_9]: "9",
            [Qt.Key_F1]: "F1", [Qt.Key_F2]: "F2", [Qt.Key_F3]: "F3", [Qt.Key_F4]: "F4",
            [Qt.Key_F5]: "F5", [Qt.Key_F6]: "F6", [Qt.Key_F7]: "F7", [Qt.Key_F8]: "F8",
            [Qt.Key_F9]: "F9", [Qt.Key_F10]: "F10", [Qt.Key_F11]: "F11", [Qt.Key_F12]: "F12",
            [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return",
            [Qt.Key_Space]: "Space", [Qt.Key_Tab]: "Tab",
            [Qt.Key_Escape]: "Escape", [Qt.Key_Backspace]: "Backspace",
            [Qt.Key_Delete]: "Delete", [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Left]: "Left", [Qt.Key_Right]: "Right",
            [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down",
            [Qt.Key_Print]: "Print",
            [Qt.Key_Minus]: "Minus", [Qt.Key_Plus]: "Plus", [Qt.Key_Equal]: "Equal",
            [Qt.Key_BracketLeft]: "BracketLeft", [Qt.Key_BracketRight]: "BracketRight",
            [Qt.Key_Semicolon]: "Semicolon", [Qt.Key_Apostrophe]: "Apostrophe",
            [Qt.Key_Comma]: "Comma", [Qt.Key_Period]: "Period",
            [Qt.Key_Slash]: "Slash", [Qt.Key_Backslash]: "Backslash",
            [Qt.Key_QuoteLeft]: "Grave"
        };
        return map[key] || "";
    }
}
```

---

## 📁 Resumo de Arquivos

| Arquivo | Ação | Descrição |
|---------|------|-----------|
| `config/ShortcutsConfig.qml` | Criar | Schema de config |
| `config/Config.qml` | Modificar | Adicionar shortcuts alias e serialize |
| `services/ShortcutsManager.qml` | Criar | Gerenciador central |
| `modules/help/HelpModal.qml` | Modificar | Usar ShortcutsManager.getCoreByCategory |
| `modules/controlcenter/settings/ShortcutsSection.qml` | Criar | UI principal |
| `modules/controlcenter/settings/ShortcutEditDialog.qml` | Criar | Dialog de edição |
| `components/controls/KeyCaptureField.qml` | Criar | Campo de captura de teclas |
| `modules/controlcenter/settings/Settings.qml` | Modificar | Incluir ShortcutsSection |

---

## 🗄️ Persistência

**Config**: `~/.config/caelestia/config.json`
```json
{
  "shortcuts": {
    "custom": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "keys": "Super + G",
        "action": "Open GIMP",
        "command": "gimp"
      }
    ]
  }
}
```

---

## ✅ Critérios de Aceitação

### Core
- [ ] Shortcuts core listados na UI (não editáveis)
- [ ] Core shortcuts exibidos no HelpModal
- [ ] Indicador visual "Sistema"

### Custom
- [ ] Criar shortcut com key capture
- [ ] Editar shortcut existente
- [ ] Remover shortcut
- [ ] Detectar conflitos
- [ ] Custom NÃO aparece no HelpModal
- [ ] Aplicar via hyprctl em runtime
- [ ] Persistir entre reinícios
- [ ] Re-aplicar no startup do shell
