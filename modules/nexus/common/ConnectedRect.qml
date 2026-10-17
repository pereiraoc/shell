import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    property bool first
    property bool last

    // Cantos grandes nas pontas do grupo: a primeira/ultima linha ganha altura
    // extra (proporcional ao raio) para o texto, centrado, nao cair dentro da
    // curva do canto. Vale para todas as linhas que usam este fundo.
    readonly property real capPad: Tokens.rounding.extraLarge * 0.5

    color: Colours.tPalette.m3surfaceContainer
    topLeftRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    topRightRadius: first ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomLeftRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    bottomRightRadius: last ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall
    Layout.preferredHeight: implicitHeight + (first ? capPad : 0) + (last ? capPad : 0)
}
