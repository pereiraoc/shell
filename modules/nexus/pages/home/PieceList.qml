pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import "setup.js" as L

// Lista das pecas do setup, ao lado do desenho na edicao do layout: icone,
// nome e estado. Mouse na linha acende a peca no desenho (`hovered(key, on)`);
// mouse na peca acende a linha (`hoverKey`); clique escolhe (`picked(key)`,
// `selectedKey`). Os nomes moram aqui, e nao em cima das pecas: menos texto
// no desenho.
ColumnLayout {
    id: root

    // [{ key, label, kind, online, device }] do SetupDiagram.pieces
    required property var pieces
    property string hoverKey
    property string selectedKey

    signal hovered(key: string, on: bool)
    signal picked(key: string)

    spacing: 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.padding.small
        text: Tr.tr("Pieces")
        color: Colours.palette.m3outline
        font: Tokens.font.label.medium
        elide: Text.ElideRight
    }

    Repeater {
        model: root.pieces.length

        StyledRect {
            id: row

            required property int index
            readonly property var piece: root.pieces[row.index] ?? ({})
            readonly property bool on: root.hoverKey === row.piece.key || area.containsMouse
            readonly property bool chosen: root.selectedKey === row.piece.key

            Layout.fillWidth: true
            implicitHeight: line.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.small
            color: row.chosen ? Qt.alpha(Colours.palette.m3tertiary, 0.18) : row.on ? Qt.alpha(Colours.palette.m3tertiary, 0.1) : "transparent"

            RowLayout {
                id: line

                anchors.left: row.left
                anchors.right: row.right
                anchors.verticalCenter: row.verticalCenter
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: L.kindIcon(row.piece.kind)
                    color: row.on || row.chosen ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: row.piece.label || Tr.tr("Unnamed")
                    color: row.piece.online === false ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: row.piece.online === false && row.piece.device !== false
                    text: Tr.tr("off")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }

            MouseArea {
                id: area

                anchors.fill: row
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered(row.piece.key, true)
                onExited: root.hovered(row.piece.key, false)
                onClicked: root.picked(row.piece.key)
            }
        }
    }
}
