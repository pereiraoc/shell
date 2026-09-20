pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Linha da arvore, com espaco de verdade para o valor a direita.
//
// Nao da pra usar o RowButton para isto: o label dele tem Layout.fillWidth e
// ocupa tudo ate o icone final, entao um texto ancorado por cima ficaria
// sobreposto ao titulo em vez de ao lado dele. Aqui o valor e' um item do
// RowLayout, entao o label elide antes de encostar nele.
ConnectedRect {
    id: root

    property string icon
    property alias text: label.text
    property alias subtext: subLabel.text
    property alias value: valueLabel.text
    property string trailingIcon
    property color iconColour: Colours.palette.m3onSurfaceVariant

    signal clicked

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    StateLayer {
        onClicked: root.clicked()
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: root.icon
            color: root.iconColour
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        Column {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                anchors.left: parent.left
                anchors.right: parent.right
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                id: subLabel

                anchors.left: parent.left
                anchors.right: parent.right
                visible: text
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        StyledText {
            id: valueLabel

            visible: text
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            horizontalAlignment: Text.AlignRight
        }

        Loader {
            asynchronous: true
            active: root.trailingIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: root.trailingIcon
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
    }
}
