pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Audio")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Output
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

        // Input
        SliderRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
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
        ToolSection {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            tool: "mic-gain"
            title: qsTr("MICROPHONE HARDWARE GAIN")
            icon: "mic"
            hint: qsTr("Internal mic, set by caelestia-mic-gain at login. The Input slider above is software volume on top of this.")
        }

        // Per-app volumes
        NavRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true

            icon: "tune"
            text: qsTr("App volumes")
            subtext: Audio.streams.length === 0 ? qsTr("No apps playing audio") : Audio.streams.length === 1 ? qsTr("1 app playing audio") : qsTr("%1 apps playing audio").arg(Audio.streams.length)
            onClicked: root.nState.openSubPage(1)
        }
    }
}
