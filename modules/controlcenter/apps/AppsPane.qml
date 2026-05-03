pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    anchors.fill: parent

    // Application launchers grouped by category
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

    StyledFlickable {
        id: flickable

        anchors.fill: parent
        anchors.margins: Appearance.padding.large * 2
        flickableDirection: Flickable.VerticalFlick
        contentHeight: contentLayout.height

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: flickable
        }

        ColumnLayout {
            id: contentLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "apps"
                    font.pointSize: Appearance.font.size.extraLarge
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: qsTr("System Applications")
                    font.pointSize: Appearance.font.size.large
                    font.weight: 500
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Quick access to system configuration tools")
                color: Colours.palette.m3onSurfaceVariant
                wrapMode: Text.WordWrap
            }

            // Categories
            Repeater {
                model: root.appCategories

                ColumnLayout {
                    id: categoryDelegate

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.topMargin: index > 0 ? Appearance.spacing.normal : 0
                    spacing: Appearance.spacing.small

                    // Category header
                    RowLayout {
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            text: categoryDelegate.modelData.icon
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: categoryDelegate.modelData.name
                            font.weight: 600
                            color: Colours.palette.m3primary
                        }
                    }

                    // Apps in category
                    Flow {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        Repeater {
                            model: categoryDelegate.modelData.apps

                            StyledRect {
                                id: appButton

                                required property var modelData

                                implicitWidth: appContent.implicitWidth + Appearance.padding.normal * 2
                                implicitHeight: appContent.implicitHeight + Appearance.padding.normal * 2

                                radius: Appearance.rounding.normal
                                color: Colours.tPalette.m3surfaceContainer

                                StateLayer {
                                    radius: parent.radius
                                    color: Colours.palette.m3onSurface

                                    onClicked: {
                                        Quickshell.execDetached(appButton.modelData.command);
                                    }
                                }

                                RowLayout {
                                    id: appContent

                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.small

                                    MaterialIcon {
                                        text: appButton.modelData.icon
                                        color: Colours.palette.m3onSurfaceVariant
                                    }

                                    ColumnLayout {
                                        spacing: 0

                                        StyledText {
                                            text: appButton.modelData.name
                                            font.weight: 500
                                        }

                                        StyledText {
                                            text: appButton.modelData.description
                                            font.pointSize: Appearance.font.size.smaller
                                            color: Colours.palette.m3onSurfaceVariant
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Spacer at bottom
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Appearance.padding.large
            }
        }
    }
}
