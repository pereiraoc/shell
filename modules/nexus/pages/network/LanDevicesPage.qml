pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Aparelhos da rede de casa (01-pendencias "rede domestica" + RPi4):
// caelestia-lan le a tabela de vizinhos do kernel, varre a sub-rede sob
// demanda, guarda nome/tipo/usuario por MAC e testa portas. Abre a interface
// web (roteador/switch/quem tem 80/443) e SSH num terminal.
PageBase {
    id: root

    readonly property var net: lan.info.network ?? null
    readonly property var devices: lan.info.devices ?? []
    readonly property var limits: lan.info.limits ?? []
    property string selectedMac
    readonly property var selected: root.devices.find(d => d.mac === root.selectedMac) ?? null
    readonly property var typeIcons: ({
            router: "router",
            switch: "lan",
            pc: "desktop_windows",
            laptop: "laptop",
            tv: "tv",
            phone: "smartphone",
            console: "sports_esports",
            printer: "print",
            iot: "sensors",
            server: "dns",
            other: "devices_other"
        })

    function label(d: var): string {
        return d.name || d.hostname.replace(/\.(local|lan|home)$/, "") || d.vendor || d.ip;
    }

    function ago(t: int): string {
        if (!t)
            return "";
        const m = Math.round((Date.now() / 1000 - t) / 60);
        return m < 1 ? Tr.tr("just now") : m < 60 ? Tr.tr("%1 min ago").arg(m) : m < 1440 ? Tr.tr("%1 h ago").arg(Math.round(m / 60)) : Tr.tr("%1 d ago").arg(Math.round(m / 1440));
    }

    function portsText(d: var): string {
        if (!d.ports)
            return Tr.tr("Not checked yet");
        const known = lan.info.ports_known ?? {};
        const open = d.ports.open ?? [];
        return open.length ? open.map(p => `${p} ${known[p] ?? ""}`.trim()).join(" · ") : Tr.tr("No common port open");
    }

    title: Tr.tr("Devices on this network")
    isSubPage: true

    ToolBridge {
        id: lan

        tool: "lan"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Lista viva: a tabela do kernel muda sozinha; reler a cada 10 s
        Timer {
            running: root.visible
            repeat: true
            interval: 10000
            onTriggered: lan.refresh()
        }

        SectionHeader {
            first: true
            text: root.net ? Tr.tr("%1 · you are %2").arg(root.net.subnet).arg(root.net.ip) : Tr.tr("Not connected")
        }

        RowButton {
            first: true
            last: root.devices.length === 0
            icon: "radar"
            text: lan.busyAction === "scan" ? Tr.tr("Scanning…") : Tr.tr("Scan the network")
            subtext: (lan.info.last_scan ?? 0) ? Tr.tr("%1 · last scan %2").arg(lan.summary).arg(root.ago(lan.info.last_scan)) : lan.summary
            disabled: lan.busyAction !== "" || !root.net
            onClicked: lan.run({ id: "scan" })
        }

        Repeater {
            model: root.devices

            ConnectedRect {
                id: devRow

                required property var modelData
                required property int index

                readonly property bool isSel: root.selectedMac === modelData.mac

                Layout.fillWidth: true
                last: index === root.devices.length - 1
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2
                color: isSel ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

                StateLayer {
                    onClicked: root.selectedMac = devRow.isSel ? "" : devRow.modelData.mac
                }

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: root.typeIcons[devRow.modelData.type] ?? "devices_other"
                        color: devRow.modelData.online ? Colours.palette.m3primary : Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.label(devRow.modelData)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: [devRow.modelData.ip, devRow.modelData.name || devRow.modelData.hostname ? devRow.modelData.vendor : "", devRow.modelData.online ? "" : Tr.tr("offline · seen %1").arg(root.ago(devRow.modelData.last_seen))].filter(x => x).join(" · ")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    MaterialIcon {
                        text: devRow.isSel ? "expand_less" : "expand_more"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }

        // ---- aparelho escolhido
        SectionHeader {
            visible: !!root.selected
            text: root.selected ? root.label(root.selected) : ""
        }

        InfoRow {
            visible: !!root.selected
            first: true
            icon: "info"
            label: root.selected ? `${root.selected.ip} · ${root.selected.mac}` : ""
            subtext: root.selected ? [root.selected.vendor, root.selected.hostname].filter(x => x).join(" · ") : ""
        }

        TextFieldRow {
            visible: !!root.selected
            label: Tr.tr("Name")
            subtext: Tr.tr("Kept by MAC address, even when the IP changes")
            value: root.selected?.name ?? ""
            maximumLength: 60
            onEditingFinished: v => {
                if (root.selected && v.trim() !== (root.selected.name ?? ""))
                    lan.run({ id: `name~${root.selected.mac}~${v.trim()}` });
            }
        }

        ExpandSelectRow {
            visible: !!root.selected
            icon: root.typeIcons[root.selected?.type ?? ""] ?? "devices_other"
            label: Tr.tr("Type")
            subtext: root.selected?.gateway ? Tr.tr("This is the router (default gateway)") : Tr.tr("Sets the icon; router and switch get the web page button")
            options: (lan.info.types ?? []).map(t => ({ value: t, label: t === "pc" || t === "tv" || t === "iot" ? t.toUpperCase() : t.charAt(0).toUpperCase() + t.slice(1) }))
            current: root.selected?.type ?? ""
            busy: lan.busyAction.startsWith("type~")
            onPicked: v => lan.run({ id: `type~${root.selected.mac}~${v}` })
        }

        RowButton {
            visible: !!root.selected
            icon: "lan"
            text: lan.busyAction.startsWith("ports~") ? Tr.tr("Checking ports…") : Tr.tr("Check open ports")
            subtext: root.selected ? root.portsText(root.selected) : ""
            disabled: lan.busyAction !== ""
            onClicked: lan.run({ id: `ports~${root.selected.ip}` })
        }

        RowButton {
            visible: !!root.selected && root.selected.web_url !== ""
            icon: "open_in_browser"
            text: Tr.tr("Open the web interface")
            subtext: root.selected?.web_url ?? ""
            trailingIcon: "open_in_new"
            onClicked: Quickshell.execDetached(["xdg-open", root.selected.web_url])
        }

        TextFieldRow {
            visible: !!root.selected && root.selected.ssh
            label: Tr.tr("SSH user")
            subtext: Tr.tr("Raspberry Pi OS / RetroPie: pi")
            value: root.selected?.ssh_user ?? ""
            smallField: true
            maximumLength: 32
            onEditingFinished: v => {
                if (root.selected && v.trim() !== (root.selected.ssh_user ?? ""))
                    lan.run({ id: `user~${root.selected.mac}~${v.trim()}` });
            }
        }

        RowButton {
            visible: !!root.selected
            last: true
            icon: "terminal"
            text: Tr.tr("Open SSH in a terminal")
            subtext: {
                const d = root.selected;
                if (!d)
                    return "";
                if (d.ssh)
                    return `ssh ${d.ssh_user ? d.ssh_user + "@" : ""}${d.ip}`;
                if (!d.ports)
                    return Tr.tr("Check open ports first");
                return d.vendor.startsWith("Raspberry") ? Tr.tr("SSH is off on the Pi: RetroPie menu › RASPI-CONFIG › Interface Options › SSH") : Tr.tr("Port 22 is closed on this device");
            }
            disabled: !root.selected?.ssh
            onClicked: Quickshell.execDetached(["kitty", "--title", `SSH ${root.label(root.selected)}`, "ssh", `${root.selected.ssh_user ? root.selected.ssh_user + "@" : ""}${root.selected.ip}`])
        }

        // O que daqui nao da para ver
        SectionHeader {
            text: Tr.tr("Not visible from this PC")
        }

        Repeater {
            model: root.limits

            InfoRow {
                required property string modelData
                required property int index

                first: index === 0
                last: index === root.limits.length - 1
                icon: "visibility_off"
                label: modelData
            }
        }
    }
}
