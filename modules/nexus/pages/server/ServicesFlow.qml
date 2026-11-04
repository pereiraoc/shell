pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Network > Services (04/11): por onde passa cada tipo de trafego da casa. Uma
// faixa por caminho (PathDiagram): tunel = linha dupla com cadeado e o nome do
// servico que faz o tunel; porta = etiqueta no no que escuta. Legenda no topo.
// Dados: caelestia-privacy. Setup: CF-32 (portal), CF-30 (NetBird), CF-33
// (e-mail), CF-35 (Proton), DS-17.
ColumnLayout {
    id: root

    property var info: ({})

    readonly property var proton: root.info.proton ?? null
    readonly property var dns: root.info.dns ?? null
    readonly property var exposure: root.info.exposure ?? null
    readonly property var routes: root.info.routes ?? []
    readonly property bool pcOn: root.info.pc?.exit_on === true
    readonly property string tunnelState: root.proton ? (root.proton.tunnel_up ? "on" : "error") : "off"
    readonly property var downloads: root.routes.find(r => r.id === "downloads") ?? null
    readonly property string fwdPort: root.downloads && /\d+/.test(root.downloads.detail ?? "") ? root.downloads.detail.match(/\d+/)[0] : ""

    function publicNames(): string {
        const s = (root.exposure?.public_sites ?? []).filter(x => x.access !== "redirect").map(x => x.label || x.fqdn);
        return s.length ? s.join(" · ") : Tr.tr("Public sites");
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    // ---- legenda ------------------------------------------------------------
    ConnectedRect {
        Layout.fillWidth: true
        first: true
        last: true
        implicitHeight: legend.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: legend

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            Row {
                spacing: Tokens.spacing.small

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.padding.extraExtraLarge
                    height: 5

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colours.palette.m3primary
                    }

                    Rectangle {
                        y: 4
                        width: parent.width
                        height: 1
                        color: Colours.palette.m3primary
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Encrypted tunnel (service named on the line)")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
            Row {
                spacing: Tokens.spacing.small

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Tokens.padding.extraExtraLarge
                    height: 1

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Colours.palette.m3outline
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("Normal connection")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
            Row {
                spacing: Tokens.spacing.small

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: legendPort.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: legendPort.implicitHeight + Tokens.padding.small
                    radius: Tokens.rounding.full
                    color: "transparent"
                    border.width: 1
                    border.color: Colours.palette.m3outline

                    Text {
                        id: legendPort

                        anchors.centerIn: parent
                        text: "port 53"
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Tr.tr("where it listens")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }
    }

    Lane {
        Layout.topMargin: Tokens.spacing.large
        first: true
        icon: "public"
        title: Tr.tr("Public sites")
        note: Tr.tr("Anyone on the internet. The Oracle portal is the only door; it does not decrypt, it hands the connection to the NAS through the tunnel the NAS opened.")
        nodes: [
            { icon: "groups", label: Tr.tr("Visitors"), sub: Tr.tr("players, browsers") },
            { icon: "cloud", label: Tr.tr("Oracle portal"), sub: Tr.tr("nginx, passes through"), port: "443" },
            { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: Tr.tr("certificates here"), port: "9443" },
            { icon: "language", label: root.publicNames(), sub: Tr.tr("each with its own login") }
        ]
        links: [
            { label: Tr.tr("HTTPS"), detail: "", encrypted: true },
            { label: Tr.tr("WireGuard tunnel"), detail: Tr.tr("UDP 51820 · NAS dials out"), tunnel: true },
            { label: Tr.tr("local"), detail: "" }
        ]
    }

    Lane {
        icon: "mail"
        title: Tr.tr("E-mail (inbox@pereiraoc.com)")
        note: Tr.tr("Incoming mail uses the same door; outgoing mail leaves through Oracle Email Delivery, never from home.")
        nodes: [
            { icon: "outgoing_mail", label: Tr.tr("Other mail servers"), sub: "" },
            { icon: "cloud", label: Tr.tr("Oracle portal"), sub: Tr.tr("passes through"), port: "25" },
            { icon: "inbox", label: Tr.tr("NAS · Stalwart"), sub: Tr.tr("your mailbox"), port: "25" },
            { icon: "send", label: Tr.tr("Oracle Email Delivery"), sub: Tr.tr("sends for you"), port: "587" }
        ]
        links: [
            { label: Tr.tr("SMTP"), detail: "" },
            { label: Tr.tr("WireGuard tunnel"), detail: Tr.tr("UDP 51820"), tunnel: true },
            { label: Tr.tr("sending"), detail: Tr.tr("TLS"), encrypted: true }
        ]
    }

    Lane {
        icon: "lock"
        title: Tr.tr("Private services")
        note: Tr.tr("Only your devices with NetBird on. They talk to the NAS directly; the NetBird server on the portal only introduces them (ports 443 and 3478).")
        nodes: [
            { icon: "devices", label: Tr.tr("Your PC, phone"), sub: Tr.tr("NetBird app on") },
            { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: "100.76.115.98", port: "443" },
            { icon: "apps", label: Tr.tr("%1 private sites").arg(root.exposure?.private_sites?.length ?? "?"), sub: Tr.tr("photos, movies, files, music…") }
        ]
        links: [
            { label: Tr.tr("NetBird (WireGuard)"), detail: Tr.tr("peer to peer"), tunnel: true },
            { label: Tr.tr("central login"), detail: Tr.tr("password + 2FA") }
        ]
    }

    Lane {
        icon: "vpn_lock"
        title: Tr.tr("Leaving through Proton")
        note: root.tunnelState === "error" ? Tr.tr("The Proton tunnel is DOWN: these have no internet right now instead of using the home IP.") : Tr.tr("Sites see Proton's IP. If Proton drops, these stop instead of leaking the home IP.")
        warn: root.tunnelState === "error"
        nodes: [
            { icon: "devices", label: Tr.tr("This PC · phone · living-room Pi"), sub: root.pcOn ? Tr.tr("this PC: on") : Tr.tr("this PC: off") },
            { icon: "shield", label: Tr.tr("NAS"), sub: Tr.tr("kill switch"), state: root.tunnelState },
            { icon: "vpn_lock", label: Tr.tr("Proton VPN"), sub: Tr.tr("Miami · Brazilian IP"), state: root.tunnelState },
            { icon: "public", label: Tr.tr("Internet"), sub: Tr.tr("sees Proton's IP") }
        ]
        links: [
            { label: Tr.tr("NetBird or home network"), detail: Tr.tr("exit node / gateway"), tunnel: true },
            { label: Tr.tr("WireGuard tunnel"), detail: Tr.tr("UDP 51820 · +~130 ms"), tunnel: true },
            { label: "", detail: "" }
        ]
    }

    Lane {
        icon: "download"
        title: Tr.tr("Downloads")
        note: Tr.tr("qBittorrent has its own Proton tunnel (gluetun) with a port opened by Proton; Radarr, Sonarr and Jellyfin's covers use the NAS tunnel above.")
        nodes: [
            { icon: "download", label: Tr.tr("qBittorrent"), sub: Tr.tr("legal torrents") },
            { icon: "shield", label: Tr.tr("gluetun"), sub: Tr.tr("kill switch"), state: root.downloads?.on ? "on" : "error" },
            { icon: "vpn_lock", label: Tr.tr("Proton P2P"), sub: Tr.tr("opens a port for you"), port: root.fwdPort, state: root.downloads?.on ? "on" : "error" },
            { icon: "group", label: Tr.tr("Other peers"), sub: Tr.tr("see Proton's IP") }
        ]
        links: [
            { label: Tr.tr("same container"), detail: "" },
            { label: Tr.tr("WireGuard tunnel"), detail: Tr.tr("UDP 51820"), tunnel: true },
            { label: Tr.tr("BitTorrent"), detail: "" }
        ]
    }

    Lane {
        icon: "filter_alt"
        title: Tr.tr("Names (DNS)")
        note: Tr.tr("Every lookup from VPN devices and the Pi goes to the filter on the NAS, which asks Quad9 or Cloudflare over HTTPS. Vivo does not see the names.")
        nodes: [
            { icon: "devices", label: Tr.tr("VPN devices · Pi"), sub: "" },
            { icon: "filter_alt", label: Tr.tr("AdGuard on the NAS"), sub: root.dns ? (root.dns.protection ? Tr.tr("%1% blocked").arg(root.dns.blocked_pct) : Tr.tr("paused")) : "", port: "53", state: root.dns && !root.dns.protection ? "off" : "on" },
            { icon: "public", label: Tr.tr("Quad9 · Cloudflare"), sub: Tr.tr("DNSSEC"), port: "443" }
        ]
        links: [
            { label: Tr.tr("DNS"), detail: Tr.tr("inside the VPN") },
            { label: Tr.tr("DNS over HTTPS"), detail: "", encrypted: true }
        ]
    }

    Lane {
        last: true
        icon: "router"
        title: Tr.tr("Direct, with the home IP")
        note: Tr.tr("What does not need hiding: the NAS itself (updates, backups, the portal tunnel), this PC when Proton is off, and the other home devices.")
        nodes: [
            { icon: "home", label: root.pcOn ? Tr.tr("NAS · other devices") : Tr.tr("NAS · this PC · others"), sub: "" },
            { icon: "router", label: Tr.tr("Vivo router"), sub: Tr.tr("no ports forwarded") },
            { icon: "public", label: Tr.tr("Internet"), sub: Tr.tr("sees the home IP") }
        ]
        links: [
            { label: Tr.tr("home network"), detail: "" },
            { label: "", detail: "" }
        ]
    }

    // ---- pecas ----------------------------------------------------------------

    component Lane: ConnectedRect {
        id: lane

        property string icon
        property string title
        property string note
        property bool warn
        property alias nodes: diagram.nodes
        property alias links: diagram.links

        Layout.fillWidth: true
        implicitHeight: laneCol.implicitHeight + Tokens.padding.large * 2

        ColumnLayout {
            id: laneCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: lane.icon
                    color: lane.warn ? Colours.palette.m3error : Colours.palette.m3primary
                }

                Text {
                    Layout.fillWidth: true
                    text: lane.title
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: lane.note
                color: lane.warn ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            PathDiagram {
                id: diagram

                // espaco para cadeado + nome do tunel em 2 linhas acima da linha
                Layout.topMargin: Tokens.padding.extraExtraLarge * 1.3
            }
        }
    }
}
