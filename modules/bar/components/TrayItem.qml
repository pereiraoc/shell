pragma ComponentBehavior: Bound

import qs.components.effects
import qs.services
import qs.config
import qs.utils
import Quickshell.Services.SystemTray
import Quickshell
import QtQuick

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Appearance.font.size.small * 2
    implicitHeight: Appearance.font.size.small * 2

    // DIAGNÓSTICO: escrever em arquivo (console pode não aparecer no output)
    Component.onCompleted: {
        const id = (modelData && modelData.id) ? String(modelData.id) : "null"
        const icon = (modelData && modelData.icon) ? String(modelData.icon) : "null"
        Quickshell.execDetached(["sh", "-c", "echo 'TRAY-DIAG: TrayItem id=" + id.replace(/'/g, "_") + " icon=" + icon.replace(/'/g, "_").slice(0, 80) + "' >> /tmp/tray-diag.txt"])
    }

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    // DIAGNÓSTICO: quadrado vermelho visível se delegate existe
    Rectangle {
        anchors.fill: parent
        color: "red"
        opacity: 0.5
        visible: !!root.modelData
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
