import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

// Linha no estilo do launcher: silhueta do jogo (art, pintada na cor do tema)
// ou simbolo Material de traco no lugar do icone
Item {
    id: row

    property string glyph
    property string art
    property string label
    property string sublabel
    property bool compact
    property bool favourite

    signal activated

    implicitHeight: compact ? Math.round(Tokens.sizes.launcher.itemHeight * 0.7) : Tokens.sizes.launcher.itemHeight

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: row.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        Item {
            implicitWidth: Math.round((row.compact ? Tokens.font.icon.medium : Tokens.font.icon.large).pointSize * 1.6)
            implicitHeight: implicitWidth

            ColouredIcon {
                anchors.centerIn: parent
                visible: row.art !== ""
                implicitSize: Math.round(parent.implicitWidth * 0.9)
                source: row.art ? `file://${row.art}` : ""
                colour: Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: row.art === ""
                text: row.glyph
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: row.compact ? Tokens.font.icon.medium : Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: implicitWidth
                    text: row.label
                    font: row.compact ? Tokens.font.body.small : Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                // Favorito: estrela cheia na cor primaria, logo depois do nome
                MaterialIcon {
                    visible: row.favourite
                    text: "star"
                    fill: 1
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.small
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !row.compact && row.sublabel !== ""
                text: row.sublabel
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }
    }
}
