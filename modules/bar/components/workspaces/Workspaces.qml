pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// US-005 — Workspace section por monitor.
//
// Renderiza UMA SEÇÃO POR MONITOR conectado, em ordem de role index.
// Cada seção tem seu próprio container (StyledClippingRect dentro de
// MonitorSection), separados visualmente.
//
// Layout de IDs: ws = roleIdx*100 + groupIdx*3 + slotIdx + 1
Item {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property var thisMonitor: Hypr.monitorFor(screen)
    readonly property int thisRoleIdx: MonitorRoles.indexForMonitor(thisMonitor)
    readonly property bool onSpecial: thisMonitor?.lastIpcObject.specialWorkspace?.name !== ""

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: layout.implicitHeight

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        ColumnLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Tokens.spacing.normal

            Repeater {
                model: MonitorRoles.count

                MonitorSection {
                    required property int index

                    monitor: MonitorRoles.monitorAtIndex(index)
                    roleIdx: index
                    isCurrent: index === root.thisRoleIdx
                }
            }
        }

        Behavior on scale { Anim {} }
        Behavior on opacity { Anim {} }
    }

    // Special workspace overlay (preserved)
    Loader {
        asynchronous: true
        anchors.fill: parent
        anchors.margins: Tokens.padding.small

        active: opacity > 0
        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
        }

        Behavior on scale { Anim {} }
        Behavior on opacity { Anim {} }
    }
}
