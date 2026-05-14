pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// US-005 — Workspace bubble com active highlight + ícones centrados.
Item {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true
    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows
    readonly property bool isActive: activeWsId === ws

    readonly property int bubbleSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
    readonly property int contentHeight: hasWindows ? Math.max(bubbleSize, iconColumn.implicitHeight) : bubbleSize

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: bubbleSize
    Layout.preferredHeight: contentHeight
    implicitWidth: bubbleSize
    implicitHeight: contentHeight

    // Active highlight background
    Rectangle {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        opacity: root.isActive ? 0.25 : 0

        Behavior on opacity {
            NumberAnimation { duration: Tokens.anim.durations.small }
        }
    }

    // Indicator (label/dot) — visível só quando NÃO tem windows
    StyledText {
        id: indicator
        anchors.centerIn: parent
        visible: !root.hasWindows
        animate: true
        text: {
            const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
            const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
            let displayName = wsName.toString();
            if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
                displayName = displayName.toUpperCase();
            } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
                displayName = displayName.toLowerCase();
            }
            const label = Config.bar.workspaces.label || displayName;
            const occupiedLabel = Config.bar.workspaces.occupiedLabel || label;
            const activeLabel = Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : label);
            return root.isActive ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: root.isActive ? Colours.palette.m3primary : (Config.bar.workspaces.occupiedBg || root.isOccupied ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2))
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
    }

    // Icons column — centrada quando hasWindows
    Column {
        id: iconColumn
        anchors.centerIn: parent
        spacing: 0
        visible: root.hasWindows

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        Repeater {
            model: ScriptModel {
                values: {
                    const ws = root.ws;
                    const wins = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
                    const maxIcons = Config.bar.workspaces.maxWindowIcons;
                    return maxIcons > 0 ? wins.slice(0, maxIcons) : wins;
                }
            }

            MaterialIcon {
                required property var modelData
                grade: 0
                text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                color: root.isActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
