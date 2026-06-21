pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
import QtQuick

Column {
    id: root

    spacing: Tokens.spacing.normal
    width: Tokens.sizes.bar.batteryWidth

    // Title: Current ACTIVE Mode (real, not configured)
    StyledText {
        text: "GPU Mode: " + GpuModeService.getModeName(GpuModeService.activeMode)
        font: Tokens.font.body.small
    }

    // Status text: Switching with timer OR Confirmation (NOT pending - that goes below)
    StyledText {
        id: statusText
        property bool hasPending: GpuModeService.pendingMode.length > 0 && GpuModeService.pendingMode !== GpuModeService.activeMode
        property bool hasConfirmation: GpuModeService.pendingConfirmation !== ""
        visible: GpuModeService.switching || hasConfirmation
        text: {
            if (GpuModeService.switching) {
                const targetName = GpuModeService.getModeName(GpuModeService.targetMode)
                const t = GpuModeService.switchTimeRemaining
                if (t > 0) {
                    return "Switching to " + targetName + "... " + t + "s"
                }
                return "Applying " + targetName + "..."
            } else if (hasConfirmation) {
                return "Click again to confirm " + GpuModeService.getModeName(GpuModeService.pendingConfirmation)
            }
            return ""
        }
        wrapMode: Text.WordWrap
        width: parent.width
        color: statusText.hasConfirmation ? Colours.palette.m3tertiary : Colours.palette.m3primary
        font: Tokens.font.body.small
    }

    // Description of CURRENT ACTIVE mode (always visible when not switching/loading)
    StyledText {
        visible: !GpuModeService.switching && !statusText.hasConfirmation && !GpuModeService.loading
        text: GpuModeService.getModeDescription(GpuModeService.activeMode)
        wrapMode: Text.WordWrap
        width: parent.width
        color: Colours.palette.m3onSurface
        font: Tokens.font.body.small
    }

    // Loading indicator
    StyledText {
        visible: GpuModeService.loading
        text: "Loading..."
        wrapMode: Text.WordWrap
        width: parent.width
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    // Mode selector buttons (visible during loading but disabled)
    StyledRect {
        id: profiles

        property string current: {
            // During switch, highlight target
            if (GpuModeService.switching && GpuModeService.targetMode !== "") {
                const target = GpuModeService.targetMode
                if (target === "integrated") return "memory"
                if (target === "hybrid") return "swap_horiz"
                if (target === "asusmuxdgpu") return "developer_board"
            }
            // If confirmation pending, highlight that
            if (GpuModeService.pendingConfirmation !== "") {
                const conf = GpuModeService.pendingConfirmation
                if (conf === "integrated") return "memory"
                if (conf === "hybrid") return "swap_horiz"
                if (conf === "asusmuxdgpu") return "developer_board"
            }
            // Otherwise show pending or active
            const pending = GpuModeService.pendingMode
            const hasPending = pending.length > 0 && pending !== GpuModeService.activeMode
            const mode = hasPending ? pending : GpuModeService.activeMode
            if (mode === "integrated") return "memory"
            if (mode === "hybrid") return "swap_horiz"
            if (mode === "asusmuxdgpu") return "developer_board"
            return ""
        }

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: integrated.implicitWidth + hybrid.implicitWidth + dedicated.implicitWidth + Tokens.padding.normal * 2 + Tokens.spacing.large * 2
        implicitHeight: Math.max(integrated.implicitHeight, hybrid.implicitHeight, dedicated.implicitHeight) + Tokens.padding.small * 2

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        // Dim overlay when switching or loading
        Rectangle {
            anchors.fill: parent
            color: Colours.palette.m3surface
            opacity: (GpuModeService.switching || GpuModeService.loading) ? 0.5 : 0
            radius: parent.radius
            
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        StyledRect {
            id: indicator

            visible: !GpuModeService.loading  // Hide indicator during loading
            color: GpuModeService.switching ? Colours.palette.m3outline : 
                   GpuModeService.pendingConfirmation !== "" ? Colours.palette.m3tertiary :
                   Colours.palette.m3primary
            radius: Tokens.rounding.full
            state: profiles.current

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            states: [
                State {
                    name: "memory"
                    Fill { item: integrated }
                },
                State {
                    name: "swap_horiz"
                    Fill { item: hybrid }
                },
                State {
                    name: "developer_board"
                    Fill { item: dedicated }
                }
            ]

            transitions: Transition {
                AnchorAnimation {
                    duration: Tokens.anim.durations.normal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Tokens.anim.curves.emphasized
                }
            }
        }

        ModeButton {
            id: integrated
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.small
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
            anchors.rightMargin: Tokens.padding.small
            mode: "asusmuxdgpu"
            icon: "developer_board"
        }
    }

    // Confirmation action text (only during confirmation)
    StyledText {
        id: confirmActionText
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !GpuModeService.switching && !GpuModeService.loading && statusText.hasConfirmation
        
        property string fromMode: GpuModeService.pendingMode !== "" ? GpuModeService.pendingMode : GpuModeService.activeMode
        property string toMode: GpuModeService.pendingConfirmation
        property int estimatedTime: GpuModeService.getEstimatedTime(fromMode, toMode)
        property bool isSlow: estimatedTime > 0
        property string action: GpuModeService.getRequiredAction(GpuModeService.activeMode, toMode)
        
        text: {
            let result = GpuModeService.getActionText(action)
            if (isSlow) {
                result += " (~" + estimatedTime + "s)"
            }
            return result
        }
        font: Tokens.font.body.small
        color: (action === "reboot" || isSlow) ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
    }

    // Pending status text (when there's a pending mode waiting for logout/reboot)
    StyledText {
        id: pendingText
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !GpuModeService.switching && !GpuModeService.loading && !statusText.hasConfirmation && statusText.hasPending
        
        property string action: GpuModeService.getRequiredAction(GpuModeService.activeMode, GpuModeService.pendingMode)
        property string actionWord: action === "reboot" ? "Reboot" : "Logout"
        
        text: "Pending " + actionWord + " to " + GpuModeService.getModeName(GpuModeService.pendingMode)
        font: Tokens.font.body.small
        color: Colours.palette.m3error  // Always red for pending
    }

    // Error message (small, discrete, red)
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: GpuModeService.lastError !== ""
        text: GpuModeService.lastError
        font: Tokens.font.body.small
        color: Colours.palette.m3error
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

        readonly property bool isCurrent: GpuModeService.activeMode === mode
        readonly property bool isPending: GpuModeService.pendingMode.length > 0 && GpuModeService.pendingMode === mode && GpuModeService.pendingMode !== GpuModeService.activeMode
        readonly property bool isTarget: GpuModeService.switching && GpuModeService.targetMode === mode
        readonly property bool isConfirmation: GpuModeService.pendingConfirmation === mode
        readonly property bool isDisabled: GpuModeService.switching || GpuModeService.loading

        implicitWidth: buttonIcon.implicitWidth + Tokens.padding.small * 2
        implicitHeight: buttonIcon.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            radius: Tokens.rounding.full
            color: parent.isDisabled ? Colours.palette.m3outline :
                   (parent.isConfirmation ? Colours.palette.m3tertiary :
                   (parent.isTarget || parent.isPending ? Colours.palette.m3primary : 
                   (parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface)))
            enabled: !parent.isDisabled

            onClicked: {
                if (parent.isDisabled) return
                console.log("[GPU] User clicked:", parent.mode, "(active:", GpuModeService.activeMode, "pending:", GpuModeService.pendingMode, "confirmation:", GpuModeService.pendingConfirmation, ")")
                GpuModeService.switchMode(parent.mode)
            }
        }

        MaterialIcon {
            id: buttonIcon
            anchors.centerIn: parent
            text: parent.icon
            fontStyle: Tokens.font.icon.builders.large.build()
            color: parent.isDisabled ? Colours.palette.m3outline :
                   (parent.isConfirmation ? Colours.palette.m3onTertiary :
                   (parent.isTarget || parent.isPending ? Colours.palette.m3onPrimary :
                   (parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface)))
            fill: parent.isTarget || parent.isPending || parent.isCurrent || parent.isConfirmation ? 1 : 0

            Behavior on fill { Anim {} }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

    }

    Connections {
        target: GpuModeService
        function onSwitchSuccess(newMode) {
            console.log("[GPU] Switch success:", newMode)
        }
        function onSwitchFailed(error) {
            console.error("[GPU] Switch failed:", error)
        }
    }
}
