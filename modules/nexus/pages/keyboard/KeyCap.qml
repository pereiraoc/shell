import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Tecla desenhada como keycap (Keyboard > Shortcuts). Modificadores tem cor
// propria pelos papeis do tema: Super = primary, Ctrl = secondary, Shift =
// tertiary, Alt = error, Fn = surface alta; teclas comuns = surface. A base,
// mais escura, e o proprio retangulo (relevo de 3 px); a tampa e um filho.
StyledRect {
    id: root

    property string text
    property string kind: "key"

    readonly property color capColour: {
        switch (root.kind) {
        case "super":
            return Colours.palette.m3primaryContainer;
        case "ctrl":
            return Colours.palette.m3secondaryContainer;
        case "shift":
            return Colours.palette.m3tertiaryContainer;
        case "alt":
            return Colours.palette.m3errorContainer;
        case "fn":
            return Colours.palette.m3surfaceContainerHighest;
        default:
            return Colours.tPalette.m3surfaceContainerHigh;
        }
    }
    readonly property color textColour: {
        switch (root.kind) {
        case "super":
            return Colours.palette.m3onPrimaryContainer;
        case "ctrl":
            return Colours.palette.m3onSecondaryContainer;
        case "shift":
            return Colours.palette.m3onTertiaryContainer;
        case "alt":
            return Colours.palette.m3onErrorContainer;
        case "fn":
            return Colours.palette.m3tertiary;
        default:
            return Colours.palette.m3onSurface;
        }
    }

    implicitWidth: Math.max(label.implicitWidth + Tokens.padding.medium * 2, implicitHeight)
    implicitHeight: label.implicitHeight + Tokens.padding.small * 2 + 3
    radius: Tokens.rounding.extraSmall
    color: Qt.darker(root.capColour, 1.35)

    StyledRect {
        anchors.fill: parent
        anchors.bottomMargin: 3
        radius: Tokens.rounding.extraSmall
        color: root.capColour
        border.width: 1
        border.color: Qt.darker(root.capColour, 1.2)

        StyledText {
            id: label

            anchors.centerIn: parent
            text: root.text
            font: Tokens.font.label.medium
            color: root.textColour
        }
    }
}
