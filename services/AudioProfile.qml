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

    // Verdadeiro do disparo de uma acao ate o estado ja refletir o resultado.
    // As acoes levam de 1,5 a 3 s -- o CLI reaplica o estado inteiro, e trocar
    // perfil Bluetooth derruba e recria nos -- tempo de sobra para a interface
    // parecer travada se nada avisar que ha algo em curso.
    //
    // Nao bastaria `actionProc.running`: quando o CLI sai o estado ainda nao
    // estabilizou (e por isso que existe o settleTimer), e apagar o indicador
    // ali faria a UI piscar o valor antigo antes de assentar no novo. Nem
    // bastaria observar `statusProc`: a sondagem periodica usa o mesmo processo
    // e o indicador acenderia sozinho a cada 10 segundos.
    property bool busy: false

    // So o refresh disparado pelo settleTimer pode apagar o `busy`. Sem esta
    // marca, uma sondagem periodica que terminasse no meio de uma acao cortaria
    // o indicador cedo demais.
    property bool settledRefresh: false

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
        root.busy = true;
        busyGuard.restart();
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
                // Mesmo com status ilegivel a interface tem de voltar: ficar
                // bloqueada seria pior que mostrar um estado desatualizado.
                if (root.settledRefresh) {
                    root.settledRefresh = false;
                    root.busy = false;
                    busyGuard.stop();
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
        onTriggered: {
            root.settledRefresh = true;
            root.refresh();
        }
    }

    // Rede de seguranca: o indicador BLOQUEIA a interacao, entao um CLI que
    // travasse deixaria o seletor morto ate o shell reiniciar. Passado o pior
    // caso plausivel (acao + settle + status), libera mesmo sem confirmacao.
    Timer {
        id: busyGuard

        interval: 10000
        onTriggered: {
            console.warn("[AudioProfile] acao sem confirmacao em 10s; liberando a interface");
            root.settledRefresh = false;
            root.busy = false;
        }
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
