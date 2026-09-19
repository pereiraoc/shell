pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

Item {
    id: root

    required property PopoutState popouts

    implicitWidth: layout.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.medium

        StyledText {
            text: qsTr("Output device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sinks

            RowLayout {
                id: control

                required property PwNode modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRadioButton {
                    ButtonGroup.group: sinks
                    // outputDevice, nao sink: com a cadeia CUSTOM ativa o sink
                    // default e o filtro, cujo id nao casa com nenhum device --
                    // e nenhuma opcao ficava marcada.
                    checked: Audio.outputDevice?.id === control.modelData.id
                    onClicked: Audio.setAudioSink(control.modelData)
                    text: control.modelData.description
                }

                // HEADPHONE <-> HEADSET com as duas opcoes a vista, logo apos o
                // nome. E o caminho rapido: da pra trocar no meio de um jogo.
                Loader {
                    active: AudioProfile.supportsHeadset(control.modelData?.name ?? "")
                    visible: active

                    sourceComponent: AudioModeToggle {
                        node: control.modelData
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                AudioTags {
                    node: control.modelData
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: qsTr("Input device")
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        Repeater {
            model: Audio.sources

            RowLayout {
                id: srcControl

                required property PwNode modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                StyledRadioButton {
                    Layout.fillWidth: true
                    ButtonGroup.group: sources
                    checked: Audio.sourceDevice?.id === srcControl.modelData.id
                    onClicked: Audio.setAudioSource(srcControl.modelData)
                    text: srcControl.modelData.description
                }

                AudioTags {
                    node: srcControl.modelData
                }
            }
        }

        // Cena de audio. Fora do dispositivo de proposito: vale para a saida
        // toda, nao para um fone especifico. O componente traz nome e descricao.
        AudioSceneSelector {
            Layout.topMargin: Tokens.spacing.medium
            Layout.fillWidth: true
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
            font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
        }

        CustomMouseArea {
            Layout.fillWidth: true
            implicitHeight: Tokens.padding.medium * 3

            onWheel: event => {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            StyledSlider {
                anchors.left: parent.left
                anchors.right: parent.right
                implicitHeight: parent.implicitHeight

                value: Audio.volume
                onInteraction: value => Audio.setVolume(value)
            }
        }

        IconTextButton {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            text: qsTr("Open settings")
            icon: "settings"

            onClicked: root.popouts.detachRequested("audio")
        }
    }
}
