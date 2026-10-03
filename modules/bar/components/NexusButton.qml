import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

// Atalho para o Nexus logo acima do botao de desligar. Alterna: abre se nao
// houver Nexus aberto, fecha se houver -- clicar de novo nao empilha janelas.
Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Mesmo truque do Power.qml para a area de clique passar do pai
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: WindowFactory.toggle()
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "tune"
        color: WindowFactory.windows.length > 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
