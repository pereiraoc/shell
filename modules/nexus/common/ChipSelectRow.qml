pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Linha com seletor segmentado (2 a 5 opcoes curtas): rotulo + estado atual em
// cima, pilula com indicador deslizante embaixo -- mesmo visual do seletor de
// cena de audio. Para listas longas use SelectRow.
//
//     ChipSelectRow {
//         label: qsTr("Charge limit")
//         options: [{ value: "60", label: "60%" }, { value: "80", label: "80%" }]
//         current: "80"
//         onPicked: v => bridge.run({ id: `charge-limit-${v}` })
//     }
ConnectedRect {
    id: root

    property string label
    property string subtext
    // [{ value: string, label: string, icon?: string }]
    property var options: []
    property string current
    // Enquanto a mudanca corre: spinner no lugar dos botoes.
    property bool busy
    property bool disabled

    readonly property var currentOption: root.options.find(o => o.value === root.current) ?? null

    signal picked(value: string)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small
        opacity: root.disabled ? 0.5 : 1

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: root.label
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                text: root.busy ? qsTr("Applying…") : (root.currentOption?.label ?? "")
                color: Colours.palette.m3primary
                font: Tokens.font.label.medium
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            visible: text !== ""
            text: root.subtext
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledRect {
            id: pill

            Layout.fillWidth: true
            implicitHeight: chips.implicitHeight + Tokens.padding.small * 2
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.full

            CircularIndicator {
                anchors.centerIn: parent
                implicitSize: chips.implicitHeight
                visible: root.busy
                running: visible
            }

            StyledRect {
                id: indicator

                readonly property Item sel: {
                    const i = root.options.findIndex(o => o.value === root.current);
                    return i >= 0 ? repeater.itemAt(i) : null;
                }

                visible: !root.busy && sel !== null
                x: chips.x + (sel?.x ?? 0)
                y: chips.y + (sel?.y ?? 0)
                width: sel?.width ?? 0
                height: sel?.height ?? 0
                color: Colours.palette.m3primary
                radius: Tokens.rounding.full

                Behavior on x {
                    Anim {}
                }

                Behavior on width {
                    Anim {}
                }
            }

            RowLayout {
                id: chips

                visible: !root.busy
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                Repeater {
                    id: repeater

                    model: root.options

                    Item {
                        id: chip

                        required property var modelData

                        readonly property bool isCurrent: root.current === modelData.value
                        readonly property color fg: isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

                        Layout.fillWidth: true
                        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2

                        StateLayer {
                            radius: Tokens.rounding.full
                            color: chip.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                            disabled: root.disabled || chip.isCurrent
                            onClicked: root.picked(chip.modelData.value)
                        }

                        RowLayout {
                            id: chipRow

                            anchors.centerIn: parent
                            spacing: Tokens.spacing.extraSmall

                            MaterialIcon {
                                visible: !!chip.modelData.icon
                                text: chip.modelData.icon ?? ""
                                color: chip.fg
                                fontStyle: Tokens.font.icon.small
                                fill: chip.isCurrent ? 1 : 0
                            }

                            StyledText {
                                text: chip.modelData.label
                                color: chip.fg
                                font: Tokens.font.label.medium
                            }
                        }
                    }
                }
            }
        }
    }
}
