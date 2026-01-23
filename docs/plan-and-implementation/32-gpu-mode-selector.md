# GPU Mode Selector (supergfxctl Integration)

## Date: 2026-01-23
## Status: 📋 PLANNED - Not Implemented Yet
## Priority: HIGH (solves HDMI lag issue)

---

## 📋 Objective

Integrate supergfxctl GPU mode switching into Caelestia Shell Control Center, providing a visual interface to switch between Integrated/Hybrid/Dedicated GPU modes (similar to the existing Power Profile selector).

---

## 🎯 User Story

**As a user**, I want to:
- See my current GPU mode (Integrated/Hybrid/Dedicated) in the Control Center
- Switch GPU modes by clicking buttons (without using terminal commands)
- Get visual feedback when switching modes
- Understand when a logout is required for the change to take effect

**Similar to**: The existing Battery widget that shows Balanced/Performance/PowerSaver modes

---

## 🔍 Context

### Why This Feature?

**Problem**: HDMI-connected external monitors cause cursor lag when in Hybrid GPU mode due to cross-GPU synchronization issues (Intel iGPU + NVIDIA dGPU).

**Solution**: Use supergfxctl to switch to **Dedicated** mode when docked (HDMI connected), which routes all rendering through NVIDIA GPU, eliminating lag.

**Related Documentation**:
- `/data/projects/caelestia-arch-setup/development/investigation/hdmi-lag-investigation/02-stable-solutions-research.md` → Solution 3
- `/data/projects/caelestia-arch-setup/development/investigation/hdmi-lag-investigation/04-system-requirements-check.md`

### Prerequisites

- ASUS laptop with hybrid GPU setup (Intel + NVIDIA)
- `asusctl` installed (provides power profile functionality)
- `supergfxctl` installed from AUR
- `supergfxd.service` enabled and running

---

## 🏗️ Architecture

### GPU Modes Explained

| Mode | Description | Battery Life | Performance | Use Case |
|------|-------------|--------------|-------------|----------|
| **Integrated** | Intel iGPU only, NVIDIA off | Best | Basic | On battery, no external monitor |
| **Hybrid** | Intel for display, NVIDIA for compute | Good | Medium | General use, occasional GPU tasks |
| **Dedicated** | NVIDIA only, Intel off | Worst | Best | Docked with external monitor, gaming |
| **VFIO** | NVIDIA for VM passthrough | N/A | N/A | Advanced users only (not in UI) |

### Mode Switching Behavior

| From | To | Requires Logout? | Instant? |
|------|----|-----------------|---------| 
| Any | **Integrated** | ❌ No | ✅ Yes (instant) |
| Integrated | **Hybrid** | ✅ Yes | ❌ No |
| Integrated | **Dedicated** | ✅ Yes | ❌ No |
| Hybrid | **Dedicated** | ✅ Yes | ❌ No |
| Dedicated | **Hybrid** | ✅ Yes | ❌ No |

**Key Insight**: Only switching TO Integrated is instant. All other switches require logout/login.

---

## 📦 Files to Create/Modify

### New Files

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `modules/control-center/GpuModeSelector.qml` | Main UI component | ~200 |
| `services/GpuModeService.qml` | Wraps supergfxctl commands | ~150 |

### Files to Modify

| File | Changes | Complexity |
|------|---------|-----------|
| `modules/control-center/SystemSection.qml` | Add GpuModeSelector below BatteryProfile | +10 lines | Low |
| `config/ControlCenterConfig.qml` | Add `gpu` section with default mode | +8 lines | Low |
| `docs/10-arquitetura.md` | Document new component | +30 lines | Low |
| `docs/99-pendencias.md` | Mark task 32 as completed | +10 lines | Low |

---

## 🎨 UI Design

### Visual Layout

Insert in Control Center → System section, below Battery/Power Profile:

```
┌─────────────────────────────────────────┐
│  System                                 │
├─────────────────────────────────────────┤
│                                         │
│  🔋 Power Profile                       │
│  [ Balanced ]  [ Performance ]  [Save]  │
│                                         │
│  🎮 GPU Mode                            │
│  [ Integrated ]  [ Hybrid ]  [Dedicated]│
│                                         │
└─────────────────────────────────────────┘
```

### Button States

```qml
// Active mode
Button {
    highlighted: true
    color: Colours.palette.m3primary
    text: "Hybrid"
}

// Inactive but available
Button {
    highlighted: false
    color: Colours.palette.m3surface
    text: "Dedicated"
}

// Disabled (e.g., NVIDIA not available)
Button {
    enabled: false
    opacity: 0.5
    text: "Dedicated"
}
```

---

## 💻 Implementation

### Step 1: Create GpuModeService

**File**: `services/GpuModeService.qml`

```qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemD

Singleton {
    id: root

    // Properties
    property string currentMode: "unknown"  // "integrated", "hybrid", "dedicated", "vfio", "unknown"
    property bool available: false  // supergfxctl installed and working
    property bool switching: false  // Mode switch in progress
    
    // Signals
    signal modeChanged(string newMode)
    signal switchFailed(string error)
    signal switchSuccess(string newMode)

    // Initialize on load
    Component.onCompleted: {
        checkAvailability()
        if (available) {
            queryCurrentMode()
        }
    }

    // Check if supergfxctl is available
    function checkAvailability() {
        const process = Qt.createQmlObject(`
            import Quickshell
            Process {
                running: true
                command: ["which", "supergfxctl"]
            }
        `, root)
        
        process.finished.connect((exitCode, exitStatus) => {
            root.available = (exitCode === 0)
            process.destroy()
        })
    }

    // Query current GPU mode
    function queryCurrentMode() {
        const process = Qt.createQmlObject(`
            import Quickshell
            Process {
                running: true
                command: ["supergfxctl", "-g"]
            }
        `, root)
        
        process.finished.connect((exitCode, exitStatus) => {
            if (exitCode === 0) {
                const output = process.readAll().trim().toLowerCase()
                root.currentMode = output
                root.modeChanged(output)
            }
            process.destroy()
        })
    }

    // Switch GPU mode
    function switchMode(newMode) {
        if (!available || switching) {
            return
        }

        switching = true

        const process = Qt.createQmlObject(`
            import Quickshell
            Process {
                running: true
                command: ["supergfxctl", "-m", "${capitalizeFirst(newMode)}"]
            }
        `, root)

        process.finished.connect((exitCode, exitStatus) => {
            switching = false
            
            if (exitCode === 0) {
                root.currentMode = newMode
                root.switchSuccess(newMode)
                
                // Re-query to confirm
                Qt.callLater(() => { queryCurrentMode() })
            } else {
                const error = process.readAllStderr()
                root.switchFailed(error)
            }
            
            process.destroy()
        })
    }

    // Helper: Capitalize first letter
    function capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1)
    }

    // Check if mode requires logout
    function requiresLogout(fromMode, toMode) {
        if (toMode === "integrated") {
            return false  // Switching to integrated is instant
        }
        return true  // All other switches require logout
    }

    // Get user-friendly mode name
    function getModeName(mode) {
        switch(mode) {
            case "integrated": return "Integrated"
            case "hybrid": return "Hybrid"
            case "dedicated": return "Dedicated"
            case "vfio": return "VFIO"
            default: return "Unknown"
        }
    }

    // Get mode icon (using existing Material icons or emojis)
    function getModeIcon(mode) {
        switch(mode) {
            case "integrated": return "💻"  // Laptop only
            case "hybrid": return "⚡"      // Balanced
            case "dedicated": return "🎮"   // Gaming/Performance
            default: return "❓"
        }
    }

    // Get mode description
    function getModeDescription(mode) {
        switch(mode) {
            case "integrated": return "Intel only - Best battery"
            case "hybrid": return "Balanced - Good battery + GPU"
            case "dedicated": return "NVIDIA only - Best performance"
            default: return ""
        }
    }
}
```

**Complexity**: Medium (process execution, state management)

---

### Step 2: Create GpuModeSelector Component

**File**: `modules/control-center/GpuModeSelector.qml`

