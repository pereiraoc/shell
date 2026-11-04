pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Storage: os sistemas de arquivos do NAS (SSD do sistema, HDs em Btrfs
// RAID1), a saude SMART de cada disco, e as acoes: scrub (verificacao de
// integridade, demora horas), teste SMART curto, abrir as pastas no Thunar.
// Os discos vem do `caelestia-nas disks --json` (mesmo formato do caelestia-storage)
// e aparecem no DiskCard da aba Partitions; clicar abre a arvore do NAS.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var disks: root.info.disks ?? []
    readonly property var maintenance: (root.bridge.actions ?? []).filter(a => a.id === "scrub" || String(a.id).startsWith("smart-short:"))
    readonly property var browsers: S.pickActions(root.bridge.actions, "browse:")
    property var nasDisks: []
    property string disksError

    function browse(path: string): void {
        root.page.nState.storageRemote = true;
        root.page.nState.storagePath = path;
        root.page.nState.openSubPage(1);
    }

    function loadDisks(): void {
        if (!disksProc.running)
            disksProc.running = true;
    }

    onOnlineChanged: if (root.online && root.nasDisks.length === 0) root.loadDisks()
    Component.onCompleted: root.loadDisks()

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
        selected: root.page.nState.selectedNasSpot
        bottomExpanded: true
        onPicked: id => root.page.nState.selectedNasSpot = id
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
            text: diagram.hovered !== "" ? S.spotLegend(diagram.hovered, root.info) : root.page.nState.selectedNasSpot !== "" ? S.spotLegend(root.page.nState.selectedNasSpot, root.info) : Tr.tr("Click a bay or an M.2 slot to read its disk.")
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
        text: Tr.tr("The system lives on the internal SSD; app data on the Lexar; photos, cloud files and media on the two HDs mirrored with Btrfs RAID1. Click a partition to see what takes space in it. A scrub reads everything and checks the checksums.")
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

    // Um cartao por disco do NAS, igual a aba Partitions (barra GParted + particoes
    // na ordem do disco). Clicar numa particao montada abre a arvore de pastas dela
    // no proprio NAS (StorageBrowser em modo remoto: caelestia-nas du).
    Repeater {
        model: root.online ? root.nasDisks.length : 0

        DiskCard {
            id: card

            required property int index
            readonly property var health: root.disks.find(d => d.dev === (root.nasDisks[card.index]?.name ?? "")) ?? ({})

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium
            disk: root.nasDisks[card.index] ?? ({})
            fmt: S.fmtBytes
            firstCard: card.index === 0
            extra: [card.health.smart ? Tr.tr("SMART %1").arg(card.health.smart) : "", card.health.temp !== null && card.health.temp !== undefined ? `${card.health.temp} °C` : "", card.health.bay ? Tr.tr("bay %1").arg(card.health.bay) : ""].filter(x => x).join("  ·  ")
            onBrowse: path => root.browse(path)
        }
    }

    InfoRow {
        visible: root.online && root.nasDisks.length === 0
        first: true
        last: true
        icon: disksProc.running ? "hourglass_top" : "hard_drive"
        iconColour: Colours.palette.m3tertiary
        label: disksProc.running ? Tr.tr("Reading the NAS disks…") : Tr.tr("Could not read the NAS disks")
        subtext: root.disksError
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
            readonly property bool isArmed: root.bridge.armed === act.modelData.id
            readonly property bool isBusy: root.bridge.busyAction === act.modelData.id

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: act.index === 0
            last: act.index === root.maintenance.length - 1
            color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
            icon: act.isBusy ? "hourglass_top" : act.modelData.id === "scrub" ? "fact_check" : "monitor_heart"
            text: root.bridge.actionText(act.modelData)
            subtext: act.modelData.detail ?? ""
            disabled: root.bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (!act.isBusy)
                    root.bridge.press(act.modelData);
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

    // Leitor dos discos (o layout ignora Item invisivel). Particoes mudam pouco:
    // le ao abrir e a cada 5 min enquanto a aba esta aberta.
    Item {
        visible: false

        Process {
            id: disksProc

            command: [`${Quickshell.env("HOME")}/.local/bin/caelestia-nas`, "disks", "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const d = JSON.parse(text);
                        if (d.ok)
                            root.nasDisks = d.disks ?? [];
                        root.disksError = d.ok ? "" : (d.message ?? "");
                    } catch (e) {
                        root.disksError = Tr.tr("caelestia-nas disks did not return JSON");
                    }
                }
            }
        }

        Timer {
            interval: 300000
            repeat: true
            running: root.visible && root.online
            onTriggered: root.loadDisks()
        }
    }
}
