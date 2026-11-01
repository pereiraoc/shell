pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import "setup.js" as L

// Lista das pecas do setup, embaixo do desenho na edicao do layout (ao lado
// ela roubava a largura e o desenho ficava pequeno demais): grupos fixos em
// duas colunas (setup.js GROUPS: notebook; teclado e mouse; telas; fones; buds;
// armazenamento; roteadores), cada um com as suas pecas indentadas. Cada
// linha de peca = icone, nome e estado. Mouse na linha acende a peca no
// desenho (`hovered(key, on)`); mouse na peca acende a linha (`hoverKey`);
// clique escolhe (`picked(key)`, `selectedKey`). Os nomes moram aqui, e nao em
// cima das pecas: menos texto no desenho.
ColumnLayout {
    id: root

    // [{ key, label, kind, online, device, x, y, w, h }] do SetupDiagram.pieces
    required property var pieces
    property string hoverKey
    property string selectedKey

    readonly property var rows: L.groupPieces(root.pieces)

    readonly property int columns: root.width >= 560 ? 2 : 1
    readonly property var cols: L.splitColumns(root.rows, root.columns)

    signal hovered(key: string, on: bool)
    signal picked(key: string)

    function groupLabel(id: string): string {
        switch (id) {
        case "laptop": return Tr.tr("Laptop");
        case "keyboard-mouse": return Tr.tr("Keyboard and mouse");
        case "monitors": return Tr.tr("Monitors");
        case "headphones": return Tr.tr("Headphones");
        case "buds": return Tr.tr("Buds");
        case "controllers": return Tr.tr("Controllers");
        case "storage": return Tr.tr("Storage");
        case "routers": return Tr.tr("Routers");
        default: return Tr.tr("Other");
        }
    }

    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        text: Tr.tr("Pieces")
        color: Colours.palette.m3outline
        font: Tokens.font.label.medium
        elide: Text.ElideRight
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Repeater {
            model: root.cols.length

            ColumnLayout {
                id: col

                required property int index
                readonly property var items: root.cols[col.index] ?? []

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Repeater {
                    model: col.items.length

                    StyledRect {
                        id: row

                        required property int index
                        readonly property var piece: col.items[row.index] ?? ({})
                        readonly property bool header: !!row.piece.header
                        readonly property bool on: !row.header && (root.hoverKey === row.piece.key || area.containsMouse)
                        readonly property bool chosen: !row.header && root.selectedKey === row.piece.key

                        Layout.fillWidth: true
                        Layout.topMargin: row.header && row.index > 0 ? Tokens.spacing.small : 0
                        implicitHeight: (row.header ? head.implicitHeight : line.implicitHeight) + Tokens.padding.small * 2
                        radius: Tokens.rounding.small
                        color: row.chosen ? Qt.alpha(Colours.palette.m3tertiary, 0.18) : row.on ? Qt.alpha(Colours.palette.m3tertiary, 0.1) : "transparent"

                        // Cabecalho do grupo
                        StyledText {
                            id: head

                            visible: row.header
                            anchors.left: row.left
                            anchors.verticalCenter: row.verticalCenter
                            anchors.leftMargin: Tokens.padding.small
                            text: root.groupLabel(row.piece.group ?? "")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                        }

                        RowLayout {
                            id: line

                            visible: !row.header
                            anchors.left: row.left
                            anchors.right: row.right
                            anchors.verticalCenter: row.verticalCenter
                            anchors.leftMargin: Tokens.padding.small + (row.piece.depth ?? 0) * Tokens.padding.large
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
                            enabled: !row.header
                            hoverEnabled: !row.header
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hovered(row.piece.key, true)
                            onExited: root.hovered(row.piece.key, false)
                            onClicked: root.picked(row.piece.key)
                        }
                    }
                }
            }
        }
    }
}
