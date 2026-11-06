pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Network > Services: a rede da casa contada por CASO DE USO (pedido de 04/11):
// quem quer chegar onde de fora de casa, de dentro de casa, e o que barra cada
// tipo de ataque. Cada caso e um card recolhido (titulo + uma linha + bolinha
// de estado); aberto, mostra o caminho (PathDiagram: tunel = linha dupla com o
// servico nomeado, porta no no que escuta, bloqueio = tracejado vermelho com X),
// "Protected by"/"Stopped by" e os pontos fracos encontrados ("Weak spots").
// Fatos conferidos na config declarada em 04/11 (flake do NAS, portal, setup):
// so entra aqui o que a config garante. Dados ao vivo: caelestia-privacy (proton,
// dns, exposure, routes, pc), so leitura. Setup: CF-29 (Sunshine), CF-30
// (NetBird), CF-31 (sala), CF-32 (portal), CF-33 (e-mail), CF-35 (Proton), DS-17.
ColumnLayout {
    id: root

    property var info: ({})
    // Card aberto (um por vez, para a pagina nao virar um muro)
    property string openId

    readonly property var proton: root.info.proton ?? null
    readonly property var dns: root.info.dns ?? null
    readonly property var exposure: root.info.exposure ?? null
    readonly property var routes: root.info.routes ?? []
    readonly property bool pcOn: root.info.pc?.exit_on === true
    readonly property string tunnelState: root.proton ? (root.proton.tunnel_up ? "on" : "error") : "off"
    readonly property var downloads: root.routes.find(r => r.id === "downloads") ?? null
    readonly property string fwdPort: root.downloads && /\d+/.test(root.downloads.detail ?? "") ? root.downloads.detail.match(/\d+/)[0] : ""
    readonly property string dnsState: root.dns ? (root.dns.protection ? "on" : "off") : "off"
    readonly property string dnsSub: root.dns ? (root.dns.protection ? Tr.tr("%1% blocked today").arg(root.dns.blocked_pct) : Tr.tr("paused")) : ""
    readonly property int privateCount: root.exposure?.private_sites?.length ?? 0

    // Ataques (dados, nao desenho): o ultimo no de cada caminho e o que barra.
    readonly property var attacks: [
        {
            icon: "radar",
            title: Tr.tr("Someone scans the home IP"),
            summary: Tr.tr("Bots try every address on the internet; at home nothing answers"),
            nodes: [
                { icon: "bug_report", label: Tr.tr("Scanner"), sub: Tr.tr("any port") },
                { icon: "router", label: Tr.tr("Vivo router"), sub: Tr.tr("no ports forwarded"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("any connection"), detail: Tr.tr("dropped"), blocked: true }],
            protections: [Tr.tr("No port forwarding at home: the NAS calls out to the portal, never the other way"), Tr.tr("The home IP is not in any public DNS record")],
            gaps: []
        },
        {
            icon: "travel_explore",
            title: Tr.tr("Someone probes the portal"),
            summary: Tr.tr("The Oracle VM is the only public door; it opens only what the sites need"),
            nodes: [
                { icon: "bug_report", label: Tr.tr("Attacker"), sub: "" },
                { icon: "cloud", label: Tr.tr("Oracle portal"), sub: "25 · 80 · 443 · 51820 · 3478 · 22", state: "blocked" }
            ],
            links: [{ label: Tr.tr("other ports or names"), detail: Tr.tr("rejected"), blocked: true }],
            protections: [Tr.tr("Firewall rejects every other port"), Tr.tr("443 only forwards known names (adrenalindos.com, the NetBird server); any other name goes nowhere"), Tr.tr("It never decrypts: no certificate and no data live there"), Tr.tr("Security updates install by themselves")],
            gaps: [Tr.tr("No brute-force ban (fail2ban) on the portal's SSH"), Tr.tr("No rate limit on the public sites")]
        },
        {
            icon: "public_off",
            title: Tr.tr("Someone tries the private sites from the internet"),
            summary: Tr.tr("photos., files., movies.… point to a NetBird address the internet cannot route"),
            nodes: [
                { icon: "bug_report", label: Tr.tr("Attacker"), sub: Tr.tr("not on NetBird") },
                { icon: "lock", label: "100.76.115.98", sub: Tr.tr("NetBird only"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("HTTPS"), detail: Tr.tr("no route"), blocked: true }],
            protections: [Tr.tr("Private names resolve only to the NetBird address"), Tr.tr("The portal tunnel accepts only mail and the public sites; it cannot reach private ones"), Tr.tr("Joining NetBird needs an invited account or a setup key")],
            gaps: []
        },
        {
            icon: "password",
            title: Tr.tr("Someone guesses passwords"),
            summary: Tr.tr("Brute force against the central login or the NAS's SSH"),
            nodes: [
                { icon: "bug_report", label: Tr.tr("Attacker"), sub: Tr.tr("on NetBird or home Wi-Fi") },
                { icon: "verified_user", label: Tr.tr("Central login"), sub: Tr.tr("2FA + lockout"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("many tries"), detail: Tr.tr("locked out"), blocked: true }],
            protections: [Tr.tr("Two factors on every rule: a password alone is not enough"), Tr.tr("5 failures in 10 min lock the account for 30 min"), Tr.tr("NAS SSH: keys only, no passwords; fail2ban bans repeat offenders"), Tr.tr("Jellyfin and ntfy refuse their own passwords from outside: only the central login, Quick Connect or a read-only phone login")],
            gaps: []
        },
        {
            icon: "wifi",
            title: Tr.tr("A guest on the home Wi-Fi"),
            summary: Tr.tr("Anyone with the Wi-Fi password is inside the home network"),
            nodes: [
                { icon: "smartphone", label: Tr.tr("Guest's phone"), sub: Tr.tr("home Wi-Fi") },
                { icon: "dns", label: Tr.tr("NAS"), sub: Tr.tr("logins on every service"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("home network"), detail: Tr.tr("needs a login"), blocked: true }],
            protections: [Tr.tr("Devices not registered at home can't open the NAS; a new one becomes a request: Allow, Media only (Jellyfin) or Block"), Tr.tr("Shared folder: user and password, no guest access"), Tr.tr("The *.nas.local names use the same central login as the private names"), Tr.tr("This PC's firewall lets the home network reach only Sunshine (paired devices), Steam Remote Play and mDNS"), Tr.tr("A new device on the Wi-Fi sends an alert to your phone (NetAlertX)")],
            gaps: [Tr.tr("No guest Wi-Fi: guests share the network with the NAS and this PC")]
        },
        {
            icon: "person_alert",
            title: Tr.tr("A player abuses a public app"),
            summary: Tr.tr("Foundry and Pleitost face the internet, so they defend themselves"),
            nodes: [
                { icon: "bug_report", label: Tr.tr("Malicious user"), sub: "" },
                { icon: "casino", label: Tr.tr("Foundry · Pleitost"), sub: Tr.tr("own login · row-level security"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("HTTPS via portal"), detail: Tr.tr("only its own data"), blocked: true }],
            protections: [Tr.tr("Foundry logins from the internet: 10 tries per 10 minutes per address (the portal passes the real IP to the NAS)"), Tr.tr("Pleitost: GitHub sign-in required before anything loads"), Tr.tr("Pleitost database: row-level security on every table; e-mail sign-up off (GitHub only)"), Tr.tr("Only the 4 Supabase APIs the app uses are public; Studio returns 404"), Tr.tr("Each app runs in its own container, published only to the NAS itself")],
            gaps: [Tr.tr("CF-32 lists 4 known row-level-security weak points to review")]
        },
        {
            icon: "visibility",
            title: Tr.tr("Someone tracks you by IP or names"),
            summary: root.tunnelState === "error" ? Tr.tr("Proton is DOWN now: protected traffic is stopped, not leaked") : Tr.tr("Sites, trackers and torrent peers see Proton, not the house"),
            nodes: [
                { icon: "visibility", label: Tr.tr("Tracker · peer"), sub: "" },
                { icon: "vpn_lock", label: Tr.tr("Proton exit"), sub: Tr.tr("kill switch"), state: "blocked" }
            ],
            links: [{ label: Tr.tr("looks for the home IP"), detail: Tr.tr("sees Proton"), blocked: true }],
            protections: [Tr.tr("If Proton drops, protected traffic stops: a blackhole route plus a firewall drop, checked every 2 min with an alert"), Tr.tr("IPv6 blocked for tunnelled traffic, so nothing slips around it"), Tr.tr("qBittorrent can only leave through its own tunnel (gluetun)"), Tr.tr("AdGuard drops tracker and ad domains (3 lists, DNSSEC)")],
            gaps: [Tr.tr("Not covered: guests' devices and the TV; on this PC, Steam, games and Discord show the home IP by design")]
        }
    ]

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.small
        text: Tr.tr("Who reaches what, and how. Open a case to see its path: a double line is an encrypted tunnel (the service that makes it is named on the line), the port tag sits on the device that listens, and a red dashed line with an X is where traffic is stopped.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    // =========================================================== fora de casa
    SectionHeader {
        first: true
        text: Tr.tr("AWAY FROM HOME")
    }

    UseCase {
        caseId: "visitor-adrenalindos"
        first: true
        icon: "groups"
        title: Tr.tr("Visitors open Adrenalindos")
        summary: Tr.tr("Players reach Foundry VTT and the Pleitost companion; the house stays closed")
        nodes: [
            { icon: "groups", label: Tr.tr("Visitor"), sub: Tr.tr("any browser") },
            { icon: "cloud", label: Tr.tr("Oracle portal"), sub: Tr.tr("passes through, cannot read"), port: "443" },
            { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: Tr.tr("certificates here"), port: "9443" },
            { icon: "casino", label: Tr.tr("Foundry · Pleitost"), sub: Tr.tr("each with its own login") }
        ]
        links: [
            { label: Tr.tr("HTTPS"), detail: "*.adrenalindos.com", encrypted: true },
            { label: Tr.tr("WireGuard (portal)"), detail: Tr.tr("the NAS dials out"), tunnel: true },
            { label: Tr.tr("inside the NAS"), detail: "" }
        ]
        protections: [Tr.tr("Only the portal is public; nothing is open at home"), Tr.tr("The portal never decrypts; certificates live on the NAS"), Tr.tr("Foundry: player and admin passwords"), Tr.tr("Pleitost: GitHub sign-in; data only through row-level security")]
    }

    UseCase {
        caseId: "trusted-private"
        icon: "lock"
        title: Tr.tr("Your devices open private services")
        summary: Tr.tr("Photos, files, music, home, Odysseus, settings… only with NetBird on")
        nodes: [
            { icon: "devices", label: Tr.tr("Phone · laptop"), sub: Tr.tr("NetBird on") },
            { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: "100.76.115.98", port: "443" },
            { icon: "verified_user", label: Tr.tr("Central login"), sub: Tr.tr("passkey or 2FA") },
            { icon: "apps", label: Tr.tr("%1 private sites").arg(root.privateCount || "?"), sub: "*.pereiraoc.com" }
        ]
        links: [
            { label: Tr.tr("NetBird"), detail: Tr.tr("peer to peer"), tunnel: true },
            { label: Tr.tr("asks once"), detail: "" },
            { label: "", detail: "" }
        ]
        protections: [Tr.tr("The names only resolve to the NetBird address; the internet cannot reach them"), Tr.tr("Approved devices skip the sign-in: an admin approves a new one from the phone, the notification or Nexus › Network › Sign-ins (30 days or always, with a nickname; revoke there)"), Tr.tr("Photos, files, movies, home and timeline sign in through the NAS login (login.pereiraoc.com), which also accepts approved devices"), Tr.tr("Central login with two factors (photos, files, movies, alerts and home sign in through it too)"), Tr.tr("Passkey: your phone's fingerprint replaces password and code (from a computer, scan a QR with the phone)"), Tr.tr("Admin-only: Odysseus, DNS filter, database admin, settings"), Tr.tr("The NetBird server on the portal only introduces devices; it never sees the traffic")]
        gaps: []
    }

    UseCase {
        caseId: "trusted-watch"
        icon: "movie"
        title: Tr.tr("Watch movies and series away")
        summary: Tr.tr("Jellyfin on the phone, tablet or a hotel TV: NetBird finds the NAS, then the video comes straight from home")
        paths: [
            {
                caption: Tr.tr("Finding the NAS: the name points to a private address, and the NetBird server on the Oracle portal introduces the phone to the NAS"),
                nodes: [
                    { icon: "tablet_android", label: Tr.tr("Phone · tablet"), sub: Tr.tr("NetBird app on") },
                    { icon: "cloud", label: Tr.tr("Oracle portal · NetBird server"), sub: Tr.tr("keys and addresses only"), port: "443 · 3478" },
                    { icon: "dns", label: Tr.tr("NAS"), sub: Tr.tr("always connected to it") }
                ],
                links: [
                    { label: Tr.tr("asks where the NAS is"), detail: Tr.tr("HTTPS · STUN"), encrypted: true },
                    { label: Tr.tr("registered here"), detail: "", encrypted: true }
                ]
            },
            {
                caption: Tr.tr("The video: straight from the NAS (if a router blocks the direct path, the portal relays it still encrypted)"),
                nodes: [
                    { icon: "tablet_android", label: Tr.tr("Jellyfin app"), sub: "movies.pereiraoc.com" },
                    { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: "100.76.115.98", port: "443" },
                    { icon: "verified_user", label: Tr.tr("Central login"), sub: Tr.tr("passkey or 2FA") },
                    { icon: "movie", label: Tr.tr("Jellyfin"), sub: Tr.tr("your library") }
                ],
                links: [
                    { label: Tr.tr("NetBird"), detail: Tr.tr("peer to peer"), tunnel: true },
                    { label: Tr.tr("asks once"), detail: "" },
                    { label: "", detail: "" }
                ]
            }
        ]
        protections: [Tr.tr("The name resolves to a NetBird address: without NetBird nothing answers"), Tr.tr("Jellyfin's own password is refused here: the browser signs in through the central login, apps with Quick Connect (approve the code from a signed-in browser)"), Tr.tr("The portal never sees the video: it only introduces devices (or relays bytes it cannot read)"), Tr.tr("With the phone's Proton exit node on, the video still goes straight to the NAS through NetBird")]
        gaps: []
    }

    UseCase {
        caseId: "trusted-pc"
        icon: "desktop_windows"
        title: Tr.tr("Use this PC from far away")
        summary: Tr.tr("Moonlight on the phone or tablet streams this PC's screen")
        nodes: [
            { icon: "smartphone", label: Tr.tr("Phone · tablet"), sub: Tr.tr("Moonlight, NetBird on") },
            { icon: "desktop_windows", label: Tr.tr("This PC · Sunshine"), sub: "100.76.188.54", port: "47984" }
        ]
        links: [
            { label: Tr.tr("NetBird"), detail: Tr.tr("peer to peer"), tunnel: true }
        ]
        protections: [Tr.tr("Only paired devices (PIN once, in Network › This network)"), Tr.tr("This PC's firewall: Sunshine answers only on the home network and NetBird, never on a hotel Wi-Fi"), Tr.tr("Its web panel answers only on the home network; UPnP off")]
    }

    UseCase {
        caseId: "trusted-internet-away"
        icon: "vpn_lock"
        title: Tr.tr("Your phone browses the internet")
        summary: root.tunnelState === "error" ? Tr.tr("Proton is DOWN: with the exit node on, the phone has no internet instead of leaking") : Tr.tr("With the exit node on, sites see Proton, never your IP; ads blocked by the NAS")
        health: root.tunnelState === "error" ? "warn" : "on"
        nodes: [
            { icon: "smartphone", label: Tr.tr("Phone"), sub: Tr.tr("exit node 'proton'") },
            { icon: "filter_alt", label: Tr.tr("NAS · AdGuard"), sub: root.dnsSub, port: "53", state: root.dnsState },
            { icon: "vpn_lock", label: Tr.tr("Proton VPN"), sub: Tr.tr("kill switch on the NAS"), state: root.tunnelState },
            { icon: "public", label: Tr.tr("Internet"), sub: Tr.tr("sees Proton's IP") }
        ]
        links: [
            { label: Tr.tr("NetBird"), detail: Tr.tr("to the NAS"), tunnel: true },
            { label: Tr.tr("WireGuard (Proton)"), detail: Tr.tr("+~130 ms"), tunnel: true },
            { label: "", detail: "" }
        ]
        protections: [Tr.tr("Names are looked up on the NAS filter, which asks upstream over HTTPS with DNSSEC"), Tr.tr("If Proton drops, traffic stops instead of using another IP"), Tr.tr("Without the exit node the phone uses its own connection, as usual")]
    }

    UseCase {
        caseId: "mail"
        last: true
        icon: "mail"
        title: Tr.tr("E-mail arrives, leaves and is read")
        summary: Tr.tr("inbox@pereiraoc.com: in through the portal, out through Oracle Email Delivery, read over NetBird")
        paths: [
            {
                caption: Tr.tr("Receiving: other mail servers deliver to the portal, which passes the mail to the NAS"),
                nodes: [
                    { icon: "outgoing_mail", label: Tr.tr("Other mail servers"), sub: "gmail, …" },
                    { icon: "cloud", label: Tr.tr("Oracle portal"), sub: Tr.tr("passes through"), port: "25" },
                    { icon: "inbox", label: Tr.tr("NAS · Stalwart"), sub: Tr.tr("your mailbox"), port: "25" }
                ],
                links: [
                    { label: Tr.tr("SMTP"), detail: Tr.tr("MX mx.pereiraoc.com") },
                    { label: Tr.tr("WireGuard (portal)"), detail: Tr.tr("the NAS dials out"), tunnel: true }
                ]
            },
            {
                caption: Tr.tr("Sending: your mail app hands the message to the NAS, which sends it through Oracle (never from the home IP)"),
                nodes: [
                    { icon: "smartphone", label: Tr.tr("Mail app"), sub: Tr.tr("NetBird on") },
                    { icon: "inbox", label: Tr.tr("NAS · Stalwart"), sub: Tr.tr("checks your login"), port: "465" },
                    { icon: "send", label: Tr.tr("Oracle Email Delivery"), sub: Tr.tr("signs and sends"), port: "587" },
                    { icon: "outgoing_mail", label: Tr.tr("Recipient"), sub: "" }
                ],
                links: [
                    { label: Tr.tr("NetBird"), detail: Tr.tr("SMTP over TLS"), tunnel: true },
                    { label: Tr.tr("sending"), detail: Tr.tr("TLS"), encrypted: true },
                    { label: Tr.tr("SMTP"), detail: "" }
                ]
            },
            {
                caption: Tr.tr("Reading: the mail app or the webmail opens the mailbox on the NAS"),
                nodes: [
                    { icon: "smartphone", label: Tr.tr("Mail app · webmail"), sub: Tr.tr("NetBird on") },
                    { icon: "inbox", label: Tr.tr("NAS · Stalwart"), sub: "mail.pereiraoc.com", port: "993" }
                ],
                links: [
                    { label: Tr.tr("NetBird"), detail: Tr.tr("IMAP over TLS"), tunnel: true }
                ]
            }
        ]
        protections: [Tr.tr("Mail is never sent from the home IP"), Tr.tr("The NAS trusts the sender address only when it comes from the portal"), Tr.tr("Sending and reading are private: NetBird + your mail password"), Tr.tr("Spam filter runs on the NAS: rules, blocklists (looked up by the NAS's own DNS) and a classifier that learns from your mail; spam goes to Junk"), Tr.tr("Incoming limits per sender IP and per sender and recipient")]
        gaps: [Tr.tr("The spam classifier is still learning: it switches on after about 100 spam and 100 good messages")]
    }

    // ============================================================ dentro de casa
    SectionHeader {
        text: Tr.tr("AT HOME")
    }

    UseCase {
        caseId: "nas-downloads"
        first: true
        icon: "download"
        title: Tr.tr("The NAS downloads and shares")
        summary: Tr.tr("Torrents and the library apps leave through Proton; the NAS's own chores go direct")
        health: root.downloads?.on === false || root.tunnelState === "error" ? "warn" : "on"
        paths: [
            {
                caption: Tr.tr("Torrents: qBittorrent lives inside its own Proton tunnel; peers reach it through the port Proton opens"),
                nodes: [
                    { icon: "dns", label: Tr.tr("NAS · qBittorrent"), sub: Tr.tr("legal torrents") },
                    { icon: "shield", label: Tr.tr("gluetun"), sub: Tr.tr("kill switch"), state: root.downloads?.on ? "on" : "error" },
                    { icon: "vpn_lock", label: Tr.tr("Proton P2P"), sub: Tr.tr("opens a port for you"), port: root.fwdPort, state: root.downloads?.on ? "on" : "error" },
                    { icon: "group", label: Tr.tr("Other peers"), sub: Tr.tr("see Proton's IP") }
                ],
                links: [
                    { label: Tr.tr("same container"), detail: "" },
                    { label: Tr.tr("WireGuard (Proton)"), detail: "", tunnel: true },
                    { label: Tr.tr("BitTorrent"), detail: Tr.tr("both ways") }
                ]
            },
            {
                caption: Tr.tr("Library apps: searches, metadata, subtitles and Jellyfin's covers leave through the NAS's Proton tunnel"),
                nodes: [
                    { icon: "dns", label: Tr.tr("NAS · Radarr, Sonarr…"), sub: Tr.tr("and Jellyfin") },
                    { icon: "shield", label: Tr.tr("NAS kill switch"), sub: Tr.tr("no Proton, no traffic"), state: root.tunnelState },
                    { icon: "vpn_lock", label: Tr.tr("Proton VPN"), sub: Tr.tr("Miami · Brazilian IP"), state: root.tunnelState },
                    { icon: "public", label: Tr.tr("Indexers · metadata"), sub: Tr.tr("see Proton's IP") }
                ],
                links: [
                    { label: Tr.tr("inside the NAS"), detail: "" },
                    { label: Tr.tr("WireGuard (Proton)"), detail: "", tunnel: true },
                    { label: "", detail: "" }
                ]
            },
            {
                caption: Tr.tr("The NAS itself: updates, backups and the tunnel to the Oracle portal go direct (nothing to hide there)"),
                nodes: [
                    { icon: "dns", label: Tr.tr("NAS"), sub: Tr.tr("NixOS, Docker images") },
                    { icon: "router", label: Tr.tr("Vivo router"), sub: Tr.tr("no ports forwarded") },
                    { icon: "public", label: Tr.tr("Internet · Oracle portal"), sub: Tr.tr("sees the home IP") }
                ],
                links: [
                    { label: Tr.tr("home network"), detail: "" },
                    { label: "", detail: "" }
                ]
            },
            {
                caption: Tr.tr("You manage it: at home, radarr.nas.local, torrent.nas.local… behind the central login"),
                nodes: [
                    { icon: "laptop_mac", label: Tr.tr("This PC · phone"), sub: Tr.tr("home network") },
                    { icon: "dns", label: Tr.tr("NAS · Caddy"), sub: "*.nas.local", port: "443" },
                    { icon: "verified_user", label: Tr.tr("Central login"), sub: Tr.tr("passkey or 2FA") },
                    { icon: "download", label: Tr.tr("Radarr · qBittorrent…"), sub: "" }
                ],
                links: [
                    { label: Tr.tr("home network"), detail: "" },
                    { label: Tr.tr("asks once"), detail: "" },
                    { label: "", detail: "" }
                ]
            }
        ]
        protections: [Tr.tr("Peers and indexers never see the home IP"), Tr.tr("If Proton drops, torrents and library traffic stop instead of leaking")]
    }

    UseCase {
        caseId: "trusted-internet-home"
        icon: "devices"
        title: Tr.tr("Your devices browse the internet")
        summary: root.pcOn ? Tr.tr("This PC leaves through Proton now; the phone too when its exit node is on") : Tr.tr("This PC goes direct now (Proton off); turn it on in Privacy")
        nodes: [
            { icon: "laptop_mac", label: Tr.tr("This PC · phone"), sub: root.pcOn ? Tr.tr("this PC: Proton on") : Tr.tr("this PC: Proton off") },
            { icon: "filter_alt", label: Tr.tr("NAS · AdGuard"), sub: root.dnsSub, port: "53", state: root.dnsState },
            { icon: "vpn_lock", label: Tr.tr("Proton VPN"), sub: Tr.tr("kill switch on the NAS"), state: root.pcOn ? root.tunnelState : "off" },
            { icon: "public", label: Tr.tr("Internet"), sub: root.pcOn ? Tr.tr("sees Proton's IP") : Tr.tr("sees the home IP") }
        ]
        links: [
            { label: Tr.tr("NetBird"), detail: Tr.tr("exit node"), tunnel: true },
            { label: Tr.tr("WireGuard (Proton)"), detail: Tr.tr("+~130 ms"), tunnel: true },
            { label: "", detail: "" }
        ]
        protections: [Tr.tr("DNS filter for every NetBird device, even with Proton off"), Tr.tr("Proton turns on at login; Steam, games and Discord go direct with the home IP (no added latency)")]
        gaps: [Tr.tr("Guests' phones and the TV use the Vivo router directly: home IP, no filter")]
    }

    UseCase {
        caseId: "pi-steam"
        icon: "sports_esports"
        title: Tr.tr("Living-room TV plays Steam")
        summary: Tr.tr("The Pi streams a games screen from this PC with Moonlight")
        nodes: [
            { icon: "sports_esports", label: Tr.tr("Living-room Pi"), sub: Tr.tr("Moonlight, controller") },
            { icon: "desktop_windows", label: Tr.tr("This PC · Sunshine 'sala'"), sub: Tr.tr("its own 1080p screen"), port: "48989" },
            { icon: "stadia_controller", label: Tr.tr("Steam"), sub: Tr.tr("gamescope session") }
        ]
        links: [
            { label: Tr.tr("home network"), detail: Tr.tr("paired, encrypted stream"), encrypted: true },
            { label: Tr.tr("inside the PC"), detail: "" }
        ]
        protections: [Tr.tr("Its own Sunshine instance: the TV sees only the games screen, never your desktop"), Tr.tr("Only the paired Pi can connect")]
    }

    UseCase {
        caseId: "pi-kodi"
        icon: "live_tv"
        title: Tr.tr("Living-room TV watches movies")
        summary: Tr.tr("Kodi on the Pi plays the Jellyfin library; away, the same library opens through NetBird")
        nodes: [
            { icon: "live_tv", label: Tr.tr("Living-room Pi · Kodi"), sub: Tr.tr("profiles per person") },
            { icon: "movie", label: Tr.tr("NAS · Jellyfin"), sub: Tr.tr("token per profile"), port: "8096" },
            { icon: "vpn_lock", label: Tr.tr("Proton VPN"), sub: Tr.tr("covers, metadata, streaming apps"), state: root.tunnelState },
            { icon: "public", label: Tr.tr("Internet"), sub: Tr.tr("sees Proton's IP") }
        ]
        links: [
            { label: Tr.tr("home network"), detail: "" },
            { label: Tr.tr("WireGuard (Proton)"), detail: Tr.tr("the NAS is the Pi's gateway"), tunnel: true },
            { label: "", detail: "" }
        ]
        protections: [Tr.tr("The Pi's DNS and internet go through the NAS: filter + Proton + kill switch"), Tr.tr("IPv6 off on the Pi, so nothing slips around the tunnel"), Tr.tr("Away: open Jellyfin through NetBird (see 'Watch movies and series away')")]
    }

    UseCase {
        caseId: "home-lan"
        last: true
        icon: "home"
        title: Tr.tr("Inside the house, without NetBird")
        summary: Tr.tr("The shared folder and *.nas.local work on the home network")
        nodes: [
            { icon: "laptop_mac", label: Tr.tr("Device on home Wi-Fi"), sub: "" },
            { icon: "router", label: Tr.tr("Vivo router"), sub: Tr.tr("no ports forwarded") },
            { icon: "dns", label: Tr.tr("NAS"), sub: "nas.local", port: "445" }
        ]
        links: [
            { label: Tr.tr("home network"), detail: "" },
            { label: Tr.tr("Samba · mDNS"), detail: "" }
        ]
        protections: [Tr.tr("Shared folder: NAS user and password, no guest access, SMB2 or newer")]
        gaps: []
    }

    // ================================================================= ataques
    SectionHeader {
        text: Tr.tr("ATTACKS · WHAT STOPS WHAT")
    }

    Repeater {
        model: root.attacks.length

        UseCase {
            id: atk

            required property int index
            readonly property var a: root.attacks[atk.index] ?? ({})

            caseId: "attack-" + atk.index
            first: atk.index === 0
            last: atk.index === root.attacks.length - 1
            attack: true
            icon: atk.a.icon ?? "warning"
            title: atk.a.title ?? ""
            summary: atk.a.summary ?? ""
            nodes: atk.a.nodes ?? []
            links: atk.a.links ?? []
            protections: atk.a.protections ?? []
            gaps: atk.a.gaps ?? []
        }
    }

    // ---- pecas ----------------------------------------------------------------

    // Um caso: cabecalho clicavel (icone, titulo, resumo, bolinha, seta) e,
    // aberto, o caminho + "Protected by"/"Stopped by" + "Weak spots".
    component UseCase: ConnectedRect {
        id: uc

        property string caseId
        property string icon
        property string title
        property string summary
        property string health: "on"    // on | warn | off ("state" e do Item)
        property bool attack
        property var nodes: []
        property var links: []
        // varios caminhos no mesmo caso (ex.: e-mail = receber / enviar / ler):
        // [{ caption, nodes, links }]; vazio = o caminho unico de nodes/links
        property var paths: []
        property var protections: []
        property var gaps: []
        readonly property var allPaths: uc.paths.length > 0 ? uc.paths : [{ caption: "", nodes: uc.nodes, links: uc.links }]
        readonly property bool expanded: root.openId === uc.caseId
        readonly property color blockColour: Colours.light ? "#c62828" : "#ef6b6b"
        readonly property color dotColour: uc.health === "warn" ? Colours.palette.m3tertiary : uc.health === "off" ? Colours.palette.m3outline : Colours.palette.m3success

        Layout.fillWidth: true
        implicitHeight: ucCol.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: ucCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.small

            // cabecalho (clique abre/fecha)
            Item {
                Layout.fillWidth: true
                implicitHeight: head.implicitHeight

                RowLayout {
                    id: head

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: uc.icon
                        color: uc.attack ? uc.blockColour : Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: uc.title
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: uc.summary
                            color: uc.health === "warn" ? Colours.palette.m3tertiary : Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    // pontos fracos achados: aviso discreto ja no card fechado
                    MaterialIcon {
                        visible: uc.gaps.length > 0
                        text: "error"
                        color: Colours.palette.m3tertiary
                        fontStyle: Tokens.font.icon.small
                    }

                    // bolinha: verde = funcionando, amarelo = com problema
                    Rectangle {
                        visible: !uc.attack
                        implicitWidth: Math.round(Tokens.font.icon.small.pointSize * 0.75)
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: uc.dotColour
                    }

                    MaterialIcon {
                        text: uc.expanded ? "expand_less" : "expand_more"
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                StateLayer {
                    anchors.fill: parent
                    anchors.margins: -Tokens.padding.small
                    radius: Tokens.rounding.medium
                    onClicked: root.openId = uc.expanded ? "" : uc.caseId
                }
            }

            Repeater {
                model: uc.expanded ? uc.allPaths.length : 0

                ColumnLayout {
                    id: path

                    required property int index
                    readonly property var p: uc.allPaths[path.index] ?? ({})

                    Layout.fillWidth: true
                    Layout.topMargin: path.index === 0 ? 0 : Tokens.spacing.medium
                    spacing: 0

                    // legenda do caminho (numerada quando ha mais de um)
                    StyledText {
                        Layout.fillWidth: true
                        visible: (path.p.caption ?? "") !== ""
                        text: uc.allPaths.length > 1 ? `${path.index + 1}. ${path.p.caption}` : path.p.caption
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.label.medium
                        wrapMode: Text.WordWrap
                    }

                    PathDiagram {
                        Layout.topMargin: Tokens.padding.extraExtraLarge * 1.3
                        nodes: path.p.nodes ?? []
                        links: path.p.links ?? []
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                visible: uc.expanded && uc.protections.length > 0
                text: uc.attack ? Tr.tr("STOPPED BY") : Tr.tr("PROTECTED BY")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            Repeater {
                model: uc.expanded ? uc.protections : []

                Line {
                    icon: uc.attack ? "shield" : "check"
                    iconColour: Colours.palette.m3success
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                visible: uc.expanded && uc.gaps.length > 0
                text: Tr.tr("WEAK SPOTS")
                color: Colours.palette.m3tertiary
                font: Tokens.font.label.small
            }

            Repeater {
                model: uc.expanded ? uc.gaps : []

                Line {
                    icon: "error"
                    iconColour: Colours.palette.m3tertiary
                }
            }
        }
    }

    // Uma linha de "Protected by"/"Weak spots": icone + texto
    component Line: RowLayout {
        id: line

        required property string modelData
        property string icon
        property color iconColour

        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: line.icon
            color: line.iconColour
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            text: line.modelData
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }
    }
}
