pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.home

// Home: o setup desenhado (SetupDiagram: monitores no arranjo, notebook,
// teclado, mouses, fones, controles -- cada um leva a sua pagina; os
// desligados so com o botao) e, embaixo, o conjunto FIXO de cartoes de status
// (rede, som, energia, tela, GPU, disco, atualizacoes, perifericos). Cada
// cartao leva a pagina dona do assunto. Fixo de proposito: cartoes que mudam
// de lugar ou "sugerem" coisas foram o que mais se criticou no Home do
// Windows 11.
PageBase {
    id: root

    readonly property var power: powerBridge.info
    readonly property var display: displayBridge.info
    readonly property var storage: storageBridge.info
    readonly property var system: systemBridge.info
    readonly property var peripherals: peripheralBridge.info.devices ?? []
    readonly property var periph: periphBridge.info
    // Aparelhos do desenho
    readonly property var setupMice: [...(root.periph.mice ?? []).map(m => ({ model: m.model, name: m.name, online: true })), ...(root.periph.mice_offline ?? []).map(m => ({ model: m.model, name: m.name, online: false }))]
    readonly property var setupKeyboard: {
        const k = (root.periph.rgb ?? []).find(d => d.backend === "hid");
        if (!k)
            return null;
        const b = root.peripherals.find(p => p.kind === "keyboard");
        return { id: k.id, name: k.name, online: true, battery: b ? b.pct : null };
    }
    readonly property var setupHeadphones: (headphonesBridge.info.headphones ?? []).map(h => ({ model: h.model, name: h.name, connected: !!h.connected }))
    readonly property var setupControllers: Bluetooth.devices.values.filter(d => d.bonded && (/controller|gamepad/i.test(d.name ?? "") || (d.icon ?? "").includes("gaming"))).map(d => ({ name: d.name, connected: d.connected }))
    property bool showOffline
    property bool editLayout

    readonly property var worstDisk: (root.storage.partitions ?? []).reduce((a, b) => (!a || b.pct > a.pct) ? b : a, null)
    readonly property var lowestPeripheral: root.peripherals.reduce((a, b) => (!a || b.pct < a.pct) ? b : a, null)
    readonly property var internalMonitor: (root.display.monitors ?? []).find(m => m.internal && m.enabled) ?? null
    readonly property int screensOn: (root.display.monitors ?? []).filter(m => m.enabled).length

    function gb(bytes: real): string {
        return `${(bytes / 1e9).toFixed(bytes > 1e11 ? 0 : 1)} GB`;
    }

    function uptime(s: int): string {
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        return d > 0 ? qsTr("up %1 d %2 h").arg(d).arg(h) : qsTr("up %1 h %2 min").arg(h).arg(Math.floor((s % 3600) / 60));
    }

    title: qsTr("Home")
    description: root.system.uptime_s ? qsTr("%1 · %2").arg(root.system.cpu_model ?? "").arg(root.uptime(root.system.uptime_s)) : qsTr("Status at a glance")

    ToolBridge {
        id: powerBridge

        tool: "power"
    }

    ToolBridge {
        id: displayBridge

        tool: "display"
    }

    ToolBridge {
        id: storageBridge

        tool: "storage"
    }

    ToolBridge {
        id: systemBridge

        tool: "system"
    }

    ToolBridge {
        id: peripheralBridge

        tool: "peripheral-battery"
    }

    ToolBridge {
        id: periphBridge

        tool: "peripherals"
    }

    ToolBridge {
        id: headphonesBridge

        tool: "headphones"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        SetupDiagram {
            id: setup

            Layout.fillWidth: true
            monitors: root.display.monitors ?? []
            mice: root.setupMice
            keyboard: root.setupKeyboard
            headphones: root.setupHeadphones
            controllers: root.setupControllers
            showOffline: root.showOffline || root.editLayout
            editing: root.editLayout
            onOpen: (page, tab) => root.nState.openPage(page, 0, tab)
        }

        // Nome do aparelho sob o mouse (linha propria, sempre reservada)
        StyledText {
            Layout.fillWidth: true
            text: setup.hoverLabel
            color: Colours.palette.m3onSurface
            font: Tokens.font.title.small
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.editLayout ? qsTr("Drag each piece to where it sits on your desk") : qsTr("Tap a device to open its settings")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            TextButton {
                visible: root.editLayout && setup.customized
                text: qsTr("Reset")
                type: TextButton.Text
                onClicked: setup.reset()
            }

            TextButton {
                visible: !root.editLayout
                text: root.showOffline ? qsTr("Hide devices that are off") : qsTr("Show devices that are off")
                type: root.showOffline ? TextButton.Tonal : TextButton.Text
                onClicked: root.showOffline = !root.showOffline
            }

            TextButton {
                text: root.editLayout ? qsTr("Done") : qsTr("Edit layout")
                type: root.editLayout ? TextButton.Filled : TextButton.Tonal
                onClicked: root.editLayout = !root.editLayout
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width >= 520 ? 2 : 1
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Nmcli.activeEthernet ? "lan" : Nmcli.active ? "wifi" : "wifi_off"
                title: qsTr("Network")
                value: Nmcli.activeEthernet ? qsTr("Ethernet") : Nmcli.active ? Nmcli.active.ssid : qsTr("Offline")
                detail: Nmcli.activeEthernet ? Nmcli.activeEthernet.ipAddress : Nmcli.active ? qsTr("Signal %1%").arg(Nmcli.active.strength) : qsTr("Not connected")
                level: Nmcli.activeEthernet || Nmcli.active ? "ok" : "warn"
                onClicked: root.nState.openPage("network", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Audio.muted ? "volume_off" : "volume_up"
                title: qsTr("Sound")
                value: Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`
                detail: Audio.outputDevice?.description ?? qsTr("No output device")
                level: Audio.outputDevice ? "ok" : "warn"
                onClicked: root.nState.openPage("sound", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                readonly property real pct: UPower.displayDevice?.isLaptopBattery ? UPower.displayDevice.percentage * 100 : (root.power.battery?.percent ?? 0)
                icon: UPower.onBattery ? "battery_5_bar" : "battery_charging_full"
                title: qsTr("Power")
                value: root.power.battery?.present === false ? qsTr("Plugged in") : `${Math.round(pct)}%`
                detail: [UPower.onBattery ? qsTr("On battery") : qsTr("Plugged in"), root.power.profile?.active ?? ""].filter(x => x).join(" · ")
                level: UPower.onBattery && pct <= 20 ? "error" : (root.power.battery?.health_pct ?? 100) < 70 ? "warn" : "ok"
                onClicked: root.nState.openPage("power", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "monitor"
                title: qsTr("Display")
                value: root.screensOn === 1 ? qsTr("1 screen") : qsTr("%1 screens").arg(root.screensOn)
                detail: root.internalMonitor ? qsTr("Built-in at %1 · %2 Hz").arg(`${Math.round(root.internalMonitor.scale * 100)}%`).arg(root.internalMonitor.mode.split("@")[1]) : ""
                level: root.display.pending ? "warn" : "ok"
                onClicked: root.nState.openPage("display", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "developer_board"
                title: qsTr("Graphics")
                value: GpuModeService.getModeName(GpuModeService.activeMode)
                detail: GpuModeService.pendingMode && GpuModeService.pendingMode !== GpuModeService.activeMode ? qsTr("%1 after reboot").arg(GpuModeService.getModeName(GpuModeService.pendingMode)) : GpuModeService.getModeDescription(GpuModeService.activeMode)
                level: GpuModeService.pendingMode && GpuModeService.pendingMode !== GpuModeService.activeMode ? "warn" : "ok"
                onClicked: root.nState.openPage("power", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "hard_drive"
                title: qsTr("Storage")
                value: root.worstDisk ? qsTr("%1 free").arg(root.gb(root.worstDisk.avail)) : qsTr("Reading…")
                detail: root.worstDisk ? qsTr("%1 is %2% full").arg(root.worstDisk.mount).arg(root.worstDisk.pct) : ""
                level: root.worstDisk?.level ?? "ok"
                onClicked: root.nState.openPage("storage", 0, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: SoftwareInventory.updateCount > 0 ? "system_update" : "verified"
                title: qsTr("Updates")
                value: SoftwareInventory.updateCount > 0 ? qsTr("%1 available").arg(SoftwareInventory.updateCount) : qsTr("Up to date")
                detail: SoftwareInventory.updatesCheckedAt ? qsTr("Checked %1").arg(SoftwareInventory.updatesCheckedAt.toLocaleString(Qt.locale(), "dd/MM HH:mm")) : ""
                level: SoftwareInventory.updateCount > 0 ? "warn" : "ok"
                onClicked: root.nState.openPage("software", 4, "")
            }

            StatusCard {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: root.lowestPeripheral?.kind === "keyboard" ? "keyboard" : root.lowestPeripheral?.kind === "mouse" ? "mouse" : "devices_other"
                title: qsTr("Devices")
                value: root.lowestPeripheral ? `${Math.round(root.lowestPeripheral.pct * 100)}%` : qsTr("%1 connected").arg(Bluetooth.devices.values.filter(d => d.connected).length)
                detail: root.lowestPeripheral ? qsTr("%1 · lowest battery").arg(root.lowestPeripheral.name) : qsTr("Bluetooth devices")
                level: root.lowestPeripheral && root.lowestPeripheral.pct < 0.2 ? "warn" : "ok"
                onClicked: root.nState.openPage("bluetooth", 0, "")
            }
        }
    }
}
