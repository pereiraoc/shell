pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Connectivity > Privacy (04/11; setup CF-35, CF-32 § Privacidade, § 5d). Feita
// para USAR: uma frase de estado e as duas chaves do dia a dia (este PC pela
// Proton; bloquear anuncios). O resto fica recolhido (o que sai sempre pela
// Proton, ultimos bloqueios) ou em uma linha (conexao da Proton, exposicao ->
// Network > Services). Dados e acoes: caelestia-privacy.
PageBase {
    id: root

    readonly property var info: bridge.info
    readonly property bool loaded: root.info.routes !== undefined
    readonly property var proton: root.info.proton ?? null
    readonly property var dns: root.info.dns ?? null
    readonly property var exposure: root.info.exposure ?? null
    readonly property var always: (root.info.routes ?? []).filter(r => r.always)
    readonly property bool pcOn: root.info.pc?.exit_on === true
    readonly property bool exitAvailable: root.info.pc?.exit_available === true
    readonly property bool tunnelUp: root.proton?.tunnel_up === true
    readonly property bool busy: bridge.busyAction !== ""

    property bool showAlways
    property bool showBlocked

    function routeIcon(id: string): string {
        return ({
                downloads: "download",
                library: "video_library",
                jellyfin: "movie",
                pi: "tv"
            })[id] ?? "public";
    }

    function ago(s: var): string {
        if (s === null || s === undefined)
            return "?";
        return s < 120 ? Tr.tr("%1 s ago").arg(s) : Tr.tr("%1 min ago").arg(Math.round(s / 60));
    }

    function bytes(n: var): string {
        if (n === null || n === undefined)
            return "?";
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < u.length - 1) {
            n /= 1024;
            i++;
        }
        return `${n.toFixed(i > 1 ? 1 : 0)} ${u[i]}`;
    }

    title: Tr.tr("Privacy")
    description: Tr.tr("Hide your IP with Proton VPN, block ads and trackers")

    ToolBridge {
        id: bridge

        tool: "privacy"
        autoRefresh: root.visible ? 30000 : 0
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- estado em uma frase ----------------------------------------------
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            implicitHeight: hero.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: hero

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                Rectangle {
                    implicitWidth: Tokens.padding.extraExtraLarge * 2
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.medium
                    color: "transparent"
                    border.width: 1
                    border.color: !root.tunnelUp && root.loaded ? Colours.palette.m3error : Colours.palette.m3outline

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: !root.loaded ? "hourglass_empty" : !root.tunnelUp ? "gpp_bad" : root.pcOn ? "shield_lock" : "shield"
                        color: !root.tunnelUp && root.loaded ? Colours.palette.m3error : root.pcOn ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.size(Tokens.padding.extraExtraLarge).build()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    Text {
                        Layout.fillWidth: true
                        text: !root.loaded ? Tr.tr("Checking…") : !root.info.nas_reachable ? Tr.tr("Can't reach the NAS") : !root.tunnelUp ? Tr.tr("Proton is down") : root.pcOn ? Tr.tr("Your home IP is hidden") : Tr.tr("This PC is using the home IP")
                        color: !root.tunnelUp && root.loaded ? Colours.palette.m3error : Colours.palette.m3onSurface
                        font: Tokens.font.title.medium
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !root.loaded ? "" : !root.info.nas_reachable ? Tr.tr("Proton and the filter run on the NAS. Check that the NAS is on and NetBird is connected.") : !root.tunnelUp ? Tr.tr("Downloads, the living-room Pi and VPN devices using Proton have no internet until it is back (no leak). Try Reconnect below.") : root.pcOn ? Tr.tr("Sites see a Proton address in Miami with a Brazilian IP. Turn it off for online games.") : Tr.tr("Downloads and the living-room Pi still go through Proton. Turn the switch on to hide this PC too.")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }
                }
            }
        }

        ToggleRow {
            text: Tr.tr("Hide this PC's IP")
            subtext: !root.exitAvailable ? Tr.tr("Needs NetBird on and the NAS exit node") : root.pcOn ? Tr.tr("Through the NAS and Proton · about 130 ms more ping") : Tr.tr("Off · direct, lowest ping (games)")
            checked: root.pcOn
            disabled: !root.exitAvailable || root.busy
            onToggled: bridge.run({
                id: checked ? "pc-on" : "pc-off"
            })
        }

        ToggleRow {
            last: true
            text: Tr.tr("Block ads and trackers")
            subtext: !root.dns ? Tr.tr("Filter on the NAS not reachable") : root.dns.protection ? Tr.tr("%1 of %2 lookups blocked today (%3%)").arg(root.dns.blocked_24h).arg(root.dns.queries_24h).arg(root.dns.blocked_pct) : Tr.tr("Paused · turns back on by itself in %1 min").arg(Math.max(1, Math.round(root.dns.paused_ms / 60000)))
            checked: root.dns?.protection === true
            disabled: root.dns === null || root.busy
            onToggled: bridge.run({
                id: checked ? "dns-resume" : "dns-pause~3600"
            })
        }

        ActionErrorRow {
            Layout.fillWidth: true
            bridge: bridge
        }

        // ---- sempre pela Proton (recolhido) -------------------------------------
        RowButton {
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: !root.showAlways
            icon: "verified_user"
            text: Tr.tr("Always through Proton")
            subtext: root.always.length ? root.always.map(r => r.label.split(" (")[0]).join(", ") : ""
            trailingIcon: root.showAlways ? "expand_less" : "expand_more"
            onClicked: root.showAlways = !root.showAlways
        }

        Repeater {
            model: root.showAlways ? root.always : []

            InfoRow {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                last: index === root.always.length - 1
                icon: root.routeIcon(modelData.id)
                iconColour: modelData.on ? Colours.palette.m3primary : Colours.palette.m3error
                label: modelData.label
                subtext: modelData.detail
                value: modelData.on ? Tr.tr("Protected") : Tr.tr("Off")
            }
        }

        // ---- celular --------------------------------------------------------------
        InfoRow {
            Layout.topMargin: Tokens.spacing.small
            Layout.fillWidth: true
            first: true
            last: true
            icon: "smartphone"
            label: Tr.tr("On your phone")
            subtext: Tr.tr("Open NetBird and choose the exit node “proton”. Works on mobile data and on any Wi-Fi.")
        }

        // ---- conexao da Proton ----------------------------------------------------
        SectionHeader {
            text: Tr.tr("Proton connection")
        }

        InfoRow {
            Layout.fillWidth: true
            first: true
            visible: root.proton !== null
            icon: root.tunnelUp ? "vpn_lock" : "error"
            iconColour: root.tunnelUp ? Colours.palette.m3primary : Colours.palette.m3error
            label: root.tunnelUp ? Tr.tr("Connected · Miami, Brazilian IP") : Tr.tr("Not connected")
            subtext: root.proton ? Tr.tr("Last contact %1 · %2 received through it").arg(root.ago(root.proton.handshake_age_s)).arg(root.bytes(root.proton.rx_bytes)) : ""
            value: root.info.proton?.provider ?? ""
        }

        RowButton {
            last: true
            visible: root.proton !== null
            icon: bridge.busyAction === "tunnel-reconnect" ? "progress_activity" : "refresh"
            text: bridge.busyAction === "tunnel-reconnect" ? Tr.tr("Reconnecting…") : Tr.tr("Reconnect")
            subtext: Tr.tr("Only if something stopped loading: a few seconds without internet for everything using Proton")
            disabled: root.busy
            onClicked: bridge.run({
                id: "tunnel-reconnect"
            })
        }

        // ---- bloqueados (recolhido) ------------------------------------------------
        RowButton {
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: !root.showBlocked
            visible: root.dns !== null
            icon: "block"
            text: Tr.tr("Recently blocked")
            subtext: Tr.tr("If a site or app broke, find it here and turn the filter off for an hour")
            trailingIcon: root.showBlocked ? "expand_less" : "expand_more"
            onClicked: root.showBlocked = !root.showBlocked
        }

        Repeater {
            model: root.showBlocked && root.dns ? root.dns.recent_blocked : []

            InfoRow {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                last: index === (root.dns?.recent_blocked.length ?? 0) - 1
                icon: "block"
                label: modelData.domain
                value: modelData.count > 1 ? Tr.tr("%1 times").arg(modelData.count) : Tr.tr("once")
            }
        }

        // ---- exposicao -------------------------------------------------------------
        RowButton {
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: true
            icon: "travel_explore"
            text: Tr.tr("What the internet can reach")
            subtext: root.exposure ? Tr.tr("No ports open at home · %1 public sites through the Oracle portal · see the diagram").arg(root.exposure.public_sites.length) : Tr.tr("See the diagram")
            trailingIcon: "chevron_right"
            onClicked: root.nState.openPage("lan", 0, "services")
        }
    }
}
