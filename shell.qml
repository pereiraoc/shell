//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

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

    GSFLoader {}

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
