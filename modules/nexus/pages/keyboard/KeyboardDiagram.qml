pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Diagrama de um teclado (laptopLayout.js / azothLayout.js) no traco do manual:
// teclas so de contorno, cantos pouco arredondados, respiros reais e o que
// esta impresso em cada uma (simbolo com Shift no canto, glifo sob o rotulo,
// logo do Windows, traco da barra de espaco). As teclas especiais (com `id`)
// levam o icone da funcao no centro e o nome pequeno no canto (`corner`: "tr"
// ou "br") e sao clicaveis; `kind` "oled" e "knob" desenham o visor e o botao
// do Azoth. Mesmo papel do MouseDiagram do Naga, mas sem SVG.
Item {
    id: root

    property string selected
    // keys()/size() do layout: [{ id, label, icon, kind, top, glyph, micon, bar, corner, x, y, w, h }], { w, h }
    required property var keys
    required property var size
    readonly property real unit: root.width / root.size.w
    // metade do respiro entre teclas (0.16u no manual) e raio dos cantos (~0.1u)
    readonly property real gap: root.unit * 0.08
    readonly property real corner: root.unit * 0.1
    readonly property string family: Tokens.font.label.small.family

    signal picked(id: string)

    implicitHeight: root.size.h * root.unit

    Repeater {
        model: root.keys

        Rectangle {
            id: key

            required property var modelData

            readonly property bool special: key.modelData.id !== ""
            readonly property string kind: key.modelData.kind ?? ""
            readonly property bool active: key.special && key.modelData.id === root.selected
            readonly property color ink: key.active ? Colours.palette.m3onTertiary : key.special ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            readonly property real inset: root.gap * 1.5

            x: key.modelData.x * root.unit + root.gap
            y: key.modelData.y * root.unit + root.gap
            width: key.modelData.w * root.unit - root.gap * 2
            height: key.modelData.h * root.unit - root.gap * 2
            radius: key.kind === "knob" ? height / 2 : root.corner
            // OLED: um visor preenchido (fica escuro, com o nome); knob: redondo
            color: key.active ? Colours.palette.m3tertiary : key.kind === "oled" ? Colours.palette.m3surfaceContainerHighest : "transparent"
            border.width: key.active ? 0 : key.special ? 2 : 1
            border.color: key.special ? Colours.palette.m3tertiary : Colours.palette.m3outline

            // Tecla comum: rotulo no centro (ou em cima, quando ha glifo embaixo)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: key.modelData.glyph ? undefined : parent.verticalCenter
                anchors.top: key.modelData.glyph ? parent.top : undefined
                anchors.topMargin: key.inset
                visible: !key.special && key.modelData.label !== "" && key.modelData.top === ""
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * (key.modelData.label.length > 2 ? 0.17 : 0.3))
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
            }

            // Simbolo com Shift no canto superior esquerdo + rotulo no inferior direito
            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: key.inset
                visible: key.modelData.top !== ""
                text: key.modelData.top
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.22)
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: key.inset
                visible: key.modelData.top !== ""
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.28)
                renderType: Text.NativeRendering
            }

            // Glifo (⇤⇥, ↵, ⇧, ☰, ⟵): embaixo do rotulo, ou no centro se nao ha rotulo
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: key.modelData.label ? parent.bottom : undefined
                anchors.bottomMargin: key.inset
                anchors.verticalCenter: key.modelData.label ? undefined : parent.verticalCenter
                visible: key.modelData.glyph !== ""
                text: key.modelData.glyph
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * (key.modelData.label ? 0.26 : 0.36))
                renderType: Text.NativeRendering
            }

            // Logo do Windows
            MaterialIcon {
                anchors.centerIn: parent
                visible: key.modelData.micon !== ""
                text: key.modelData.micon
                color: key.ink
                fontStyle: Tokens.font.icon.size(Math.max(6, root.unit * 0.3)).build()
            }

            // Traco da barra de espaco
            Rectangle {
                anchors.centerIn: parent
                visible: key.modelData.bar
                width: root.unit * 0.8
                height: Math.max(1, root.unit * 0.03)
                color: key.ink
            }

            // Tecla especial: icone da funcao no centro, nome pequeno no canto
            MaterialIcon {
                anchors.centerIn: parent
                visible: key.special && key.kind !== "oled"
                text: key.modelData.icon
                color: key.ink
                fontStyle: Tokens.font.icon.size(Math.max(6, root.unit * 0.3)).build()
            }

            Text {
                anchors.right: key.kind === "oled" ? undefined : parent.right
                anchors.horizontalCenter: key.kind === "oled" ? parent.horizontalCenter : undefined
                anchors.verticalCenter: key.kind === "oled" ? parent.verticalCenter : undefined
                anchors.top: key.modelData.corner === "tr" && key.kind !== "oled" ? parent.top : undefined
                anchors.bottom: key.modelData.corner === "br" && key.kind !== "oled" ? parent.bottom : undefined
                anchors.margins: root.gap
                visible: key.special
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.15)
                renderType: Text.NativeRendering
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
