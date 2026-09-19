pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ponte fina para o caelestia-audio-profile.
//
// Toda a logica de audio (perfis Bluetooth, cadeia de efeitos, roteamento)
// vive no CLI, nao aqui: ele e testavel no terminal, funciona por atalho de
// teclado e continua valendo se o shell cair. Este singleton so le o estado e
// dispara acoes.
Singleton {
    id: root

    // Caminho absoluto: ~/.local/bin nao esta no PATH neste sistema.
    readonly property string cli: `${Quickshell.env("HOME")}/.local/bin/caelestia-audio-profile`

    property var status: ({})
    property var presets: []

    readonly property string scene: root.status.scene ?? "normal"
    readonly property var outputs: root.status.outputs ?? []
    readonly property string preset: root.status.custom_spec?.preset ?? ""
    readonly property bool customEffective: root.status.custom_effective ?? false

    function refresh(): void {
        statusProc.running = false;
        statusProc.running = true;
    }

    function modeFor(nodeName: string): string {
        const d = root.outputs.find(o => o.name === nodeName);
        return d?.mode ?? "";
    }

    function supportsHeadset(nodeName: string): bool {
        const d = root.outputs.find(o => o.name === nodeName);
        return d?.supports_headset ?? false;
    }

    // Uma acao por vez: o CLI reaplica o estado inteiro a cada chamada, entao
    // disparar duas em paralelo poderia intercalar escritas no mesmo arquivo.
    function exec(args: list<string>): void {
        if (actionProc.running)
            return;
        actionProc.command = [root.cli, ...args];
        actionProc.running = true;
    }

    function setScene(value: string): void {
        root.exec(["scene", value]);
    }

    function setMode(nodeName: string, value: string): void {
        root.exec(["mode", value, "--device", nodeName]);
    }

    function setOutput(nodeName: string): void {
        root.exec(["output", nodeName]);
    }

    function setPreset(id: string): void {
        root.exec(["custom", "preset", id]);
    }

    Component.onCompleted: {
        root.refresh();
        presetsProc.running = true;
    }

    Process {
        id: statusProc

        command: [root.cli, "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                } catch (e) {
                    console.warn("[AudioProfile] status ilegivel:", e);
                }
            }
        }
    }

    Process {
        id: presetsProc

        command: [root.cli, "custom", "presets"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.presets = JSON.parse(text);
                } catch (e) {
                    console.warn("[AudioProfile] presets ilegiveis:", e);
                }
            }
        }
    }

    Process {
        id: actionProc

        // Trocar perfil Bluetooth derruba e recria nos; o estado so estabiliza
        // um instante depois, entao o refresh e adiado.
        onExited: settleTimer.restart()
    }

    Timer {
        id: settleTimer

        interval: 1200
        onTriggered: root.refresh()
    }

    // O estado tambem muda por fora (atalho de teclado, terminal, fone que
    // conecta). Uma sondagem lenta mantem a UI honesta sem custo relevante.
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
