pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.misc
import Caelestia.I18n
import qs.services
import qs.utils
import qs.modules.nexus.common

// Som, em abas: Output (volume, dispositivo, cena, fones, quem esta tocando e
// o mixer por app), Input (mic, dispositivo, ganho de hardware, quem esta
// gravando), Effects (EasyEffects) e Advanced. Substitui o uso diario do
// pavucontrol, qpwgraph (ver o roteamento) e EasyEffects (trocar preset).
// Roteamento e efeitos pelo caelestia-sound; ganho pelo caelestia-mic-gain.
PageBase {
    id: root

    readonly property var routes: soundBridge.info
    readonly property var effects: root.routes.easyeffects ?? ({})
    readonly property var mic: micBridge.info
    readonly property var headphones: hpBridge.info.headphones ?? []


    // "cs2 in focus → Spatial", "Microphone in use → Headset"
    function ruleText(r: var): string {
        const effect = [r.mode === "headset" ? qsTr("Headset") : r.mode === "headphone" ? qsTr("Headphones") : "", r.scene === "custom" ? qsTr("Spatial") : r.scene === "normal" ? qsTr("Normal scene") : ""].filter(x => x).join(" · ");
        const when = r.match === "mic-open" ? qsTr("Microphone in use") : qsTr("%1 in focus").arg(r.value ?? "");
        return `${when} → ${effect || qsTr("nothing")}`;
    }
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
    tabs: [
        { id: "output", label: qsTr("Output") },
        { id: "input", label: qsTr("Input") },
        { id: "effects", label: qsTr("Effects") }
    ]

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

        // ------------------------------------------------------------ Output
        TabPane {
            active: root.tab === "output"

            SliderRow {
                first: true
                icon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                label: Tr.trCtx("Output", "audio output")
                valueLabel: Strings.percentOne(value)
                value: Audio.volume
                enabled: !Audio.muted
                onMoved: v => Audio.setVolume(v)
            }

            ToggleRow {
                text: Tr.trCtx("Muted", "audio output muted")
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
                placeholderText: Tr.trCtx("No output devices", "no audio outputs")
                onSelected: node => Audio.setAudioSink(node)
            }

            // Cena de audio. O componente ja traz nome e descricao do selecionado.
            AudioSceneSelector {
                Layout.topMargin: Tokens.spacing.large - parent.spacing
                Layout.fillWidth: true
                // Aqui ha espaco para explicar; no popout da barra, nao.
                showDescription: true
            }

            // Regras automaticas: o motor (modules/AudioRules.qml) chama
            // `caelestia-audio-profile auto` a cada janela em foco / mic aberto
            SectionHeader {
                text: qsTr("Automatic")
            }

            ToggleRow {
                first: true
                last: !AudioProfile.rulesEnabled
                text: qsTr("Follow the app in focus and the microphone")
                subtext: AudioProfile.rulesEnabled ? qsTr("The rules below apply by themselves, with a notification. Picking a mode or scene by hand pauses them until you release.") : qsTr("Off: mode and scene only change when you pick them")
                checked: AudioProfile.rulesEnabled
                disabled: AudioProfile.busy
                onToggled: AudioProfile.setRules(checked)
            }

            RowButton {
                visible: AudioProfile.rulesEnabled && AudioProfile.manual
                icon: "lock_open"
                iconLabel.color: Colours.palette.m3tertiary
                text: qsTr("Paused: set by hand")
                subtext: qsTr("Tap to let the rules take over again")
                disabled: AudioProfile.busy
                onClicked: AudioProfile.unpin()
            }

            Repeater {
                model: AudioProfile.rulesEnabled ? AudioProfile.rules.length : 0

                ToggleRow {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: AudioProfile.rules[index] ?? ({})
                    readonly property var liveItem: AudioProfile.rules[index]
                    required property int index

                    last: index === AudioProfile.rules.length - 1
                    text: root.ruleText(modelData)
                    subtext: modelData.match === "mic-open" ? qsTr("Any app capturing the microphone") : qsTr("Window class “%1” in focus").arg(modelData.value ?? "")
                    checked: modelData.enabled !== false
                    disabled: AudioProfile.busy
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                    onToggled: AudioProfile.setRule(index, checked)
                }
            }

            // Fones com controle proprio (Sony, Huawei): modos na subpagina
            SectionHeader {
                visible: root.headphones.length > 0
                text: qsTr("Headphones")
            }

            Repeater {
                model: root.headphones.length

                RowButton {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: root.headphones[index] ?? ({})
                    readonly property var liveItem: root.headphones[index]
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
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

            // Quem toca onde (a pergunta que levava ao qpwgraph) e o mixer por app
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
                model: (root.routes.playback ?? []).length

                InfoRow {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: (root.routes.playback ?? [])[index] ?? ({})
                    readonly property var liveItem: (root.routes.playback ?? [])[index]
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                    required property int index

                    first: index === 0
                    icon: modelData.corked ? "pause_circle" : "play_circle"
                    label: modelData.app
                    subtext: [modelData.media, modelData.corked ? qsTr("paused") : ""].filter(x => x).join(" · ")
                    value: (modelData.device || modelData.target) + (modelData.filtered ? qsTr(" · with effects") : "")
                }
            }

            NavRow {
                last: true
                icon: "tune"
                text: Tr.tr("App volumes")
                subtext: Audio.streams.length === 0 ? Tr.tr("No apps playing audio") : Tr.trN("%n app playing audio", "%n apps playing audio", Audio.streams.length)
                onClicked: root.nState.openSubPage(1)
            }

            ActionErrorRow {
                bridge: soundBridge
            }

            AdvancedGroup {
                Layout.topMargin: Tokens.spacing.large
                apps: [
                    { id: "org.rncbc.qpwgraph", text: qsTr("Audio routing graph"), subtext: qsTr("Connect any app to any device by hand (qpwgraph)") },
                    { id: "com.github.wwmm.easyeffects", text: qsTr("EasyEffects"), subtext: qsTr("Edit equalizer, compressor and noise presets") }
                ]
            }
        }

        // ------------------------------------------------------------- Input
        TabPane {
            active: root.tab === "input"

            SliderRow {
                first: true
                icon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                label: Tr.trCtx("Input", "audio input")
                valueLabel: Strings.percentOne(value)
                value: Audio.sourceVolume
                enabled: !Audio.sourceMuted
                onMoved: v => Audio.setSourceVolume(v)
            }

            ToggleRow {
                text: Tr.trCtx("Muted", "audio input muted")
                checked: Audio.sourceMuted
                onToggled: Audio.setStreamMuted(Audio.source, checked)
            }

            AudioDeviceList {
                nodes: Audio.sources
                currentId: Audio.source?.id ?? -1
                iconName: "mic"
                placeholderIcon: "mic_off"
                placeholderText: Tr.trCtx("No input devices", "no audio inputs")
                onSelected: node => Audio.setAudioSource(node)
            }

            // Processamento do mic (caelestia-audio-profile): a fonte padrao e a
            // filtrada (cancelamento de eco + supressao de ruido); apps que
            // escolhem o mic cru pelo nome ficam de fora -- e a lista de Apps avisa
            SectionHeader {
                text: qsTr("Microphone processing")
            }

            InfoRow {
                first: true
                icon: "noise_control_off"
                label: qsTr("Default input")
                subtext: qsTr("What apps get when they pick “Default”: the laptop microphone through echo cancelling%1").arg(AudioProfile.status.suppress ? qsTr(" and noise suppression") : "")
                value: AudioProfile.status.default_source_description ?? ""
            }

            ToggleRow {
                last: true
                text: qsTr("Noise suppression")
                subtext: qsTr("Cuts fans, keyboard and room noise from the filtered microphone")
                checked: !!AudioProfile.status.suppress
                disabled: AudioProfile.busy
                onToggled: AudioProfile.exec(["suppress", checked ? "on" : "off"])
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

            // Quem esta gravando, e com qual fonte
            SectionHeader {
                text: qsTr("Apps")
            }

            InfoRow {
                first: true
                last: (root.routes.recording ?? []).length === 0
                visible: (root.routes.recording ?? []).length === 0
                icon: "mic_off"
                label: qsTr("Nothing is using the microphone")
            }

            Repeater {
                model: (root.routes.recording ?? []).length

                InfoRow {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: (root.routes.recording ?? [])[index] ?? ({})
                    readonly property var liveItem: (root.routes.recording ?? [])[index]
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                    required property int index

                    first: index === 0
                    last: index === (root.routes.recording ?? []).length - 1
                    icon: modelData.raw ? "warning" : "mic"
                    iconColour: modelData.raw ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                    label: qsTr("%1 is recording").arg(modelData.app)
                    subtext: modelData.raw ? qsTr("Uses the raw microphone — no noise filter or echo cancelling. Pick “Default” in the app's settings.") : (modelData.filtered ? qsTr("Through the noise filter") : "")
                    value: modelData.device || modelData.target
                }
            }
        }

        // ----------------------------------------------------------- Effects
        TabPane {
            active: root.tab === "effects"

            InfoRow {
                first: true
                last: true
                visible: root.effects.available !== true
                icon: "graphic_eq"
                label: qsTr("EasyEffects is not installed")
                subtext: qsTr("Equalizer and noise presets need it")
            }

            // Servico: sobe sem janela e fica pendurado no PipeWire
            ToggleRow {
                first: true
                visible: root.effects.available === true
                text: qsTr("EasyEffects running")
                subtext: root.effects.running ? qsTr("Equalizer and noise presets apply to the sound; turn off to go back to direct output") : qsTr("Starts it in the background (no window) so presets and bypass work")
                checked: root.effects.running === true
                disabled: soundBridge.busyAction !== ""
                onToggled: soundBridge.run({ id: checked ? "ee-start" : "ee-stop" })
            }

            ToggleRow {
                visible: root.effects.running === true
                text: qsTr("Effects enabled")
                subtext: qsTr("Turn off to hear the sound without any processing")
                checked: root.effects.bypass === false
                onToggled: soundBridge.run({ id: checked ? "ee-bypass-off" : "ee-bypass-on" })
            }

            // Sem presets ainda: so o app cria (equalizador, compressor, RNNoise)
            RowButton {
                last: (root.effects.output_presets ?? []).length === 0 && (root.effects.input_presets ?? []).length === 0
                visible: root.effects.available === true
                icon: "equalizer"
                text: (root.effects.output_presets ?? []).length === 0 && (root.effects.input_presets ?? []).length === 0 ? qsTr("No presets yet — create them in EasyEffects") : qsTr("Edit presets in EasyEffects")
                subtext: qsTr("Save a preset there and it shows up here to pick from")
                trailingIcon: "open_in_new"
                onClicked: DesktopEntries.byId("com.github.wwmm.easyeffects")?.execute()
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
        }
    }
}
