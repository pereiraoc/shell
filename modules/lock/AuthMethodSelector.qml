pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    // Properties
    property string selectedMethod: "face"
    property bool faceEnabled: true
    property bool pinEnabled: true

    spacing: Appearance.spacing.normal

    // Face button
    StyledRect {
        id: faceButton

        Layout.preferredWidth: 80
        Layout.preferredHeight: 70

        color: root.selectedMethod === "face" ? 
            Colours.palette.m3primaryContainer : 
            Colours.tPalette.m3surfaceContainer
        
        radius: Appearance.rounding.small
        opacity: root.faceEnabled ? 1 : 0.5

        border.width: root.selectedMethod === "face" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            enabled: root.faceEnabled
            
            function onClicked(): void {
                if (root.faceEnabled) {
                    root.selectedMethod = "face";
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "face"
                color: root.selectedMethod === "face" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Face")
                color: root.selectedMethod === "face" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
            }
        }

        Tooltip {
            visible: parent.hovered
            text: root.faceEnabled ? 
                qsTr("Unlock with face recognition") : 
                qsTr("Face disabled. Use PIN or Password.")
        }
    }

    // PIN button
    StyledRect {
        id: pinButton

        Layout.preferredWidth: 80
        Layout.preferredHeight: 70

        color: root.selectedMethod === "pin" ? 
            Colours.palette.m3primaryContainer : 
            Colours.tPalette.m3surfaceContainer
        
        radius: Appearance.rounding.small
        opacity: root.pinEnabled ? 1 : 0.5

        border.width: root.selectedMethod === "pin" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            enabled: root.pinEnabled
            
            function onClicked(): void {
                if (root.pinEnabled) {
                    root.selectedMethod = "pin";
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "dialpad"
                color: root.selectedMethod === "pin" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("PIN")
                color: root.selectedMethod === "pin" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
            }
        }

        Tooltip {
            visible: parent.hovered
            text: root.pinEnabled ? 
                qsTr("Unlock with PIN") : 
                qsTr("PIN disabled. Use Face or Password.")
        }
    }

    // Password button (always enabled)
    StyledRect {
        id: passwordButton

        Layout.preferredWidth: 80
        Layout.preferredHeight: 70

        color: root.selectedMethod === "password" ? 
            Colours.palette.m3primaryContainer : 
            Colours.tPalette.m3surfaceContainer
        
        radius: Appearance.rounding.small

        border.width: root.selectedMethod === "password" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            function onClicked(): void {
                root.selectedMethod = "password";
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "password"
                color: root.selectedMethod === "password" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Password")
                color: root.selectedMethod === "password" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Appearance.font.size.small
            }
        }

        Tooltip {
            visible: parent.hovered
            text: qsTr("Unlock with password")
        }
    }
}
