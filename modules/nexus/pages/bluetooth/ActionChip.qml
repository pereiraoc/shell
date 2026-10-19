pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Chip de acao de um botao do mouse, com icone na frente (reconhecer pelo
// icone e mais rapido que ler); cheio quando e a acao em uso.
StyledRect {
    id: chip

    property string text
    property string icon
    property bool selected

    signal picked

    implicitWidth: chipIcon.implicitWidth + chipRow.spacing + chipLabel.implicitWidth + Tokens.padding.medium * 2
    implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.full
    color: chip.selected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

    StateLayer {
        radius: chip.radius
        color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        disabled: chip.selected
        onClicked: chip.picked()
    }

    Row {
        id: chipRow

        anchors.verticalCenter: parent.verticalCenter
        x: Tokens.padding.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: chipIcon

            anchors.verticalCenter: parent.verticalCenter
            visible: chip.icon !== ""
            text: chip.icon
            color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: chip.selected ? 1 : 0
        }

        StyledText {
            id: chipLabel

            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, chip.width - Tokens.padding.medium * 2 - chipRow.spacing - chipIcon.implicitWidth)
            text: chip.text
            elide: Text.ElideRight
            color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
        }
    }
}
