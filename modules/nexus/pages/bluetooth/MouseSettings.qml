pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.misc
import qs.modules.nexus.common

// Subpagina de um mouse (deep link antigo / IPC): so embrulha a
// MouseSettingsView com o mouse escolhido (nState.selectedMouse).
PageBase {
    id: root

    readonly property var mouse: (bridge.info.mice ?? []).find(m => m.model === root.nState.selectedMouse) ?? null

    title: root.mouse ? root.mouse.name.replace(/\s*\(.*?\)\s*$/, "") : qsTr("Mouse")
    description: qsTr("Buttons, DPI stages and power")
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

        MouseSettingsView {
            model: root.nState.selectedMouse
            bridge: bridge
        }
    }
}
