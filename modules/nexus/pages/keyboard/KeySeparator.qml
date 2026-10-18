import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// "+" / "tap" entre keycaps, com a altura de um keycap (KeyCap.qml) para
// ficar centrado mesmo dentro de um Flow, que nao aceita anchors.
StyledText {
    id: root

    height: metrics.height + Tokens.padding.extraSmall * 2 + 2
    verticalAlignment: Text.AlignVCenter
    text: "+"
    color: Colours.palette.m3outline
    font: Tokens.font.label.small

    FontMetrics {
        id: metrics

        font: Tokens.font.label.small
    }
}
