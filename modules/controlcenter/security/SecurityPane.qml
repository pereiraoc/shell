pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property string newPin: ""
    property string confirmPin: ""
    property bool pinMismatch: false
    property bool pinSaved: false
    property string statusMessage: ""

    anchors.fill: parent

    function savePin() {
        if (newPin.length !== 4) {
            statusMessage = qsTr("PIN must be exactly 4 digits");
            pinMismatch = true;
            return;
        }
        if (newPin !== confirmPin) {
            statusMessage = qsTr("PINs do not match");
            pinMismatch = true;
            return;
        }

        // Save PIN to config
        Config.lock.auth.userPin = newPin;
        Config.save();

        pinMismatch = false;
        pinSaved = true;
        statusMessage = qsTr("PIN saved successfully!");
        newPin = "";
        confirmPin = "";

        // Reset status after 3 seconds
        pinSavedTimer.start();
    }

    function resetLockouts() {
        // Reset all lockout counters (this would be saved in a state file)
        Config.lock.auth.faceEnabled = true;
        Config.lock.auth.pinEnabled = true;
        Config.save();
        statusMessage = qsTr("All authentication methods have been reset");
        pinSavedTimer.start();
    }

    Timer {
        id: pinSavedTimer
        interval: 3000
        onTriggered: {
            pinSaved = false;
            statusMessage = "";
        }
    }

    StyledFlickable {
        anchors.fill: parent
        anchors.margins: Appearance.padding.large * 2
        flickableDirection: Flickable.VerticalFlick
        contentHeight: contentLayout.height

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: parent
        }

        ColumnLayout {
            id: contentLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Appearance.spacing.large

            // Header
            SettingsHeader {
                icon: "security"
                title: qsTr("Security Settings")
            }

            // PIN Configuration Section
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Appearance.rounding.normal
                implicitHeight: pinSection.implicitHeight + Appearance.padding.large * 2

                ColumnLayout {
                    id: pinSection
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "pin"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: qsTr("PIN Configuration")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 500
                        }
                    }

                    StyledText {
                        text: qsTr("Set a 4-digit PIN for quick lock screen authentication")
                        color: Colours.palette.m3outline
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // New PIN input
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("New PIN")
                            font.weight: 500
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                            radius: Appearance.rounding.small
                            implicitHeight: newPinField.implicitHeight + Appearance.padding.normal * 2

                            StyledTextField {
                                id: newPinField
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                placeholderText: qsTr("Enter 4-digit PIN")
                                echoMode: TextInput.Password
                                maximumLength: 4
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]{0,4}/
                                }
                                onTextChanged: {
                                    root.newPin = text;
                                    root.pinMismatch = false;
                                }
                            }
                        }
                    }

                    // Confirm PIN input
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacing.small

                        StyledText {
                            text: qsTr("Confirm PIN")
                            font.weight: 500
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                            radius: Appearance.rounding.small
                            implicitHeight: confirmPinField.implicitHeight + Appearance.padding.normal * 2

                            StyledTextField {
                                id: confirmPinField
                                anchors.fill: parent
                                anchors.margins: Appearance.padding.normal
                                placeholderText: qsTr("Confirm 4-digit PIN")
                                echoMode: TextInput.Password
                                maximumLength: 4
                                inputMethodHints: Qt.ImhDigitsOnly
                                validator: RegularExpressionValidator {
                                    regularExpression: /[0-9]{0,4}/
                                }
                                onTextChanged: {
                                    root.confirmPin = text;
                                    root.pinMismatch = false;
                                }
                            }
                        }
                    }

                    // Status message
                    StyledText {
                        visible: root.statusMessage !== ""
                        text: root.statusMessage
                        color: root.pinMismatch ? Colours.palette.m3error : Colours.palette.m3primary
                        font.weight: 500
                    }

                    // Save button
                    StyledRect {
                        Layout.topMargin: Appearance.spacing.normal
                        color: Colours.palette.m3primary
                        radius: Appearance.rounding.small
                        implicitWidth: savePinRow.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: savePinRow.implicitHeight + Appearance.padding.normal * 2

                        StateLayer {
                            color: Colours.palette.m3onPrimary

                            function onClicked(): void {
                                root.savePin();
                            }
                        }

                        RowLayout {
                            id: savePinRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "save"
                                color: Colours.palette.m3onPrimary
                            }

                            StyledText {
                                text: qsTr("Save PIN")
                                color: Colours.palette.m3onPrimary
                                font.weight: 500
                            }
                        }
                    }
                }
            }

            // Account Recovery Section
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Appearance.rounding.normal
                implicitHeight: recoverySection.implicitHeight + Appearance.padding.large * 2

                ColumnLayout {
                    id: recoverySection
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "lock_open"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3tertiary
                        }

                        StyledText {
                            text: qsTr("Account Recovery")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 500
                        }
                    }

                    StyledText {
                        text: qsTr("If you've been locked out due to too many failed attempts, you can reset your authentication methods here.")
                        color: Colours.palette.m3outline
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Current status
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.small

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                text: "face"
                                color: Config.lock.auth.enableFaceAuth ? Colours.palette.m3primary : Colours.palette.m3error
                            }

                            StyledText {
                                text: qsTr("Face Authentication: %1").arg(
                                    Config.lock.auth.enableFaceAuth ? qsTr("Enabled") : qsTr("Disabled")
                                )
                            }
                        }

                        RowLayout {
                            spacing: Appearance.spacing.normal

                            MaterialIcon {
                                text: "pin"
                                color: Config.lock.auth.enablePinAuth ? Colours.palette.m3primary : Colours.palette.m3error
                            }

                            StyledText {
                                text: qsTr("PIN Authentication: %1").arg(
                                    Config.lock.auth.enablePinAuth ? qsTr("Enabled") : qsTr("Disabled")
                                )
                            }
                        }
                    }

                    // Reset button
                    StyledRect {
                        Layout.topMargin: Appearance.spacing.normal
                        color: Colours.palette.m3tertiaryContainer
                        radius: Appearance.rounding.small
                        implicitWidth: resetRow.implicitWidth + Appearance.padding.large * 2
                        implicitHeight: resetRow.implicitHeight + Appearance.padding.normal * 2

                        StateLayer {
                            color: Colours.palette.m3onTertiaryContainer

                            function onClicked(): void {
                                root.resetLockouts();
                            }
                        }

                        RowLayout {
                            id: resetRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.small

                            MaterialIcon {
                                text: "restart_alt"
                                color: Colours.palette.m3onTertiaryContainer
                            }

                            StyledText {
                                text: qsTr("Reset All Authentication Methods")
                                color: Colours.palette.m3onTertiaryContainer
                                font.weight: 500
                            }
                        }
                    }
                }
            }

            // Default Auth Method Section
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Appearance.rounding.normal
                implicitHeight: defaultSection.implicitHeight + Appearance.padding.large * 2

                ColumnLayout {
                    id: defaultSection
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.large
                    spacing: Appearance.spacing.normal

                    RowLayout {
                        spacing: Appearance.spacing.normal

                        MaterialIcon {
                            text: "settings"
                            font.pointSize: Appearance.font.size.large
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            text: qsTr("Default Authentication")
                            font.pointSize: Appearance.font.size.large
                            font.weight: 500
                        }
                    }

                    StyledText {
                        text: qsTr("Choose which authentication method to show first on the lock screen")
                        color: Colours.palette.m3outline
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }

                    // Method buttons
                    RowLayout {
                        Layout.topMargin: Appearance.spacing.normal
                        spacing: Appearance.spacing.normal

                        Repeater {
                            model: [
                                { id: "face", icon: "face", label: qsTr("Face") },
                                { id: "pin", icon: "pin", label: qsTr("PIN") },
                                { id: "password", icon: "password", label: qsTr("Password") }
                            ]

                            StyledRect {
                                required property var modelData

                                readonly property bool isSelected: Config.lock.auth.defaultMethod === modelData.id

                                color: isSelected ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                radius: Appearance.rounding.small
                                implicitWidth: methodContent.implicitWidth + Appearance.padding.large * 2
                                implicitHeight: methodContent.implicitHeight + Appearance.padding.normal * 2

                                StateLayer {
                                    color: isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                                    function onClicked(): void {
                                        Config.lock.auth.defaultMethod = modelData.id;
                                        Config.save();
                                    }
                                }

                                RowLayout {
                                    id: methodContent
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacing.small

                                    MaterialIcon {
                                        text: modelData.icon
                                        color: isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                    }

                                    StyledText {
                                        text: modelData.label
                                        color: isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                        font.weight: isSelected ? 600 : 400
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Spacer
            Item {
                Layout.fillHeight: true
            }
        }
    }
}
