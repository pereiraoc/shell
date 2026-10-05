pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common

// Som: saida, cena, entrada, ganho de hardware do mic, quem toca/grava em
// qual dispositivo e efeitos. Substitui o uso diario do pavucontrol,
// qpwgraph (ver o roteamento) e EasyEffects (trocar preset). Roteamento e
// efeitos pelo caelestia-sound; ganho pelo caelestia-mic-gain.
PageBase {
    id: root

    readonly property var routes: soundBridge.info
    readonly property var effects: root.routes.easyeffects ?? ({})
    readonly property var mic: micBridge.info
    readonly property var headphones: hpBridge.info.headphones ?? []

    function hpText(h: var): string {
        if (!h.connected)
            return qsTr("Not connected");
        const st = h.state;
        if (!st)
            return h.error ?? qsTr("Connected");
        const mode = ({ nc: qsTr("Cancelling noise"), ambient: qsTr("Ambient sound"), off: qsTr("Noise control off") })[st.noise?.mode] ?? "";
        const b = st.battery ?? {};
        const bat = b.level != null ? `${b.level}%` : b.left != null ? qsTr("L %1% · R %2%").arg(b.left).arg(b.right ?? "–") : "";
        return [mode, st.eq && !mode ? qsTr("EQ: %1").arg(st.eq) : "", bat].filter(x => x).join(" · ") || qsTr("Connected");
    }

    title: qsTr("Sound")
    description: qsTr("Devices, headphone modes, apps, effects and microphone")

    ToolBridge {
        id: soundBridge

        tool: "sound"

        // Quem toca/grava muda o tempo todo; so enquanto a pagina esta aberta.
        Timer {
            interval: 4000
            repeat: true
            running: root.visible
            onTriggered: soundBridge.refresh()
        }
    }

    // Modos dos fones (cancelamento de ruido, EQ...) -- caelestia-headphones
    ToolBridge {
        id: hpBridge

        tool: "headphones"
    }

    ToolBridge {
        id: micBridge

        tool: "mic-gain"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Output")
        }

        SliderRow {
            first: true
            icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            label: qsTr("Output")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.volume
            enabled: !Audio.muted
            onMoved: v => Audio.setVolume(v)
        }

        ToggleRow {
            text: qsTr("Muted")
            checked: Audio.muted
            onToggled: Audio.setStreamMuted(Audio.sink, checked)
        }

        AudioDeviceList {
            nodes: Audio.sinks
            // outputDevice, nao sink: com a cadeia CUSTOM ativa o sink default
            // e o filtro, cujo id nao casa com nenhum device -- e nenhuma linha
            // ficava marcada como ativa.
            currentId: Audio.outputDevice?.id ?? -1
            iconName: "speaker"
            placeholderIcon: "speaker"
            placeholderText: qsTr("No output devices")
            onSelected: node => Audio.setAudioSink(node)
        }

        // Cena de audio. O componente ja traz nome e descricao do selecionado.
        AudioSceneSelector {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            Layout.fillWidth: true
            // Aqui ha espaco para explicar; no popout da barra, nao.
            showDescription: true
        }

        // Fones com controle proprio (Sony, Huawei): modos na subpagina
        SectionHeader {
            visible: root.headphones.length > 0
            text: qsTr("Headphones")
        }

        Repeater {
            model: root.headphones

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.headphones.length - 1
                icon: modelData.buds ? "earbuds" : "headphones"
                iconLabel.color: modelData.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                text: modelData.name
                subtext: root.hpText(modelData)
                trailingIcon: "chevron_right"
                onClicked: {
                    root.nState.selectedHeadphone = modelData.id;
                    root.nState.openSubPage(2);
                }
            }
        }

        SectionHeader {
            text: qsTr("Input")
        }

        SliderRow {
            first: true
            icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            label: qsTr("Input")
            valueLabel: Math.round(value * 100) + "%"
            value: Audio.sourceVolume
            enabled: !Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
        }

        ToggleRow {
            text: qsTr("Muted")
            checked: Audio.sourceMuted
            onToggled: Audio.setStreamMuted(Audio.source, checked)
        }

        AudioDeviceList {
            nodes: Audio.sources
            currentId: Audio.source?.id ?? -1
            iconName: "mic"
            placeholderIcon: "mic_off"
            placeholderText: qsTr("No input devices")
            onSelected: node => Audio.setAudioSource(node)
        }

        // Ganho de hardware do mic interno: o PipeWire usa soft-mixer e nao
        // toca no ALSA, entao quem fixa o ganho e o caelestia-mic-gain.
        SectionHeader {
            visible: !!root.mic.card
            text: qsTr("Microphone hardware gain")
        }

        ChipSelectRow {
            first: true
            last: root.mic.in_sync !== false
            visible: !!root.mic.card
            label: qsTr("Built-in microphone boost")
            subtext: qsTr("+30 dB keeps game voice and Discord from clipping. Raise it only for distant sound. The Input slider is software volume on top of this.")
            options: [
                { value: "0", label: "+30 dB" },
                { value: "1", label: "+40 dB" },
                { value: "2", label: "+50 dB" }
            ]
            current: String(root.mic.target?.boost ?? "")
            busy: micBridge.busyAction.startsWith("boost-")
            onPicked: v => micBridge.run({ id: `boost-${v}` })
        }

        RowButton {
            last: true
            visible: root.mic.in_sync === false
            icon: "sync_problem"
            iconLabel.color: Colours.palette.m3tertiary
            text: qsTr("Something changed the gain to +%1 dB").arg(Math.round(root.mic.total_db ?? 0))
            subtext: qsTr("Click to reapply the chosen boost")
            disabled: micBridge.busyAction !== ""
            onClicked: micBridge.run({ id: "apply" })
        }

        ActionErrorRow {
            bridge: micBridge
        }

        // Quem toca e quem grava: a pergunta que levava ao qpwgraph.
        SectionHeader {
            text: qsTr("Apps")
        }

        InfoRow {
            first: true
            visible: (root.routes.playback ?? []).length === 0
            icon: "music_off"
            label: qsTr("Nothing is playing")
        }

        Repeater {
            model: root.routes.playback ?? []

            InfoRow {
                required property var modelData
                required property int index

                first: index === 0
                icon: modelData.corked ? "pause_circle" : "play_circle"
                label: modelData.app
                subtext: [modelData.media, modelData.corked ? qsTr("paused") : ""].filter(x => x).join(" · ")
                value: (modelData.device || modelData.target) + (modelData.filtered ? qsTr(" · with effects") : "")
            }
        }

        InfoRow {
            visible: (root.routes.recording ?? []).length === 0
            icon: "mic_off"
            label: qsTr("Nothing is using the microphone")
        }

        Repeater {
            model: root.routes.recording ?? []

            InfoRow {
                required property var modelData

                icon: modelData.raw ? "warning" : "mic"
                iconColour: modelData.raw ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                label: qsTr("%1 is recording").arg(modelData.app)
                subtext: modelData.raw ? qsTr("Uses the raw microphone — no noise filter or echo cancelling. Pick “Default” in the app's settings.") : (modelData.filtered ? qsTr("Filtered microphone") : "")
                value: modelData.device || modelData.target
            }
        }

        NavRow {
            last: true
            icon: "tune"
            text: qsTr("App volumes")
            subtext: Audio.streams.length === 0 ? qsTr("No apps playing audio") : Audio.streams.length === 1 ? qsTr("1 app playing audio") : qsTr("%1 apps playing audio").arg(Audio.streams.length)
            onClicked: root.nState.openSubPage(1)
        }

        // Efeitos (EasyEffects)
        SectionHeader {
            visible: root.effects.available === true
            text: qsTr("Effects")
        }

        InfoRow {
            first: true
            last: true
            visible: root.effects.available === true && !root.effects.running
            icon: "graphic_eq"
            label: qsTr("EasyEffects is not running")
            subtext: qsTr("Open it from Advanced below to use equalizer and noise presets")
        }

        ToggleRow {
            first: true
            last: (root.effects.output_presets ?? []).length === 0 && (root.effects.input_presets ?? []).length === 0
            visible: root.effects.running === true
            text: qsTr("Effects enabled")
            subtext: qsTr("Turn off to hear the sound without any processing")
            checked: root.effects.bypass === false
            onToggled: soundBridge.run({ id: checked ? "ee-bypass-off" : "ee-bypass-on" })
        }

        ExpandSelectRow {
            last: (root.effects.input_presets ?? []).length === 0
            visible: root.effects.running === true && (root.effects.output_presets ?? []).length > 0
            icon: "speaker"
            label: qsTr("Output preset")
            options: (root.effects.output_presets ?? []).map(p => ({ value: p, label: p }))
            current: root.effects.active_output ?? ""
            busy: soundBridge.busyAction.startsWith("ee-output-")
            onPicked: v => soundBridge.run({ id: `ee-output-${v}` })
        }

        ExpandSelectRow {
            last: true
            visible: root.effects.running === true && (root.effects.input_presets ?? []).length > 0
            icon: "mic"
            label: qsTr("Microphone preset")
            options: (root.effects.input_presets ?? []).map(p => ({ value: p, label: p }))
            current: root.effects.active_input ?? ""
            busy: soundBridge.busyAction.startsWith("ee-input-")
            onPicked: v => soundBridge.run({ id: `ee-input-${v}` })
        }

        ActionErrorRow {
            bridge: soundBridge
        }

        AdvancedGroup {
            apps: [
                { id: "org.rncbc.qpwgraph", text: qsTr("Audio routing graph"), subtext: qsTr("Connect any app to any device by hand (qpwgraph)") },
                { id: "com.github.wwmm.easyeffects", text: qsTr("EasyEffects"), subtext: qsTr("Edit equalizer, compressor and noise presets") },
                { id: "pavucontrol", alt: ["org.pulseaudio.pavucontrol"], text: qsTr("Volume control"), subtext: qsTr("Card profiles and per-device settings (pavucontrol)") }
            ]
        }
    }
}
