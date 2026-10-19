pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Tampa do ROG Zephyrus G16 (GU603) vista de frente, no traco do manual
// (E25289, "vista superior": tela, camera no meio da moldura de cima, os dois
// microfones do array nas pontas dela, a dobradica com o ROG ZEPHYRUS e as
// fendas). 763 x 522 unidades do desenho. Clicavel: camera, mic (os dois sao
// um array) e screen; `cameraOn` e `micMuted` pintam o estado.
Item {
    id: root

    property string selected
    property bool cameraOn
    property bool micMuted

    readonly property real k: root.width / 763
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property string family: Tokens.font.label.small.family

    signal picked(id: string)

    function spotColor(id: string, on: bool): color {
        if (root.selected === id)
            return Colours.palette.m3tertiary;
        return on ? Colours.palette.m3primary : root.ink;
    }

    implicitHeight: 522 * root.k

    // Tampa
    Rectangle {
        x: 20 * root.k
        y: 14 * root.k
        width: 725 * root.k
        height: 482 * root.k
        radius: 12 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.ink
    }

    // Tela (moldura fina dos lados, mais alta em cima para a camera)
    Rectangle {
        id: screen

        x: 34 * root.k
        y: 42 * root.k
        width: 697 * root.k
        height: 436 * root.k
        radius: 3 * root.k
        color: root.selected === "screen" ? Qt.alpha(Colours.palette.m3tertiary, 0.08) : "transparent"
        border.width: 1
        border.color: root.selected === "screen" ? Colours.palette.m3tertiary : root.faint

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked("screen")
        }
    }

    // Microfones do array (esquerda e direita da camera)
    Repeater {
        model: [300, 460]

        Rectangle {
            required property int modelData

            x: (modelData - 4) * root.k
            y: 24 * root.k
            width: 8 * root.k
            height: 8 * root.k
            radius: width / 2
            color: root.micMuted ? "transparent" : root.spotColor("mic", true)
            border.width: 1
            border.color: root.spotColor("mic", !root.micMuted)

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked("mic")
            }
        }
    }

    // Camera (com o LED ao lado, aceso quando em uso)
    Rectangle {
        x: 372 * root.k
        y: 20 * root.k
        width: 16 * root.k
        height: 16 * root.k
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, 1.5 * root.k)
        border.color: root.spotColor("camera", root.cameraOn)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.4
            height: width
            radius: width / 2
            color: root.spotColor("camera", root.cameraOn)
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked("camera")
        }
    }

    Rectangle {
        visible: root.cameraOn
        x: 395 * root.k
        y: 26 * root.k
        width: 4 * root.k
        height: 4 * root.k
        radius: width / 2
        color: Colours.palette.m3error
    }

    // Dobradica: ROG ZEPHYRUS e as fendas de ventilacao
    Rectangle {
        x: 55 * root.k
        y: 496 * root.k
        width: 655 * root.k
        height: 24 * root.k
        radius: 3 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 481 * root.k
        text: "ROG ZEPHYRUS"
        color: root.faint
        font.family: root.family
        font.pixelSize: Math.max(6, 9 * root.k)
        font.letterSpacing: 2 * root.k
        renderType: Text.NativeRendering
    }

    Repeater {
        model: 36

        Rectangle {
            required property int index

            x: (72 + index * 17.5 + (index >= 18 ? 50 : 0)) * root.k
            y: 500 * root.k
            width: Math.max(1, 1.2 * root.k)
            height: 16 * root.k
            rotation: 25
            color: root.faint
        }
    }
}
