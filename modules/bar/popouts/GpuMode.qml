pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    spacing: Appearance.spacing.normal
    width: Config.bar.sizes.batteryWidth

    StyledText {
        text: qsTr("GPU Mode: %1").arg(GpuModeService.getModeName(GpuModeService.currentMode))
    }

    StyledText {
        text: GpuModeService.getModeDescription(GpuModeService.currentMode)
        wrapMode: Text.WordWrap
        width: parent.width
    }

    StyledRect {
        id: profiles

        property string current: {
            const mode = GpuModeService.currentMode
            if (mode === "integrated") return "memory"
            if (mode === "hybrid") return "swap_horiz"
            if (mode === "asusmuxdgpu") return "developer_board"
            return ""
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: integrated.implicitWidth + hybrid.implicitWidth + dedicated.implicitWidth + Appearance.padding.normal * 2 + Appearance.spacing.large * 2
        implicitHeight: Math.max(integrated.implicitHeight, hybrid.implicitHeight, dedicated.implicitHeight) + Appearance.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Appearance.rounding.full

        StyledRect {
            id: indicator

            color: Colours.palette.m3primary
            radius: Appearance.rounding.full
            state: profiles.current

            states: [
                State {
                    name: "memory"

                    Fill {
                        item: integrated
                    }
                },
                State {
                    name: "swap_horiz"

                    Fill {
                        item: hybrid
                    }
                },
                State {
                    name: "developer_board"

                    Fill {
                        item: dedicated
                    }
                }
            ]

            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.emphasized
                }
            }
        }

        ModeButton {
            id: integrated

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Appearance.padding.small

            mode: "integrated"
            icon: "memory"
        }

        ModeButton {
            id: hybrid

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            mode: "hybrid"
            icon: "swap_horiz"
        }

        ModeButton {
            id: dedicated

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Appearance.padding.small

            mode: "asusmuxdgpu"
            icon: "developer_board"
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("Requires logout to apply")
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3onSurfaceVariant
        visible: !GpuModeService.switching
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        text: qsTr("🔄 Switching...")
        font.pointSize: Appearance.font.size.small
        color: Colours.palette.m3primary
        visible: GpuModeService.switching
    }

    component Fill: AnchorChanges {
        required property Item item

        target: indicator
        anchors.left: item.left
        anchors.right: item.right
        anchors.top: item.top
        anchors.bottom: item.bottom
    }

    component ModeButton: Item {
        required property string mode
        required property string icon

        readonly property bool isCurrent: GpuModeService.currentMode === mode

        implicitWidth: buttonIcon.implicitWidth + Appearance.padding.small * 2
        implicitHeight: buttonIcon.implicitHeight + Appearance.padding.small * 2

        StateLayer {
            radius: Appearance.rounding.full
            color: parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            enabled: !parent.isCurrent && !GpuModeService.switching

            function onClicked(): void {
                console.log("Switching GPU mode to:", parent.mode)
                GpuModeService.switchMode(parent.mode)
            }
        }

        MaterialIcon {
            id: buttonIcon

            anchors.centerIn: parent

            text: parent.icon
            font.pointSize: Appearance.font.size.large
            color: parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            fill: parent.isCurrent ? 1 : 0

            Behavior on fill {
                Anim {}
            }
        }
    }

    Connections {
        target: GpuModeService

        function onSwitchSuccess(newMode) {
            console.log("GPU mode switched to:", newMode)
        }

        function onSwitchFailed(error) {
            console.error("GPU switch failed:", error)
        }
    }
}
