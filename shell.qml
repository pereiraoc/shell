//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import qs.config
import Quickshell
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

    // Apply persisted Hyprland settings on startup (F3 — gaps)
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
