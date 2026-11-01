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
// em `caelestia-nas` (setup, contrato status/actions/run) e chega pela ToolBridge;
// esta pagina so desenha e dispara. Abas: Overview (saude + abrir os apps),
// Services (stacks Docker), Storage (HDs, SMART, scrub), System (NixOS, watchdog,
// ventoinhas, rebuild, reiniciar), Logs (journal de uma unidade no NAS). Acoes
// com risk "medium" pedem dois cliques (o shell nao tem dialogo de confirmacao).
// Streaming e fotos NAO sao controlados aqui: a aba Overview so abre o app certo.
PageBase {
    id: root

    property string armed: ""
    property string logsUnit: ""
    // Peca da silhueta escolhida (bay-1..4, m2-1/2, power, fan, lan-10g, lan-2g5)
    property string selectedSpot: ""

    readonly property var info: nas.info
    readonly property bool online: root.info.online === true
    readonly property string reach: S.reachKey(root.info)

    function press(action: var): void {
        if (!action?.id)
            return;
        if (action.risk === "medium" && root.armed !== action.id) {
            root.armed = action.id;
            disarm.restart();
            return;
        }
        root.armed = "";
        nas.run(action);
    }

    function actionText(action: var): string {
        if (root.armed === action.id)
            return Tr.tr("Click again: %1").arg(action.label);
        if (nas.busyAction === action.id)
            return Tr.tr("%1 — running…").arg(action.label);
        return action.label ?? "";
    }

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

    title: Tr.tr("Server")
    description: Tr.tr("The NAS at home: services, storage, health")
    tabs: [
        { id: "overview", label: Tr.tr("Overview") },
        { id: "services", label: Tr.tr("Services") },
        { id: "network", label: Tr.tr("Network") },
        { id: "home", label: Tr.tr("Home") },
        { id: "storage", label: Tr.tr("Storage") },
        { id: "system", label: Tr.tr("System") },
        { id: "logs", label: Tr.tr("Logs") }
    ]

    // O PageBase so aceita Item como filho; os Timers moram dentro da ponte (que e Item).
    ToolBridge {
        id: nas

        tool: "nas"

        Timer {
            id: disarm

            interval: 4000
            onTriggered: root.armed = ""
        }

        // Atualiza sozinho enquanto esta pagina esta na frente (um ssh a cada 30 s).
        Timer {
            interval: 30000
            repeat: true
            running: root.visible && root.pageId === "server"
            onTriggered: nas.refresh()
        }
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
            id: networkPane

            active: root.tab === "network"

            // So nasce na primeira abertura (lista os aparelhos pela CLI a cada 30 s enquanto visivel).
            Loader {
                Layout.fillWidth: true
                active: networkPane.opened
                sourceComponent: ServerNetwork {
                    page: root
                    bridge: nas
                }
            }
        }

        TabPane {
            active: root.tab === "home"

            ServerHome {
                page: root
                bridge: nas
            }
        }

        TabPane {
            active: root.tab === "storage"

            ServerStorage {
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
