import QtQuick
import Caelestia.Config
import qs.services

// "+" / "tap" entre keycaps. Quem usa da a altura (ShortcutsPage.capHeight,
// a de um KeyCap) para centrar mesmo dentro de um Flow, que nao aceita
// anchors. Text puro: sao centenas por pagina.
Text {
    id: root

    verticalAlignment: Text.AlignVCenter
    text: "+"
    color: Colours.palette.m3outline
    font: Tokens.font.label.small
    renderType: Text.NativeRendering
}
