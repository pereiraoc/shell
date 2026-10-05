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

    // Luzes: a do notebook (asusd) vai em Keyboard > Laptop keyboard; teclados
    // externos ganham subsecao propria; o resto fica em "Lighting".
    readonly property var laptopRgb: (root.periph.rgb ?? []).find(d => d.backend === "asusd") ?? null
    readonly property var keyboards: (root.periph.rgb ?? []).filter(d => d.type === "Keyboard" && d.backend !== "asusd")
    readonly property var otherRgb: (root.periph.rgb ?? []).filter(d => d.type !== "Keyboard")

    // Bateria de cada periferico vai na secao DELE (teclado RGB <- bateria de
    // teclado, mouse Razer <- bateria de mouse); o que sobrar fica em "Other
    // batteries".
    readonly property var kbBattery: root.keyboards.length > 0 ? (root.peripherals.find(b => b.kind === "keyboard") ?? null) : null
    readonly property var mouseBattery: (root.periph.mice ?? []).length > 0 ? (root.peripherals.find(b => b.kind === "mouse") ?? null) : null
    readonly property var otherBatteries: root.peripherals.filter(b => b !== root.kbBattery && b !== root.mouseBattery)

    readonly property var scrollOptions: [
        { value: "0.5", label: qsTr("Slow") },
        { value: "1", label: qsTr("Default") },
        { value: "1.5", label: qsTr("Fast") },
        { value: "2", label: qsTr("Faster") }
    ]

    // 1.0 -> "1", 1.5 -> "1.5" (o valor dos chips)
    function num(v: var): string {
        return String(Number(v ?? 1));
    }

    function mouseName(n: string): string {
        return (n ?? "").replace(/\s*\(.*?\)\s*$/, "");
    }

    function isOff(s: var): bool {
        return s?.mode === "Static" && (s?.colors ?? [])[0] === "000000";
    }

    function lightingText(s: var): string {
        if (!s)
            return qsTr("Effect, colours, brightness and speed");
        if (root.isOff(s))
            return qsTr("Off");
        return [s.mode, s.random ? qsTr("random colours") : (s.colors ?? []).map(c => `#${c}`).join(" "), s.brightness !== null && s.brightness !== undefined ? qsTr("%1% brightness").arg(s.brightness) : ""].filter(x => x).join(" · ");
    }

    function openLighting(id: string): void {
        root.nState.selectedRgbDevice = id;
        root.nState.openSubPage(3);
    }

    function batteryText(b: var): string {
        return b.charging ? qsTr("Charging") : b.stale ? qsTr("Last known level — the device is asleep") : "";
    }

    function periphRun(id: string): void {
        periphBridge.run({ id: id });
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

        // ---------------------------------------------------------- Keyboard
        // Geral (vale para qualquer teclado) e, embaixo, cada teclado.
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

        // Teclado do notebook: brilho (asusctl) + efeito (asusd)
        SubsectionHeader {
            visible: root.periph.laptop_keyboard?.available === true || !!root.laptopRgb
            icon: "laptop"
            text: qsTr("Laptop keyboard")
        }

        ChipSelectRow {
            first: true
            last: !root.laptopRgb
            visible: root.periph.laptop_keyboard?.available === true
            label: qsTr("Backlight")
            subtext: qsTr("Fn + F2 / F3 on the laptop change this too")
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
            last: true
            visible: !!root.laptopRgb
            icon: root.isOff(root.laptopRgb?.settings) ? "light_off" : "palette"
            text: qsTr("Lighting")
            subtext: root.lightingText(root.laptopRgb?.settings)
            trailingIcon: "chevron_right"
            onClicked: root.openLighting(root.laptopRgb.id)
        }

        // Teclados externos com luz (Azoth...): bateria + iluminacao
        Repeater {
            model: root.keyboards

            ColumnLayout {
                id: kbd

                required property var modelData
                required property int index

                readonly property var battery: kbd.index === 0 ? root.kbBattery : null

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SubsectionHeader {
                    icon: "keyboard"
                    text: kbd.modelData.name.replace(/\s*(2\.4GHz|USB)$/, "")
                    status: kbd.battery ? (kbd.battery.stale ? qsTr("Asleep · %1%") : "%1%").arg(Math.round(kbd.battery.pct * 100)) : ""
                    warn: !!kbd.battery && kbd.battery.pct < 0.2
                }

                MeterRow {
                    first: true
                    visible: !!kbd.battery
                    icon: "battery_full"
                    label: qsTr("Battery")
                    valueText: kbd.battery ? `${Math.round(kbd.battery.pct * 100)}%` : ""
                    value: kbd.battery?.pct ?? 0
                    warnAt: 0.2
                    warnBelow: true
                    subtext: kbd.battery ? root.batteryText(kbd.battery) : ""
                }

                RowButton {
                    first: !kbd.battery
                    last: true
                    icon: root.isOff(kbd.modelData.settings) ? "light_off" : "palette"
                    text: qsTr("Lighting")
                    subtext: root.lightingText(kbd.modelData.settings)
                    trailingIcon: "chevron_right"
                    onClicked: root.openLighting(kbd.modelData.id)
                }
            }
        }

        ActionErrorRow {
            bridge: periphBridge
        }

        // ------------------------------------------------------------- Mouse
        SectionHeader {
            visible: !!root.input.pointer
            text: qsTr("Mouse")
        }

        ChipSelectRow {
            first: true
            visible: !!root.input.pointer
            label: qsTr("Pointer speed")
            subtext: qsTr("Multiplies the speed of every mouse and the touchpad, instantly. Gaming mice also have their own DPI in hardware — set it in the mouse's section below.")
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
            visible: !!root.input.pointer
            text: qsTr("Mouse acceleration")
            subtext: qsTr("Off is better for games: the pointer moves the same distance at any speed")
            checked: root.pointer.accel_profile !== "flat"
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "accel-adaptive" : "accel-flat")
        }

        ChipSelectRow {
            visible: !!root.input.pointer
            label: qsTr("Scroll speed")
            subtext: qsTr("How far one notch of the wheel scrolls")
            options: root.scrollOptions
            current: root.num(root.pointer.scroll_factor)
            busy: inputBridge.busyAction.startsWith("scroll-")
            onPicked: v => root.inputRun(`scroll-${v}`)
        }

        ToggleRow {
            visible: !!root.input.pointer
            text: qsTr("Natural scrolling")
            subtext: qsTr("The wheel moves the content instead of the view")
            checked: !!root.pointer.natural_scroll
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "mouse-natural-on" : "mouse-natural-off")
        }

        ToggleRow {
            last: true
            visible: !!root.input.pointer
            text: qsTr("Left-handed")
            subtext: qsTr("Swaps the left and right buttons")
            checked: !!root.pointer.left_handed
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "left-handed-on" : "left-handed-off")
        }

        // Touchpad
        SubsectionHeader {
            visible: !!root.input.touchpad?.present
            icon: "touchpad_mouse"
            text: qsTr("Touchpad")
        }

        ToggleRow {
            first: true
            visible: !!root.input.touchpad?.present
            text: qsTr("Tap to click")
            subtext: qsTr("A light tap counts as a click")
            checked: !!root.input.touchpad?.tap_to_click
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "tap-on" : "tap-off")
        }

        ToggleRow {
            visible: !!root.input.touchpad?.present
            text: qsTr("Natural scrolling")
            subtext: qsTr("Content follows your fingers, like a phone")
            checked: !!root.input.touchpad?.natural_scroll
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "natural-scroll-on" : "natural-scroll-off")
        }

        ToggleRow {
            visible: !!root.input.touchpad?.present
            text: qsTr("Ignore while typing")
            subtext: qsTr("Stops a palm on the touchpad from moving the cursor")
            checked: !!root.input.touchpad?.disable_while_typing
            disabled: inputBridge.busyAction !== ""
            onToggled: root.inputRun(checked ? "dwt-on" : "dwt-off")
        }

        ChipSelectRow {
            last: true
            visible: !!root.input.touchpad?.present
            label: qsTr("Scroll speed")
            options: root.scrollOptions
            current: root.num(root.input.touchpad?.scroll_factor)
            busy: inputBridge.busyAction.startsWith("tp-scroll-")
            onPicked: v => root.inputRun(`tp-scroll-${v}`)
        }

        ActionErrorRow {
            bridge: inputBridge
        }

        // Mouses com driver (openrazer): bateria, DPI, polling; botoes,
        // estagios e energia na subpagina
        Repeater {
            model: root.periph.mice ?? []

            ColumnLayout {
                id: mouse

                required property var modelData
                required property int index

                readonly property var battery: mouse.index === 0 ? root.mouseBattery : null
                readonly property var stages: {
                    const st = [...(mouse.modelData.dpi_stages ?? [])];
                    if (mouse.modelData.dpi && !st.includes(mouse.modelData.dpi))
                        st.push(mouse.modelData.dpi);
                    return st.sort((a, b) => a - b);
                }
                readonly property int remapped: (mouse.modelData.buttons ?? []).filter(b => b.action !== "default").length

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SubsectionHeader {
                    icon: "mouse"
                    text: root.mouseName(mouse.modelData.name)
                    status: mouse.modelData.asleep ? qsTr("Asleep") : mouse.battery ? "%1%".arg(Math.round(mouse.battery.pct * 100)) : ""
                    warn: !!mouse.battery && mouse.battery.pct < 0.2
                }

                MeterRow {
                    first: true
                    visible: !!mouse.battery
                    icon: "battery_full"
                    label: qsTr("Battery")
                    valueText: mouse.battery ? `${Math.round(mouse.battery.pct * 100)}%` : ""
                    value: mouse.battery?.pct ?? 0
                    warnAt: 0.2
                    warnBelow: true
                    subtext: mouse.battery ? root.batteryText(mouse.battery) : ""
                }

                InfoRow {
                    first: !mouse.battery
                    visible: !!mouse.modelData.asleep
                    icon: "bedtime"
                    label: qsTr("The mouse is asleep")
                    subtext: qsTr("Move it to wake it up — its settings can only change while it is awake")
                }

                ChipSelectRow {
                    first: !mouse.battery && !mouse.modelData.asleep
                    visible: mouse.stages.length > 0
                    label: qsTr("Sensitivity (DPI)")
                    subtext: qsTr("Set in the mouse itself — the same in every app and game. The DPI button on the mouse cycles these stages.")
                    options: mouse.stages.map(d => ({ value: String(d), label: d >= 1000 ? `${d / 1000}k` : String(d) }))
                    current: String(mouse.modelData.dpi ?? "")
                    disabled: !!mouse.modelData.asleep
                    busy: periphBridge.busyAction.startsWith(`dpi-${mouse.modelData.id}-`)
                    onPicked: v => root.periphRun(`dpi-${mouse.modelData.id}-${v}`)
                }

                ChipSelectRow {
                    visible: mouse.modelData.poll_rate != null && (mouse.modelData.poll_choices ?? []).length > 0
                    label: qsTr("Polling rate")
                    subtext: qsTr("Higher is smoother and more responsive, and uses more battery")
                    options: (mouse.modelData.poll_choices ?? []).map(h => ({ value: String(h), label: `${h} Hz` }))
                    current: String(mouse.modelData.poll_rate ?? "")
                    disabled: !!mouse.modelData.asleep
                    busy: periphBridge.busyAction.startsWith(`poll-${mouse.modelData.id}-`)
                    onPicked: v => root.periphRun(`poll-${mouse.modelData.id}-${v}`)
                }

                RowButton {
                    last: true
                    icon: "settings_input_component"
                    text: qsTr("Buttons, DPI stages and power")
                    subtext: [(mouse.modelData.buttons ?? []).length > 0 ? (mouse.remapped > 0 ? qsTr("%n button(s) remapped", "", mouse.remapped) : qsTr("%n button(s), all default", "", mouse.modelData.buttons.length)) : "", mouse.modelData.dpi_stages?.length ? qsTr("%n DPI stage(s)", "", mouse.modelData.dpi_stages.length) : ""].filter(x => x).join(" · ")
                    trailingIcon: "chevron_right"
                    onClicked: {
                        root.nState.selectedMouse = mouse.modelData.model;
                        root.nState.openSubPage(4);
                    }
                }
            }
        }

        // Mouses ja vistos que nao estao conectados agora (o Atheris quando
        // desligado): a secao fica, com o motivo de estar vazia
        Repeater {
            model: root.periph.mice_offline ?? []

            ColumnLayout {
                id: offline

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SubsectionHeader {
                    icon: "mouse"
                    text: root.mouseName(offline.modelData.name)
                    status: qsTr("Not connected")
                }

                InfoRow {
                    first: true
                    last: true
                    icon: "link_off"
                    label: qsTr("Turn it on to change its settings")
                    subtext: qsTr("Wireless: plug in its receiver or switch it to 2.4 GHz. Over Bluetooth only the battery shows up.")
                }
            }
        }

        // Outras luzes RGB (nao teclado)
        SectionHeader {
            visible: root.otherRgb.length > 0
            text: qsTr("Lighting")
        }

        Repeater {
            model: root.otherRgb

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.otherRgb.length - 1
                icon: root.isOff(modelData.settings) ? "light_off" : "palette"
                text: modelData.name
                subtext: root.lightingText(modelData.settings)
                trailingIcon: "chevron_right"
                onClicked: root.openLighting(modelData.id)
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
