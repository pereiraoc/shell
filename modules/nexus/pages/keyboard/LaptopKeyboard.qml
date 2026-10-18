pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "laptopLayout.js" as Lk

// Diagrama esquematico do teclado do notebook (GU603, laptopLayout.js): as 16
// teclas especiais (M1-M4 e a fila Fn) em destaque e clicaveis, com o icone da
// funcao impressa; o resto so da contexto, apagado. Mesmo papel do
// MouseDiagram do Naga, mas teclas sao retangulos -- dispensa SVG.
Item {
    id: root

    property string selected
    readonly property var keys: Lk.keys()
    readonly property var size: Lk.size()
    readonly property real unit: root.width / root.size.w
    readonly property real gap: root.unit * 0.05

    signal picked(id: string)

    implicitHeight: root.size.h * root.unit

    Repeater {
        model: root.keys

        Rectangle {
            id: key

            required property var modelData

            readonly property bool special: key.modelData.id !== ""
            readonly property bool active: key.special && key.modelData.id === root.selected

            x: key.modelData.x * root.unit + root.gap
            y: key.modelData.y * root.unit + root.gap
            width: key.modelData.w * root.unit - root.gap * 2
            height: key.modelData.h * root.unit - root.gap * 2
            radius: Tokens.rounding.small
            color: key.active ? Colours.palette.m3tertiary : key.special ? Colours.palette.m3surfaceContainerHighest : Colours.palette.m3surfaceContainer
            border.width: key.special && !key.active ? 1 : 0
            border.color: Colours.palette.m3outlineVariant

            // Tecla comum: so o rotulo, apagado
            Text {
                anchors.centerIn: parent
                visible: !key.special
                text: key.modelData.label
                color: Colours.palette.m3outline
                font.family: Tokens.font.label.small.family
                font.pixelSize: Math.max(7, root.unit * 0.3)
                renderType: Text.NativeRendering
            }

            // Tecla especial: rotulo no canto + icone da funcao impressa
            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: root.gap * 1.5
                visible: key.special
                text: key.modelData.label
                color: key.active ? Colours.palette.m3onTertiary : Colours.palette.m3onSurfaceVariant
                font.family: Tokens.font.label.small.family
                font.pixelSize: Math.max(7, root.unit * 0.26)
                renderType: Text.NativeRendering
            }

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.gap * 1.5
                visible: key.special
                text: key.modelData.icon
                color: key.active ? Colours.palette.m3onTertiary : Colours.palette.m3tertiary
            }

            MouseArea {
                anchors.fill: parent
                enabled: key.special
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(key.modelData.id)
            }
        }
    }
}
