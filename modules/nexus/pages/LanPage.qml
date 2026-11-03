pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.server

// A rede como ela esta (pedido de 01/11), em abas (02/11, spec
// 2026-11-02-nas-login-rede-nexus-design.md secao 4):
// - This network: o diagrama desta rede (internet, roteador, este PC, a VPN por
//   cima), o que ha nela (caelestia-lan; a lista completa e a subpagina 1) e o
//   acesso remoto ao PC pelo celular e pelo tablet (caelestia-remote: Sunshine
//   + Moonlight; DS-37, CF-29);
// - Home: o mapa da rede de casa pelo monitor que roda no NAS (HomeNetwork, que
//   era ServerNetwork / Server > Network; DS-18): desconhecidos em cima, a
//   arvore Internet > roteador > cabo / Wi-Fi por AP > tipo, apelido e tipo;
// - Home Devices saiu daqui em 03/11: pagina propria Smart Home Devices (SmartHomePage).
//   Mora aqui porque "Connectivity" e so um grupo do menu (Internet, Network,
//   Bluetooth) e esta e a pagina dele que ja fala da casa.
// Wi-Fi, ethernet e VPN ficam na pagina Internet.
PageBase {
    id: root

    readonly property var net: lan.info.network ?? null
    readonly property var devices: lan.info.devices ?? []
    readonly property int onlineCount: root.devices.filter(d => d.online).length
    readonly property var router: root.devices.find(d => d.type === "router") ?? null
    readonly property string routerName: root.router ? (root.router.name || root.router.hostname || root.router.vendor || Tr.tr("Router")) : Tr.tr("Router")
    readonly property string linkText: Nmcli.activeEthernet ? Tr.tr("Ethernet") : (Nmcli.active ? (Nmcli.active.ssid ?? Tr.tr("Wi-Fi")) : (root.net ? root.net.iface : Tr.tr("No connection")))
    readonly property var pending: remote.info.pending ?? []
    property string pinText
    property string pinName

    title: Tr.tr("Network")
    description: Tr.tr("How you are connected, what is on this network, home, remote access")
    tabs: [
        { id: "local", label: Tr.tr("This network") },
        { id: "home", label: Tr.tr("Home") }
    ]

    ToolBridge {
        id: lan

        tool: "lan"
        autoRefresh: 15000
    }

    // Uma ponte do NAS para as abas Home e Home Devices (as acoes dos toggles
    // passam por ela); relê a cada 30 s so com uma delas na frente.
    NasBridge {
        id: nas

        live: root.visible && root.tab === "home"
    }

    ToolBridge {
        id: remote

        tool: "remote"
        autoRefresh: 10000
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            visible: nas.error !== "" && root.tab !== "local"
            first: true
            last: true
            icon: "error"
            iconColour: Colours.palette.m3error
            label: Tr.tr("Could not read the NAS tool")
            subtext: nas.error
        }

        TabPane {
            active: root.tab === "local"

            // ---- esta rede -----------------------------------------------------
            SectionHeader {
                first: true
                text: Tr.tr("This network")
            }

            ConnectedRect {
                Layout.fillWidth: true
                first: true
                implicitHeight: diagram.implicitHeight + Tokens.padding.large * 2

                RowLayout {
                    id: diagram

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    spacing: 0

                    NetNode {
                        icon: "public"
                        label: Tr.tr("Internet")
                        sub: VPN.connected ? Tr.tr("via VPN · %1").arg(VPN.providerName) : ""
                        dim: !Nmcli.isConnected
                    }

                    NetLink {
                        label: VPN.connected && VPN.pingMs >= 0 ? Tr.tr("%1 ms").arg(VPN.pingMs) : ""
                    }

                    NetNode {
                        icon: "router"
                        label: root.routerName
                        sub: root.net ? root.net.gateway : ""
                        dim: !root.net
                    }

                    NetLink {
                        label: root.linkText
                    }

                    NetNode {
                        icon: "laptop_mac"
                        label: Tr.tr("This PC")
                        sub: root.net ? root.net.ip : ""
                        dim: !root.net
                    }
                }
            }

            InfoRow {
                icon: "lan"
                label: root.net ? Tr.tr("%1 · %2 device(s) online now").arg(root.net.subnet).arg(root.onlineCount) : Tr.tr("Not connected to any network")
                subtext: root.net ? Tr.tr("Other devices on this network, as this PC sees them (kernel neighbour table)") : ""
            }

            RowButton {
                icon: "devices"
                text: Tr.tr("Devices on this network")
                subtext: Tr.tr("Names, open ports, router page, SSH; mark which ones are routers")
                onClicked: root.nState.openSubPage(1)
            }

            RowButton {
                last: true
                icon: "vpn_key"
                text: Tr.tr("Wi-Fi, ethernet and VPN")
                subtext: Tr.tr("Connect, saved networks, VPN providers")
                onClicked: root.nState.openPage("network", 0, "")
            }

            // ---- acesso remoto -------------------------------------------------
            ToolSection {
                tool: "remote"
                title: Tr.tr("Use this PC from your phone or tablet")
                icon: "cast"
                hint: Tr.tr("Sunshine streams the screen (HEVC on the GPU) with touch, keyboard, mouse and controller. On the device, install Moonlight, pick this PC and type the PIN it shows below. On the home network now; over the VPN once Tailscale is logged in.")
            }

            // PIN do Moonlight: campo curto, nome do aparelho, botao. Sem texto de apoio
            // nos campos (sobrepunha um ao outro); o que falta dizer esta no resumo acima.
            ConnectedRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                first: true
                last: true
                implicitHeight: pinRow.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: pinRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        id: pinField

                        Layout.preferredWidth: Tokens.padding.extraExtraLarge * 5
                        placeholderText: Tr.tr("PIN from Moonlight")
                        leadingIcon: "pin"
                        inputMethodHints: Qt.ImhDigitsOnly
                        onTextChanged: root.pinText = text
                        onAccepted: nameField.forceActiveFocus()
                    }

                    StyledTextField {
                        id: nameField

                        Layout.fillWidth: true
                        placeholderText: Tr.tr("Device name (e.g. OP's Phone)")
                        leadingIcon: "devices"
                        onTextChanged: root.pinName = text
                        onAccepted: pairButton.clicked()
                    }

                    TextButton {
                        id: pairButton

                        Layout.preferredWidth: Tokens.padding.extraExtraLarge * 3
                        text: remote.busyAction.startsWith("pair") ? Tr.tr("Pairing…") : Tr.tr("Pair")
                        enabled: /^\d{4}$/.test(root.pinText) && remote.busyAction === ""
                        opacity: enabled ? 1 : 0.5
                        onClicked: {
                            remote.run({ id: `pair~${root.pinText}~${root.pinName.trim() || "device"}` });
                            pinField.text = "";
                        }
                    }
                }
            }
        }

        TabPane {
            id: homePane

            active: root.tab === "home"

            // So nasce na primeira abertura (lista os aparelhos pela CLI a cada 30 s enquanto visivel).
            Loader {
                Layout.fillWidth: true
                active: homePane.opened
                sourceComponent: HomeNetwork {
                    page: root
                    bridge: nas
                }
            }
        }
    }

    // No do diagrama: icone grande, nome e detalhe
    component NetNode: ColumnLayout {
        id: node

        property string icon
        property string label
        property string sub
        property bool dim

        Layout.preferredWidth: 1
        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Tokens.padding.extraExtraLarge * 2
            implicitHeight: implicitWidth
            radius: Tokens.rounding.medium
            color: "transparent"
            border.width: 1
            border.color: node.dim ? Colours.palette.m3outlineVariant : Colours.palette.m3outline

            MaterialIcon {
                anchors.centerIn: parent
                text: node.icon
                color: node.dim ? Colours.palette.m3outline : Colours.palette.m3primary
                fontStyle: Tokens.font.icon.size(Tokens.padding.extraExtraLarge).build()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: node.label
            horizontalAlignment: Text.AlignHCenter
            color: node.dim ? Colours.palette.m3outline : Colours.palette.m3onSurface
            font: Tokens.font.label.medium
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: node.sub !== ""
            text: node.sub
            horizontalAlignment: Text.AlignHCenter
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }
    }

    // Ligacao entre dois nos: linha com o nome do enlace em cima
    component NetLink: ColumnLayout {
        id: link

        property string label

        Layout.preferredWidth: 1
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: Tokens.padding.extraExtraLarge - Tokens.padding.small
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            text: link.label
            horizontalAlignment: Text.AlignHCenter
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.palette.m3outline
        }
    }
}
