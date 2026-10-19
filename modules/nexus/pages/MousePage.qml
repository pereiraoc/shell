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

// Mouses (Nexus > Mouse), em abas: General (o que vale para todos -- velocidade,
// aceleracao, rolagem -- caelestia-input), Touchpad, uma aba por mouse com
// driver (Razer: bateria, DPI, polling e, embutida, a MouseSettingsView --
// silhueta com os botoes, perfis, estagios, energia), os mouses ja vistos mas
// desligados, e Advanced (apps).
PageBase {
    id: root

    readonly property var input: inputBridge.info
    readonly property var pointer: root.input.pointer ?? ({})
    readonly property var periph: periphBridge.info
    readonly property var peripherals: batteryBridge.info.devices ?? []
    readonly property var mice: root.periph.mice ?? []
    readonly property var miceOffline: root.periph.mice_offline ?? []
    readonly property var mouseBattery: root.mice.length > 0 ? (root.peripherals.find(b => b.kind === "mouse") ?? null) : null

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

    // Aba de um mouse: id = modelo (o mesmo do IPC `nexus openMouse`), rotulo sem a marca
    function tabId(m: var): string {
        return m.model ?? m.id ?? m.name ?? "";
    }

    function tabLabel(m: var): string {
        return root.mouseName(m.name).replace(/^Razer\s+/i, "");
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
    tabs: {
        const t = [{ id: "general", label: qsTr("General") }];
        if (root.input.touchpad?.present)
            t.push({ id: "touchpad", label: qsTr("Touchpad") });
        for (const m of root.mice)
            t.push({ id: root.tabId(m), label: root.tabLabel(m) });
        for (const m of root.miceOffline)
            t.push({ id: root.tabId(m), label: root.tabLabel(m) });
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
        TabPane {
            active: root.tab === "general"

            SectionHeader {
                first: true
                visible: !!root.input.pointer
                text: qsTr("All mice")
            }

            ChipSelectRow {
                first: true
                visible: !!root.input.pointer
                label: qsTr("Pointer speed")
                subtext: qsTr("Multiplies the speed of every mouse and the touchpad, instantly. Gaming mice also have their own DPI in hardware — set it in their tab.")
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

            ActionErrorRow {
                bridge: inputBridge
            }
        }

        // ---------------------------------------------------------- Touchpad
        TabPane {
            active: root.tab === "touchpad"

            TouchpadDiagram {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                Layout.bottomMargin: Tokens.spacing.large
            }

            ToggleRow {
                first: true
                text: qsTr("Tap to click")
                subtext: qsTr("A light tap counts as a click")
                checked: !!root.input.touchpad?.tap_to_click
                disabled: inputBridge.busyAction !== ""
                onToggled: root.inputRun(checked ? "tap-on" : "tap-off")
            }

            ToggleRow {
                text: qsTr("Natural scrolling")
                subtext: qsTr("Content follows your fingers, like a phone")
                checked: !!root.input.touchpad?.natural_scroll
                disabled: inputBridge.busyAction !== ""
                onToggled: root.inputRun(checked ? "natural-scroll-on" : "natural-scroll-off")
            }

            ToggleRow {
                text: qsTr("Ignore while typing")
                subtext: qsTr("Stops a palm on the touchpad from moving the cursor")
                checked: !!root.input.touchpad?.disable_while_typing
                disabled: inputBridge.busyAction !== ""
                onToggled: root.inputRun(checked ? "dwt-on" : "dwt-off")
            }

            ChipSelectRow {
                last: true
                label: qsTr("Scroll speed")
                options: root.scrollOptions
                current: root.num(root.input.touchpad?.scroll_factor)
                busy: inputBridge.busyAction.startsWith("tp-scroll-")
                onPicked: v => root.inputRun(`tp-scroll-${v}`)
            }

            ActionErrorRow {
                bridge: inputBridge
            }
        }

        // ------------------------------------------------- Um mouse por aba
        // Mouses com driver (openrazer): bateria, DPI, polling; botoes,
        // estagios e energia na subpagina
        Repeater {
            model: root.mice.length

            TabPane {
                id: mouse

                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.mice[index] ?? ({})
                readonly property var liveItem: root.mice[index]
                required property int index
                readonly property var battery: mouse.index === 0 ? root.mouseBattery : null

                active: root.tab === root.tabId(mouse.modelData)
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

                SubsectionHeader {
                    icon: "mouse"
                    text: root.mouseName(mouse.modelData.name)
                    status: mouse.modelData.asleep ? qsTr("Asleep") : mouse.battery ? "%1%".arg(Math.round(mouse.battery.pct * 100)) : ""
                    warn: !!mouse.battery && mouse.battery.pct < 0.2
                }

                MeterRow {
                    first: true
                    last: !mouse.modelData.asleep
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
                    last: true
                    visible: !!mouse.modelData.asleep
                    icon: "bedtime"
                    label: qsTr("The mouse is asleep")
                    subtext: qsTr("Move it to wake it up — its settings can only change while it is awake")
                }

                ActionErrorRow {
                    bridge: periphBridge
                }

                // Silhueta com os botoes, perfis, estagios de DPI e energia: so
                // nasce quando a aba abre; depois fica viva
                Loader {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.medium
                    active: mouse.opened
                    visible: active
                    sourceComponent: MouseSettingsView {
                        model: mouse.modelData.model ?? ""
                        bridge: periphBridge
                        standalone: false
                    }
                }
            }
        }

        // Mouses ja vistos que nao estao conectados agora (o Atheris quando
        // desligado): a aba fica, com o motivo de estar vazia
        Repeater {
            model: root.miceOffline.length

            TabPane {
                id: offline

                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.miceOffline[index] ?? ({})
                readonly property var liveItem: root.miceOffline[index]
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                required property int index

                active: root.tab === root.tabId(offline.modelData)

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

                // Silhueta apagada: o mouse existe, so nao esta ligado
                MouseDiagram {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.medium
                    model: offline.modelData.model ?? ""
                    buttons: []
                    opacity: 0.45
                }
            }
        }

        // ---------------------------------------------------------- Advanced
        TabPane {
            active: root.tab === "advanced"

            AdvancedGroup {
                apps: [
                    { id: "app.polychromatic.controller", alt: ["polychromatic"], text: qsTr("Razer devices"), subtext: qsTr("Buttons, DPI and lighting (Polychromatic)") },
                    { id: "org.freedesktop.Piper", text: qsTr("Gaming mouse"), subtext: qsTr("Buttons and DPI profiles (Piper)") }
                ]
            }
        }
    }
}