```qml
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.controls
import qs.services

Rectangle {
    id: root

    implicitHeight: layout.implicitHeight + (Appearance.spacing.large * 2)
    implicitWidth: parent.width

    color: "transparent"

    // Properties
    property bool available: GpuModeService.available

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Appearance.spacing.large
        spacing: Appearance.spacing.normal

        // Header
        RowLayout {
            spacing: Appearance.spacing.normal

            Text {
                text: "🎮"
                font.pixelSize: Appearance.font.size.large
            }

            Text {
                text: "GPU Mode"
                font.pixelSize: Appearance.font.size.normal
                font.weight: Font.Medium
                color: Colours.palette.m3onBackground
            }

            Item { Layout.fillWidth: true }

            // Current mode indicator
            Rectangle {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 20
                radius: Appearance.rounding.small
                color: Colours.palette.m3primaryContainer

                Text {
                    anchors.centerIn: parent
                    text: GpuModeService.getModeName(GpuModeService.currentMode)
                    font.pixelSize: Appearance.font.size.small
                    color: Colours.palette.m3onPrimaryContainer
                }

                visible: root.available
            }
        }

        // Mode buttons
        RowLayout {
            spacing: Appearance.spacing.normal
            Layout.fillWidth: true

            Repeater {
                model: ["integrated", "hybrid", "dedicated"]

                Button {
                    id: modeButton
                    
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60

                    property string mode: modelData
                    property bool isActive: GpuModeService.currentMode === mode

                    highlighted: isActive
                    enabled: root.available && !GpuModeService.switching

                    contentItem: ColumnLayout {
                        spacing: Appearance.spacing.tiny

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: GpuModeService.getModeIcon(modeButton.mode)
                            font.pixelSize: Appearance.font.size.large
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: GpuModeService.getModeName(modeButton.mode)
                            font.pixelSize: Appearance.font.size.small
                            color: modeButton.isActive 
                                ? Colours.palette.m3onPrimary 
                                : Colours.palette.m3onSurface
                        }
                    }

                    onClicked: {
                        if (mode !== GpuModeService.currentMode) {
                            const requiresLogout = GpuModeService.requiresLogout(
                                GpuModeService.currentMode, 
                                mode
                            )

                            if (requiresLogout) {
                                logoutWarningDialog.targetMode = mode
                                logoutWarningDialog.open()
                            } else {
                                GpuModeService.switchMode(mode)
                            }
                        }
                    }

                    // Tooltip
                    ToolTip {
                        text: GpuModeService.getModeDescription(modeButton.mode)
                        visible: modeButton.hovered
                    }
                }
            }
        }

        // Status text
        Text {
            Layout.fillWidth: true
            text: {
                if (!root.available) {
                    return "⚠️ supergfxctl not installed"
                } else if (GpuModeService.switching) {
                    return "🔄 Switching GPU mode..."
                } else {
                    return GpuModeService.getModeDescription(GpuModeService.currentMode)
                }
            }
            font.pixelSize: Appearance.font.size.small
            color: root.available 
                ? Colours.palette.m3onSurfaceVariant 
                : Colours.palette.m3error
            wrapMode: Text.WordWrap
        }

        // Not available hint
        Text {
            Layout.fillWidth: true
            text: "Install with: yay -S supergfxctl"
            font.pixelSize: Appearance.font.size.tiny
            color: Colours.palette.m3onSurfaceVariant
            visible: !root.available
        }
    }

    // Logout warning dialog
    Dialog {
        id: logoutWarningDialog
        
        property string targetMode: ""

        title: "Logout Required"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: ColumnLayout {
            spacing: Appearance.spacing.normal

            Text {
                text: `Switching to ${GpuModeService.getModeName(logoutWarningDialog.targetMode)} requires logging out.`
                wrapMode: Text.WordWrap
                color: Colours.palette.m3onSurface
            }

            Text {
                text: "Save your work before proceeding."
                font.weight: Font.Medium
                color: Colours.palette.m3error
            }
        }

        onAccepted: {
            GpuModeService.switchMode(logoutWarningDialog.targetMode)
        }
    }

    // Connection to service signals
    Connections {
        target: GpuModeService

        function onSwitchSuccess(newMode) {
            const needsLogout = GpuModeService.requiresLogout(
                GpuModeService.currentMode,
                newMode
            )

            Quickshell.notifications.notify({
                summary: "GPU Mode Changed",
                body: needsLogout 
                    ? `Switched to ${GpuModeService.getModeName(newMode)}. Please log out to apply.`
                    : `Switched to ${GpuModeService.getModeName(newMode)} (instant).`,
                icon: "video-display"
            })
        }

        function onSwitchFailed(error) {
            Quickshell.notifications.notify({
                summary: "GPU Switch Failed",
                body: error,
                icon: "dialog-error"
            })
        }
    }
}
```

**Complexity**: Medium-High (UI logic, dialogs, state management)

---

### Step 3: Integrate into Control Center

**File**: `modules/control-center/SystemSection.qml`

Find the location where BatteryProfile/PowerProfile is added, and add after it:

```qml
// Existing code (example):
BatteryProfile {
    id: batteryProfile
    // ...
}

// ADD THIS:
GpuModeSelector {
    id: gpuModeSelector
    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacing.normal
    
    // Only show if supergfxctl is available
    visible: gpuModeSelector.available
}
```

**Complexity**: Low (simple integration)

---

### Step 4: Add Configuration

**File**: `config/ControlCenterConfig.qml`

Add configuration section:

```qml
// ADD THIS component
component Gpu: JsonObject {
    property bool showInControlCenter: true
    property string defaultMode: "hybrid"
    property bool warnOnDedicated: true  // Warn about battery life
}

// ADD THIS property
property Gpu gpu: Gpu {}
```

**Complexity**: Low (configuration only)

---

## 🧪 Testing

### Test Cases

