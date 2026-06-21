pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Security")

    property string newPin: ""
    property string confirmPin: ""
    property bool pinError: false
    property string statusMessage: ""

    // Salt do PIN — DEVE bater com modules/lock/Pam.qml
    readonly property string pinSalt: "caelestia-lock-2026"

    readonly property list<MenuItem> methodItems: [
        MenuItem {
            text: qsTr("Face")
        },
        MenuItem {
            text: qsTr("PIN")
        },
        MenuItem {
            text: qsTr("Password")
        }
    ]
    readonly property list<string> methodValues: ["face", "pin", "password"]

    function hashPin(pin: string): string {
        return Qt.md5(pinSalt + pin + pinSalt);
    }

    function savePin(): void {
        if (root.newPin.length !== 4) {
            root.statusMessage = qsTr("PIN must be exactly 4 digits");
            root.pinError = true;
            return;
        }
        if (root.newPin !== root.confirmPin) {
            root.statusMessage = qsTr("PINs do not match");
            root.pinError = true;
            return;
        }
        GlobalConfig.lock.userPin = root.hashPin(root.newPin); // plugin C++ persiste com debounce
        root.pinError = false;
        root.statusMessage = qsTr("PIN saved");
        root.newPin = "";
        root.confirmPin = "";
        newPinField.clear();
        confirmPinField.clear();
        statusTimer.restart();
    }

    function resetLockouts(): void {
        GlobalConfig.lock.enableFaceAuth = true;
        GlobalConfig.lock.enablePinAuth = true;
        root.pinError = false;
        root.statusMessage = qsTr("Authentication methods reset");
        statusTimer.restart();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Timer {
            id: statusTimer

            interval: 3000
            onTriggered: root.statusMessage = ""
        }

        // Methods
        SectionHeader {
            first: true
            text: qsTr("Methods")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Face authentication")
            subtext: qsTr("Unlock with Howdy face recognition")
            checked: Config.lock.enableFaceAuth
            onToggled: GlobalConfig.lock.enableFaceAuth = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            text: qsTr("PIN authentication")
            subtext: qsTr("Unlock with a 4-digit PIN")
            checked: Config.lock.enablePinAuth
            onToggled: GlobalConfig.lock.enablePinAuth = checked
        }

        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Default method")
            subtext: qsTr("Method shown first on the lock screen")
            menuItems: root.methodItems
            active: root.methodItems[Math.max(0, root.methodValues.indexOf(Config.lock.defaultMethod))]
            onSelected: item => GlobalConfig.lock.defaultMethod = root.methodValues[root.methodItems.indexOf(item)]
        }

        // Lock screen
        SectionHeader {
            text: qsTr("Lock screen")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: qsTr("Hide notifications")
            subtext: qsTr("Don't show notification content on the lock screen")
            checked: Config.lock.hideNotifs
            onToggled: GlobalConfig.lock.hideNotifs = checked
        }

        // PIN
        SectionHeader {
            text: qsTr("PIN")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: newPinLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: newPinLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("New PIN")
                    font: Tokens.font.body.small
                }

                StyledTextField {
                    id: newPinField

                    Layout.preferredWidth: 120
                    placeholderText: qsTr("4 digits")
                    echoMode: TextInput.Password
                    maximumLength: 4
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: RegularExpressionValidator {
                        regularExpression: /[0-9]{0,4}/
                    }
                    onTextChanged: {
                        root.newPin = text;
                        root.pinError = false;
                    }
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            implicitHeight: confirmPinLayout.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: confirmPinLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Confirm PIN")
                    font: Tokens.font.body.small
                }

                StyledTextField {
                    id: confirmPinField

                    Layout.preferredWidth: 120
                    placeholderText: qsTr("4 digits")
                    echoMode: TextInput.Password
                    maximumLength: 4
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: RegularExpressionValidator {
                        regularExpression: /[0-9]{0,4}/
                    }
                    onTextChanged: {
                        root.confirmPin = text;
                        root.pinError = false;
                    }
                }
            }
        }

        NavRow {
            Layout.fillWidth: true
            last: true
            icon: "save"
            label: qsTr("Save PIN")
            status: root.statusMessage
            onClicked: root.savePin()
        }

        // Recovery
        SectionHeader {
            text: qsTr("Recovery")
        }

        NavRow {
            Layout.fillWidth: true
            first: true
            last: true
            icon: "restart_alt"
            label: qsTr("Reset authentication methods")
            status: qsTr("Re-enable face and PIN if locked out")
            onClicked: root.resetLockouts()
        }
    }
}
