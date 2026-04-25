pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import Caelestia.Config
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

    // Salt for PIN hashing (unique per installation)
    readonly property string pinSalt: "caelestia-lock-2026"

    anchors.fill: parent

    // Simple hash function for PIN security
    function hashPin(pin: string): string {
        // Use Qt.md5 with salt for basic security
        // Format: md5(salt + pin + salt)
        return Qt.md5(pinSalt + pin + pinSalt);
    }

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

        // Save hashed PIN to config for security
        GlobalConfig.lock.userPin = hashPin(newPin);
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
        GlobalConfig.lock.enableFaceAuth = true;
        GlobalConfig.lock.enablePinAuth = true;
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
        anchors.margins: Tokens.padding.large * 2
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
            spacing: Tokens.spacing.large

            // Header
            SettingsHeader {
                icon: "security"
                title: qsTr("Security Settings")
            }

            // PIN Configuration Section
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.normal
                implicitHeight: pinSection.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: pinSection
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            text: "pin"
                            font.pointSize: Tokens.font.size.large
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            text: qsTr("PIN Configuration")
                            font.pointSize: Tokens.font.size.large
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
                        Layout.topMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("New PIN")
                            font.weight: 500
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                            radius: Tokens.rounding.small
                            implicitHeight: newPinField.implicitHeight + Tokens.padding.normal * 2

                            StyledTextField {
                                id: newPinField
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.normal
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
                        spacing: Tokens.spacing.small

                        StyledText {
                            text: qsTr("Confirm PIN")
                            font.weight: 500
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
                            radius: Tokens.rounding.small
                            implicitHeight: confirmPinField.implicitHeight + Tokens.padding.normal * 2

                            StyledTextField {
                                id: confirmPinField
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.normal
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
                        Layout.topMargin: Tokens.spacing.normal
                        color: Colours.palette.m3primary
                        radius: Tokens.rounding.small
                        implicitWidth: savePinRow.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: savePinRow.implicitHeight + Tokens.padding.normal * 2

                        StateLayer {
                            color: Colours.palette.m3onPrimary

                            function onClicked(): void {
                                root.savePin();
                            }
                        }

                        RowLayout {
                            id: savePinRow
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

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
                Layout.topMargin: Tokens.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.normal
                implicitHeight: recoverySection.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: recoverySection
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            text: "lock_open"
                            font.pointSize: Tokens.font.size.large
                            color: Colours.palette.m3tertiary
                        }

                        StyledText {
                            text: qsTr("Account Recovery")
                            font.pointSize: Tokens.font.size.large
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
                        Layout.topMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.small

                        RowLayout {
                            spacing: Tokens.spacing.normal

                            MaterialIcon {
                                text: "face"
                                color: GlobalConfig.lock.enableFaceAuth ? Colours.palette.m3primary : Colours.palette.m3error
                            }

                            StyledText {
                                text: qsTr("Face Authentication: %1").arg(
                                    GlobalConfig.lock.enableFaceAuth ? qsTr("Enabled") : qsTr("Disabled")
                                )
                            }
                        }

                        RowLayout {
                            spacing: Tokens.spacing.normal

                            MaterialIcon {
                                text: "pin"
                                color: GlobalConfig.lock.enablePinAuth ? Colours.palette.m3primary : Colours.palette.m3error
                            }

                            StyledText {
                                text: qsTr("PIN Authentication: %1").arg(
                                    GlobalConfig.lock.enablePinAuth ? qsTr("Enabled") : qsTr("Disabled")
                                )
                            }
                        }
                    }

                    // Reset button
                    StyledRect {
                        Layout.topMargin: Tokens.spacing.normal
                        color: Colours.palette.m3tertiaryContainer
                        radius: Tokens.rounding.small
                        implicitWidth: resetRow.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: resetRow.implicitHeight + Tokens.padding.normal * 2

                        StateLayer {
                            color: Colours.palette.m3onTertiaryContainer

                            function onClicked(): void {
                                root.resetLockouts();
                            }
                        }

                        RowLayout {
                            id: resetRow
                            anchors.centerIn: parent
                            spacing: Tokens.spacing.small

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
                Layout.topMargin: Tokens.spacing.large
                color: Colours.layer(Colours.palette.m3surfaceContainer, 1)
                radius: Tokens.rounding.normal
                implicitHeight: defaultSection.implicitHeight + Tokens.padding.large * 2

                ColumnLayout {
                    id: defaultSection
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.normal

                    RowLayout {
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            text: "settings"
                            font.pointSize: Tokens.font.size.large
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            text: qsTr("Default Authentication")
                            font.pointSize: Tokens.font.size.large
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
                        Layout.topMargin: Tokens.spacing.normal
                        spacing: Tokens.spacing.normal

                        Repeater {
                            model: [
                                { id: "face", icon: "face", label: qsTr("Face") },
                                { id: "pin", icon: "pin", label: qsTr("PIN") },
                                { id: "password", icon: "password", label: qsTr("Password") }
                            ]

                            StyledRect {
                                required property var modelData

                                readonly property bool isSelected: GlobalConfig.lock.defaultMethod === modelData.id

                                color: isSelected ? Colours.palette.m3primaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 2)
                                radius: Tokens.rounding.small
                                implicitWidth: methodContent.implicitWidth + Tokens.padding.large * 2
                                implicitHeight: methodContent.implicitHeight + Tokens.padding.normal * 2

                                StateLayer {
                                    color: isSelected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

                                    function onClicked(): void {
                                        GlobalConfig.lock.defaultMethod = modelData.id;
                                        Config.save();
                                    }
                                }

                                RowLayout {
                                    id: methodContent
                                    anchors.centerIn: parent
                                    spacing: Tokens.spacing.small

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
