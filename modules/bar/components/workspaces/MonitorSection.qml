pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.services

// US-005 — Seção de um monitor: header (fora) + container com 3 bubbles.
//
// Layout:
//   [🖥 N]              ← header inline (fora do container)
//   [●○○]               ← group cycle indicator (se >1 grupo)
//   ┌──────┐            ← container próprio do monitor
//   │  ws  │
//   │  ws  │  ← 3 bubbles do grupo ativo
//   │  ws  │
//   └──────┘
ColumnLayout {
    id: root

    required property HyprlandMonitor monitor
    required property int roleIdx
    required property bool isCurrent

    readonly property int displayNumber: roleIdx + 1
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    readonly property int activeGroupIdx: {
        if (roleIdx < 0) return 0;
        const localId = activeWsId - roleIdx * 100;
        if (localId < 1) return 0;
        return Math.floor((localId - 1) / 3);
    }
    readonly property int wsPerGroup: 3
    readonly property int groupsPerMonitor: 5
    readonly property int groupOffset: roleIdx >= 0 ? roleIdx * 100 + activeGroupIdx * wsPerGroup : 0

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values) {
            if (ws.monitor && ws.monitor.name === monitor?.name) {
                occ[ws.id] = ws.lastIpcObject.windows > 0;
            }
        }
        return occ;
    }

    Layout.alignment: Qt.AlignHCenter
    spacing: Math.floor(Tokens.spacing.smaller / 2)

    // Header inline: [🖥 N] — fora do container
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 1

        MaterialIcon {
            text: "monitor"
            font.pointSize: Tokens.font.size.smaller
            color: root.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            grade: 0
        }
        StyledText {
            text: root.displayNumber
            font.pointSize: Tokens.font.size.smaller
            font.weight: 700
            color: root.isCurrent ? Colours.palette.m3primary : Colours.palette.m3onSurface
        }
    }

    // Group cycle dots (●○○) — só se >1 grupo
    GroupCycleIndicator {
        Layout.alignment: Qt.AlignHCenter
        groupCount: root.groupsPerMonitor
        activeGroupIdx: root.activeGroupIdx
    }

    // Container próprio do monitor — rounded background com 3 bubbles dentro
    StyledClippingRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Tokens.sizes.bar.innerWidth
        implicitHeight: bubblesLayout.implicitHeight + Tokens.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        ColumnLayout {
            id: bubblesLayout
            anchors.centerIn: parent
            spacing: Math.floor(Tokens.spacing.small / 2)

            Repeater {
                model: root.wsPerGroup
                Workspace {
                    activeWsId: root.activeWsId
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }
        }
    }
}
