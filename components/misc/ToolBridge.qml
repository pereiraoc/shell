import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Ponte generica para as ferramentas do contrato (caelestia-<tool>):
//
//     ToolBridge { id: storage; tool: "storage" }
//
// Toda a logica vive no CLI, no repositorio de setup, e funciona sem o shell.
// Aqui so se le o que o executor (caelestia-tool-run) grava em
// ~/.cache/caelestia/tools/ e se dispara o executor.
//
// POR QUE AS ACOES SAO DESTACADAS: processo filho de pagina morre quando a
// pagina fecha. Fechar o Nexus no meio de um `sudo paccache` nao pode matar a
// limpeza, entao `run()` usa execDetached e a ponte so OBSERVA o last.json.
// Ja o refresh e filho de proposito: morrer no meio e inofensivo (o executor
// grava com tmp + mv).
//
// Spec: docs/superpowers/specs/2026-10-03-contrato-ferramentas-e-storage-design.md
// (repositorio caelestia-arch-setup).
Item {
    id: root

    required property string tool

    // Caminho absoluto: ~/.local/bin nao esta no PATH deste sistema.
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin`
    readonly property string runner: `${root.bin}/caelestia-tool-run`
    readonly property string cacheBase: `${Paths.cache}/tools/${root.tool}`

    property var status: ({})
    property var actionsDoc: ({})
    property var last: ({})
    property string error: ""

    // "info", nao "data": data e a propriedade padrao de Item (os filhos).
    readonly property var info: root.status.data ?? ({})
    readonly property string summary: root.status.summary ?? ""
    readonly property string level: root.status.level ?? "ok"
    readonly property var actions: root.actionsDoc.actions ?? []
    readonly property bool loading: refreshProc.running

    // Acao disparada e ainda sem last.json novo. Com sudo pode durar o tempo
    // que o usuario levar no terminal -- o teto so evita ficar preso para
    // sempre se o terminal for fechado sem rodar nada.
    property string busyAction: ""
    property real busySince: 0
    readonly property int busyTimeoutMs: 15 * 60 * 1000

    // Ultima acao executada (de qualquer origem: Nexus ou terminal).
    readonly property var lastResult: root.last.result ?? null

    function refresh(): void {
        if (refreshProc.running)
            return;
        root.error = "";
        refreshProc.timedOut = false;
        refreshProc.running = true;
        watchdog.restart();
    }

    function run(action: var): void {
        if (!action?.id || root.busyAction)
            return;
        root.busyAction = action.id;
        root.busySince = Date.now();
        busyTimer.restart();
        lastPoll.start();
        // Sem terminal tambem para as que pedem root: sem tty, a ferramenta
        // eleva com pkexec, que abre a caixa de senha do Caelestia
        // (modules/polkit). `root` na acao so muda o icone na pagina.
        Quickshell.execDetached([root.runner, "action", root.tool, action.id]);
    }

    function parse(view: FileView, target: string): void {
        try {
            root[target] = JSON.parse(view.text());
        } catch (e) {
            root.error = qsTr("%1: unreadable %2 cache").arg(root.tool).arg(target);
        }
    }

    Component.onCompleted: root.refresh()

    FileView {
        id: statusFile

        path: `${root.cacheBase}.status.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(statusFile, "status")
    }

    FileView {
        id: actionsFile

        path: `${root.cacheBase}.actions.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(actionsFile, "actionsDoc")
    }

    FileView {
        id: lastFile

        path: `${root.cacheBase}.last.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            root.parse(lastFile, "last");
            // last.json e gravado por ultimo: quando muda, a acao acabou e o
            // cache ja foi refeito.
            if (root.busyAction && (root.last.at ?? 0) * 1000 >= root.busySince - 1000) {
                root.busyAction = "";
                busyTimer.stop();
                lastPoll.stop();
                // O executor refez o cache; arquivos que nasceram agora nao
                // tem watch ainda, entao recarrega explicitamente.
                statusFile.reload();
                actionsFile.reload();
            }
        }
    }

    Process {
        id: refreshProc

        property bool timedOut

        command: [root.runner, "refresh", root.tool]
        stderr: StdioCollector {
            id: refreshErr
        }
        onExited: code => { // qmllint disable signal-handler-parameters
            watchdog.stop();
            if (refreshProc.timedOut)
                return; // o watchdog ja deixou a mensagem certa
            if (code !== 0)
                root.error = refreshErr.text.trim() || qsTr("%1: refresh failed (exit %2)").arg(root.tool).arg(code);
            // Os FileViews pegam a mudanca pelo watch; o reload garante o caso
            // do arquivo recem-criado (sem watch ainda).
            statusFile.reload();
            actionsFile.reload();
        }
    }

    Timer {
        id: watchdog

        interval: 15000
        onTriggered: {
            refreshProc.timedOut = true;
            refreshProc.running = false;
            root.error = qsTr("%1: timed out after 15 s").arg(root.tool);
        }
    }

    Timer {
        id: busyTimer

        interval: root.busyTimeoutMs
        onTriggered: {
            root.busyAction = "";
            lastPoll.stop();
        }
    }

    // FileView nao vigia arquivo que ainda nao existe: na primeira acao de
    // uma ferramenta o last.json nasce depois da ponte, e o watch nunca
    // dispararia (achado no harness). Enquanto ha acao em andamento, relemos.
    Timer {
        id: lastPoll

        interval: 1000
        repeat: true
        onTriggered: lastFile.reload()
    }
}
