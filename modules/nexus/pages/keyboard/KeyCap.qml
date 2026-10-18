import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Tecla desenhada como keycap (Keyboard > Shortcuts). Super = amarelo do tema
// (tertiary), o foco principal; Ctrl/Shift/Alt/Fn em matizes fixos distintos
// (azul, verde, roxo, laranja) que seguem claro/escuro -- os papeis do tema
// nao dao 5 cores distinguiveis (primary == secondary, error == tertiary).
// A base, mais escura, e o proprio retangulo (relevo de 3 px); a tampa e um filho.
StyledRect {
    id: root

    property string text
    property string kind: "key"

    readonly property real hue: root.kind === "ctrl" ? 215 / 360 : root.kind === "shift" ? 140 / 360 : root.kind === "alt" ? 300 / 360 : 25 / 360
    readonly property bool tinted: root.kind === "ctrl" || root.kind === "shift" || root.kind === "alt" || root.kind === "fn"
    readonly property color capColour: root.kind === "super" ? Colours.palette.m3tertiary : root.tinted ? Qt.hsla(root.hue, 0.35, Colours.light ? 0.82 : 0.28, 1) : Colours.tPalette.m3surfaceContainerHigh
    readonly property color textColour: root.kind === "super" ? Colours.palette.m3onTertiary : root.tinted ? Qt.hsla(root.hue, 0.55, Colours.light ? 0.18 : 0.92, 1) : Colours.palette.m3onSurface

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