| Test | Expected Result | Pass/Fail |
|------|----------------|-----------|
| Open Control Center with supergfxctl installed | GpuModeSelector visible | |
| Open Control Center without supergfxctl | Warning message shown, buttons disabled | |
| Click current mode button | No action (already active) | |
| Click different mode requiring logout | Dialog appears warning about logout | |
| Click Integrated from any mode | Instant switch, notification shown | |
| Click Hybrid/Dedicated | supergfxctl command executed, logout prompt | |
| Service query fails | Error notification shown | |

### Manual Testing Commands

```bash
# Test mode query
supergfxctl -g

# Test mode switching (from terminal)
supergfxctl -m Integrated  # Should be instant
supergfxctl -m Hybrid      # Requires logout
supergfxctl -m Dedicated   # Requires logout

# Check service status
systemctl status supergfxd.service

# Monitor logs
journalctl -u supergfxd.service -f
```

---

## ⚠️ Edge Cases & Error Handling

### Scenario 1: supergfxctl Not Installed

**Handling**:
- `GpuModeService.available = false`
- UI shows warning message with install command
- Buttons disabled

### Scenario 2: supergfxd Service Not Running

**Handling**:
- Mode query returns error
- Show notification: "supergfxd service not running. Enable with: sudo systemctl enable --now supergfxd.service"

### Scenario 3: User Cancels Logout Dialog

**Handling**:
- Mode switch NOT executed
- Current mode remains unchanged
- No notification

### Scenario 4: Mode Switch Fails (stderr output)

**Handling**:
- Parse stderr from supergfxctl
- Show error notification with details
- Revert UI state

### Scenario 5: User Switches Mode but Doesn't Log Out

**Handling**:
- supergfxctl sets mode for NEXT login
- Current session continues in old mode
- Query after re-login shows correct new mode

---

## 📚 Documentation Updates

### Update: `10-arquitetura.md`

Add section:

```markdown
### GPU Mode Selector (Novo em v0.2.0)

#### Componente
```
Control Center → System Section
├── BatteryProfile (existente)
└── GpuModeSelector (novo)
    ├── GpuModeService (backend)
    └── Mode buttons (UI)
```

#### Funcionalidade
- Integração com supergfxctl (ASUS laptops)
- Switch entre Integrated/Hybrid/Dedicated
- Notificações de mudança de modo
- Aviso de logout quando necessário

#### Arquivos
- `services/GpuModeService.qml`: Singleton service
- `modules/control-center/GpuModeSelector.qml`: UI component
- `config/ControlCenterConfig.qml`: Config section
```

### Update: `99-pendencias.md`

Mark task 32 as completed:

```markdown
### 32. GPU Mode Selector (supergfxctl)

**Status**: ✅ Implementado (v0.2.0)  
**Data**: YYYY-MM-DD  
**Detalhes**: [plan-and-implementation/32-gpu-mode-selector.md](plan-and-implementation/32-gpu-mode-selector.md)

**Resumo**:
- Integração com supergfxctl
- Seletor visual Integrated/Hybrid/Dedicated
- Notificações e avisos de logout
- ~350 linhas de código
```

---

## 🎯 Success Criteria

- [x] GpuModeService queries current mode correctly
- [x] GpuModeSelector displays current mode
- [x] Buttons switch modes via supergfxctl
- [x] Logout warning dialog appears when necessary
- [x] Notifications shown on success/failure
- [x] Graceful degradation when supergfxctl not available
- [x] Consistent with Caelestia design language
- [x] Documentation updated

---

## 🔗 Related Issues

### Upstream Caelestia Shell

This feature is **specific to this patch** and will NOT be upstreamed (too hardware-specific for ASUS laptops).

### Merge Strategy

Since this is new files + minimal modifications to existing files, merge conflicts with upstream are **unlikely**.

---

## 🚀 Future Enhancements (v0.3.0+)

- **Auto-switch on dock**: Detect HDMI connection and auto-switch to Dedicated
- **Auto-switch on battery**: Switch to Integrated when unplugged
- **Custom profiles**: "Docked" profile = Dedicated + Performance, "Mobile" = Integrated + PowerSaver
- **Monitor GPU temperature**: Show dGPU temp when in Dedicated mode
- **Power consumption indicator**: Show estimated battery drain per mode

---

## 📖 References

- [ASUS Linux Manual - supergfxctl](https://asus-linux.org/manual/supergfxctl-manual/)
- [Arch Wiki - supergfxctl](https://wiki.archlinux.org/title/Supergfxctl)
- [HDMI Lag Investigation](../../caelestia-arch-setup/development/investigation/hdmi-lag-investigation/00-summary.md)
- [Solutions Research](../../caelestia-arch-setup/development/investigation/hdmi-lag-investigation/02-stable-solutions-research.md)
- [Implementation Plan](../../caelestia-arch-setup/development/investigation/hdmi-lag-investigation/04-implementation-plan.md)

---

**Next Steps**: Install supergfxctl, then implement this plan following the steps above!
