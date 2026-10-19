pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Uma cor da paleta da RgbLightingView: bolinha com a cor, anel quando e a
// escolhida, e um icone pequeno por cima (`badge`) quando precisa.
Item {
    id: sw

    property string hex
    property bool selected
    property bool big
    property string badge

    signal picked

    implicitWidth: Tokens.font.icon.medium.pointSize * (sw.big ? 2.2 : 1.8)
    implicitHeight: implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: sw.selected ? 2 : 0
        border.color: Colours.palette.m3primary
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: width / 2
        color: `#${sw.hex}`
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3onSurface, 0.2)

        MaterialIcon {
            anchors.centerIn: parent
            visible: sw.badge !== ""
            text: sw.badge
            color: Qt.hsva(0, 0, 0, 0.6)
            fontStyle: Tokens.font.icon.small
        }
    }

    StateLayer {
        radius: width / 2
        onClicked: sw.picked()
    }
}
