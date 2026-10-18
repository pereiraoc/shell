import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Tecla desenhada como keycap (Keyboard > Shortcuts): a base, 2 px mais
// escura, e o proprio retangulo (o relevo); a tampa com borda fina e um filho
// que deixa a base aparecer embaixo.
StyledRect {
    id: root

    property string text

    implicitWidth: Math.max(label.implicitWidth + Tokens.padding.small * 2, implicitHeight)
    implicitHeight: label.implicitHeight + Tokens.padding.extraSmall * 2 + 2
    radius: Tokens.rounding.small
    color: Colours.palette.m3outlineVariant

    StyledRect {
        anchors.fill: parent
        anchors.bottomMargin: 2
        radius: Tokens.rounding.small
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        StyledText {
            id: label

            anchors.centerIn: parent
            text: root.text
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurface
        }
    }
}
