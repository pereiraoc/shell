pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar
    required property bool barRight

    ExclusionZone {
        anchors.left: true
        exclusiveZone: root.barRight ? contentItem.Config.border.thickness : root.bar.exclusiveZone
    }

    ExclusionZone {
        anchors.top: true
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: root.barRight ? root.bar.exclusiveZone : contentItem.Config.border.thickness
    }

    ExclusionZone {
        anchors.bottom: true
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }
}
