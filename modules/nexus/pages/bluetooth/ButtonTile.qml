pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Um botao do mouse na grade (mouses sem silhueta): nome + o que faz,
// cheio quando e o escolhido; `remapped` pinta o detalhe.
StyledRect {
    id: tile

    property string title
    property string detail
    property bool remapped
    property bool selected

    signal picked

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: tileCol.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.medium
    color: tile.selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

    StateLayer {
        radius: tile.radius
        color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        onClicked: tile.picked()
    }

    ColumnLayout {
        id: tileCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.small
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.title
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            font: Tokens.font.label.large
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: tile.detail
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : tile.remapped ? Colours.palette.m3primary : Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }
}
