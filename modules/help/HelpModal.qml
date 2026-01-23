pragma ComponentBehavior: Bound

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

    property bool showing: false

    visible: showing

    readonly property var shortcuts: [
        { category: qsTr("Navigation"), items: [
            { keys: "Super + 1-5", action: qsTr("Switch to workspace") },
            { keys: "Super + Tab", action: qsTr("Next workspace group") },
            { keys: "Super + Shift + Tab", action: qsTr("Previous workspace group") },
            { keys: "Alt + Tab", action: qsTr("Cycle workspaces in current group") },
            { keys: "Ctrl + Super + Tab", action: qsTr("Cycle through all windows") },
            { keys: "Super + D", action: qsTr("Show desktop (new empty workspace)") },
            { keys: "Super + Shift + D", action: qsTr("Dual empty workspaces") },
            { keys: "Super + Arrows", action: qsTr("Move/Snap window to edge") },
            { keys: "Super + Up/Down", action: qsTr("Maximize/Restore window") },
            { keys: "Super + Ctrl + Left/Right", action: qsTr("Focus between monitors") }
        ]},
        { category: qsTr("Window Management"), items: [
            { keys: "Super + Q", action: qsTr("Close active window") },
            { keys: "Super + F", action: qsTr("Toggle fullscreen") },
            { keys: "Super + V", action: qsTr("Toggle floating") },
            { keys: "Super + Shift + 1-5", action: qsTr("Move window to workspace") },
            { keys: "Super + Shift + Arrows", action: qsTr("Move window between workspaces") },
            { keys: "Super + Shift + Up/Down", action: qsTr("Move window between workspace groups") },
            { keys: "Super + Alt + Q", action: qsTr("Force kill window process") }
        ]},
        { category: qsTr("Applications"), items: [
            { keys: "Super", action: qsTr("Open launcher") },
            { keys: "Super + Return", action: qsTr("Open terminal (Kitty)") },
            { keys: "Super + T", action: qsTr("Open terminal") },
            { keys: "Super + O", action: qsTr("Open Obsidian") },
            { keys: "Super + E", action: qsTr("Open file manager (Thunar)") }
        ]},
        { category: qsTr("Session"), items: [
            { keys: "Super + L", action: qsTr("Lock screen") },
            { keys: "Super + Shift + E", action: qsTr("Exit/Logout") },
            { keys: "Super + Shift + R", action: qsTr("Reload Caelestia Shell") }
        ]},
        { category: qsTr("Screenshots"), items: [
            { keys: "Super + Shift + S", action: qsTr("Screenshot region (clipboard)") },
            { keys: "Print", action: qsTr("Screenshot fullscreen") }
        ]},
        { category: qsTr("Caelestia Shell"), items: [
            { keys: "Super + Space", action: qsTr("Toggle scratchpad/special workspace") },
            { keys: "Super + N", action: qsTr("New workspace group") },
            { keys: "Super + F1", action: qsTr("Show this help") }
        ]}
    ]

    StyledRect {
        anchors.centerIn: parent
        implicitWidth: Math.min(parent.width * 0.85, 1000)
        implicitHeight: Math.min(parent.height * 0.8, 800)

        color: Colours.palette.m3surfaceContainerHigh
        radius: Appearance.rounding.large

        StyledFlickable {
            id: flickable

            anchors.fill: parent
            anchors.margins: Appearance.padding.large
            flickableDirection: Flickable.VerticalFlick
            contentHeight: contentLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: flickable
            }

            ColumnLayout {
                id: contentLayout

                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Appearance.spacing.large

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "keyboard"
                        font.pointSize: Appearance.font.size.extraLarge
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: qsTr("Keyboard Shortcuts")
                        font.pointSize: Appearance.font.size.extraLarge
                        font.weight: 600
                    }
                }

                // Shortcut categories in 2 columns
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Appearance.spacing.large
                    columnSpacing: Appearance.spacing.large

                    Repeater {
                        model: root.shortcuts

                        ColumnLayout {
                            id: categoryDelegate

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: Appearance.spacing.small

                            // Category header
                            StyledText {
                                text: categoryDelegate.modelData.category
                                font.weight: 600
                                font.pointSize: Appearance.font.size.large
                                color: Colours.palette.m3primary
                            }

                            // Shortcuts in category
                            Repeater {
                                model: categoryDelegate.modelData.items

                                RowLayout {
                                    id: shortcutRow

                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.normal

                                    // Kbd-style key badge (3D look)
                                    StyledRect {
                                        implicitWidth: keysText.implicitWidth + Appearance.padding.normal * 2
                                        implicitHeight: keysText.implicitHeight + Appearance.padding.small * 2

                                        color: Colours.palette.m3surface
                                        radius: Appearance.rounding.small

                                        border.width: 1
                                        border.color: Colours.palette.m3outline

                                        // 3D effect - top highlight
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.bottomMargin: parent.height * 0.5
                                            color: Qt.rgba(1, 1, 1, 0.1)
                                            radius: parent.radius
                                        }

                                        // 3D effect - bottom shadow
                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 2
                                            color: Qt.rgba(0, 0, 0, 0.2)
                                            radius: parent.radius
                                        }

                                        StyledText {
                                            id: keysText

                                            anchors.centerIn: parent
                                            text: shortcutRow.modelData.keys
                                            font.family: Appearance.font.family.mono
                                            font.pointSize: Appearance.font.size.small
                                            font.weight: 600
                                            color: Colours.palette.m3onSurface
                                        }
                                    }

                                    // Action description
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: shortcutRow.modelData.action
                                        color: Colours.palette.m3onSurfaceVariant
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.padding.large
                }
            }
        }
    }
}
