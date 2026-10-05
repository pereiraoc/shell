import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Subsecao dentro de uma SectionHeader: um aparelho especifico (ex.: Keyboard >
// Laptop keyboard / ASUS ROG Azoth). Icone + nome, e o estado do aparelho a
// direita (bateria, "Asleep", "Not connected").
RowLayout {
    id: root

    property string icon
    property string text
    property string status
    property bool warn

    Layout.fillWidth: true
    Layout.topMargin: Tokens.spacing.large - ((parent as ColumnLayout)?.spacing ?? 0)
    Layout.bottomMargin: Tokens.spacing.extraSmall
    Layout.leftMargin: Tokens.padding.small
    Layout.rightMargin: Tokens.padding.small
    spacing: Tokens.spacing.small

    MaterialIcon {
        visible: root.icon !== ""
        text: root.icon
        color: Colours.palette.m3primary
        fontStyle: Tokens.font.icon.small
        fill: 1
    }

    StyledText {
        Layout.fillWidth: true
        text: root.text
        font: Tokens.font.body.medium
        elide: Text.ElideRight
    }

    StyledText {
        visible: root.status !== ""
        text: root.status
        color: root.warn ? Colours.palette.m3tertiary : Colours.palette.m3outline
        font: Tokens.font.label.medium
    }
}
