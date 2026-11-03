pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Smart Home Devices (pedido de 03/11: botao proprio em Connectivity, depois do
// Bluetooth): o Home Assistant do NAS -- tomadas, luzes, consumo, toggles. O
// conteudo e o ServerHome (que foi Server > Home e Network > Home Devices); a
// ponte do NAS so consulta a cada 30 s com a pagina na frente.
PageBase {
    id: root

    title: Tr.tr("Smart Home Devices")
    description: Tr.tr("Home Assistant on the NAS: plugs, lights, power use")

    NasBridge {
        id: nas

        live: root.visible && root.pageId === "smarthome"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            visible: nas.error !== ""
            first: true
            last: true
            icon: "error"
            iconColour: Colours.palette.m3error
            label: Tr.tr("Could not read the NAS tool")
            subtext: nas.error
        }

        ServerHome {
            page: root
            bridge: nas
        }
    }
}
