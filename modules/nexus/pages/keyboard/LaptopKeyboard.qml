pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "laptopLayout.js" as Lk

// Diagrama do teclado do notebook (GU603, laptopLayout.js) no traco do manual
// da ASUS: teclas so de contorno, cantos pouco arredondados, respiros reais.
// As 16 especiais (M1-M4 e a fila Fn) tem contorno e icone em destaque e sao
// clicaveis; o resto so da contexto. Mesmo papel do MouseDiagram do Naga, mas
// teclas sao retangulos -- dispensa SVG.
Item {
    id: root

    property string selected
    readonly property var keys: Lk.keys()
    readonly property var size: Lk.size()
    readonly property real unit: root.width / root.size.w
    // metade do respiro entre teclas (0.16u no manual) e raio dos cantos (~0.1u)
    readonly property real gap: root.unit * 0.08
    readonly property real corner: root.unit * 0.1

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
            radius: root.corner
            color: key.active ? Colours.palette.m3tertiary : "transparent"
            border.width: key.active ? 0 : key.special ? 2 : 1
            border.color: key.special ? Colours.palette.m3tertiary : Colours.palette.m3outline

            // Tecla comum: so o rotulo, apagado
            Text {
                anchors.centerIn: parent
                visible: !key.special
                text: key.modelData.label
                color: Colours.palette.m3onSurfaceVariant
                font.family: Tokens.font.label.small.family
                font.pixelSize: Math.max(7, root.unit * (key.modelData.label.length > 3 ? 0.2 : 0.3))
                renderType: Text.NativeRendering
            }

            // Tecla especial (baixa): rotulo a esquerda, icone da funcao impressa a direita
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.gap * 2
                visible: key.special
                text: key.modelData.label
                color: key.active ? Colours.palette.m3onTertiary : Colours.palette.m3tertiary
                font.family: Tokens.font.label.small.family
                font.pixelSize: Math.max(7, root.unit * 0.24)
                renderType: Text.NativeRendering
            }

            MaterialIcon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: root.gap * 2
                visible: key.special
                text: key.modelData.icon
                color: key.active ? Colours.palette.m3onTertiary : Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.small
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
