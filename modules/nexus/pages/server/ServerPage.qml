pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Nexus > Server: o NAS de casa (UGREEN DXP4800 Plus, NixOS). Toda a logica mora
// em `caelestia-nas` (setup, contrato status/actions/run) e chega pela ToolBridge
// (NasBridge: dois cliques nas acoes de risco medio, releitura a cada 30 s);
// esta pagina so desenha e dispara. Abas: Overview (saude + abrir os apps),
// Services (stacks Docker), System (NixOS, watchdog, ventoinhas, rebuild,
// reiniciar), Storage / Network / Home Devices (atalhos: o conteudo mora em
// Storage > NAS, Network > Home e Network > Home Devices -- spec
// 2026-11-02-nas-login-rede-nexus-design.md secao 4), Users (login central:
// papel, acesso por servico, bloqueio, senha temporaria), Logs (journal de uma
// unidade no NAS). Streaming e fotos NAO sao controlados aqui: a aba Overview
// so abre o app certo.
PageBase {
    id: root

    property string logsUnit: ""

    readonly property var info: nas.info
    readonly property bool online: root.info.online === true
    readonly property string reach: S.reachKey(root.info)

    function showLogs(unit: string): void {
        root.logsUnit = unit;
        root.nState.openPage("server", 0, "logs");
    }

    function reachLabel(): string {
        switch (root.reach) {
        case "lan":
            return Tr.tr("Home network");
        case "overlay":
            return Tr.tr("Through the VPN");
        case "ssh":
            return Tr.tr("SSH only");
        default:
            return Tr.tr("Out of reach");
        }
    }

    // Uma linha para a aba-atalho Storage: o mesmo cartao da Overview, em texto
    function storageSummary(): string {
        if (!root.online)
            return "";
        const fs = S.storageFs(root.info, "/srv/storage");
        if (!fs)
            return Tr.tr("HDs not mounted");
        return Tr.tr("%1 free · %2% used · %3").arg(S.fmtBytes(fs.avail)).arg(fs.pct).arg(fs.btrfs?.profile ?? "?");
    }

    title: Tr.tr("Server")
    description: Tr.tr("The NAS at home: services, storage, health")
    tabs: [
        { id: "overview", label: Tr.tr("Overview") },
        { id: "services", label: Tr.tr("Services") },
        { id: "system", label: Tr.tr("System") },
        { id: "storage", label: Tr.tr("Storage") },
        { id: "network", label: Tr.tr("Network") },
        { id: "home", label: Tr.tr("Home Devices") },
        { id: "users", label: Tr.tr("Users") },
        { id: "logs", label: Tr.tr("Logs") }
    ]

    // O PageBase so aceita Item como filho; os Timers moram dentro da ponte (que e Item).
    NasBridge {
        id: nas

        live: root.visible && root.pageId === "server"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            visible: nas.error !== ""
            first: true
            last: true
            icon: "error"
            iconColour: Colours.palette.m3error
            label: Tr.tr("Could not read the NAS tool")
            subtext: nas.error
        }

        TabPane {
            active: root.tab === "overview"

            ServerOverview {
                page: root
                bridge: nas
            }
        }

        TabPane {
            active: root.tab === "services"

            ServerServices {
                page: root
                bridge: nas
            }
        }

        TabPane {
            active: root.tab === "system"

            ServerSystem {
                page: root
                bridge: nas
            }
        }

        // Atalhos: o conteudo mora na pagina do assunto, na aba certa
        TabPane {
            active: root.tab === "storage"

            ServerShortcut {
                page: root
                target: "storage"
                targetTab: "nas"
                where: Tr.tr("Storage › NAS")
                icon: "hard_drive"
                explanation: Tr.tr("The NAS disks (bays, M.2, RAID1, SMART, scrub) and its shared folders now sit with the rest of the disks, in Storage, tab NAS.")
                summary: root.storageSummary()
                summaryIcon: "hard_drive"
            }
        }

        TabPane {
            active: root.tab === "network"

            ServerShortcut {
                page: root
                target: "lan"
                targetTab: "home"
                where: Tr.tr("Network › Home")
                icon: "hub"
                explanation: Tr.tr("The home network monitor that runs on the NAS (who is online, new devices, mark as known) now sits with this PC's network, in Network, tab Home.")
                summary: root.online && nas.info.monitor?.ok ? Tr.tr("%1 online now · %2 new").arg(nas.info.monitor.online ?? "?").arg(nas.info.monitor.new ?? "?") : ""
                summaryIcon: "devices"
            }
        }

        TabPane {
            active: root.tab === "home"

            ServerShortcut {
                page: root
                target: "lan"
                targetTab: "devices"
                where: Tr.tr("Network › Home Devices")
                icon: "home"
                explanation: Tr.tr("Home Assistant on the NAS (smart plugs, lights, power use, toggles) now sits under Connectivity, in Network, tab Home Devices.")
            }
        }

        TabPane {
            active: root.tab === "users"

            ServerShortcut {
                page: root
                target: "security"
                targetTab: "users"
                where: Tr.tr("Security › NAS users")
                icon: "manage_accounts"
                explanation: Tr.tr("Who can sign in to the NAS services (central login), as user or administrator, which services each person sees, and blocking, now sit with the rest of the sign-in settings, in Security, tab NAS users.")
            }
        }

        TabPane {
            id: logsPane

            active: root.tab === "logs"

            // So nasce na primeira abertura da aba (e um ssh a cada 5 s enquanto visivel).
            Loader {
                Layout.fillWidth: true
                active: logsPane.opened
                sourceComponent: ServerLogs {
                    page: root
                    bridge: nas
                }
            }
        }
    }
}
