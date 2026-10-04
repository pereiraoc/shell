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

    readonly property var periph: periphBridge.info

    function periphRun(id: string): void {
        periphBridge.run({ id: id });
    }

    // "Static" -> "static", "Spectrum Cycle" -> "spectrum-cycle" (ids do CLI)
    function modeSlug(mode: string): string {
        return (mode ?? "").toLowerCase().replace(/[^a-z0-9]+/g, "-");
    }

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

    // Configuracoes de cada periferico: mouse Razer (openrazer), luz RGB
    // (OpenRGB), luz do teclado do notebook (asusctl) -- caelestia-peripherals.
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

        // Mouses Razer: DPI, polling, tempo para dormir
        Repeater {
            model: root.periph.mice ?? []

            ColumnLayout {
                id: mouse

                required property var modelData

                readonly property var stages: {
                    const st = [...(mouse.modelData.dpi_stages ?? [])];
                    if (mouse.modelData.dpi && !st.includes(mouse.modelData.dpi))
                        st.push(mouse.modelData.dpi);
                    return st.sort((a, b) => a - b);
                }

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: mouse.modelData.name.replace(/\s*\(Receiver\)$/, "")
                }

                ChipSelectRow {
                    first: true
                    label: qsTr("Sensitivity (DPI)")
                    subtext: qsTr("Set in the mouse itself — the same in every app and game. The DPI button on the mouse cycles these stages.")
                    options: mouse.stages.map(d => ({ value: String(d), label: d >= 1000 ? `${d / 1000}k` : String(d) }))
                    current: String(mouse.modelData.dpi ?? "")
                    busy: periphBridge.busyAction.startsWith(`dpi-${mouse.modelData.id}-`)
                    onPicked: v => root.periphRun(`dpi-${mouse.modelData.id}-${v}`)
                }

                ChipSelectRow {
                    visible: mouse.modelData.poll_rate != null
                    label: qsTr("Polling rate")
                    subtext: qsTr("Higher is smoother and more responsive, and uses more battery")
                    options: (mouse.modelData.poll_choices ?? []).map(h => ({ value: String(h), label: `${h} Hz` }))
                    current: String(mouse.modelData.poll_rate ?? "")
                    busy: periphBridge.busyAction.startsWith(`poll-${mouse.modelData.id}-`)
                    onPicked: v => root.periphRun(`poll-${mouse.modelData.id}-${v}`)
                }

                ChipSelectRow {
                    last: true
                    visible: mouse.modelData.idle_s != null
                    label: qsTr("Sleep after")
                    subtext: qsTr("Turns the mouse off when you stop using it, to save battery")
                    options: [60, 300, 600, 900].map(s => ({ value: String(s), label: qsTr("%1 min").arg(s / 60) }))
                    current: String(mouse.modelData.idle_s ?? "")
                    busy: periphBridge.busyAction.startsWith(`idle-${mouse.modelData.id}-`)
                    onPicked: v => root.periphRun(`idle-${mouse.modelData.id}-${v}`)
                }
            }
        }

        // Luz RGB (teclado externo etc.)
        Repeater {
            model: root.periph.rgb ?? []

            ColumnLayout {
                id: rgb

                required property var modelData

                readonly property var known: [
                    { mode: "Static", value: "static", label: qsTr("Theme colour"), icon: "palette" },
                    { mode: "Breathing", value: "breathing", label: qsTr("Breathing"), icon: "air" },
                    { mode: "Reactive", value: "reactive", label: qsTr("On key press"), icon: "touch_app" },
                    { mode: "Spectrum Cycle", value: "spectrum-cycle", label: qsTr("Cycle"), icon: "autorenew" },
                    { mode: "Rainbow Wave", value: "rainbow-wave", label: qsTr("Rainbow"), icon: "gradient" }
                ]
                readonly property var options: [{ value: "off", label: qsTr("Off"), icon: "light_off" }, ...rgb.known.filter(k => rgb.modelData.modes.includes(k.mode))]

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: rgb.modelData.name.replace(/\s*2\.4GHz$/, "")
                }

                ChipSelectRow {
                    first: true
                    last: true
                    label: qsTr("Lighting")
                    subtext: root.periph.theme_colour ? qsTr("Theme colour, breathing and key press use the current theme's accent (#%1)").arg(root.periph.theme_colour) : ""
                    options: rgb.options
                    current: root.modeSlug(rgb.modelData.mode)
                    busy: periphBridge.busyAction.startsWith(`rgb-${rgb.modelData.id}-`)
                    onPicked: v => root.periphRun(`rgb-${rgb.modelData.id}-${v}`)
                }
            }
        }

        ActionErrorRow {
            bridge: periphBridge
        }

        // Teclado
        SectionHeader {
            visible: !!root.input.keyboard
            text: qsTr("Keyboard")
        }

        ChipSelectRow {
            first: true
            visible: root.periph.laptop_keyboard?.available === true
            label: qsTr("Laptop keyboard light")
            options: [
                { value: "off", label: qsTr("Off"), icon: "light_off" },
                { value: "low", label: qsTr("Low") },
                { value: "med", label: qsTr("Medium") },
                { value: "high", label: qsTr("High") }
            ]
            current: root.periph.laptop_keyboard?.brightness ?? ""
            busy: periphBridge.busyAction.startsWith("kbd-")
            onPicked: v => root.periphRun(`kbd-${v}`)
        }

        RowButton {
            first: root.periph.laptop_keyboard?.available !== true
            visible: root.input.persisted === false
            icon: "save"
            iconLabel.color: Colours.palette.m3tertiary
            text: qsTr("Keep keyboard and mouse settings after a restart")
            subtext: qsTr("One-time setup: lets these settings survive reloading Hyprland")
            disabled: inputBridge.busyAction !== ""
            onClicked: root.inputRun("setup")
        }

        ExpandSelectRow {
            first: root.input.persisted !== false && root.periph.laptop_keyboard?.available !== true
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
            subtext: qsTr("Multiplies the speed of every mouse and the touchpad, instantly. Gaming mice also have their own DPI in hardware — change that under Advanced › Razer devices.")
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

        ActionErrorRow {
            bridge: inputBridge
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

        AdvancedGroup {
            apps: [
                { id: "app.polychromatic.controller", alt: ["polychromatic"], text: qsTr("Razer devices"), subtext: qsTr("Buttons, DPI and lighting (Polychromatic)") },
                { id: "org.openrgb.OpenRGB", alt: ["openrgb"], text: qsTr("RGB lighting"), subtext: qsTr("Keyboard and peripheral lighting (OpenRGB)") },
                { id: "org.freedesktop.Piper", text: qsTr("Gaming mouse"), subtext: qsTr("Buttons and DPI profiles (Piper)") },
                { id: "qcam", text: qsTr("Camera viewer"), subtext: qsTr("Preview a camera (qcam)") }
            ]
        }
    }
}
