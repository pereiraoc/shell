import QtQuick
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Falha da ultima acao de uma ponte, mostrada onde a acao foi disparada.
// So acoes desta visita a pagina (last.at depois de a linha nascer): uma
// falha antiga de outro dia nao deve assombrar a pagina. Some sozinha em 12 s.
InfoRow {
    id: root

    required property ToolBridge bridge
    property real since: Date.now() / 1000 - 2
    property bool dismissed

    readonly property var lastRun: root.bridge.last ?? ({})
    readonly property bool failed: !!root.lastRun.result && root.lastRun.result.ok === false && (root.lastRun.at ?? 0) >= root.since

    first: true
    last: true
    visible: root.failed && !root.dismissed
    icon: "error"
    iconColour: Colours.palette.m3error
    label: qsTr("That didn't work")
    subtext: root.lastRun.result?.message ?? ""

    onFailedChanged: {
        if (root.failed) {
            root.dismissed = false;
            hide.restart();
        }
    }

    Timer {
        id: hide

        interval: 12000
        onTriggered: root.dismissed = true
    }
}
