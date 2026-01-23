import qs.components
import qs.services
import qs.utils
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Appearance.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    // Get monitor index for this workspace (1-based), or 0 if not associated with any monitor
    function getMonitorIndex(): int {
        const wsObj = Hypr.workspaces.values.find(w => w.id === root.ws);
        if (!wsObj || !wsObj.monitor) return 0;
        
        // Get the monitor object associated with this workspace
        const wsMonitor = wsObj.monitor;
        
        // Find the index of this monitor among all monitors
        const monitors = Quickshell.screens;
        for (let i = 0; i < monitors.length; i++) {
            const mon = Hypr.monitorFor(monitors[i]);
            if (mon && mon.name === wsMonitor.name) {
                return i + 1; // 1-based index
            }
        }
        return 0;
    }

    // Convert number to Roman numeral
    function toRoman(num: int): string {
        const romans = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"];
        return num >= 1 && num <= 10 ? romans[num] : num.toString();
    }

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: Config.bar.sizes.innerWidth - Appearance.padding.small * 2

        animate: true
        text: {
            const monIdx = root.getMonitorIndex();
            if (monIdx > 0) {
                // Workspace is active on a monitor - show Roman numeral
                return root.toRoman(monIdx);
            }
            // Not on any monitor - show original label (dot/circle behavior)
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
            return root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
        }
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        verticalAlignment: Qt.AlignVCenter
    }

    Loader {
        id: windows

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: -Config.bar.sizes.innerWidth / 10

        visible: active
        active: root.hasWindows

        sourceComponent: StyledRect {
            id: windowsContainer

            // Visual grouping: subtle border around windows of this workspace
            color: "transparent"
            border.color: root.activeWsId === root.ws ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
            border.width: 1
            radius: Appearance.rounding.small

            implicitWidth: windowsColumn.implicitWidth + Appearance.padding.small * 2
            implicitHeight: windowsColumn.implicitHeight + Appearance.padding.small

            Column {
                id: windowsColumn
                anchors.centerIn: parent
                spacing: 0

                add: Transition {
                    Anim {
                        properties: "scale"
                        from: 0
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                }

                move: Transition {
                    Anim {
                        properties: "scale"
                        to: 1
                        easing.bezierCurve: Appearance.anim.curves.standardDecel
                    }
                    Anim {
                        properties: "x,y"
                    }
                }

                Repeater {
                    model: ScriptModel {
                        values: Hypr.toplevels.values.filter(c => c.workspace?.id === root.ws)
                    }

                    MaterialIcon {
                        required property var modelData

                        grade: 0
                        text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
