pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Telas: resolucao/taxa, escala e liga/desliga por monitor, brilho, tamanho de
// texto dos apps X11. Logica no caelestia-display (repositorio de setup):
// toda mudanca e aplicada SO ao vivo (try-*) e o banner de 15 s pergunta se
// mantem -- sem resposta, volta ao monitors.conf.
PageBase {
    id: root

    readonly property var monitors: (bridge.info.monitors ?? []).filter(m => m.connected)
    readonly property int enabledCount: root.monitors.filter(m => m.enabled).length
    readonly property bool pending: !!bridge.info.pending

    function tryChange(id: string): void {
        bridge.run({ id: id });
    }

    function scaleLabel(m: var, s: real): string {
        const [w, h] = (m.mode.split("@")[0] ?? "").split("x").map(Number);
        const pct = `${Math.round(s * 100)}%`;
        return w ? `${pct} · ${Math.round(w / s)}×${Math.round(h / s)}` : pct;
    }

    function modeLabel(mode: string): string {
        const [res, hz] = mode.split("@");
        return `${res.replace("x", " × ")} · ${hz} Hz`;
    }

    function friendlyName(m: var): string {
        if (m.internal)
            return qsTr("Built-in display");
        // "LG Electronics LG ULTRAWIDE 0x01010101" -> sem o serial no fim
        const d = (m.description ?? "").replace(/\s*\(.*\)$/, "").replace(/\s+(0x)?[0-9A-Fa-f]{6,}$/, "");
        return d || m.name;
    }

    title: qsTr("Display")
    description: qsTr("Resolution, refresh rate, scale and brightness for each screen")

    ToolBridge {
        id: bridge

        tool: "display"

        // Com mudanca pendente, acompanha o prazo: a reversao automatica
        // acontece fora do shell e so aparece aqui no proximo refresh.
        Timer {
            interval: 2000
            repeat: true
            running: root.pending && root.visible
            onTriggered: bridge.refresh()
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: bridge.error !== ""
            icon: "error"
            iconColour: Colours.palette.m3error
            label: qsTr("Could not read display settings")
            subtext: bridge.error
        }

        RevertBanner {
            id: banner

            first: true
            last: true
            visible: root.pending
            deadline: bridge.info.pending?.deadline ?? 0
            text: bridge.busyAction ? qsTr("Applying…") : qsTr("Keep these display settings?")
            onKeep: bridge.run({ id: "keep" })
            onRevert: bridge.run({ id: "revert" })
        }

        Repeater {
            model: root.monitors

            ColumnLayout {
                id: mon

                required property var modelData
                required property int index

                readonly property var brightness: Brightness.getMonitor(mon.modelData.name)
                readonly property bool busy: bridge.busyAction.endsWith(mon.modelData.name) || bridge.busyAction.includes(`-${mon.modelData.name}-`)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: mon.index === 0 && !banner.visible && bridge.error === ""
                    text: root.friendlyName(mon.modelData)
                }

                InfoRow {
                    first: true
                    icon: mon.modelData.internal ? "laptop" : "desktop_windows"
                    label: mon.modelData.enabled ? qsTr("%1 · %2 workspace area").arg(mon.modelData.name).arg(mon.modelData.logical.replace("x", " × ")) : qsTr("%1 · turned off").arg(mon.modelData.name)
                    subtext: mon.modelData.description
                }

                ExpandSelectRow {
                    visible: mon.modelData.enabled
                    icon: "aspect_ratio"
                    label: qsTr("Resolution & refresh rate")
                    subtext: qsTr("Higher refresh rate means smoother motion")
                    options: mon.modelData.modes.map(m => ({ value: m, label: root.modeLabel(m) }))
                    current: mon.modelData.mode
                    busy: mon.busy && bridge.busyAction.startsWith("try-mode")
                    onPicked: v => root.tryChange(`try-mode-${mon.modelData.name}-${v}`)
                }

                ChipSelectRow {
                    visible: mon.modelData.enabled
                    label: qsTr("Scale")
                    subtext: qsTr("Makes text, apps and the shell bigger. Whole numbers are always sharp.")
                    options: mon.modelData.valid_scales.map(s => ({ value: String(s), label: `${Math.round(s * 100)}%` }))
                    current: String(mon.modelData.valid_scales.find(s => Math.abs(s - mon.modelData.scale) < 0.01) ?? mon.modelData.scale)
                    busy: mon.busy && bridge.busyAction.startsWith("try-scale")
                    onPicked: v => root.tryChange(`try-scale-${mon.modelData.name}-${v}`)
                }

                SliderRow {
                    visible: mon.modelData.enabled && !!mon.brightness
                    icon: "brightness_6"
                    label: qsTr("Brightness")
                    valueLabel: `${Math.round((mon.brightness?.brightness ?? 0) * 100)}%`
                    value: mon.brightness?.brightness ?? 0
                    onMoved: v => mon.brightness?.setBrightness(v)
                }

                ToggleRow {
                    last: true
                    text: qsTr("Use this display")
                    subtext: mon.modelData.enabled && root.enabledCount <= 1 ? qsTr("This is the only screen on") : qsTr("Windows move to the other screen when it turns off")
                    checked: mon.modelData.enabled
                    disabled: mon.busy || (mon.modelData.enabled && root.enabledCount <= 1)
                    onToggled: root.tryChange(`${checked ? "try-on" : "try-off"}-${mon.modelData.name}`)
                }
            }
        }

        SectionHeader {
            text: qsTr("Text size for X11 apps")
        }

        ChipSelectRow {
            first: true
            last: true
            label: qsTr("Steam, games and other X11 apps")
            subtext: qsTr("These apps ignore the scale above. Restart them after changing.")
            options: [
                { value: "96", label: "100%" },
                { value: "120", label: "125%" },
                { value: "144", label: "150%" },
                { value: "192", label: "200%" }
            ]
            current: String(bridge.info.xft_dpi ?? "")
            busy: bridge.busyAction.startsWith("dpi-")
            onPicked: v => bridge.run({ id: `dpi-${v}` })
        }

        SectionHeader {
            text: qsTr("Advanced")
        }

        AdvancedAppRow {
            first: true
            last: true
            desktopId: "nwg-displays"
            text: qsTr("Arrange displays")
            subtext: qsTr("Position screens side by side, mirror (nwg-displays)")
        }
    }
}
