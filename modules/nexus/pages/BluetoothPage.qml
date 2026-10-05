pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common


// Bluetooth (Nexus > Bluetooth): adaptador, aparelhos salvos, parear;
// baterias sem pagina propria; compartilhar arquivos.
PageBase {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool btEnabled: adapter?.enabled ?? false

    readonly property var periph: periphBridge.info
    readonly property var peripherals: batteryBridge.info.devices ?? []
    // Baterias de teclado/mouse com pagina propria ficam la (Keyboard/Mouse);
    // aqui o resto (UPower etc.).
    readonly property bool kbHasPage: (root.periph.rgb ?? []).some(d => d.type === "Keyboard" && d.backend !== "asusd")
    readonly property bool mouseHasPage: (root.periph.mice ?? []).length > 0
    readonly property var otherBatteries: root.peripherals.filter(b => !(b.kind === "keyboard" && root.kbHasPage) && !(b.kind === "mouse" && root.mouseHasPage))

    function batteryText(b: var): string {
        return b.charging ? qsTr("Charging") : b.stale ? qsTr("Last known level — the device is asleep") : "";
    }


    title: qsTr("Bluetooth")
    description: qsTr("Devices, pairing, batteries, sharing")

    ToolBridge {
        id: periphBridge

        tool: "peripherals"
    }

    ToolBridge {
        id: batteryBridge

        tool: "peripheral-battery"

        Timer {
            interval: 60000
            repeat: true
            running: root.visible
            onTriggered: batteryBridge.refresh()
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Bluetooth")
        }

        ToggleRow {
            first: true
            text: qsTr("Bluetooth")
            font: Tokens.font.body.medium
            horizontalPadding: Tokens.padding.largeIncreased
            checked: root.btEnabled
            onToggled: {
                if (root.adapter)
                    root.adapter.enabled = checked;
            }
        }

        ItemList {
            id: savedList

            showList: root.btEnabled
            placeholderIcon: root.btEnabled ? "devices_other" : "bluetooth_disabled"
            placeholderText: root.btEnabled ? qsTr("No saved devices") : qsTr("Bluetooth disabled")

            model: ScriptModel {
                values: Bluetooth.devices.values.filter(d => d.bonded).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name)) // qmllint disable unresolved-type
            }

            delegate: StyledRect {
                id: device

                required property BluetoothDevice modelData
                readonly property bool connected: modelData && modelData.state === BluetoothDeviceState.Connected // qmllint disable unresolved-type
                readonly property bool loading: modelData && (modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting) // qmllint disable unresolved-type
                property real textOpacity: loading ? 0.5 : 1

                anchors.left: savedList.list.contentItem.left
                anchors.right: savedList.list.contentItem.right
                implicitHeight: deviceLayout.implicitHeight + deviceLayout.anchors.margins * 2
                radius: Tokens.rounding.extraSmall
                color: "transparent"

                Behavior on textOpacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                StateLayer {
                    disabled: device.loading
                    onClicked: {
                        if (!device.modelData || device.loading)
                            return;
                        device.modelData.connected = !device.connected;
                    }
                }

                RowLayout {
                    id: deviceLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: implicitHeight
                        implicitHeight: deviceIcon.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: device.connected ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            id: deviceIcon

                            anchors.centerIn: parent
                            text: Icons.getBluetoothIcon(device.modelData?.icon ?? "")
                            color: device.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.medium
                            fill: device.connected ? 1 : 0
                            opacity: device.textOpacity

                            Behavior on fill {
                                Anim {}
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        opacity: device.textOpacity

                        StyledText {
                            Layout.fillWidth: true
                            text: device.modelData?.name ?? qsTr("Unknown")
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: device.connected ? qsTr("Connected%1").arg(device.modelData?.batteryAvailable ? " • " + Math.round(device.modelData.battery * 100) + "%" : "") : qsTr("Saved")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            animate: true
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        implicitWidth: height

                        AnimLoader {
                            anchors.centerIn: parent
                            sourceComp: device.loading ? loadingComp : btnComp

                            Component {
                                id: btnComp

                                IconButton {
                                    icon: "settings"
                                    type: IconButton.Text
                                    padding: Tokens.padding.small
                                    inactiveOnColour: device.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                    label.fill: 0

                                    onClicked: {
                                        root.nState.selectedBtDevice = device.modelData;
                                        root.nState.openSubPage(1); // Per device info page
                                    }
                                }
                            }

                            Component {
                                id: loadingComp

                                LoadingIndicator {
                                    implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.3)
                                }
                            }
                        }
                    }
                }
            }
        }

        RowButton {
            last: true
            icon: "add"
            text: qsTr("Pair new device")
            disabled: !root.btEnabled
            onClicked: root.nState.openSubPage(2)
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing

            first: true
            text: qsTr("Discoverable")
            subtext: qsTr("Allow nearby devices to find this one")
            disabled: !root.btEnabled
            checked: root.adapter?.discoverable ?? false
            onToggled: {
                if (root.adapter)
                    root.adapter.discoverable = checked;
            }

            Behavior on opacity {
                Anim {}
            }
        }

        ToggleRow {
            last: true
            text: qsTr("Pairable")
            subtext: qsTr("Allow nearby devices to pair with this one")
            disabled: !root.btEnabled
            checked: root.adapter?.pairable ?? false
            onToggled: {
                if (root.adapter)
                    root.adapter.pairable = checked;
            }

            Behavior on opacity {
                Anim {}
            }
        }

        // Baterias sem secao propria (UPower etc.)
        SectionHeader {
            visible: root.otherBatteries.length > 0
            text: qsTr("Other batteries")
        }

        Repeater {
            model: root.otherBatteries

            MeterRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.otherBatteries.length - 1
                icon: modelData.kind === "keyboard" ? "keyboard" : modelData.kind === "mouse" ? "mouse" : modelData.kind === "headset" ? "headphones" : "battery_full"
                label: modelData.name
                valueText: `${Math.round(modelData.pct * 100)}%`
                value: modelData.pct
                warnAt: 0.2
                warnBelow: true
                subtext: root.batteryText(modelData)
            }
        }

        // Compartilhar arquivos (estava na antiga System apps). LocalSend nao
        // tem CLI; e a linha que abre o app, e o Snapdrop abre no navegador.
        SectionHeader {
            text: qsTr("Sharing")
        }

        RowButton {
            first: true
            readonly property var entry: {
                DesktopEntries.applications.values;
                return DesktopEntries.byId("localsend") ?? DesktopEntries.byId("localsend_app");
            }

            visible: !!entry
            icon: "send_to_mobile"
            text: qsTr("Send or receive files nearby")
            subtext: qsTr("Phones and computers on this network, no cable or account (LocalSend)")
            trailingIcon: "open_in_new"
            onClicked: entry?.execute()
        }

        RowButton {
            last: true
            icon: "language"
            text: qsTr("Share through the browser")
            subtext: qsTr("For a device without LocalSend: open Snapdrop on both")
            trailingIcon: "open_in_new"
            onClicked: Quickshell.execDetached(["xdg-open", "https://snapdrop.net"])
        }

    }
}
