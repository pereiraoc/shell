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

    // Gaps salvos no Nexus: na partida e a cada reload do Hyprland (o reload
    // -- hotplug de monitor, alocador de workspaces -- voltava ao da config).
    // applyOptions fala keyword (.conf) ou eval hl.config (Lua).
    function applyGaps(): void {
        Hypr.extras.applyOptions({ "general:gaps_in": GlobalConfig.hyprland.gapsInner, "general:gaps_out": GlobalConfig.hyprland.gapsOuter });
    }

    Timer {
        running: true
        interval: 100
        repeat: false
        onTriggered: root.applyGaps()
    }

    Connections {
        target: Hypr

        function onConfigReloaded(): void {
            root.applyGaps();
        }
    }
}
