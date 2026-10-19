pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia.I18n
import qs.services
import "audioRules.js" as R

// Motor das regras automaticas de audio (RF-03): observa a janela em foco
// (classe) e se algum app esta capturando o microfone, e a cada mudanca
// chama `caelestia-audio-profile auto`, que resolve as regras de
// ~/.config/caelestia/audio-rules.json e aplica SO o que mudou (modo e/ou
// cena). Toda a logica fica no CLI; aqui so o contexto, o debounce e a
// notificacao. Regras desligadas (Nexus > Sound > Automatic) ou estado fixado
// a mao (manual, ate o "unpin") = o CLI nao mexe e nada e notificado.
Scope {
    id: root

    readonly property string cli: `${Quickshell.env("HOME")}/.local/bin/caelestia-audio-profile`
    readonly property string windowClass: Hypr.activeToplevel?.lastIpcObject?.class ?? ""
    // Streams de captura (Stream/Input): o PwObjectTracker carrega as
    // propriedades (application.name) de forma assincrona, por isso o mic e
    // reavaliado um instante depois de cada mudanca na lista
    property list<PwNode> recStreams: []
    property bool micOpen
    property var micApps: []
    property bool pendingRun
    readonly property var modeLabels: ({ headphone: Tr.tr("Headphones"), headset: Tr.tr("Headset") })
    readonly property var sceneLabels: ({ normal: Tr.tr("Normal"), custom: Tr.tr("Spatial") })

    function refreshStreams(): void {
        root.recStreams = Pipewire.nodes.values.filter(n => n.isStream && !n.isSink && n.audio);
        settle.restart();
    }

    function evalMic(): void {
        const list = root.recStreams.map(n => ({ name: n.name ?? "", app: n.properties?.["application.name"] ?? "", bin: n.properties?.["application.process.binary"] ?? "" }));
        const open = R.micOpen(list, Audio.isProcessingNode);
        root.micApps = R.micApps(list, Audio.isProcessingNode);
        if (open !== root.micOpen)
            root.micOpen = open;
    }

    function schedule(): void {
        if (AudioProfile.rulesEnabled)
            debounce.restart();
    }

    function run(): void {
        if (!AudioProfile.rulesEnabled)
            return;
        // Acao do usuario em curso (ou a nossa anterior): espera e repete
        if (AudioProfile.busy || proc.running) {
            root.pendingRun = true;
            return;
        }
        const args = [root.cli, "auto", "--json"];
        if (root.windowClass)
            args.push("--class", root.windowClass);
        if (root.micOpen)
            args.push("--mic-open");
        proc.command = args;
        proc.running = true;
    }

    function notifyApplied(r: var): void {
        const icon = r.mode === "headset" ? "material:headset_mic" : r.scene === "custom" ? "material:spatial_audio" : "material:headphones";
        const who = r.mic_open && root.micApps.length > 0 ? root.micApps.join(", ") : (r.class ?? "");
        const body = R.summary(r.mode, r.scene, who, root.modeLabels, root.sceneLabels);
        notify.command = ["notify-send", "-a", "Caelestia", "-i", icon, "-r", "7431", "-t", "3000", Tr.tr("Audio switched"), body];
        notify.running = true;
    }

    onWindowClassChanged: root.schedule()
    onMicOpenChanged: root.schedule()
    Component.onCompleted: root.refreshStreams()

    Connections {
        function onValuesChanged(): void {
            root.refreshStreams();
        }

        target: Pipewire.nodes
    }

    // Ligou as regras no Nexus, ou soltou o override manual: avalia ja
    Connections {
        function onRulesEnabledChanged(): void {
            root.schedule();
        }

        function onManualChanged(): void {
            if (!AudioProfile.manual)
                root.schedule();
        }

        target: AudioProfile
    }

    PwObjectTracker {
        objects: root.recStreams
    }

    Timer {
        id: settle

        interval: 600
        onTriggered: root.evalMic()
    }

    Timer {
        id: debounce

        interval: 400
        onTriggered: root.run()
    }

    Timer {
        id: retry

        interval: 1500
        onTriggered: root.run()
    }

    // O CLI reaplica o estado inteiro ao mudar (perfil Bluetooth derruba e
    // recria nos): o status do AudioProfile so e lido depois de assentar
    Timer {
        id: afterApply

        interval: 1500
        onTriggered: AudioProfile.refresh()
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                let r = null;
                try {
                    r = JSON.parse(text);
                } catch (e) {
                    console.warn("[AudioRules] resposta ilegivel:", text);
                }
                if (r && r.applied) {
                    root.notifyApplied(r);
                    afterApply.restart();
                }
            }
        }
        onExited: {
            if (root.pendingRun) {
                root.pendingRun = false;
                retry.restart();
            }
        }
    }

    Process {
        id: notify
    }
}
