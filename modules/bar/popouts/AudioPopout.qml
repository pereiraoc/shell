pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

Item {
    id: root

    required property PopoutState popouts

    // Mixer por app, recolhido por padrao: o popout existe para ser rapido, e
    // a lista so interessa quando ha algo tocando que voce queira ajustar.
    property bool mixerOpen: false

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

        // Volume por aplicativo. A lista vem de Audio.streams, que sao os
        // streams de REPRODUCAO -- um app aberto mas sem stream nao aparece
        // porque nao ha nada em que aplicar volume.
        Loader {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            active: root.mixerOpen
            visible: active

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    visible: Audio.streams.length === 0
                    text: qsTr("Nothing playing")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                Repeater {
                    model: Audio.streams

                    delegate: ColumnLayout {
                        id: stream

                        required property PwNode modelData

                        readonly property bool streamMuted: Audio.getStreamMuted(stream.modelData)

                        Layout.fillWidth: true
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            // Clicar no icone silencia esse app so.
                            MaterialIcon {
                                // getAppCategoryIcon, nao getAppIcon: este devolve
                                // NOME DE GLIFO (usavel em MaterialIcon), enquanto
                                // o outro devolve caminho de arquivo, para Image.
                                text: stream.streamMuted ? "volume_off" : Icons.getAppCategoryIcon(Audio.getStreamName(stream.modelData), "music_note")
                                color: stream.streamMuted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.small

                                StateLayer {
                                    radius: Tokens.rounding.full
                                    onClicked: Audio.setStreamMuted(stream.modelData, !stream.streamMuted)
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: Audio.getStreamName(stream.modelData)
                                color: stream.streamMuted ? Colours.palette.m3outline : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: `${Math.round(Audio.getStreamVolume(stream.modelData) * 100)}%`
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                            }
                        }

                        CustomMouseArea {
                            Layout.fillWidth: true
                            implicitHeight: Tokens.padding.medium * 2

                            onWheel: event => {
                                const v = Audio.getStreamVolume(stream.modelData);
                                Audio.setStreamVolume(stream.modelData, v + (event.angleDelta.y > 0 ? 0.05 : -0.05));
                            }

                            StyledSlider {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                implicitHeight: parent.implicitHeight

                                value: Audio.getStreamVolume(stream.modelData)
                                onInteraction: value => Audio.setStreamVolume(stream.modelData, value)
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.medium
            spacing: Tokens.spacing.small

            IconTextButton {
                Layout.fillWidth: true
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                verticalPadding: Tokens.padding.extraSmall
                text: qsTr("Open settings")
                icon: "settings"

                onClicked: root.popouts.detachRequested("audio")
            }

            // 'tune' e o icone que o projeto ja usa para volume por app
            // (AudioPage.qml:92) -- mantido para nao inventar vocabulario.
            IconButton {
                icon: "tune"
                isToggle: true
                isRound: true
                shapeMorph: true
                checked: root.mixerOpen
                inactiveColour: Colours.palette.m3secondaryContainer
                verticalPadding: Tokens.padding.extraSmall

                onClicked: root.mixerOpen = !root.mixerOpen
            }
        }
    }
}
