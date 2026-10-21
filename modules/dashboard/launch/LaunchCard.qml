import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: card

    property string title
    property string icon
    default property alias content: cardCol.data

    Layout.alignment: Qt.AlignTop
    implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: cardCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.leftMargin: Tokens.padding.medium
            Layout.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: card.icon
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: card.title
                color: Colours.palette.m3onSurface
                font: Tokens.font.title.small
            }
        }
    }
}
