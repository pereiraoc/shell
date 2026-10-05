pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Home: conjunto FIXO de cartoes de status (rede, som, energia, tela, GPU,
// disco, atualizacoes, perifericos). Cada cartao leva a pagina dona do
// assunto. Fixo de proposito: cartoes que mudam de lugar ou "sugerem" coisas
// foram o que mais se criticou no Home do Windows 11.
PageBase {
    id: root

    readonly property var power: powerBridge.info
    readonly property var display: displayBridge.info
    readonly property var storage: storageBridge.info
    readonly property var system: systemBridge.info
    readonly property var peripherals: peripheralBridge.info.devices ?? []

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

    GridLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
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
            onClicked: root.nState.openPage("network", 0)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: Audio.muted ? "volume_off" : "volume_up"
            title: qsTr("Sound")
            value: Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`
            detail: Audio.outputDevice?.description ?? qsTr("No output device")
            level: Audio.outputDevice ? "ok" : "warn"
            onClicked: root.nState.openPage("sound", 0)
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
            onClicked: root.nState.openPage("power", 0)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "monitor"
            title: qsTr("Display")
            value: root.screensOn === 1 ? qsTr("1 screen") : qsTr("%1 screens").arg(root.screensOn)
            detail: root.internalMonitor ? qsTr("Built-in at %1 · %2 Hz").arg(`${Math.round(root.internalMonitor.scale * 100)}%`).arg(root.internalMonitor.mode.split("@")[1]) : ""
            level: root.display.pending ? "warn" : "ok"
            onClicked: root.nState.openPage("display", 0)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "developer_board"
            title: qsTr("Graphics")
            value: GpuModeService.getModeName(GpuModeService.activeMode)
            detail: GpuModeService.pendingMode && GpuModeService.pendingMode !== GpuModeService.activeMode ? qsTr("%1 after reboot").arg(GpuModeService.getModeName(GpuModeService.pendingMode)) : GpuModeService.getModeDescription(GpuModeService.activeMode)
            level: GpuModeService.pendingMode && GpuModeService.pendingMode !== GpuModeService.activeMode ? "warn" : "ok"
            onClicked: root.nState.openPage("power", 0)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "hard_drive"
            title: qsTr("Storage")
            value: root.worstDisk ? qsTr("%1 free").arg(root.gb(root.worstDisk.avail)) : qsTr("Reading…")
            detail: root.worstDisk ? qsTr("%1 is %2% full").arg(root.worstDisk.mount).arg(root.worstDisk.pct) : ""
            level: root.worstDisk?.level ?? "ok"
            onClicked: root.nState.openPage("storage", 0)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: SoftwareInventory.updateCount > 0 ? "system_update" : "verified"
            title: qsTr("Updates")
            value: SoftwareInventory.updateCount > 0 ? qsTr("%1 available").arg(SoftwareInventory.updateCount) : qsTr("Up to date")
            detail: SoftwareInventory.updatesCheckedAt ? qsTr("Checked %1").arg(SoftwareInventory.updatesCheckedAt.toLocaleString(Qt.locale(), "dd/MM HH:mm")) : ""
            level: SoftwareInventory.updateCount > 0 ? "warn" : "ok"
            onClicked: root.nState.openPage("software", 4)
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: root.lowestPeripheral?.kind === "keyboard" ? "keyboard" : root.lowestPeripheral?.kind === "mouse" ? "mouse" : "devices_other"
            title: qsTr("Devices")
            value: root.lowestPeripheral ? `${Math.round(root.lowestPeripheral.pct * 100)}%` : qsTr("%1 connected").arg(Bluetooth.devices.values.filter(d => d.connected).length)
            detail: root.lowestPeripheral ? qsTr("%1 · lowest battery").arg(root.lowestPeripheral.name) : qsTr("Bluetooth devices")
            level: root.lowestPeripheral && root.lowestPeripheral.pct < 0.2 ? "warn" : "ok"
            onClicked: root.nState.openPage("bluetooth", 0)
        }
    }
}
