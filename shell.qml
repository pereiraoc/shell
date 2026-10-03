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
import "modules/polkit"
import QtQuick
import Quickshell
import qs.services
import Caelestia.Config

ShellRoot {
    id: root

    settings.watchFiles: true

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    ServiceLoader {}

    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    // Agente polkit: caixa de senha do Caelestia para pkexec e afins
    Polkit {}

    ConfigToasts {}
    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    // Apply persisted Hyprland settings on startup (gaps via Caelestia.Config)
    Timer {
        running: true
        interval: 100
        repeat: false
        onTriggered: {
            const innerGap = GlobalConfig.hyprland.gapsInner;
            const outerGap = GlobalConfig.hyprland.gapsOuter;
            Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", innerGap.toString()]);
            Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", outerGap.toString()]);
        }
    }
}
