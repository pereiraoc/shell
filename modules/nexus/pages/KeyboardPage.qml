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


// Teclados (Nexus > Keyboard): o que vale para todos (layout, repeticao --
// caelestia-input) e cada teclado: o do notebook (brilho asusctl + efeito
// asusd) e os externos (Azoth: bateria + luz) -- caelestia-peripherals.
PageBase {
    id: root

    readonly property var input: inputBridge.info
    readonly property var kb: root.input.keyboard ?? ({})
    readonly property var periph: periphBridge.info
    readonly property var peripherals: batteryBridge.info.devices ?? []

    // Luz do notebook (asusd) em Laptop keyboard; teclados externos com
    // subsecao propria; outras luzes RGB no fim.
    readonly property var laptopRgb: (root.periph.rgb ?? []).find(d => d.backend === "asusd") ?? null
    readonly property var keyboards: (root.periph.rgb ?? []).filter(d => d.type === "Keyboard" && d.backend !== "asusd")
    readonly property var otherRgb: (root.periph.rgb ?? []).filter(d => d.type !== "Keyboard")
    readonly property var kbBattery: root.keyboards.length > 0 ? (root.peripherals.find(b => b.kind === "keyboard") ?? null) : null

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
        root.nState.openSubPage(1);
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

    title: qsTr("Keyboard")
    description: qsTr("Layout, key repeat, lighting")

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

        // ---------------------------------------------------------- Keyboard
        // Geral (vale para qualquer teclado) e, embaixo, cada teclado.
        SectionHeader {
            first: true
            visible: !!root.input.keyboard
            text: qsTr("All keyboards")
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

        AdvancedGroup {
            apps: [
                { id: "org.openrgb.OpenRGB", alt: ["openrgb"], text: qsTr("RGB lighting"), subtext: qsTr("Keyboard and peripheral lighting (OpenRGB)") }
            ]
        }
    }
}
