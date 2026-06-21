pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Window management")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // === US-007: gaps do Hyprland (config C++ hyprland.gaps*, aplica via hyprctl) ===
        SectionHeader {
            first: true
            text: qsTr("Gaps")
        }

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Inner gaps")
            subtext: qsTr("Spacing between windows (px)")
            value: Config.hyprland.gapsInner
            from: 0
            to: 30
            stepSize: 1
            onMoved: v => {
                GlobalConfig.hyprland.gapsInner = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", String(v)]);
            }
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Outer gaps")
            subtext: qsTr("Spacing between windows and screen edges (px)")
            value: Config.hyprland.gapsOuter
            from: 0
            to: 50
            stepSize: 1
            onMoved: v => {
                GlobalConfig.hyprland.gapsOuter = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", String(v)]);
            }
        }
    }
}
