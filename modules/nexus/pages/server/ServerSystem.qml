pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba System: NixOS (versao, geracao, commit do flake), watchdog de hardware,
// ventoinhas, rede e VPN; acoes de baixo nivel (backup agora, aplicar o flake,
// reiniciar, desligar, terminal). Reiniciar/desligar/rebuild pedem dois cliques.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var nixos: root.info.nixos ?? ({})
    readonly property var wd: root.info.watchdog ?? null
    readonly property var fans: root.info.fans ?? null
    readonly property var overlay: root.info.overlay ?? null
    readonly property var net: root.info.net ?? []
    readonly property var acts: (root.bridge.actions ?? []).filter(a => ["backup-now", "rebuild", "reboot", "poweroff", "shell"].includes(a.id))

    function actIcon(id: string): string {
        switch (id) {
        case "backup-now":
            return "backup";
        case "rebuild":
            return "published_with_changes";
        case "reboot":
            return "restart_alt";
        case "poweroff":
            return "power_settings_new";
        default:
            return "terminal";
        }
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("The NAS runs NixOS from a flake kept on this PC: 'Apply the flake' builds here and switches the NAS over SSH. The hardware watchdog must stay armed — the firmware resets the box 17 minutes after it stops being fed.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: !root.online
        first: true
        last: true
        icon: "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: Tr.tr("NAS out of reach")
    }

    SectionHeader {
        visible: root.online
        text: Tr.tr("NIXOS")
    }

    InfoRow {
        visible: root.online
        first: true
        icon: "verified"
        label: Tr.tr("NixOS %1").arg(root.nixos.version ?? "?")
        subtext: Tr.tr("generation %1 · flake %2").arg(root.nixos.generation ?? "?").arg(root.nixos.rev ?? Tr.tr("unknown commit"))
        value: root.info.host ?? ""
    }

    InfoRow {
        visible: root.online
        icon: root.wd && root.wd.state === "active" ? "shield" : "gpp_bad"
        iconColour: root.wd && root.wd.state === "active" ? Colours.palette.m3primary : Colours.palette.m3error
        label: Tr.tr("Hardware watchdog")
        subtext: root.wd ? Tr.tr("%1 · %2 · fed every %3 s by systemd").arg(root.wd.identity ?? "?").arg(root.wd.state ?? "?").arg(root.wd.timeout ?? "?") : Tr.tr("not found — the NAS would reset every 17 minutes")
    }

    InfoRow {
        visible: root.online
        icon: "mode_fan"
        label: Tr.tr("Fans")
        subtext: root.fans ? Tr.tr("CPU %1 rpm (%2, pwm %3) · case %4 rpm (%5, pwm %6)").arg(root.fans.cpu_rpm ?? "?").arg(root.fans.cpu_mode ?? "?").arg(root.fans.cpu_pwm ?? "?").arg(root.fans.case_rpm ?? "?").arg(root.fans.case_mode ?? "?").arg(root.fans.case_pwm ?? "?") : Tr.tr("no reading")
    }

    InfoRow {
        visible: root.online
        icon: "lan"
        label: Tr.tr("Network")
        subtext: root.net.length === 0 ? Tr.tr("no address") : root.net.map(n => `${n.iface} ${n.ip}${n.speed_mbps ? ` · ${n.speed_mbps} Mb/s` : ""}`).join(" · ")
    }

    InfoRow {
        visible: root.online
        last: true
        icon: "vpn_lock"
        label: Tr.tr("Remote access")
        subtext: !root.overlay ? Tr.tr("no VPN agent on the NAS") : Tr.tr("%1 · %2 · %3 %4").arg(root.overlay.kind ?? "?").arg(root.overlay.online ? Tr.tr("online") : Tr.tr("offline")).arg(root.overlay.ip ?? "").arg(root.overlay.name ?? "")
    }

    SectionHeader {
        visible: root.online && root.acts.length > 0
        text: Tr.tr("ACTIONS")
    }

    Repeater {
        model: root.online ? root.acts.length : 0

        RowButton {
            id: act

            required property int index
            property var modelData: root.acts[index] ?? ({})
            readonly property var liveItem: root.acts[index]
            readonly property bool isArmed: root.page.armed === act.modelData.id
            readonly property bool isBusy: root.bridge.busyAction === act.modelData.id

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: act.index === 0
            last: act.index === root.acts.length - 1
            color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
            icon: act.isBusy ? "hourglass_top" : root.actIcon(act.modelData.id ?? "")
            text: root.page.actionText(act.modelData)
            subtext: act.modelData.detail ?? ""
            disabled: root.bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (act.isBusy)
                    return;
                if (act.modelData.id === "shell")
                    root.bridge.run(act.modelData);
                else
                    root.page.press(act.modelData);
            }
        }
    }
}
