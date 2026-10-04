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

PageBase {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter // qmllint disable unresolved-type
    readonly property bool btEnabled: adapter?.enabled ?? false

    readonly property var input: inputBridge.info
    readonly property var kb: root.input.keyboard ?? ({})
    readonly property var pointer: root.input.pointer ?? ({})
    readonly property var peripherals: batteryBridge.info.devices ?? []

    function inputRun(id: string): void {
        inputBridge.run({ id: id });
    }

    title: qsTr("Devices")
    description: qsTr("Bluetooth, batteries, keyboard, mouse and cameras")

    // Entrada (teclado/mouse/cameras) pelo caelestia-input; baterias de
    // perifericos que o UPower nao ve pelo caelestia-peripheral-battery.
    ToolBridge {
        id: inputBridge

        tool: "input"
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

        // Baterias de perifericos (Razer, Azoth) + UPower
        SectionHeader {
            visible: root.peripherals.length > 0
            text: qsTr("Peripheral batteries")
        }

        Repeater {
            model: root.peripherals

            MeterRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.peripherals.length - 1
                icon: modelData.kind === "keyboard" ? "keyboard" : modelData.kind === "mouse" ? "mouse" : modelData.kind === "headset" ? "headphones" : "battery_full"
                label: modelData.name
                valueText: `${Math.round(modelData.pct * 100)}%`
                value: modelData.pct
                warnAt: 0.2
                warnBelow: true
                subtext: modelData.charging ? qsTr("Charging") : modelData.stale ? qsTr("Last known level — the device is asleep") : ""
            }
        }

        // Teclado
        SectionHeader {
            visible: !!root.input.keyboard
            text: qsTr("Keyboard")
        }

        RowButton {
            first: true
            visible: root.input.persisted === false
            icon: "save"
            iconLabel.color: Colours.palette.m3tertiary
            text: qsTr("Keep keyboard and mouse settings after a restart")
            subtext: qsTr("One-time setup: lets these settings survive reloading Hyprland")
            disabled: inputBridge.busyAction !== ""
            onClicked: root.inputRun("setup")
        }

        ExpandSelectRow {
            first: root.input.persisted !== false
            visible: !!root.input.keyboard
            icon: "keyboard"
            label: qsTr("Layout")
            subtext: root.kb.variant ? qsTr("Variant: %1").arg(root.kb.variant) : ""
            options: [
                { value: "us", label: qsTr("English (US)") },
                { value: "br", label: qsTr("Portuguese (Brazil, ABNT2)") },
                { value: "us,br", label: qsTr("Both — switch with the layout key") }
            ]
            current: root.kb.layout ?? ""
            busy: inputBridge.busyAction.startsWith("layout-")
            onPicked: v => root.inputRun(`layout-${v}`)
        }

        ChipSelectRow {
            last: true
            visible: !!root.input.keyboard
            label: qsTr("Key repeat")
            subtext: qsTr("How fast a held key repeats. Now: %1 per second after %2 ms").arg(root.kb.repeat_rate ?? "?").arg(root.kb.repeat_delay ?? "?")
            options: [
                { value: "20-600", label: qsTr("Slow") },
                { value: "25-400", label: qsTr("Default") },
                { value: "35-300", label: qsTr("Fast") }
            ]
            current: `${root.kb.repeat_rate}-${root.kb.repeat_delay}`
            busy: inputBridge.busyAction.startsWith("repeat-")
            onPicked: v => root.inputRun(`repeat-${v}`)
        }

        // Mouse e touchpad
        SectionHeader {
            visible: !!root.input.pointer
            text: qsTr("Mouse & touchpad")
        }

        ChipSelectRow {
            first: true
            visible: !!root.input.pointer
            label: qsTr("Pointer speed")
            subtext: qsTr("Applies to every mouse and the touchpad")
            options: [
                { value: "-0.5", label: qsTr("Slower") },
                { value: "-0.25", label: qsTr("Slow") },
                { value: "0", label: qsTr("Default") },
                { value: "0.25", label: qsTr("Fast") },
                { value: "0.5", label: qsTr("Faster") }
            ]
            current: String(Number(root.pointer.sensitivity ?? 0))
            busy: inputBridge.busyAction.startsWith("sensitivity-")
            onPicked: v => root.inputRun(`sensitivity-${v}`)
        }

        ToggleRow {
            last: !root.input.touchpad?.present
            visible: !!root.input.pointer
            text: qsTr("Mouse acceleration")
            subtext: qsTr("Off is better for games: the pointer moves the same distance at any speed")
            checked: root.pointer.accel_profile !== "flat"
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "accel-adaptive" : "accel-flat")
        }

        ToggleRow {
            last: true
            visible: !!root.input.touchpad?.present
            text: qsTr("Natural scrolling (touchpad)")
            subtext: qsTr("Content follows your fingers, like a phone")
            checked: !!root.pointer.natural_scroll_touchpad
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "natural-scroll-on" : "natural-scroll-off")
        }

        // Cameras
        SectionHeader {
            visible: (root.input.cameras ?? []).length > 0
            text: qsTr("Cameras")
        }

        Repeater {
            model: root.input.cameras ?? []

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === (root.input.cameras ?? []).length - 1
                icon: modelData.ir ? "face" : "videocam"
                text: modelData.ir ? qsTr("Infrared camera") : qsTr("Webcam")
                subtext: modelData.face_unlock ? qsTr("%1 · used by face unlock").arg(modelData.node) : `${modelData.node} · ${modelData.name}`
                trailingIcon: modelData.face_unlock ? "chevron_right" : ""
                onClicked: {
                    if (modelData.face_unlock)
                        root.nState.openPage("security", 0);
                }
            }
        }

        SectionHeader {
            text: qsTr("Advanced")
        }

        AdvancedAppRow {
            first: true
            desktopId: "app.polychromatic.controller"
            altIds: ["polychromatic"]
            text: qsTr("Razer devices")
            subtext: qsTr("Buttons, DPI and lighting (Polychromatic)")
        }

        AdvancedAppRow {
            desktopId: "org.openrgb.OpenRGB"
            altIds: ["openrgb"]
            text: qsTr("RGB lighting")
            subtext: qsTr("Keyboard and peripheral lighting (OpenRGB)")
        }

        AdvancedAppRow {
            desktopId: "org.freedesktop.Piper"
            text: qsTr("Gaming mouse")
            subtext: qsTr("Buttons and DPI profiles (Piper)")
        }

        AdvancedAppRow {
            last: true
            desktopId: "qcam"
            text: qsTr("Camera viewer")
            subtext: qsTr("Preview a camera (qcam)")
        }
    }
}
