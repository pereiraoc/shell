pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    // Properties
    property string selectedMethod: "face"
    property bool faceEnabled: true
    property bool pinEnabled: true

    spacing: Tokens.spacing.normal

    // Face button
    StyledRect {
        id: faceButton

        Layout.preferredWidth: 80
        Layout.preferredHeight: 70

        color: root.selectedMethod === "face" ? 
            Colours.palette.m3primaryContainer : 
            Colours.tPalette.m3surfaceContainer
        
        radius: Tokens.rounding.small
        opacity: root.faceEnabled ? 1 : 0.5

        border.width: root.selectedMethod === "face" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            enabled: root.faceEnabled
            
            onClicked: {
                if (root.faceEnabled) {
                    root.selectedMethod = "face";
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "face"
                color: root.selectedMethod === "face" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Face")
                color: root.selectedMethod === "face" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.small
            }
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
        
        radius: Tokens.rounding.small
        opacity: root.pinEnabled ? 1 : 0.5

        border.width: root.selectedMethod === "pin" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            enabled: root.pinEnabled
            
            onClicked: {
                if (root.pinEnabled) {
                    root.selectedMethod = "pin";
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "dialpad"
                color: root.selectedMethod === "pin" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("PIN")
                color: root.selectedMethod === "pin" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.small
            }
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
        
        radius: Tokens.rounding.small

        border.width: root.selectedMethod === "password" ? 2 : 0
        border.color: Colours.palette.m3primary

        StateLayer {
            onClicked: {
                root.selectedMethod = "password";
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "password"
                color: root.selectedMethod === "password" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Password")
                color: root.selectedMethod === "password" ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3onSurface
                font.pointSize: Tokens.font.size.small
            }
        }
    }
}
