pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Network: o monitor de rede que roda no NAS (NetAlertX): quem esta na
// rede agora, quem apareceu e ainda nao foi reconhecido, quem sumiu. "Known"
// marca o aparelho como conhecido (some do alerta); a lista completa vem de
// `caelestia-nas network --json` a cada 30 s enquanto a aba esta visivel. O
// monitor em si (historico, mapa de rede, nomes) abre no navegador.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    property var devices: []
    property bool failed
    property string failMessage

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var monitor: root.info.monitor ?? null
    readonly property bool monitorOk: !!root.monitor && root.monitor.ok === true
    readonly property var knownActions: S.pickActions(root.bridge.actions, "known:")
    readonly property var openers: (root.bridge.actions ?? []).filter(a => a.id === "open:netalertx" || a.id === "open:ntfy")
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/caelestia-nas`

    function reload(): void {
        if (!root.online)
            return;
        proc.running = false;
        proc.command = [root.bin, "network", "--json"];
        proc.running = true;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: reload()
    onOnlineChanged: reload()

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.devices = d.devices ?? [];
                    root.failed = !d.ok;
                    root.failMessage = d.message ?? "";
                } catch (e) {
                    root.failed = true;
                    root.failMessage = Tr.tr("unreadable answer from caelestia-nas");
                }
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: root.reload()
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("NetAlertX on the NAS scans the home network every few minutes. A device seen for the first time shows up as new and pings your phone (ntfy); mark it as known to silence it. The full history and the network map live in the monitor itself.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: !root.online || !root.monitorOk
        first: true
        last: true
        icon: root.online ? "lan" : "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: !root.online ? Tr.tr("NAS out of reach") : Tr.tr("Network monitor not running")
        subtext: !root.online ? "" : (root.monitor?.message ?? Tr.tr("The netalertx stack is off or still starting"))
    }

    GridLayout {
        visible: root.online && root.monitorOk
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.medium
        columns: width >= 520 ? 3 : 1
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "devices"
            title: Tr.tr("Online now")
            value: String(root.monitor?.online ?? "?")
            detail: Tr.tr("%1 known in total").arg(root.monitor?.total ?? "?")
            level: "ok"
            onClicked: root.reload()
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "new_releases"
            title: Tr.tr("New")
            value: String(root.monitor?.new ?? "?")
            detail: (root.monitor?.new ?? 0) > 0 ? Tr.tr("Not yet marked as known") : Tr.tr("Nothing unknown on the network")
            level: (root.monitor?.new ?? 0) > 0 ? "warn" : "ok"
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "signal_disconnected"
            title: Tr.tr("Down")
            value: String(root.monitor?.down ?? "?")
            detail: Tr.tr("Known devices that are currently offline")
            level: "ok"
        }
    }

    SectionHeader {
        visible: root.online && root.monitorOk && root.knownActions.length > 0
        text: Tr.tr("NEW DEVICES")
    }

    Repeater {
        model: root.online && root.monitorOk ? root.knownActions.length : 0

        RowButton {
            id: act

            required property int index
            property var modelData: root.knownActions[index] ?? ({})
            readonly property var liveItem: root.knownActions[index]
            readonly property bool isBusy: root.bridge.busyAction === act.modelData.id

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: act.index === 0
            last: act.index === root.knownActions.length - 1
            icon: act.isBusy ? "hourglass_top" : "verified"
            text: act.isBusy ? Tr.tr("%1 — running…").arg(act.modelData.label) : act.modelData.label
            subtext: act.modelData.detail ?? ""
            disabled: root.bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (!act.isBusy)
                    root.bridge.run(act.modelData);
            }
        }
    }

    SectionHeader {
        visible: root.online && root.monitorOk
        text: root.devices.length === 0 ? Tr.tr("ON THE NETWORK NOW") : Tr.trN("%n DEVICE ON THE NETWORK NOW", "%n DEVICES ON THE NETWORK NOW", root.devices.length)
    }

    InfoRow {
        visible: root.online && root.monitorOk && root.devices.length === 0
        first: true
        last: true
        icon: root.failed ? "error" : proc.running ? "hourglass_empty" : "check_circle"
        iconColour: root.failed ? Colours.palette.m3error : Colours.palette.m3primary
        label: root.failed ? Tr.tr("Could not list the devices") : proc.running ? Tr.tr("Asking the NAS…") : Tr.tr("No device online")
        subtext: root.failed ? root.failMessage : ""
    }

    Repeater {
        model: root.online && root.monitorOk ? root.devices.length : 0

        InfoRow {
            id: dev

            required property int index
            property var modelData: root.devices[index] ?? ({})
            readonly property var liveItem: root.devices[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: dev.index === 0
            last: dev.index === root.devices.length - 1
            icon: dev.modelData.new ? "new_releases" : "devices"
            iconColour: dev.modelData.new ? Colours.palette.m3tertiary : Colours.palette.m3primary
            label: (dev.modelData.name && dev.modelData.name !== "(unknown)") ? dev.modelData.name : (dev.modelData.vendor || dev.modelData.mac || "?")
            subtext: [dev.modelData.ip ?? "", dev.modelData.mac ?? "", dev.modelData.type ?? "", dev.modelData.new ? Tr.tr("new") : ""].filter(x => x).join(" · ")
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
