pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Linha com seletor segmentado (2 a 5 opcoes curtas): rotulo a esquerda e a
// pilula de chips a direita, na mesma linha, quando os chips cabem em metade
// da largura; senao rotulo + valor atual em cima e a pilula na largura toda
// embaixo. Para listas longas use SelectRow.
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
    // Compacto: chips que cabem em metade da linha ficam a direita do rotulo,
    // na mesma linha (como um valor); senao a pilula toma a largura embaixo
    readonly property real chipsNaturalWidth: chips.implicitWidth + Tokens.padding.small * 2
    readonly property bool compact: root.width > 0 && root.chipsNaturalWidth <= root.width * 0.5

    signal picked(value: string)

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    GridLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        columns: 2
        columnSpacing: Tokens.spacing.medium
        rowSpacing: Tokens.spacing.small
        opacity: root.disabled ? 0.5 : 1

        ColumnLayout {
            Layout.row: 0
            Layout.column: 0
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                font: Tokens.font.body.small
                elide: Text.ElideRight
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
        }

        StyledText {
            Layout.row: 0
            Layout.column: 1
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            // Valor atual (modo largo) ou um valor fora dos presets (ex.:
            // repeticao 25/600 do hyprland.conf) em qualquer modo
            visible: !root.compact || (!root.currentOption && root.current !== "")
            text: root.busy ? qsTr("Applying…") : (root.currentOption?.label ?? (root.current !== "" ? qsTr("Custom") : ""))
            color: Colours.palette.m3primary
            font: Tokens.font.label.medium
        }

        StyledRect {
            id: pill

            Layout.row: root.compact ? 0 : 1
            Layout.column: root.compact ? 1 : 0
            Layout.columnSpan: root.compact ? 1 : 2
            Layout.fillWidth: !root.compact
            Layout.preferredWidth: root.compact ? root.chipsNaturalWidth : -1
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            implicitHeight: chips.implicitHeight + Tokens.padding.small * 2
            color: Colours.tPalette.m3surfaceContainerHigh
            radius: Tokens.rounding.full

            CircularIndicator {
                anchors.centerIn: parent
                implicitSize: chips.implicitHeight
                visible: root.busy
                running: visible
            }

            RowLayout {
                id: chips

                visible: !root.busy
                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                spacing: Tokens.spacing.small

                Repeater {
                    id: repeater

                    // Quantidade, nao a lista: opcoes recalculadas a cada
                    // refresh nao recriam os chips.
                    model: root.options.length

                    // Fundo proprio por chip (nao um indicador deslizante): o
                    // indicador dependia de repeater.itemAt() numa binding, que
                    // nao reavalia quando os itens nascem -- ficava invisivel e o
                    // texto do selecionado (onPrimary) sumia no fundo claro.
                    StyledRect {
                        id: chip

                        required property int index
                        readonly property var modelData: root.options[index] ?? ({})

                        readonly property bool isCurrent: root.current === modelData.value
                        readonly property color fg: isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

                        Layout.fillWidth: !root.compact
                        implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
                        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        // StyledRect ja anima a cor.
                        color: isCurrent ? Colours.palette.m3primary : "transparent"

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
