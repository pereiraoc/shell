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
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.keyboard

// Teclados (Nexus > Keyboard), em abas: General (layout, repeticao --
// caelestia-input), Laptop (LaptopKeysView: teclas especiais, brilho asusctl,
// efeito asusd com previa na silhueta), uma aba por teclado externo (Azoth:
// AzothView -- bateria, silhueta, luz, OLED -- caelestia-peripherals),
// Shortcuts (a pagina do Super+/) e Advanced (outras luzes RGB, OpenRGB).
PageBase {
    id: root

    readonly property var input: inputBridge.info
    readonly property var kb: root.input.keyboard ?? ({})
    readonly property var periph: periphBridge.info
    readonly property var peripherals: batteryBridge.info.devices ?? []

    // Luz do notebook (asusd) na aba Laptop; teclados externos com aba
    // propria; outras luzes RGB em Advanced.
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
        return [s.mode, s.random ? qsTr("random colours") : (s.colors ?? []).map(c => `#${c}`).join(" "), s.brightness !== null && s.brightness !== undefined ? `${s.brightness}%` : ""].filter(x => x).join(" · ");
    }

    function openLighting(id: string): void {
        root.nState.selectedRgbDevice = id;
        root.nState.openSubPage(1);
    }

    // "ASUS ROG Azoth 2.4GHz" -> "ROG Azoth"
    function keyboardLabel(name: string): string {
        return (name ?? "").replace(/\s*(2\.4GHz|USB)$/, "").replace(/^ASUS\s+/i, "");
    }

    function periphRun(id: string): void {
        periphBridge.run({ id: id });
    }

    function inputRun(id: string): void {
        inputBridge.run({ id: id });
    }

    title: qsTr("Keyboard")
    description: qsTr("Layout, key repeat, lighting, shortcuts")
    tabs: {
        const t = [{ id: "general", label: qsTr("General") }, { id: "laptop", label: qsTr("Laptop") }];
        for (const k of root.keyboards)
            t.push({ id: k.id, label: root.keyboardLabel(k.name) });
        t.push({ id: "shortcuts", label: qsTr("Shortcuts") });
        t.push({ id: "advanced", label: qsTr("Advanced") });
        return t;
    }

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

        // ----------------------------------------------------------- General
        // Vale para qualquer teclado
        TabPane {
            active: root.tab === "general"

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

            ActionErrorRow {
                bridge: inputBridge
            }
        }

        // ------------------------------------------------------------ Laptop
        // Teclado do notebook: teclas especiais, brilho e efeito (LaptopKeysView).
        // So nasce quando a aba abre; depois fica viva.
        TabPane {
            id: laptopPane

            active: root.tab === "laptop"

            Loader {
                Layout.fillWidth: true
                active: laptopPane.opened
                visible: active
                sourceComponent: LaptopKeysView {
                    peripherals: periphBridge
                }
            }

            ActionErrorRow {
                bridge: periphBridge
            }
        }

        // ------------------------------------------- Um teclado externo por aba
        // Familia do Azoth (canal vendor): AzothView. Outro teclado externo com
        // luz: bateria + iluminacao. So nascem quando a aba abre; depois ficam vivos.
        Repeater {
            model: root.keyboards.length

            TabPane {
                id: kbd

                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.keyboards[index] ?? ({})
                readonly property var liveItem: root.keyboards[index]
                required property int index
                readonly property var battery: kbd.index === 0 ? root.kbBattery : null
                readonly property bool azoth: kbd.modelData.backend === "hid"

                active: root.tab === kbd.modelData.id
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

                Loader {
                    Layout.fillWidth: true
                    active: kbd.azoth && kbd.opened
                    visible: active
                    sourceComponent: AzothView {
                        device: kbd.modelData
                        bridge: periphBridge
                        battery: kbd.battery
                    }
                }

                SubsectionHeader {
                    visible: !kbd.azoth
                    icon: "keyboard"
                    text: root.keyboardLabel(kbd.modelData.name)
                    status: kbd.battery ? (kbd.battery.stale ? qsTr("Asleep · %1%") : "%1%").arg(Math.round(kbd.battery.pct * 100)) : ""
                    warn: !!kbd.battery && kbd.battery.pct < 0.2
                }

                MeterRow {
                    first: true
                    last: true
                    visible: !kbd.azoth && !!kbd.battery
                    icon: "battery_full"
                    label: qsTr("Battery")
                    valueText: kbd.battery ? `${Math.round(kbd.battery.pct * 100)}%` : ""
                    value: kbd.battery?.pct ?? 0
                    warnAt: 0.2
                    warnBelow: true
                    subtext: kbd.battery?.charging ? qsTr("Charging") : kbd.battery?.stale ? qsTr("Last known level — the device is asleep") : ""
                }

                Loader {
                    Layout.fillWidth: true
                    active: !kbd.azoth && kbd.opened
                    visible: active
                    sourceComponent: RgbLightingView {
                        deviceId: kbd.modelData.id
                        bridge: periphBridge
                    }
                }

                ActionErrorRow {
                    bridge: periphBridge
                }
            }
        }

        // --------------------------------------------------------- Shortcuts
        TabPane {
            id: shortcutsPane

            active: root.tab === "shortcuts"

            // A grade de atalhos custa ~0,4 s para nascer: so na 1a abertura da aba
            Loader {
                Layout.fillWidth: true
                active: shortcutsPane.opened
                visible: active
                sourceComponent: ShortcutsView {}
            }
        }

        // ---------------------------------------------------------- Advanced
        // Outras luzes RGB (nao teclado) e apps externos
        TabPane {
            active: root.tab === "advanced"

            SectionHeader {
                first: true
                visible: root.otherRgb.length > 0
                text: qsTr("Lighting")
            }

            Repeater {
                model: root.otherRgb.length

                RowButton {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: root.otherRgb[index] ?? ({})
                    readonly property var liveItem: root.otherRgb[index]
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
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
}
