pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("System apps")

    // Application launchers grouped by category (US-007: portado do controlcenter)
    readonly property var appCategories: [
        {
            name: qsTr("Audio"),
            icon: "graphic_eq",
            apps: [
                { name: "qpwgraph", icon: "cable", command: ["qpwgraph"], description: qsTr("PipeWire Graph Manager") },
                { name: "EasyEffects", icon: "tune", command: ["easyeffects"], description: qsTr("Audio Effects & Equalizer") },
                { name: "PulseAudio Volume", icon: "volume_up", command: ["pavucontrol"], description: qsTr("Volume Control") }
            ]
        },
        {
            name: qsTr("Display"),
            icon: "monitor",
            apps: [
                { name: "nwg-displays", icon: "desktop_windows", command: ["nwg-displays"], description: qsTr("Monitor Configuration") },
                { name: "Font Scaling", icon: "text_fields", command: ["font-scaling-manager"], description: qsTr("Font Size & DPI") }
            ]
        },
        {
            name: qsTr("System"),
            icon: "settings",
            apps: [
                { name: "System Monitor", icon: "monitoring", command: ["gnome-system-monitor"], description: qsTr("Resource Monitor") },
                { name: "Logs", icon: "article", command: ["gnome-logs"], description: qsTr("System Logs") },
                { name: "Disk Usage", icon: "storage", command: ["baobab"], description: qsTr("Disk Usage Analyzer") }
            ]
        },
        {
            name: qsTr("Hardware"),
            icon: "memory",
            apps: [
                { name: "Qt Camera", icon: "videocam", command: ["qcam"], description: qsTr("Camera Viewer (V4L2)") },
                { name: "Howdy Manager", icon: "face", command: ["howdy-manager"], description: qsTr("Facial Recognition") },
                { name: "ROG Control", icon: "sports_esports", command: ["rog-control-center"], description: qsTr("ASUS ROG Settings") }
            ]
        },
        {
            name: qsTr("Sharing"),
            icon: "share",
            apps: [
                { name: "LocalSend", icon: "send", command: ["localsend_app"], description: qsTr("Local File Sharing") },
                { name: "Snapdrop", icon: "language", command: ["xdg-open", "https://snapdrop.net"], description: qsTr("Web-based Sharing") }
            ]
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: root.appCategories

            ColumnLayout {
                id: catDelegate

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: catDelegate.index === 0
                    text: catDelegate.modelData.name
                }

                Repeater {
                    model: catDelegate.modelData.apps

                    NavRow {
                        required property var modelData
                        required property int index

                        icon: modelData.icon
                        label: modelData.name
                        status: modelData.description
                        first: index === 0
                        last: index === catDelegate.modelData.apps.length - 1
                        onClicked: Quickshell.execDetached(modelData.command)
                    }
                }
            }
        }
    }
}
