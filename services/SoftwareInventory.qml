pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Ponte fina para o caelestia-software.
//
// Toda a logica -- rastreamento requisito/design/implementacao, classificacao
// Required x Derived, deteccao de arquivo sem dono -- vive no CLI. Ele e
// testavel no terminal, vale sem o shell aberto, e mora no repositorio de
// setup, entao nao vira superficie de conflito a cada rebase do upstream.
//
// Nada aqui escreve: o CLI e somente leitura por design. Remover ou atualizar
// pacote continua sendo trabalho de terminal ou do pamac.
Singleton {
    id: root

    // Caminho absoluto: ~/.local/bin nao esta no PATH neste sistema.
    readonly property string cli: `${Quickshell.env("HOME")}/.local/bin/caelestia-software`

    property var trace: ({})
    property var inventory: ({})
    property var updates: ({})

    property bool loadingTrace: traceProc.running
    property bool loadingInventory: invProc.running
    property bool loadingUpdates: updProc.running
    property bool updatesFetched: false

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
    // custam ~1,7 s, contra 0,4 s do rastreamento local. Juntar as duas faria a
    // pagina inteira esperar pela parte que pode nem responder.
    function fetchUpdates(): void {
        if (updProc.running)
            return;
        updProc.running = true;
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

        command: [root.cli, "updates", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.updates = JSON.parse(text);
                    root.updatesFetched = true;
                } catch (e) {
                    console.warn("[SoftwareInventory] updates ilegivel:", e);
                }
            }
        }
    }
}
