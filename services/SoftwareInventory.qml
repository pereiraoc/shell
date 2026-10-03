pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Ponte fina para o caelestia-software.
//
// Toda a logica -- rastreamento requisito/design/implementacao, classificacao
// Required x Derived, deteccao de arquivo sem dono -- vive no CLI. Ele e
// testavel no terminal, vale sem o shell aberto, e mora no repositorio de
// setup, entao nao vira superficie de conflito a cada rebase do upstream.
//
// Nada aqui escreve: o CLI e somente leitura por design. Atualizar e' o
// caelestia-update, aberto num terminal (runUpdate) -- sudo e prompts do
// pacman precisam de alguem olhando, nao de um botao silencioso.
Singleton {
    id: root

    // Caminho absoluto: ~/.local/bin nao esta no PATH neste sistema.
    readonly property string cli: `${Quickshell.env("HOME")}/.local/bin/caelestia-software`
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin`

    property var trace: ({})
    property var inventory: ({})
    property var updates: ({})

    property bool loadingTrace: traceProc.running
    property bool loadingInventory: invProc.running
    property bool loadingUpdates: updProc.running
    property bool updatesFetched: false

    readonly property int updateCount: root.updates.count ?? 0
    // Parcial = alguma fonte nao respondeu ou o checkupdates falta. Um zero
    // parcial NAO e' "em dia" e a pagina nao pode mostrar como se fosse.
    readonly property bool updatesComplete: root.updates.complete ?? false
    readonly property var updatesCheckedAt: root.updates.checked_at ? new Date(root.updates.checked_at * 1000) : null

    readonly property var counts: root.trace.counts ?? ({})
    readonly property var requirements: root.trace.requirements ?? []
    readonly property var design: root.trace.design ?? []
    readonly property var implementation: root.trace.implementation ?? []
    readonly property var derived: root.trace.derived ?? ({})
    readonly property var broken: root.trace.broken ?? []
    readonly property var untracked: root.inventory.untracked ?? []
    readonly property var orphans: root.inventory.orphans ?? ({})

    // Design que nao serve requisito nenhum, e implementacao declarada que nao
    // faz nada: as duas pontas soltas do lado do repositorio, simetricas as
    // pontas soltas do lado da maquina.
    readonly property var unusedDesign: root.design.filter(d => (d.requirements?.length ?? 0) === 0)
    readonly property var stubs: root.implementation.filter(i => i.stub)

    function designFor(req: var): var {
        return (req?.design ?? []).map(p => root.design.find(d => d.file === p)).filter(d => d);
    }

    function implFor(req: var): var {
        return (req?.implementation ?? []).map(p => root.implementation.find(i => i.path === p)).filter(i => i);
    }

    function refresh(): void {
        traceProc.running = false;
        traceProc.running = true;
        invProc.running = false;
        invProc.running = true;
    }

    // Separada de proposito: `paru -Qua` e `flatpak remote-ls` vao a rede e
    // custam segundos, contra 0,4 s do rastreamento local. Juntar as duas faria
    // a pagina inteira esperar pela parte que pode nem responder.
    //
    // Passa pelo caelestia-update-check em vez do CLI direto: ele grava o mesmo
    // cache que o timer grava, e marca a lista como vista (sem notificacao
    // repetida do que o usuario acabou de olhar).
    function fetchUpdates(): void {
        if (updProc.running)
            return;
        updProc.running = true;
    }

    // Abre o terminal configurado (general.apps.terminal) com o aplicador. Ao
    // terminar ele regrava o cache, e o FileView abaixo atualiza a pagina.
    function runUpdate(): void {
        Quickshell.execDetached([...GlobalConfig.general.apps.terminal, `${root.bin}/caelestia-update`]);
    }

    Component.onCompleted: root.refresh()

    Process {
        id: traceProc

        command: [root.cli, "trace", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.trace = JSON.parse(text);
                } catch (e) {
                    console.warn("[SoftwareInventory] trace ilegivel:", e);
                }
            }
        }
    }

    Process {
        id: invProc

        command: [root.cli, "inventory", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.inventory = JSON.parse(text);
                } catch (e) {
                    console.warn("[SoftwareInventory] inventory ilegivel:", e);
                }
            }
        }
    }

    Process {
        id: updProc

        command: [`${root.bin}/caelestia-update-check`, "--no-notify"]
        onExited: cacheFile.reload()
    }

    // Ultima resposta conhecida, de quem quer que tenha checado (timer, botao,
    // fim do caelestia-update). A pagina abre com ela sem ir a rede.
    FileView {
        id: cacheFile

        path: `${Paths.cache}/updates.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.updates = JSON.parse(text());
                root.updatesFetched = true;
            } catch (e) {
                console.warn("[SoftwareInventory] updates.json ilegivel:", e);
            }
        }
    }
}
