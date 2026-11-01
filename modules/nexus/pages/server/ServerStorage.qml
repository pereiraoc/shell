pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Storage: os sistemas de arquivos do NAS (SSD do sistema, HDs em Btrfs
// RAID1), a saude SMART de cada disco, e as acoes: scrub (verificacao de
// integridade, demora horas), teste SMART curto, abrir as pastas no Thunar.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var filesystems: root.info.filesystems ?? []
    readonly property var disks: root.info.disks ?? []
    readonly property var maintenance: (root.bridge.actions ?? []).filter(a => a.id === "scrub" || String(a.id).startsWith("smart-short:"))
    readonly property var browsers: S.pickActions(root.bridge.actions, "browse:")

    function fsSubtext(fs: var): string {
        const parts = [fs.fstype ?? ""];
        if (fs.btrfs) {
            parts.push(Tr.tr("%1 on %2 disks").arg(fs.btrfs.profile ?? "?").arg(fs.btrfs.devices ?? "?"));
            const sc = fs.btrfs.scrub;
            if (sc)
                parts.push(sc.errors > 0 ? Tr.tr("scrub found %1 errors").arg(sc.errors) : Tr.tr("scrub %1%2").arg(sc.status ?? "?").arg(sc.started ? ` (${sc.started})` : ""));
        }
        return parts.filter(x => x).join(" · ");
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    // Mesma silhueta da Overview; aqui o clique so escolhe a peca (baia ou M.2)
    // e a legenda diz o disco que esta nela.
    ServerDiagram {
        id: diagram

        Layout.fillWidth: true
        Layout.maximumWidth: 760
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacing.small
        info: root.info
        selected: root.page.selectedSpot
        onPicked: id => root.page.selectedSpot = id
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.small
        text: diagram.hovered !== "" ? S.spotLegend(diagram.hovered, root.info) : root.page.selectedSpot !== "" ? S.spotLegend(root.page.selectedSpot, root.info) : Tr.tr("Click a bay or an M.2 slot to read its disk.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("The system lives on the internal SSD; photos, cloud files and media live on the two HDs mirrored with Btrfs RAID1. A scrub reads everything and checks the checksums.")
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
        text: Tr.tr("FILESYSTEMS")
    }

    Repeater {
        model: root.online ? root.filesystems.length : 0

        MeterRow {
            id: fsRow

            required property int index
            property var modelData: root.filesystems[index] ?? ({})
            readonly property var liveItem: root.filesystems[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: fsRow.index === 0
            last: fsRow.index === root.filesystems.length - 1
            icon: fsRow.modelData.fstype === "btrfs" ? "hard_drive" : "memory"
            label: fsRow.modelData.mount ?? ""
            subtext: root.fsSubtext(fsRow.modelData)
            valueText: Tr.tr("%1 of %2").arg(S.fmtBytes(fsRow.modelData.used)).arg(S.fmtBytes(fsRow.modelData.size))
            value: S.pct(fsRow.modelData)
            warnAt: 0.75
        }
    }

    SectionHeader {
        visible: root.online && root.disks.length > 0
        text: Tr.tr("DISKS")
    }

    Repeater {
        model: root.online ? root.disks.length : 0

        InfoRow {
            id: disk

            required property int index
            property var modelData: root.disks[index] ?? ({})
            readonly property var liveItem: root.disks[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: disk.index === 0
            last: disk.index === root.disks.length - 1
            icon: disk.modelData.smart === "FAILED" ? "error" : disk.modelData.kind === "hdd" ? "hard_drive" : "memory"
            iconColour: disk.modelData.smart === "FAILED" ? Colours.palette.m3error : disk.modelData.smart === "PASSED" ? Colours.palette.m3primary : Colours.palette.m3outline
            label: `${disk.modelData.dev ?? ""} · ${disk.modelData.model ?? ""}`
            subtext: [disk.modelData.kind === "hdd" ? Tr.tr("hard disk") : Tr.tr("SSD"), S.fmtBytes(disk.modelData.size), disk.modelData.smart ? Tr.tr("SMART %1").arg(disk.modelData.smart) : Tr.tr("SMART unknown"), disk.modelData.temp !== null && disk.modelData.temp !== undefined ? `${disk.modelData.temp} °C` : ""].filter(x => x).join(" · ")
        }
    }

    SectionHeader {
        visible: root.online && root.maintenance.length > 0
        text: Tr.tr("CHECKS")
    }

    Repeater {
        model: root.online ? root.maintenance.length : 0

        RowButton {
            id: act

            required property int index
            property var modelData: root.maintenance[index] ?? ({})
            readonly property var liveItem: root.maintenance[index]
            readonly property bool isArmed: root.page.armed === act.modelData.id
            readonly property bool isBusy: root.bridge.busyAction === act.modelData.id

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: act.index === 0
            last: act.index === root.maintenance.length - 1
            color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
            icon: act.isBusy ? "hourglass_top" : act.modelData.id === "scrub" ? "fact_check" : "monitor_heart"
            text: root.page.actionText(act.modelData)
            subtext: act.modelData.detail ?? ""
            disabled: root.bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (!act.isBusy)
                    root.page.press(act.modelData);
            }
        }
    }

    SectionHeader {
        visible: root.online && root.browsers.length > 0
        text: Tr.tr("FOLDERS")
    }

    Repeater {
        model: root.online ? root.browsers.length : 0

        RowButton {
            id: browser

            required property int index
            property var modelData: root.browsers[index] ?? ({})
            readonly property var liveItem: root.browsers[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: browser.index === 0
            last: browser.index === root.browsers.length - 1
            icon: browser.modelData.icon ?? "folder_open"
            text: browser.modelData.label ?? ""
            subtext: browser.modelData.detail ?? ""
            trailingIcon: "open_in_new"
            onClicked: root.bridge.run(browser.modelData)
        }
    }
}
