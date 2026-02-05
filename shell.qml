//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import qs.config
import qs.services
import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    // HDMI hotplug workaround - force complete refresh when screens change
    Connections {
        target: Quickshell
        function onScreensChanged() {
            console.log("[Hotplug] Screens changed, scheduling complete refresh");
            hotplugRefresh.restart();
        }
    }

    Timer {
        id: hotplugRefresh
        interval: 500
        repeat: false
        onTriggered: {
            console.log("[Hotplug] Refreshing Hyprland state");
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
            
            // Clear and rebuild Visibilities maps to fix stale monitor references
            console.log("[Hotplug] Clearing Visibilities maps");
            Visibilities.screens.clear();
            Visibilities.bars.clear();
            
            // Second timer to let Variants recreate instances
            hotplugRefresh2.restart();
        }
    }
    
    Timer {
        id: hotplugRefresh2
        interval: 200
        repeat: false
        onTriggered: {
            console.log("[Hotplug] Phase 2 - triggering visibility reload via focusedmon");
            // Dispatch a focus event to trigger bindings refresh
            Hyprland.dispatch("focusmonitor eDP-1");
        }
    }

    // Apply persisted Hyprland settings on startup
    Timer {
        running: true
        interval: 100
        repeat: false
        onTriggered: {
            if (Config.hyprland?.gaps) {
                const innerGap = Config.hyprland.gaps.inner ?? 5;
                const outerGap = Config.hyprland.gaps.outer ?? 20;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", innerGap.toString()]);
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", outerGap.toString()]);
            }
        }
    }
}
