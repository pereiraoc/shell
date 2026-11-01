pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Overview: cartoes de saude (alcance, CPU/RAM, HDs, backup, servicos, VPN)
// e a fila "Open" que abre cada app no lugar certo (janela web ou app nativo)
// e as pastas no Thunar. Offline: o que aconteceu e quando foi visto por ultimo.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var store: S.storageFs(root.info, "/srv/storage")
    readonly property var backup: root.info.backup ?? null
    readonly property var overlay: root.info.overlay ?? null
    readonly property var temps: root.info.temps ?? ({})
    readonly property var mem: root.info.mem ?? ({})
    readonly property var launchers: S.pickActions(root.bridge.actions, "open:").concat(S.pickActions(root.bridge.actions, "browse:"))
    readonly property int stacksUp: (root.info.stacks ?? []).filter(s => s.active === "active").length
    readonly property int stacksTotal: (root.info.stacks ?? []).length

    function backupText(): string {
        if (!root.backup)
            return Tr.tr("No backup job");
        if (root.backup.running)
            return Tr.tr("Running now");
        if (root.backup.last_result === "failed")
            return Tr.tr("Last one failed");
        if (root.backup.last_result === "success")
            return Tr.tr("OK, %1").arg(S.fmtAgo(root.backup.last_start));
        return Tr.tr("Never ran");
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    // A silhueta do aparelho, como nas paginas de teclado e mouse: cada peca
    // pinta o estado, o mouse em cima mostra a legenda, o clique abre a aba dela.
    ServerDiagram {
        id: diagram

        Layout.fillWidth: true
        Layout.maximumWidth: 760
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.small
        info: root.info
        selected: root.page.selectedSpot
        bottomExpanded: false
        onPicked: id => {
            root.page.selectedSpot = id;
            root.page.nState.openPage("server", 0, S.spotTab(id));
        }
    }

    // Legenda do que esta sob o mouse e, no canto, o botao miudo que abre ou
    // fecha a vista de baixo (M.2 e memoria, na largura da frente)
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: diagram.hovered !== "" ? S.spotLegend(diagram.hovered, root.info) : root.page.selectedSpot !== "" ? S.spotLegend(root.page.selectedSpot, root.info) : Tr.tr("Hover a bay, the fan or a port to read it; click to open its tab.")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        IconTextButton {
            Layout.alignment: Qt.AlignTop
            type: IconTextButton.Text
            icon: diagram.bottomExpanded ? "expand_less" : "expand_more"
            text: diagram.bottomExpanded ? Tr.tr("Hide the underside") : Tr.tr("Underside")
            onClicked: diagram.bottomExpanded = !diagram.bottomExpanded
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("Health of the NAS at a glance, and where to open photos, cloud, movies and music. Also in a terminal: caelestia-nas status.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    // ------------------------------------------------------------- offline
    InfoRow {
        visible: !root.online
        first: true
        icon: root.bridge.loading ? "hourglass_empty" : "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: root.bridge.loading ? Tr.tr("Reaching the NAS…") : Tr.tr("NAS out of reach")
        subtext: root.online ? "" : [root.info.error ?? "", root.info.last_seen ? Tr.tr("Last seen %1").arg(S.fmtAgo(root.info.last_seen)) : ""].filter(x => x).join(" · ")
    }

    RowButton {
        visible: !root.online
        last: true
        icon: "refresh"
        text: Tr.tr("Try again")
        subtext: Tr.tr("Pings the NAS over SSH (home network first, then the VPN)")
        disabled: root.bridge.loading
        onClicked: root.bridge.refresh()
    }

    // ------------------------------------------------------------- cartoes
    GridLayout {
        visible: root.online
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.medium
        columns: width >= 520 ? 2 : 1
        columnSpacing: Tokens.spacing.small
        rowSpacing: Tokens.spacing.small

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "dns"
            title: Tr.tr("Reach")
            value: root.page.reachLabel()
            detail: Tr.tr("%1 · up for %2").arg(root.info.host ?? "").arg(S.fmtUptime(root.info.uptime_s))
            level: root.page.reach === "ssh" ? "warn" : "ok"
            onClicked: root.page.nState.openPage("server", 0, "system")
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "thermostat"
            title: Tr.tr("CPU and memory")
            value: root.temps.cpu !== undefined && root.temps.cpu !== null ? `${Math.round(root.temps.cpu)} °C` : "?"
            detail: Tr.tr("load %1 · %2 of %3 MB used").arg((root.info.load ?? ["?"])[0]).arg(root.mem.used ?? "?").arg(root.mem.total ?? "?")
            level: (root.temps.cpu ?? 0) >= 85 ? "error" : (root.temps.cpu ?? 0) >= 70 ? "warn" : "ok"
            onClicked: root.page.nState.openPage("server", 0, "system")
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "hard_drive"
            title: Tr.tr("Storage")
            value: root.store ? Tr.tr("%1 free").arg(S.fmtBytes(root.store.avail)) : Tr.tr("HDs not mounted")
            detail: root.store ? Tr.tr("%1% used · %2 on %3 disks · scrub %4").arg(root.store.pct).arg(root.store.btrfs?.profile ?? "?").arg(root.store.btrfs?.devices ?? "?").arg(root.store.btrfs?.scrub?.status ?? "?") : Tr.tr("Services stay down until /srv/storage is mounted")
            level: root.store ? S.fsLevel(root.store) : "error"
            onClicked: root.page.nState.openPage("server", 0, "storage")
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "backup"
            title: Tr.tr("Backup")
            value: root.backupText()
            detail: root.backup?.alert ? Tr.tr("Disk space alert on the HDs") : root.backup?.next ? Tr.tr("Next %1").arg(root.backup.next.replace("T", " ")) : ""
            level: S.backupLevel(root.backup)
            onClicked: root.page.nState.openPage("server", 0, "system")
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "deployed_code"
            title: Tr.tr("Services")
            value: root.stacksTotal === 0 ? Tr.tr("None configured") : Tr.tr("%1 of %2 running").arg(root.stacksUp).arg(root.stacksTotal)
            detail: (root.info.stacks ?? []).map(s => `${s.name} ${s.active === "active" ? "✓" : "✗"}`).join(" · ")
            level: root.stacksTotal > 0 && root.stacksUp < root.stacksTotal ? "warn" : "ok"
            onClicked: root.page.nState.openPage("server", 0, "services")
        }

        StatusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            icon: "vpn_lock"
            title: Tr.tr("Remote access")
            value: !root.overlay ? Tr.tr("No VPN on the NAS") : root.overlay.online ? Tr.tr("%1 online").arg(root.overlay.kind) : Tr.tr("%1 offline").arg(root.overlay.kind)
            detail: root.overlay ? [root.overlay.ip ?? "", root.overlay.name ?? ""].filter(x => x).join(" · ") : Tr.tr("Only the home network reaches it")
            level: root.overlay && !root.overlay.online ? "warn" : "ok"
            onClicked: root.page.nState.openPage("server", 0, "system")
        }
    }

    // ------------------------------------------------------------- abrir
    SectionHeader {
        visible: root.online
        text: Tr.tr("OPEN")
    }

    InfoRow {
        visible: root.online && root.launchers.length === 0
        first: true
        last: true
        icon: "apps"
        label: Tr.tr("Nothing to open yet")
        subtext: Tr.tr("The apps appear here once caelestia-nas knows them")
    }

    Repeater {
        model: root.online ? root.launchers.length : 0

        RowButton {
            id: launcher

            required property int index
            property var modelData: root.launchers[index] ?? ({})
            readonly property var liveItem: root.launchers[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: launcher.index === 0
            last: launcher.index === root.launchers.length - 1
            icon: launcher.modelData.icon ?? "open_in_new"
            text: launcher.modelData.label ?? ""
            subtext: launcher.modelData.detail ?? ""
            trailingIcon: "open_in_new"
            onClicked: root.bridge.run(launcher.modelData)
        }
    }
}
