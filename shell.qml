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
import QtQuick

ShellRoot {
    settings.watchFiles: true

    // Force MonitorRoles singleton to load — US-005 Fase 1 verification
    Component.onCompleted: {
        const desc = MonitorRoles.orderedMonitors.map((m, i) =>
            MonitorRoles.nameForIndex(i) + "=" + (m?.name ?? "null")).join(", ");
        console.log("[shell] MonitorRoles loaded (count=" + MonitorRoles.count + "):", desc);
    }


    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    ConfigToasts {}
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
