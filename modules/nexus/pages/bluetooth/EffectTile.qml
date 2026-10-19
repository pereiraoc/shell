pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Um efeito de iluminacao na grade da RgbLightingView: icone + nome, cheio
// quando e o escolhido.
StyledRect {
    id: tile

    property string label
    property string icon
    property bool selected

    signal picked

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: tileCol.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.large
    color: tile.selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

    StateLayer {
        radius: tile.radius
        color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
        disabled: tile.selected
        onClicked: tile.picked()
    }

    ColumnLayout {
        id: tileCol

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: tile.icon
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: tile.selected ? 1 : 0
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: tile.label
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            font: Tokens.font.label.medium
        }
    }
}
