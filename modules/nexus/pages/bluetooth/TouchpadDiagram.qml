import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Silhueta do touchpad do notebook (GU603: vidro sem botoes, ~130 x 80 mm)
// no mesmo traco dos outros aparelhos: so o contorno, cantos pouco
// arredondados, o icone no meio. Nao tem areas clicaveis -- e so para a aba
// Touchpad ter a mesma cara das abas dos mouses e dos teclados.
Item {
    id: root

    readonly property real ratio: 80 / 130
    readonly property real w: Math.min(root.width, 300)

    implicitHeight: root.w * root.ratio

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.w
        height: root.implicitHeight
        radius: height * 0.08
        color: "transparent"
        border.width: 1
        border.color: Colours.palette.m3outline

        MaterialIcon {
            anchors.centerIn: parent
            text: "touchpad_mouse"
            color: Colours.palette.m3outlineVariant
            fontStyle: Tokens.font.icon.large
        }
    }
}
