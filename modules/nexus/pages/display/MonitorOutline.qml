pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Uma tela no arranjo (Display > General): so o retangulo da tela, no tamanho
// logico do Hyprland -- aqui importa a resolucao, nao o aparelho (as silhuetas
// reais ficam no Home). O notebook ganha a moldura de baixo um pouco mais
// grossa, so para se distinguir; rotulo no meio.
Item {
    id: root

    required property var mon
    property string label
    property string sublabel
    property bool selected
    property bool dim
    property bool dragging

    readonly property bool laptop: !!root.mon.internal
    readonly property color stroke: root.selected ? Colours.palette.m3tertiary : Colours.palette.m3outline
    readonly property real bezel: Math.max(2, root.height * 0.035)

    signal clicked

    implicitHeight: 100
    opacity: root.dim ? 0.4 : 1

    Rectangle {
        anchors.fill: parent
        radius: Math.max(2, root.height * 0.03)
        color: root.selected ? Qt.alpha(Colours.palette.m3tertiary, 0.1) : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.6)
        border.width: root.selected ? 2 : 1
        border.color: root.stroke

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.bezel
            anchors.bottomMargin: root.laptop ? root.bezel * 2.2 : root.bezel
            radius: 1
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha(root.stroke, 0.5)
        }

        Column {
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                color: root.selected ? Colours.palette.m3tertiary : Colours.palette.m3onSurface
                font: Tokens.font.label.medium
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.width - root.bezel * 4)
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.sublabel !== "" && root.height > 56
                text: root.sublabel
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.width - root.bezel * 4)
            }
        }
    }
}
