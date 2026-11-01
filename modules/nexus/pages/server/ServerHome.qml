pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Home: o Home Assistant que roda no NAS — potencia agora e energia de hoje
// (tomadas com medicao), o que esta ligado, o que esta indisponivel, e os
// interruptores (luzes, tomadas, ventiladores) com toggle. Dados vem do
// `caelestia-nas status` (resumo `home`); cada toggle e a acao `ha:<entidade>:toggle`.
// Automacoes, cenas e o resto ficam no proprio Home Assistant (botao Abrir).
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var home: root.info.home ?? null
    readonly property bool homeOk: !!root.home && root.home.ok === true
    readonly property var controls: S.pickActions(root.bridge.actions, "ha:")
    readonly property var power: root.home?.power ?? []
    readonly property var openers: (root.bridge.actions ?? []).filter(a => a.id === "open:homeassistant" || a.id === "open:zigbee2mqtt")

    function onCount(): int {
        const on = root.home?.on ?? ({});
        return (on.light ?? 0) + (on.switch ?? 0) + (on.fan ?? 0);
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("Home Assistant runs on the NAS and talks to the smart plugs, lights and sensors. Power readings come from plugs with energy metering. Automations and the full dashboard live in the app itself.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: !root.online || !root.homeOk
        first: true
        last: true
        icon: root.online ? "home" : "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: !root.online ? Tr.tr("NAS out of reach") : Tr.tr("Home Assistant not answering")
        subtext: !root.online ? "" : (root.home?.message ?? Tr.tr("The homeassistant stack is off, still starting, or the API token is missing"))
    }

    GridLayout {
        visible: root.online && root.homeOk
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.medium
        columns: width >= 520 ? 2 : 1
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "bolt"
            title: Tr.tr("Power now")
            value: root.home?.power_total_w !== undefined && root.home?.power_total_w !== null ? `${root.home.power_total_w} W` : "?"
            detail: root.power.length === 0 ? Tr.tr("No metering plug yet") : Tr.tr("%1 metered plugs · today %2 kWh").arg(root.power.length).arg(root.home?.energy_today_kwh ?? "?")
            level: "ok"
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "lightbulb"
            title: Tr.tr("Switched on")
            value: Tr.tr("%1 devices").arg(root.onCount())
            detail: Tr.tr("lights %1 · plugs %2 · fans %3").arg(root.home?.on?.light ?? 0).arg(root.home?.on?.switch ?? 0).arg(root.home?.on?.fan ?? 0)
            level: "ok"
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "devices"
            title: Tr.tr("Entities")
            value: String(root.home?.entities ?? "?")
            detail: Tr.tr("everything Home Assistant knows about")
            level: "ok"
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "signal_disconnected"
            title: Tr.tr("Unavailable")
            value: String((root.home?.unavailable ?? []).length)
            detail: (root.home?.unavailable ?? []).length > 0 ? (root.home.unavailable).slice(0, 3).join(" · ") : Tr.tr("All devices reachable")
            level: (root.home?.unavailable ?? []).length > 0 ? "warn" : "ok"
        }
    }

    SectionHeader {
        visible: root.online && root.homeOk && root.controls.length > 0
        text: Tr.tr("SWITCHES")
    }

    Repeater {
        model: root.online && root.homeOk ? root.controls.length : 0

        RowButton {
            id: act

            required property int index
            property var modelData: root.controls[index] ?? ({})
            readonly property var liveItem: root.controls[index]
            readonly property bool isBusy: root.bridge.busyAction === act.modelData.id
            readonly property bool isOn: String(act.modelData.label ?? "").startsWith("Desligar")

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: act.index === 0
            last: act.index === root.controls.length - 1
            icon: act.isBusy ? "hourglass_top" : (act.modelData.icon ?? "toggle_on")
            text: act.isBusy ? Tr.tr("%1 — running…").arg(act.modelData.label) : act.modelData.label
            subtext: act.modelData.detail ?? ""
            trailingIcon: act.isOn ? "toggle_on" : "toggle_off"
            disabled: root.bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (!act.isBusy)
                    root.bridge.run(act.modelData);
            }
        }
    }

    SectionHeader {
        visible: root.online && root.homeOk && root.power.length > 0
        text: Tr.tr("POWER BY PLUG")
    }

    Repeater {
        model: root.online && root.homeOk ? root.power.length : 0

        InfoRow {
            id: meter

            required property int index
            property var modelData: root.power[index] ?? ({})
            readonly property var liveItem: root.power[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: meter.index === 0
            last: meter.index === root.power.length - 1
            icon: "bolt"
            label: meter.modelData.name ?? ""
            subtext: meter.modelData.id ?? ""
            value: `${meter.modelData.w ?? "?"} W`
        }
    }

    SectionHeader {
        visible: root.online && root.openers.length > 0
        text: Tr.tr("OPEN")
    }

    Repeater {
        model: root.online ? root.openers.length : 0

        RowButton {
            id: opener

            required property int index
            property var modelData: root.openers[index] ?? ({})
            readonly property var liveItem: root.openers[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: opener.index === 0
            last: opener.index === root.openers.length - 1
            icon: opener.modelData.icon ?? "open_in_new"
            text: opener.modelData.label ?? ""
            subtext: opener.modelData.detail ?? ""
            trailingIcon: "open_in_new"
            onClicked: root.bridge.run(opener.modelData)
        }
    }
}
