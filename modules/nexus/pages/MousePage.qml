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


// Mouses (Nexus > Mouse): o que vale para todos (velocidade, aceleracao,
// rolagem -- caelestia-input), o touchpad e cada mouse com driver (Razer:
// bateria, DPI, polling; botoes/estagios/energia em MouseSettings).
PageBase {
    id: root

    readonly property var input: inputBridge.info
    readonly property var pointer: root.input.pointer ?? ({})
    readonly property var periph: periphBridge.info
    readonly property var peripherals: batteryBridge.info.devices ?? []
    readonly property var mouseBattery: (root.periph.mice ?? []).length > 0 ? (root.peripherals.find(b => b.kind === "mouse") ?? null) : null

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

    function batteryText(b: var): string {
        return b.charging ? qsTr("Charging") : b.stale ? qsTr("Last known level — the device is asleep") : "";
    }

    function periphRun(id: string): void {
        periphBridge.run({ id: id });
    }

    function inputRun(id: string): void {
        inputBridge.run({ id: id });
    }

    title: qsTr("Mouse")
    description: qsTr("Pointer, touchpad, gaming mice")

    ToolBridge {
        id: inputBridge

        tool: "input"
    }

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

        // ------------------------------------------------------------- Mouse
        SectionHeader {
            first: true
            visible: !!root.input.pointer
            text: qsTr("All mice")
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
                        root.nState.openSubPage(1);
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

        ActionErrorRow {
            bridge: periphBridge
        }

        AdvancedGroup {
            apps: [
                { id: "app.polychromatic.controller", alt: ["polychromatic"], text: qsTr("Razer devices"), subtext: qsTr("Buttons, DPI and lighting (Polychromatic)") },
                { id: "org.freedesktop.Piper", text: qsTr("Gaming mouse"), subtext: qsTr("Buttons and DPI profiles (Piper)") }
            ]
        }
    }
}
