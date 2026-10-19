pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.misc
import qs.modules.nexus.common

// Subpagina de iluminacao para as luzes que nao tem aba propria (Keyboard >
// Advanced): so embrulha a RgbLightingView com o aparelho escolhido.
PageBase {
    id: root

    title: qsTr("Lighting")
    description: qsTr("Lighting effect, colours, brightness and speed")
    isSubPage: true

    ToolBridge {
        id: bridge

        tool: "peripherals"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        RgbLightingView {
            deviceId: root.nState.selectedRgbDevice
            bridge: bridge
        }
    }
}
