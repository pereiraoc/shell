pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

// Modo aviao (rfkill): Fn+F12 no notebook, `rfkill block all` ou o kernel.
// `rfkill event` nao imprime o estado inicial e o sysfs nao avisa, entao o
// estado vem de `rfkill -J`: a cada 5 s e, na hora, quando o Wi-Fi (nmcli) ou
// o adaptador Bluetooth mudam -- os dois caem junto com o rfkill, e e isso que
// a barra e os popouts mostram (aviao no lugar do Bluetooth; Wireless apagado).
Singleton {
    id: root

    // Todos os radios bloqueados (soft ou hard) = modo aviao
    readonly property bool airplane: root.devices.length > 0 && root.devices.every(d => d.blocked)
    readonly property bool wifiBlocked: root.devices.some(d => d.type === "wlan" && d.blocked)
    readonly property bool bluetoothBlocked: root.devices.some(d => d.type === "bluetooth" && d.blocked)
    // [{ type, blocked }]
    property list<var> devices: []

    function refresh(): void {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc

        running: true
        command: ["rfkill", "-J"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text).rfkilldevices ?? [];
                    root.devices = list.map(d => ({ type: d.type, blocked: d.soft === "blocked" || d.hard === "blocked" }));
                } catch (e) {
                    root.devices = [];
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Connections {
        function onWifiEnabledChanged(): void {
            root.refresh();
        }

        target: Nmcli
    }

    Connections {
        function onEnabledChanged(): void {
            root.refresh();
        }

        target: Bluetooth.defaultAdapter // qmllint disable unresolved-type
        ignoreUnknownSignals: true
    }
}
