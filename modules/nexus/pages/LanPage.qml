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

// A rede como ela esta (pedido de 01/11): o diagrama desta rede (internet,
// roteador, este PC, a VPN por cima), o que ha nela (caelestia-lan; a lista
// completa e a subpagina 1), a rede de casa pelo monitor que roda no NAS
// (caelestia-nas; DS-18) e o acesso remoto ao PC pelo celular e pelo tablet
// (caelestia-remote: Sunshine + Moonlight; DS-37, CF-29). Wi-Fi, ethernet e VPN
// ficam na pagina Internet.
PageBase {
    id: root

    readonly property var net: lan.info.network ?? null
    readonly property var devices: lan.info.devices ?? []
    readonly property int onlineCount: root.devices.filter(d => d.online).length
    readonly property var router: root.devices.find(d => d.type === "router") ?? null
    readonly property string routerName: root.router ? (root.router.name || root.router.hostname || root.router.vendor || Tr.tr("Router")) : Tr.tr("Router")
    readonly property string linkText: Nmcli.activeEthernet ? Tr.tr("Ethernet") : (Nmcli.active ? (Nmcli.active.ssid ?? Tr.tr("Wi-Fi")) : (root.net ? root.net.iface : Tr.tr("No connection")))
    readonly property bool nasOnline: nas.info.online === true
    readonly property var monitor: nas.info.monitor ?? null
    readonly property var pending: remote.info.pending ?? []
    property string pinText
    property string pinName

    title: Tr.tr("Network")
    description: Tr.tr("How you are connected, what is on this network, home, remote access")

    ToolBridge {
        id: lan

        tool: "lan"
        autoRefresh: 15000
    }

    ToolBridge {
        id: nas

        tool: "nas"
        autoRefresh: 60000
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

        // ---- em casa -------------------------------------------------------
        SectionHeader {
            text: Tr.tr("At home")
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.nasOnline && !!root.monitor
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

        InfoRow {
            first: true
            last: false
            visible: !root.nasOnline
            icon: "home"
            iconColour: Colours.palette.m3outline
            label: nas.info.last_seen ? Tr.tr("The NAS is out of reach · last seen %1").arg(String(nas.info.last_seen).replace("T", " ").slice(5, 16)) : Tr.tr("The NAS is out of reach")
            subtext: Tr.tr("The home map (router, switch, every device) lives in the monitor on the NAS; it shows here when the NAS answers, at home or over the VPN")
        }

        RowButton {
            first: root.nasOnline
            last: true
            icon: "hub"
            text: Tr.tr("Home network monitor (on the NAS)")
            subtext: Tr.tr("New and unknown devices, alerts on the phone, network map")
            onClicked: root.nState.openPage("server", 0, "network")
        }

        // ---- acesso remoto -------------------------------------------------
        ToolSection {
            tool: "remote"
            title: Tr.tr("Use this PC from your phone or tablet")
            icon: "cast"
            hint: Tr.tr("Sunshine streams the screen (HEVC on the GPU) with touch, keyboard, mouse and controller. On the device, install Moonlight, pick this PC and type the PIN it shows below. On the home network now; over the VPN once Tailscale is logged in.")
        }

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

                    Layout.preferredWidth: Tokens.padding.extraExtraLarge * 4
                    placeholderText: Tr.tr("PIN")
                    supportingText: root.pending.length > 0 ? Tr.tr("%1 waiting").arg(root.pending[0].name || root.pending[0].id.slice(0, 8)) : Tr.tr("4 digits from Moonlight")
                    leadingIcon: "pin"
                    inputMethodHints: Qt.ImhDigitsOnly
                    onTextChanged: root.pinText = text
                    onAccepted: nameField.forceActiveFocus()
                }

                StyledTextField {
                    id: nameField

                    Layout.fillWidth: true
                    placeholderText: Tr.tr("Device name")
                    supportingText: Tr.tr("e.g. OP's Tablet")
                    leadingIcon: "devices"
                    onTextChanged: root.pinName = text
                    onAccepted: pairButton.clicked()
                }

                TextButton {
                    id: pairButton

                    text: remote.busyAction.startsWith("pair") ? Tr.tr("Pairing…") : Tr.tr("Pair")
                    enabled: /^\d{4}$/.test(root.pinText) && remote.busyAction === ""
                    onClicked: {
                        remote.run({ id: `pair~${root.pinText}~${root.pinName.trim() || "device"}` });
                        pinField.text = "";
                    }
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
            radius: Tokens.rounding.normal
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
