pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Um monitor no traco dos outros aparelhos: o notebook e a tampa aberta
// (moldura mais grossa embaixo e a base por tras), um monitor externo e a
// tela com o pe. O retangulo da tela e `width` x `height` (quem usa ja
// escala pela area logica); o pe/base vai por fora, embaixo. Rotulo no meio.
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
    // Altura extra do pe (monitor) ou da base (notebook), fora da tela
    readonly property real foot: Math.max(6, root.height * (root.laptop ? 0.08 : 0.16))

    signal clicked

    implicitHeight: 100
    opacity: root.dim ? 0.4 : 1

    // Base do notebook (atras, mais larga) ou pe do monitor
    Rectangle {
        visible: root.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - root.foot * 0.3
        width: root.width * 1.06
        height: root.foot
        radius: root.foot * 0.3
        color: Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.4)
        border.width: 1
        border.color: root.stroke
    }

    Rectangle {
        visible: !root.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height
        width: Math.max(4, root.width * 0.06)
        height: root.foot * 0.6
        color: root.stroke
    }

    Rectangle {
        visible: !root.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height + root.foot * 0.6
        width: root.width * 0.35
        height: Math.max(2, root.foot * 0.4)
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: root.stroke
    }

    // Tela (moldura + painel)
    Rectangle {
        id: frame

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
