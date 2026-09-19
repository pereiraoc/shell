pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.Services

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    // O sink default pode ser um FILTRO (a cadeia CUSTOM do caelestia-audio-profile),
    // que nao e um dispositivo: e uma etapa de processamento entre os apps e o
    // hardware. Nos de filtro carregam node.link-group; nos de hardware carregam
    // device.id. Distinguir importa por dois motivos:
    //   1. o filtro nao deve aparecer no seletor de saida (nome confuso, nao e fone)
    //   2. volume tem que seguir o DISPOSITIVO; seguindo o filtro, o estagio de
    //      hardware fica orfao e o usuario nao alcanca o volume maximo do fone
    readonly property bool defaultIsFilter: !!sink?.properties["node.link-group"]

    // Quando o default e um filtro, o dispositivo real e aquele em que o
    // WirePlumber liga a saida dele: o de maior priority.session entre os
    // devices (mesma regra de linking/find-best-target.lua, que so itera sobre
    // item.node.type = "device").
    readonly property PwNode outputDevice: {
        if (!defaultIsFilter)
            return sink;
        let best = null;
        let bestPrio = -1;
        for (const n of sinks) {
            const prio = parseInt(n.properties["priority.session"] ?? "0");
            if (prio > bestPrio) {
                bestPrio = prio;
                best = n;
            }
        }
        return best;
    }

    // Espelha outputDevice do lado da entrada: quando a supressao esta ligada,
    // a fonte padrao e o no do echo-cancel, que nao e um dispositivo. Quem
    // resolve o microfone real por tras dele e o CLI (campo input_device).
    readonly property PwNode sourceDevice: {
        const wanted = AudioProfile.status?.input_device ?? "";
        if (!wanted)
            return source;
        return sources.find(n => n.name === wanted) ?? source;
    }

    readonly property bool muted: !!outputDevice?.audio?.muted
    readonly property real volume: outputDevice?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!sourceDevice?.audio?.muted
    readonly property real sourceVolume: sourceDevice?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    // Nos de PROCESSAMENTO que este setup cria (cadeia CUSTOM e supressao de
    // ruido). Nao sao dispositivos e nao devem aparecer no seletor.
    //
    // O criterio e o NOME de proposito. A tentativa anterior usava
    // properties["device.id"], que e preenchida de forma ASSINCRONA pelo
    // PipeWire: refreshNodes() so roda em Component.onCompleted e quando o
    // conjunto de nos muda, entao a propriedade ainda estava vazia na hora da
    // avaliacao e os dispositivos eram descartados para sempre -- as listas
    // ficavam vazias. node.name vem preenchido em initProps, sincronamente.
    function isProcessingNode(name: string): bool {
        if (!name)
            return false;
        // "caelestia_ec_*" sao os nos que NOS nomeamos ao carregar o
        // module-echo-cancel; "echo-cancel-*" sao os internos que o proprio
        // modulo cria e batiza, independente dos nomes que passamos. Sem o
        // segundo prefixo, o echo-cancel-playback aparecia no mixer como se
        // fosse um app tocando audio.
        return name.startsWith("effect_input.") || name.startsWith("effect_output.") || name.startsWith("caelestia_ec_") || name.startsWith("echo-cancel-");
    }

    function setVolume(newVolume: real): void {
        // Escreve no DISPOSITIVO, nao no default: com a cadeia CUSTOM no caminho
        // o default e o filtro, e mexer nele deixa o estagio de hardware do fone
        // parado onde estava -- foi assim que o volume maximo ficou inalcancavel.
        const target = outputDevice;
        if (target?.ready && target?.audio) {
            target.audio.muted = false;
            target.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        const target = sourceDevice;
        if (target?.ready && target?.audio) {
            target.audio.muted = false;
            target.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        // Com a cena CUSTOM ativa o default precisa continuar sendo o filtro;
        // trocar de dispositivo e' mover a SAIDA do filtro. Isso e' feito pelo
        // caelestia-audio-profile, que e o dono dessa logica.
        if (root.defaultIsFilter)
            selectOutputProc.exec([selectOutputProc.cli, "output", newSink.name]);
        else
            Pipewire.preferredDefaultAudioSink = newSink;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return qsTr("Unknown");
        // Try application name first, then description, then name
        return stream.properties["application.name"] || stream.description || stream.name || qsTr("Unknown Application");
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                // So DISPOSITIVOS no seletor de saida. Nos virtuais (filter-chain
                // da cena CUSTOM, echo-cancel) tem media.class Audio/Sink mas nao
                // tem device.id -- apareciam na lista com nomes tipo
                // "Custom (HRTF atmos.wav + EQ)" e "Echo-Cancel Sink", como se
                // fossem fones.
                if (node.isSink && !root.isProcessingNode(node.name))
                    newSinks.push(node);
                else if (node.audio && !root.isProcessingNode(node.name))
                    // Mesmo criterio da saida: nos virtuais (o echo-cancel da
                    // supressao) nao sao dispositivos e nao entram no seletor.
                    // O processamento aparece como tag no dispositivo real.
                    newSources.push(node);
            } else if (node.audio && node.isSink && !root.isProcessingNode(node.name)) {
                // isSink isola streams de REPRODUCAO: AudioOutStream e Audio|Sink|Stream,
                // enquanto AudioInStream e Audio|Source|Stream. Sem isso, streams de
                // captura (o proprio visualizer do shell, por exemplo) apareciam em
                // "App volumes", que se anuncia como "apps currently playing audio".
                // isProcessingNode exclui os nos de filter-chain e do echo-cancel,
                // que sao Stream/Output/Audio mas nao sao apps. Pelo nome, e nao
                // por node.link-group, porque essa propriedade chega assincrona.
                newStreams.push(node);
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || qsTr("Unknown Device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(qsTr("Audio output changed"), qsTr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || qsTr("Unknown Device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(qsTr("Audio input changed"), qsTr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || qsTr("Unknown Device");
        previousSourceName = source?.description || source?.name || qsTr("Unknown Device");
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    Process {
        id: selectOutputProc

        // Caminho absoluto de proposito: ~/.local/bin NAO esta no PATH neste
        // sistema (nem no login shell), entao chamar pelo nome falharia.
        readonly property string cli: `${Quickshell.env("HOME")}/.local/bin/caelestia-audio-profile`
    }

    PwObjectTracker {
        objects: [root.sink, root.source, root.outputDevice, root.sourceDevice, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    CavaProvider {
        id: cava

        bars: GlobalConfig.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
