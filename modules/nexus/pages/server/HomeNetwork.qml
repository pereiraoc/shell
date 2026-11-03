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
import "homenet.js" as H

// Aba Network > Home: o mapa da rede de casa pelo monitor do NAS (NetAlertX +
// o que o NAS sabe dos enlaces: roteador, Cast, ethtool, varredura de Wi-Fi).
// Em cima, o resumo e os aparelhos desconhecidos (marcar como conhecido, dar
// apelido e tipo ali mesmo); embaixo, a arvore Internet > roteador > Cabo /
// Wi-Fi por AP e faixa > tipo, com o chip de conexao em cada linha. Clicar
// num aparelho abre o editor embaixo dele.
//
// Dados: `caelestia-nas network --all --json` (lista completa) a cada 30 s
// enquanto visivel. Edicoes: `caelestia-nas network name|type|known <MAC>`,
// e `group <principal> <MAC>...|ungroup <MAC>|delete <MAC>` (um aparelho com
// varios enderecos; o backend ja manda uma linha por grupo, com `macs`),
// numa fila (um ssh por vez) com a lista otimista (H.applyPending), como em
// ServerUsers; relemos quando a fila esvazia. A logica pura mora em homenet.js.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/caelestia-nas`
    readonly property string surveyBin: `${Quickshell.env("HOME")}/.local/bin/caelestia-wifi-survey`

    property var devices: []
    property bool loaded
    property string listError
    // Fila de ops { verb, mac, value } (a primeira roda) e as ja aplicadas desde a ultima leitura
    property var queue: []
    property var applied: []
    property bool reloadAgain
    // { mac, message }
    property var lastError: ({})
    property string selectedMac
    property bool showOffline: true
    // Varredura de Wi-Fi: dois cliques, ~3 min, depois relê
    property bool surveyArmed
    property string surveyResult
    property bool surveyFailed

    readonly property bool online: root.bridge.info.online === true
    readonly property var monitor: root.bridge.info.monitor ?? null
    readonly property bool monitorOk: !!root.monitor && root.monitor.ok === true
    readonly property var view: H.applyPending(root.devices, [...root.applied, ...root.queue])
    readonly property var byMac: H.indexByMac(root.view)
    readonly property var rows: H.buildMap(root.view, { showOffline: root.showOffline })
    readonly property var unknowns: H.unknownDevices(root.view)
    readonly property var sum: H.summary(root.view)
    readonly property bool working: root.queue.length > 0
    readonly property real indent: Tokens.padding.extraExtraLarge / 2
    readonly property color railColour: Qt.alpha(Colours.palette.m3outline, 0.7)
    readonly property var labels: ({
            wifi: Tr.tr("Wi-Fi"),
            cable: Tr.tr("Cable"),
            unknown: Tr.tr("Unknown")
        })

    function reload(): void {
        if (!root.online)
            return;
        if (listProc.running) {
            root.reloadAgain = true;
            return;
        }
        listProc.snapshot = root.applied.length;
        listProc.running = true;
    }

    function enqueue(verb: string, mac: string, value: var): void {
        root.enqueueOp({ verb: verb, mac: mac.toLowerCase(), value: value });
    }

    // op { verb, mac, value, owner? }: owner = o aparelho (MAC principal) em que
    // o erro aparece quando a op e sobre outro endereco (ungroup de um extra)
    function enqueueOp(op: var): void {
        const owner = op.owner || op.mac;
        if (root.lastError.mac === owner)
            root.lastError = ({});
        root.queue = H.enqueueOp(root.queue, op);
        if (!actProc.running)
            root.startNext();
    }

    function startNext(): void {
        if (root.queue.length === 0) {
            root.reload();
            return;
        }
        actProc.op = root.queue[0];
        actProc.command = [root.bin, ...H.opArgs(actProc.op)];
        actProc.running = true;
    }

    function finishOp(text: string): void {
        const op = actProc.op;
        let doc = null;
        try {
            doc = JSON.parse(text);
        } catch (e) {
            doc = { ok: false, message: Tr.tr("unreadable answer from caelestia-nas") };
        }
        if (doc.ok)
            root.applied = [...root.applied, op];
        else
            root.lastError = { mac: op.owner || op.mac, message: doc.message || Tr.tr("The NAS refused (no message)") };
        root.queue = root.queue.slice(1);
        Qt.callLater(root.startNext);
    }

    function chipOf(d: var): var {
        return H.chip(d, root.byMac, root.labels);
    }

    function sourceText(src: string): string {
        switch (src) {
        case "router":
            return Tr.tr("from the router");
        case "cast":
            return Tr.tr("from Google Cast");
        case "ethtool":
            return Tr.tr("measured on the device");
        case "survey":
            return Tr.tr("from the Wi-Fi survey");
        case "map":
            return Tr.tr("from the NetAlertX map");
        default:
            return Tr.tr("not known");
        }
    }

    function linkLabel(medium: string, band: string): string {
        switch (medium) {
        case "cable":
            return Tr.tr("Cable");
        case "wifi":
            return band ? Tr.tr("Wi-Fi %1").arg(band) : Tr.tr("Wi-Fi (band not known)");
        case "unknown":
            return Tr.tr("Linked here, medium not known");
        default:
            return Tr.tr("Unknown connection");
        }
    }

    function linkIcon(medium: string): string {
        return medium === "cable" ? "cable" : medium === "wifi" ? "wifi" : "help";
    }

    function agoText(s: string): string {
        const m = H.minutesSince(s);
        if (m === null)
            return "";
        return m < 1 ? Tr.tr("just now") : m < 60 ? Tr.tr("%1 min ago").arg(m) : m < 2880 ? Tr.tr("%1 h ago").arg(Math.floor(m / 60)) : Tr.tr("%1 d ago").arg(Math.floor(m / 1440));
    }

    function typeText(t: string): string {
        return t ? H.typeLabel(t) : Tr.tr("No type");
    }

    function subOf(d: var, isRoot: bool): string {
        if (!d)
            return "";
        const name = H.bestName(d);
        const vendor = d.vendor && !/^\(unknown/i.test(d.vendor) && d.vendor !== name ? d.vendor : "";
        return [d.ip || (H.isPassive(d) ? Tr.tr("no IP (unmanaged)") : ""), isRoot ? Tr.tr("main router") : "", H.groupAddrs(d).length > 1 ? Tr.tr("%1 addresses").arg(H.groupAddrs(d).length) : "", vendor, d.online || H.isPassive(d) ? "" : Tr.tr("offline · seen %1").arg(root.agoText(d.last_seen))].filter(x => x).join(" · ");
    }

    function pressSurvey(): void {
        if (surveyProc.running)
            return;
        if (!root.surveyArmed) {
            root.surveyArmed = true;
            disarm.restart();
            return;
        }
        root.surveyArmed = false;
        root.surveyResult = "";
        root.surveyFailed = false;
        surveyProc.running = true;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: reload()
    onOnlineChanged: reload()

    Process {
        id: listProc

        property int snapshot

        command: [root.bin, "network", "--all", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    if (d.ok) {
                        root.devices = d.devices ?? [];
                        root.listError = "";
                        root.loaded = true;
                    } else {
                        root.listError = d.message || Tr.tr("caelestia-nas network failed");
                    }
                } catch (e) {
                    root.listError = Tr.tr("unreadable answer from caelestia-nas");
                }
                // O que ja foi aplicado antes desta leitura agora esta na lista
                root.applied = root.applied.slice(listProc.snapshot);
                if (root.reloadAgain) {
                    root.reloadAgain = false;
                    Qt.callLater(root.reload);
                }
            }
        }
    }

    Process {
        id: actProc

        property var op: ({})

        stdout: StdioCollector {
            onStreamFinished: root.finishOp(text)
        }
    }

    Process {
        id: surveyProc

        command: [root.surveyBin, "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d = null;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    d = { ok: false, message: Tr.tr("unreadable answer from caelestia-wifi-survey") };
                }
                root.surveyFailed = !d.ok;
                root.surveyResult = d.ok ? (d.sent === false ? Tr.tr("Heard %1 client(s), but could not send them to the NAS").arg(d.count ?? 0) : Tr.tr("Heard %1 client(s) on the home access points").arg(d.count ?? 0)) : (d.message || Tr.tr("The survey failed (no message)"));
                root.reload();
            }
        }
    }

    Timer {
        id: disarm

        interval: 4000
        onTriggered: root.surveyArmed = false
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.visible && !root.working
        onTriggered: root.reload()
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("Every device in the house and what it hangs from, as the NAS sees it (NetAlertX plus what the router, Google Cast and the Wi-Fi survey tell). Click a device to name it, set its type, mark it as known or group its addresses (a phone with a random MAC per network is one device).")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: !root.online || !root.monitorOk
        first: true
        last: true
        icon: root.online ? "lan" : "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: !root.online ? Tr.tr("NAS out of reach") : Tr.tr("Network monitor not running")
        subtext: !root.online ? "" : (root.monitor?.message ?? Tr.tr("The netalertx stack is off or still starting"))
    }

    InfoRow {
        visible: root.listError !== ""
        first: true
        last: true
        icon: "error"
        iconColour: Colours.palette.m3error
        label: Tr.tr("Could not list the devices")
        subtext: root.listError
    }

    InfoRow {
        visible: root.online && !root.loaded && root.listError === ""
        first: true
        last: true
        icon: "hourglass_empty"
        iconColour: Colours.palette.m3primary
        label: Tr.tr("Asking the NAS…")
    }

    // ------------------------------------------------------------ resumo
    ConnectedRect {
        Layout.fillWidth: true
        visible: root.loaded
        first: true
        last: true
        implicitHeight: summaryCol.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: summaryCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.large

                Stat {
                    value: root.sum.online
                    label: Tr.tr("online")
                    tone: Colours.palette.m3primary
                }

                Stat {
                    value: root.sum.fresh
                    label: Tr.tr("new")
                    tone: root.sum.fresh > 0 ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                }

                Stat {
                    value: root.sum.total
                    label: Tr.tr("total")
                    tone: Colours.palette.m3onSurfaceVariant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: root.sum.reads.router ? Tr.tr("Router read %1").arg(root.agoText(root.sum.reads.router)) : Tr.tr("Router not read yet")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                        elide: Text.ElideLeft
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: [root.sum.reads.survey ? Tr.tr("Wi-Fi survey %1").arg(root.agoText(root.sum.reads.survey)) : Tr.tr("No Wi-Fi survey yet"), root.sum.reads.cast ? Tr.tr("Cast %1").arg(root.agoText(root.sum.reads.cast)) : ""].filter(x => x).join(" · ")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideLeft
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignTop
                    text: "visibility_off"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.tr("Not visible from here: the speed of each switch port (the switch is unmanaged) and anything behind the VR router (it runs its own network, NAT).")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    // ------------------------------------------------------------ desconhecidos
    SectionHeader {
        visible: root.loaded
        text: root.unknowns.length > 0 ? Tr.trN("%n UNKNOWN DEVICE", "%n UNKNOWN DEVICES", root.unknowns.length) : Tr.tr("UNKNOWN DEVICES")
    }

    InfoRow {
        visible: root.loaded && root.unknowns.length === 0
        first: true
        last: true
        icon: "check_circle"
        iconColour: Colours.palette.m3primary
        label: Tr.tr("Nothing unknown on the network")
        subtext: Tr.tr("A device seen for the first time shows up here and pings your phone (ntfy)")
    }

    Repeater {
        model: root.loaded ? root.unknowns.length : 0

        ColumnLayout {
            id: card

            required property int index
            property var d: root.unknowns[index] ?? ({})
            readonly property var liveItem: root.unknowns[index]
            readonly property var chip: root.chipOf(card.d)

            onLiveItemChanged: if (liveItem !== undefined) d = liveItem

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall / 2

            ConnectedRect {
                Layout.fillWidth: true
                first: true
                implicitHeight: uHead.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: uHead

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium
                    opacity: card.d.online ? 1 : 0.55

                    MaterialIcon {
                        text: card.d.type ? H.typeIcon(card.d.type) : "new_releases"
                        color: Colours.palette.m3tertiary
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: H.bestName(card.d)
                            font: Tokens.font.title.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: [card.d.ip ?? "", card.d.vendor && H.bestName(card.d) !== card.d.vendor ? card.d.vendor : "", Tr.tr("first seen %1").arg(root.agoText(card.d.first_seen)), card.d.online ? "" : Tr.tr("offline")].filter(x => x).join(" · ")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    ConnChip {
                        Layout.maximumWidth: uHead.width * 0.45
                        chip: card.chip
                        source: root.sourceText(H.sourceOf(card.d))
                        known: H.sourceOf(card.d) !== ""
                    }
                }
            }

            ConnectedRect {
                Layout.fillWidth: true
                last: true
                implicitHeight: uEdit.implicitHeight + Tokens.padding.small * 2

                DeviceEditor {
                    id: uEdit

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.medium
                    host: root
                    dev: card.d
                }
            }
        }
    }

    // ------------------------------------------------------------ mapa
    SectionHeader {
        visible: root.loaded
        text: Tr.tr("HOUSE MAP")
    }

    ToggleRow {
        id: offlineToggle

        visible: root.loaded
        first: true
        text: Tr.tr("Show offline devices")
        subtext: Tr.tr("Offline devices are dimmed; hiding them keeps the map short")
        checked: root.showOffline
        onToggled: root.showOffline = offlineToggle.checked
    }

    ConnectedRect {
        Layout.fillWidth: true
        visible: root.loaded
        last: true
        implicitHeight: mapCol.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: mapCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.medium
            spacing: 0

            Repeater {
                model: root.loaded ? root.rows.length : 0

                Item {
                    id: row

                    required property int index
                    property var r: root.rows[index] ?? ({ kind: "", depth: 0, rails: [] })
                    readonly property var liveItem: root.rows[index]
                    readonly property var d: row.r.dev ?? null
                    readonly property bool isDev: row.r.kind === "device"
                    readonly property bool isRoot: row.isDev && row.r.depth === 1
                    readonly property bool selected: row.isDev && !!row.d && root.selectedMac === row.d.mac
                    readonly property bool hasKids: row.r.kind === "wan" ? row.r.depth === 0 && root.rows.length > 1 : row.r.kind === "link" || (row.isDev && row.r.kids > 0)
                    readonly property bool dim: row.isDev && !!row.d && !row.d.online && !H.isPassive(row.d)
                    readonly property real x0: row.r.depth * root.indent
                    readonly property real mid: head.y + head.height / 2

                    onLiveItemChanged: if (liveItem !== undefined) r = liveItem

                    Layout.fillWidth: true
                    implicitHeight: body.implicitHeight

                    // Trilhos da arvore (so linha): colunas dos ancestrais, o
                    // "├/└" desta linha e a descida para os filhos
                    Repeater {
                        model: Math.max(0, row.r.depth - 1)

                        Rectangle {
                            required property int index

                            visible: row.r.rails[index] === true
                            x: index * root.indent + root.indent / 2
                            width: 1
                            height: row.height
                            color: root.railColour
                        }
                    }

                    Rectangle {
                        visible: row.r.depth > 0
                        x: (row.r.depth - 1) * root.indent + root.indent / 2
                        width: 1
                        height: row.r.kind === "type" || !row.r.last ? row.height : row.mid
                        color: root.railColour
                    }

                    Rectangle {
                        visible: row.r.depth > 0 && row.r.kind !== "type"
                        x: (row.r.depth - 1) * root.indent + root.indent / 2
                        y: row.mid
                        width: root.indent / 2 + 2
                        height: 1
                        color: root.railColour
                    }

                    Rectangle {
                        visible: row.hasKids
                        x: row.x0 + root.indent / 2
                        y: row.mid + root.indent / 2
                        width: 1
                        height: Math.max(0, row.height - y)
                        color: root.railColour
                    }

                    ColumnLayout {
                        id: body

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: row.x0
                        spacing: 0

                        Item {
                            id: head

                            Layout.fillWidth: true
                            implicitHeight: headRow.implicitHeight + (row.isDev || row.r.kind === "wan" ? Tokens.padding.small * 2 : Tokens.padding.small)

                            StateLayer {
                                visible: row.isDev && H.isEditable(row.d)
                                radius: Tokens.rounding.small
                                onClicked: root.selectedMac = row.selected ? "" : row.d.mac
                            }

                            RowLayout {
                                id: headRow

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Tokens.spacing.small

                                Item {
                                    id: iconBox

                                    implicitWidth: root.indent
                                    implicitHeight: root.indent

                                    MaterialIcon {
                                        anchors.centerIn: iconBox
                                        opacity: row.dim ? 0.5 : 1
                                        text: {
                                            switch (row.r.kind) {
                                            case "wan":
                                                return "public";
                                            case "link":
                                                return root.linkIcon(row.r.medium);
                                            case "type":
                                                return H.typeIcon(row.r.type);
                                            case "note":
                                                return "visibility_off";
                                            default:
                                                return H.typeIcon(row.d?.type ?? "");
                                            }
                                        }
                                        color: row.r.kind === "device" ? (row.d?.new ? Colours.palette.m3tertiary : Colours.palette.m3primary) : Colours.palette.m3onSurfaceVariant
                                        fontStyle: row.isDev || row.r.kind === "wan" ? Tokens.font.icon.medium : Tokens.font.icon.small
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    opacity: row.dim ? 0.5 : 1

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: {
                                            switch (row.r.kind) {
                                            case "wan":
                                                return Tr.tr("Internet");
                                            case "link":
                                                return `${root.linkLabel(row.r.medium, row.r.band)} · ${row.r.count}`;
                                            case "type":
                                                return `${root.typeText(row.r.type)} · ${row.r.count}`;
                                            case "note":
                                                return row.r.note === "nat" ? Tr.tr("Its own network (NAT): devices behind it are not visible from here") : Tr.tr("Unmanaged switch: the speed of each port cannot be read");
                                            default:
                                                return H.bestName(row.d);
                                            }
                                        }
                                        color: row.isDev || row.r.kind === "wan" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                        font: row.isDev || row.r.kind === "wan" ? Tokens.font.body.small : Tokens.font.label.medium
                                        wrapMode: row.r.kind === "note" ? Text.WordWrap : Text.NoWrap
                                        elide: row.r.kind === "note" ? Text.ElideNone : Text.ElideRight
                                    }

                                    StyledText {
                                        id: subLine

                                        Layout.fillWidth: true
                                        visible: subLine.text !== ""
                                        text: row.r.kind === "wan" ? [row.d?.ip ?? "", row.d?.name ?? ""].filter(x => x).join(" · ") : row.isDev ? [row.d?.new ? Tr.tr("New") : "", root.subOf(row.d, row.isRoot)].filter(x => x).join(" · ") : ""
                                        color: row.d?.new ? Colours.palette.m3tertiary : Colours.palette.m3outline
                                        font: Tokens.font.label.small
                                        elide: Text.ElideRight
                                    }
                                }

                                ConnChip {
                                    visible: row.isDev && !row.isRoot
                                    Layout.maximumWidth: headRow.width * 0.5
                                    opacity: row.dim ? 0.5 : 1
                                    chip: row.isDev ? root.chipOf(row.d) : ({})
                                    source: row.isDev ? root.sourceText(H.sourceOf(row.d)) : ""
                                    known: row.isDev && H.sourceOf(row.d) !== ""
                                }

                                MaterialIcon {
                                    visible: row.isDev && H.isEditable(row.d)
                                    text: row.selected ? "expand_less" : "expand_more"
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.small
                                }
                            }
                        }

                        // Editor do aparelho escolhido: detalhes, apelido, tipo, conhecido
                        StyledRect {
                            Layout.fillWidth: true
                            Layout.leftMargin: root.indent
                            Layout.bottomMargin: Tokens.spacing.small
                            visible: row.selected
                            implicitHeight: row.selected ? mapEdit.implicitHeight + Tokens.padding.medium * 2 : 0
                            radius: Tokens.rounding.medium
                            color: "transparent"
                            border.width: 1
                            border.color: Colours.palette.m3outlineVariant

                            DeviceEditor {
                                id: mapEdit

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: Tokens.padding.medium
                                host: root
                                dev: row.selected ? row.d : null
                                details: true
                            }
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------ ferramentas
    SectionHeader {
        visible: root.online
        text: Tr.tr("TOOLS")
    }

    RowButton {
        visible: root.online
        first: true
        icon: surveyProc.running ? "hourglass_top" : "radar"
        text: surveyProc.running ? Tr.tr("Wi-Fi survey running…") : root.surveyArmed ? Tr.tr("Click again: run the Wi-Fi survey") : Tr.tr("Run a Wi-Fi survey: who is on which access point, signal, rate")
        subtext: Tr.tr("About 3 min · this PC's Wi-Fi drops meanwhile (the cable stays)")
        disabled: surveyProc.running
        onClicked: root.pressSurvey()
    }

    InfoRow {
        visible: root.online && root.surveyResult !== ""
        icon: root.surveyFailed ? "error" : "check_circle"
        iconColour: root.surveyFailed ? Colours.palette.m3error : Colours.palette.m3primary
        label: root.surveyFailed ? Tr.tr("The Wi-Fi survey did not finish") : Tr.tr("Wi-Fi survey done")
        subtext: root.surveyResult
    }

    RowButton {
        visible: root.online
        icon: "monitoring"
        text: Tr.tr("Open the network monitor")
        subtext: Tr.tr("NetAlertX on the NAS: history, events, the full map")
        trailingIcon: "open_in_new"
        onClicked: Quickshell.execDetached([root.bin, "run", "open:netalertx"])
    }

    RowButton {
        visible: root.online
        last: true
        icon: listProc.running ? "hourglass_top" : "refresh"
        text: root.working ? Tr.tr("Saving changes…") : Tr.tr("Reload the list")
        subtext: Tr.tr("It also reloads by itself every 30 s while this tab is open")
        disabled: listProc.running || root.working
        onClicked: root.reload()
    }

    // Numero grande + rotulo do resumo
    component Stat: ColumnLayout {
        id: stat

        property int value
        property string label
        property color tone

        spacing: 0

        StyledText {
            text: String(stat.value)
            color: stat.tone
            font: Tokens.font.title.large
        }

        StyledText {
            text: stat.label
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }
    }

    // Chip de conexao (so contorno) e, embaixo, de onde veio a informacao
    component ConnChip: ColumnLayout {
        id: cc

        property var chip: ({})
        property string source
        property bool known

        spacing: 0

        StyledRect {
            Layout.alignment: Qt.AlignRight
            Layout.maximumWidth: cc.Layout.maximumWidth
            implicitWidth: chipRow.implicitWidth + Tokens.padding.small * 2
            implicitHeight: chipRow.implicitHeight + Tokens.padding.small
            radius: Tokens.rounding.full
            color: "transparent"
            border.width: 1
            border.color: cc.chip.weak ? Colours.palette.m3tertiary : Colours.palette.m3outlineVariant

            RowLayout {
                id: chipRow

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.small
                anchors.rightMargin: Tokens.padding.small
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: cc.chip.icon ?? "help"
                    color: cc.chip.medium === "unknown" ? Colours.palette.m3outline : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: cc.chip.text ?? ""
                    color: cc.chip.weak ? Colours.palette.m3tertiary : cc.chip.medium === "unknown" ? Colours.palette.m3outline : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            visible: cc.known
            text: cc.source
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }
    }

    // Botoes Known / Nickname / Type / Group with / Delete de um aparelho, a
    // sugestao de grupo (mesmo hostname de um conhecido; so com um clique) e,
    // num grupo, os enderecos dele; com `details`, MAC, datas e fonte
    component DeviceEditor: ColumnLayout {
        id: ed

        required property var host
        property var dev: null
        property bool details
        // "" | "name" | "type" | "group"
        property string open
        property bool showAddrs
        // Apagar: dois cliques, como a varredura de Wi-Fi
        property bool armDelete
        readonly property string mac: (ed.dev?.mac ?? "").toLowerCase()
        readonly property bool busy: H.busyForDev(ed.host.queue, ed.dev)
        readonly property var addrs: H.groupAddrs(ed.dev)
        readonly property var suggestion: H.suggestionFor(ed.dev, ed.host.byMac)
        readonly property bool canDelete: !!ed.dev && !ed.dev.online && !H.isPassive(ed.dev) && H.isEditable(ed.dev)
        readonly property var cands: ed.open === "group" ? H.groupCandidates(ed.host.view, ed.dev) : []

        function pressDelete(): void {
            if (!ed.armDelete) {
                ed.armDelete = true;
                delDisarm.restart();
                return;
            }
            ed.armDelete = false;
            // num grupo, todos os enderecos (apagar so o principal promoveria o proximo)
            for (const a of H.addrsOf(ed.dev))
                ed.host.enqueueOp({ verb: "delete", mac: a.mac.toLowerCase(), value: "", owner: ed.mac });
        }

        function groupWith(other: var): void {
            const op = H.groupOp(ed.dev, other);
            op.owner = ed.mac;
            if (op.value.length > 0)
                ed.host.enqueueOp(op);
            ed.open = "";
        }

        function saveName(): void {
            const v = nameField.text.trim();
            if (v !== "" && v !== H.nickname(ed.dev))
                ed.host.enqueue("name", ed.mac, v);
            ed.open = "";
        }

        spacing: Tokens.spacing.small

        onMacChanged: {
            ed.open = "";
            ed.showAddrs = false;
            ed.armDelete = false;
        }

        Timer {
            id: delDisarm

            interval: 4000
            onTriggered: ed.armDelete = false
        }

        // Sugestao do NAS: nunca aplicada sozinha, fica desconhecido ate o clique
        RowLayout {
            Layout.fillWidth: true
            visible: !!ed.suggestion
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "link"
                color: Colours.palette.m3tertiary
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Looks like %1 (same DHCP name)").arg(ed.suggestion?.name ?? "")
                color: Colours.palette.m3tertiary
                font: Tokens.font.label.medium
                wrapMode: Text.WordWrap
            }

            TextButton {
                text: Tr.tr("Group")
                type: TextButton.Filled
                disabled: ed.busy
                onClicked: ed.host.enqueueOp({
                    verb: "group",
                    mac: ed.suggestion.mac.toLowerCase(),
                    value: H.addrsOf(ed.dev).map(a => a.mac.toLowerCase()),
                    owner: ed.mac
                })
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: ed.details && !!ed.dev
            text: [`MAC ${ed.dev?.mac ?? ""}`, ed.dev?.vendor ?? "", ed.dev?.hostname ? Tr.tr("DHCP name %1").arg(ed.dev.hostname) : ""].filter(x => x).join(" · ")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledText {
            Layout.fillWidth: true
            visible: ed.details && !!ed.dev
            text: [Tr.tr("First seen %1").arg(ed.host.agoText(ed.dev?.first_seen ?? "") || "?"), Tr.tr("last seen %1").arg(ed.host.agoText(ed.dev?.last_seen ?? "") || "?"), Tr.tr("connection %1").arg(ed.host.sourceText(H.sourceOf(ed.dev)))].join(" · ")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            TextButton {
                visible: ed.dev?.new === true
                text: Tr.tr("Known")
                type: TextButton.Filled
                disabled: ed.busy
                onClicked: ed.host.enqueue("known", ed.mac, "")
            }

            TextButton {
                text: Tr.tr("Nickname")
                type: TextButton.Tonal
                isToggle: true
                checked: ed.open === "name"
                onClicked: ed.open = ed.open === "name" ? "" : "name"
            }

            TextButton {
                text: ed.dev?.type ? Tr.tr("Type: %1").arg(H.typeLabel(ed.dev.type)) : Tr.tr("Type")
                type: TextButton.Tonal
                isToggle: true
                checked: ed.open === "type"
                onClicked: ed.open = ed.open === "type" ? "" : "type"
            }

            TextButton {
                text: Tr.tr("Group with…")
                type: TextButton.Tonal
                isToggle: true
                checked: ed.open === "group"
                disabled: ed.busy
                onClicked: ed.open = ed.open === "group" ? "" : "group"
            }

            TextButton {
                visible: ed.addrs.length > 1
                text: Tr.tr("%1 addresses").arg(ed.addrs.length)
                type: TextButton.Tonal
                isToggle: true
                checked: ed.showAddrs
                onClicked: ed.showAddrs = !ed.showAddrs
            }

            TextButton {
                visible: ed.canDelete
                text: ed.armDelete ? Tr.tr("Click again: delete") : Tr.tr("Delete")
                type: ed.armDelete ? TextButton.Filled : TextButton.Text
                disabled: ed.busy
                onClicked: ed.pressDelete()
            }

            StyledText {
                visible: ed.busy
                topPadding: Tokens.padding.small
                text: Tr.tr("Saving…")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: ed.open === "name"
            spacing: Tokens.spacing.small

            StyledTextField {
                id: nameField

                Layout.fillWidth: true
                placeholderText: H.bestName(ed.dev)
                text: H.nickname(ed.dev)
                leadingIcon: "edit"
                maximumLength: 60
                onAccepted: ed.saveName()
            }

            TextButton {
                text: Tr.tr("Save")
                type: TextButton.Filled
                onClicked: ed.saveName()
            }
        }

        Flow {
            Layout.fillWidth: true
            visible: ed.open === "type"
            spacing: Tokens.spacing.extraSmall

            Repeater {
                model: ed.open === "type" ? H.TYPES.length : 0

                TextButton {
                    id: tb

                    required property int index
                    readonly property var t: H.TYPES[index]

                    text: H.typeLabel(tb.t.value)
                    type: TextButton.Tonal
                    isToggle: true
                    checked: ed.dev?.type === tb.t.value
                    onClicked: {
                        if (ed.dev?.type !== tb.t.value)
                            ed.host.enqueue("type", ed.mac, tb.t.value);
                        ed.open = "";
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: ed.armDelete
            text: ed.addrs.length > 1 ? Tr.tr("Deletes its %1 addresses from the network monitor; if one shows up again it comes back as a new device").arg(ed.addrs.length) : Tr.tr("Deletes it from the network monitor; if it shows up again it comes back as a new device")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        // Com quem agrupar: mesmo hostname primeiro
        ColumnLayout {
            Layout.fillWidth: true
            visible: ed.open === "group"
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: ed.cands.length > 0 ? Tr.tr("Pick the device this one really is: their addresses become one device (an unknown one joins the known one and takes its name and type)") : Tr.tr("No other device to group with")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            Flow {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                Repeater {
                    model: ed.cands.length

                    TextButton {
                        id: cb

                        required property int index
                        readonly property var c: ed.cands[index] ?? ({ dev: null, sameHost: false })

                        text: cb.c.sameHost ? Tr.tr("%1 · same DHCP name").arg(H.bestName(cb.c.dev)) : H.bestName(cb.c.dev)
                        type: cb.c.sameHost ? TextButton.Filled : TextButton.Tonal
                        onClicked: ed.groupWith(cb.c.dev)
                    }
                }
            }
        }

        // Enderecos de um grupo: rede, online, ultima vez, qual esta em uso
        ColumnLayout {
            Layout.fillWidth: true
            visible: ed.showAddrs && ed.addrs.length > 1
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("The main address keeps the name and type; one taken out of the group becomes a device of its own")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: ed.showAddrs ? ed.addrs.length : 0

                RowLayout {
                    id: ar

                    required property int index
                    readonly property var a: ed.addrs[index] ?? ({})
                    readonly property bool primary: H.isPrimary(ed.dev, ar.a.mac)
                    readonly property string net: H.addrNetwork(ar.a, ed.host.labels)

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    // online = cheio; offline = so o contorno
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: ar.a.online ? Colours.palette.m3primary : "transparent"
                        border.width: 1
                        border.color: ar.a.online ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: [(ar.a.mac ?? "").toLowerCase(), ar.primary ? Tr.tr("main") : "", H.isActive(ed.dev, ar.a.mac) ? Tr.tr("in use now") : ""].filter(x => x).join(" · ")
                            color: Colours.palette.m3onSurface
                            font: Tokens.font.label.medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: [ar.net || Tr.tr("not seen on Wi-Fi yet"), ar.a.ip ?? "", ar.a.online ? Tr.tr("online") : Tr.tr("seen %1").arg(ed.host.agoText(ar.a.last_seen ?? "") || "?")].filter(x => x).join(" · ")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    TextButton {
                        visible: !ar.primary
                        text: Tr.tr("Remove from group")
                        type: TextButton.Text
                        disabled: ed.busy
                        onClicked: ed.host.enqueueOp({
                            verb: "ungroup",
                            mac: (ar.a.mac ?? "").toLowerCase(),
                            value: "",
                            owner: ed.mac
                        })
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: ed.host.lastError.mac === ed.mac && ed.mac !== ""
            text: Tr.tr("That didn't work: %1").arg(ed.host.lastError.message ?? "")
            color: Colours.palette.m3error
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
