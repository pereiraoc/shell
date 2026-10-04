pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Energia: bateria (carga, tempo, consumo, saude, limite de carga), perfil de
// desempenho ASUS (agora / na tomada / na bateria), modo da GPU e se a
// hibernacao esta pronta. Logica no caelestia-power (repositorio de setup);
// GPU pelo GpuModeService, que ja trata confirmacao e reboot.
PageBase {
    id: root

    readonly property var battery: bridge.info.battery ?? ({})
    readonly property var profile: bridge.info.profile ?? ({})
    readonly property var hibernate: bridge.info.hibernate ?? ({})
    readonly property bool hasBattery: !!root.battery.present

    // Carga ao vivo pelo UPower (o CLI atualiza a cada 15 s).
    readonly property real percent: UPower.displayDevice?.isLaptopBattery ? UPower.displayDevice.percentage * 100 : (root.battery.percent ?? 0)

    readonly property var profileIcons: ({ Quiet: "eco", Balanced: "balance", Performance: "bolt" })

    function duration(minutes: var): string {
        if (minutes === null || minutes === undefined)
            return "";
        const h = Math.floor(minutes / 60);
        const m = Math.round(minutes % 60);
        return h > 0 ? qsTr("%1 h %2 min").arg(h).arg(m) : qsTr("%1 min").arg(m);
    }

    function stateText(): string {
        const st = root.battery.status ?? "";
        const t = root.duration(root.battery.time_to);
        if (st === "Charging")
            return t ? qsTr("Charging · full in %1").arg(t) : qsTr("Charging");
        if (st === "Discharging")
            return t ? qsTr("On battery · %1 left").arg(t) : qsTr("On battery");
        if (st === "Full" || bridge.info.ac)
            return root.battery.charge_limit < 100 && root.percent >= root.battery.charge_limit - 1 ? qsTr("Plugged in · held at %1% to protect the battery").arg(root.battery.charge_limit) : qsTr("Plugged in · fully charged");
        return st;
    }

    function profileOptions(): var {
        return (root.profile.choices ?? []).map(p => ({ value: p.toLowerCase(), label: p, icon: root.profileIcons[p] ?? "" }));
    }

    title: qsTr("Power")
    description: qsTr("Battery, performance profile, graphics and sleep")

    ToolBridge {
        id: bridge

        tool: "power"

        Timer {
            interval: 15000
            repeat: true
            running: root.visible
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
            label: qsTr("Could not read power settings")
            subtext: bridge.error
        }

        // Bateria em destaque
        ConnectedRect {
            Layout.fillWidth: true
            visible: root.hasBattery
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: hero

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.large

                MaterialIcon {
                    text: root.battery.status === "Charging" ? "battery_charging_full" : root.percent > 90 ? "battery_full" : root.percent > 50 ? "battery_5_bar" : root.percent > 20 ? "battery_3_bar" : "battery_alert"
                    color: root.percent <= 20 && root.battery.status === "Discharging" ? Colours.palette.m3error : Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.extraLarge
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        text: `${Math.round(root.percent)}%`
                        font: Tokens.font.headline.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.stateText()
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }
                }

                ColumnLayout {
                    visible: (root.battery.power_w ?? 0) > 0.1
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: `${(root.battery.power_w ?? 0).toFixed(1)} W`
                        font: Tokens.font.title.medium
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignRight
                        text: root.battery.status === "Charging" ? qsTr("charging") : qsTr("power draw")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }
            }
        }

        // Desempenho
        SectionHeader {
            text: qsTr("Performance")
        }

        InfoRow {
            first: true
            last: true
            visible: root.profile.available === false
            icon: "block"
            label: qsTr("Performance profiles unavailable")
            subtext: root.profile.reason ?? ""
        }

        ChipSelectRow {
            first: true
            visible: root.profile.available === true
            label: qsTr("Right now")
            subtext: qsTr("Quiet keeps fans low and saves battery; Performance lets the CPU and GPU run hotter")
            options: root.profileOptions()
            current: (root.profile.active ?? "").toLowerCase()
            busy: bridge.busyAction.startsWith("profile-") && !bridge.busyAction.startsWith("profile-ac") && !bridge.busyAction.startsWith("profile-battery")
            onPicked: v => bridge.run({ id: `profile-${v}` })
        }

        ChipSelectRow {
            visible: root.profile.available === true
            label: qsTr("When plugged in")
            subtext: qsTr("Applied automatically when the charger is connected")
            options: root.profileOptions()
            current: (root.profile.ac ?? "").toLowerCase()
            busy: bridge.busyAction.startsWith("profile-ac-")
            onPicked: v => bridge.run({ id: `profile-ac-${v}` })
        }

        ChipSelectRow {
            last: true
            visible: root.profile.available === true
            label: qsTr("On battery")
            subtext: qsTr("Applied automatically when the charger is removed")
            options: root.profileOptions()
            current: (root.profile.battery ?? "").toLowerCase()
            busy: bridge.busyAction.startsWith("profile-battery-")
            onPicked: v => bridge.run({ id: `profile-battery-${v}` })
        }

        // Bateria
        SectionHeader {
            visible: root.hasBattery
            text: qsTr("Battery")
        }

        ChipSelectRow {
            first: true
            visible: root.hasBattery && root.battery.charge_limit !== undefined
            label: qsTr("Charge limit")
            subtext: qsTr("Stopping at 80% makes the battery last years longer if the laptop is mostly plugged in")
            options: [
                { value: "60", label: "60%" },
                { value: "80", label: "80%" },
                { value: "100", label: "100%" }
            ]
            current: String(root.battery.charge_limit ?? "")
            busy: bridge.busyAction.startsWith("charge-limit-")
            onPicked: v => bridge.run({ id: `charge-limit-${v}` })
        }

        MeterRow {
            last: true
            visible: root.hasBattery && root.battery.health_pct !== undefined
            icon: "favorite"
            label: qsTr("Battery health")
            valueText: `${Math.round(root.battery.health_pct ?? 0)}%`
            value: (root.battery.health_pct ?? 0) / 100
            warnAt: 0.7
            warnBelow: true
            subtext: qsTr("Holds %1 Wh of the original %2 Wh").arg((root.battery.energy_full_wh ?? 0).toFixed(1)).arg((root.battery.energy_design_wh ?? 0).toFixed(1)) + ((root.battery.cycles ?? 0) > 0 ? qsTr(" · %1 cycles").arg(root.battery.cycles) : "")
        }

        // Graficos
        SectionHeader {
            text: qsTr("Graphics")
        }

        InfoRow {
            first: true
            last: true
            visible: !GpuModeService.available && !GpuModeService.loading
            icon: "block"
            label: qsTr("Graphics switching unavailable")
            subtext: GpuModeService.lastError || qsTr("supergfxd is not running")
        }

        ChipSelectRow {
            first: true
            last: true
            visible: GpuModeService.available
            label: qsTr("Graphics mode")
            subtext: {
                if (GpuModeService.pendingConfirmation !== "")
                    return qsTr("Click %1 again to confirm. A reboot is needed.").arg(GpuModeService.getModeName(GpuModeService.pendingConfirmation));
                if (GpuModeService.pendingMode !== "" && GpuModeService.pendingMode !== GpuModeService.activeMode)
                    return qsTr("Switches to %1 after a reboot").arg(GpuModeService.getModeName(GpuModeService.pendingMode));
                return qsTr("Hybrid saves battery and still runs games on the NVIDIA GPU. The HDMI port needs Hybrid or Dedicated.");
            }
            options: [
                { value: "integrated", label: qsTr("Integrated"), icon: "battery_saver" },
                { value: "hybrid", label: qsTr("Hybrid"), icon: "join" },
                { value: "asusmuxdgpu", label: qsTr("Dedicated"), icon: "sports_esports" }
            ]
            current: GpuModeService.pendingMode || GpuModeService.activeMode
            busy: GpuModeService.switching || GpuModeService.loading
            onPicked: v => GpuModeService.switchMode(v)
        }

        // Sono
        SectionHeader {
            text: qsTr("Sleep")
        }

        InfoRow {
            first: true
            last: true
            icon: root.hibernate.ready ? "check_circle" : "warning"
            iconColour: root.hibernate.ready ? Colours.palette.m3primary : Colours.palette.m3tertiary
            label: root.hibernate.ready ? qsTr("Hibernate is ready") : qsTr("Hibernate is not set up")
            subtext: {
                const sizes = qsTr("Swap %1 GB for %2 GB of memory").arg(root.hibernate.swap_gb ?? "?").arg(root.hibernate.ram_gb ?? "?");
                if (root.hibernate.ready)
                    return (root.hibernate.swap_gb ?? 0) < (root.hibernate.ram_gb ?? 0) ? qsTr("%1 · may fail if memory is very full").arg(sizes) : sizes;
                return qsTr("Hibernating now would lose your session. Fix: sudo bash scripts/system/enable-hibernate.sh · %1").arg(sizes);
            }
        }

        SectionHeader {
            text: qsTr("Advanced")
        }

        AdvancedAppRow {
            first: true
            last: true
            desktopId: "rog-control-center"
            altIds: ["org.opengamingcollective.rog-control-center"]
            text: qsTr("ROG Control Center")
            subtext: qsTr("Fan curves, keyboard lighting, firmware settings")
        }
    }
}
