pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Aba Logs de System: o journal ao vivo, filtrado por gravidade, boot e origem,
// com busca por texto ou unidade. Le `journalctl -o json` direto (o usuario
// esta no grupo wheel); o mais recente primeiro. So nasce quando a aba abre.
// Os arquivos antigos (caelestia-storage) ficam para o `caelestia-journal-search`.
ColumnLayout {
    id: root

    property string level: "err"
    property string boot: "0"
    property string source: "system"
    property string query
    property var entries: []
    property bool failed

    readonly property int limit: 80

    function reload(): void {
        const argv = ["journalctl", "-o", "json", "--no-pager", "-q", "-r", "-n", String(root.limit), "-b", root.boot];
        if (root.level === "err")
            argv.push("-p", "3");
        else if (root.level === "warn")
            argv.push("-p", "4");
        if (root.source === "kernel")
            argv.push("-k");
        else if (root.source === "user")
            argv.push("--user");
        if (root.query.trim() !== "") {
            const q = root.query.trim();
            if (/^[\w.@-]+\.(service|socket|timer|mount|target|slice|scope)$/.test(q))
                argv.push("-u", q);
            else
                argv.push("-g", q);
        }
        proc.running = false;
        proc.command = argv;
        proc.running = true;
    }

    function when(usec: var): string {
        const d = new Date(Number(usec) / 1000);
        return Qt.formatDateTime(d, "dd/MM HH:mm:ss");
    }

    function unitOf(e: var): string {
        return e._SYSTEMD_UNIT ?? e._SYSTEMD_USER_UNIT ?? e.SYSLOG_IDENTIFIER ?? e._COMM ?? "";
    }

    function levelIcon(p: var): string {
        const n = Number(p);
        if (n <= 3)
            return "error";
        if (n === 4)
            return "warning";
        return "info";
    }

    function levelColour(p: var): color {
        const n = Number(p);
        if (n <= 3)
            return Colours.palette.m3error;
        if (n === 4)
            return Colours.palette.m3tertiary;
        return Colours.palette.m3onSurfaceVariant;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: reload()
    onLevelChanged: reload()
    onBootChanged: reload()
    onSourceChanged: reload()

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\\n")) {
                    if (!line.trim())
                        continue;
                    try {
                        out.push(JSON.parse(line));
                    } catch (e) {
                    }
                }
                root.entries = out;
                root.failed = false;
            }
        }
        onExited: code => { // qmllint disable signal-handler-parameters
            if (code !== 0 && root.entries.length === 0)
                root.failed = true;
        }
    }

    // Busca: so dispara ao confirmar (Enter), para nao rodar o journalctl a cada tecla
    Timer {
        id: debounce

        interval: 350
        onTriggered: root.reload()
    }

    ChipSelectRow {
        first: true
        label: Tr.tr("Severity")
        options: [
            { value: "err", label: Tr.tr("Errors"), icon: "error" },
            { value: "warn", label: Tr.tr("Warnings and up"), icon: "warning" },
            { value: "all", label: Tr.tr("Everything") }
        ]
        current: root.level
        onPicked: v => root.level = v
    }

    ChipSelectRow {
        label: Tr.tr("Boot")
        options: [
            { value: "0", label: Tr.tr("This boot") },
            { value: "-1", label: Tr.tr("Previous boot") }
        ]
        current: root.boot
        onPicked: v => root.boot = v
    }

    ChipSelectRow {
        label: Tr.tr("Source")
        options: [
            { value: "system", label: Tr.tr("System") },
            { value: "user", label: Tr.tr("Your session") },
            { value: "kernel", label: Tr.tr("Kernel") }
        ]
        current: root.source
        onPicked: v => root.source = v
    }

    TextFieldRow {
        last: true
        label: Tr.tr("Search")
        placeholderText: Tr.tr("Text, or a unit like NetworkManager.service")
        value: root.query
        onValueEdited: v => {
            root.query = v;
            debounce.restart();
        }
    }

    SectionHeader {
        text: root.entries.length === 0 ? Tr.tr("Entries") : Tr.trN("%n entry · newest first", "%n entries · newest first", root.entries.length)
    }

    InfoRow {
        first: true
        last: true
        visible: root.entries.length === 0
        icon: root.failed ? "error" : proc.running ? "hourglass_empty" : "check_circle"
        iconColour: root.failed ? Colours.palette.m3error : Colours.palette.m3primary
        label: root.failed ? Tr.tr("journalctl failed") : proc.running ? Tr.tr("Reading the journal…") : Tr.tr("Nothing matches")
    }

    Repeater {
        model: root.entries.length

        InfoRow {
            // Modelo = quantidade: atualizar o status nao recria a linha
            required property int index
            property var modelData: root.entries[index] ?? ({})
            readonly property var liveItem: root.entries[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: index === 0
            last: index === root.entries.length - 1
            icon: root.levelIcon(modelData.PRIORITY)
            iconColour: root.levelColour(modelData.PRIORITY)
            label: `${root.when(modelData.__REALTIME_TIMESTAMP)}  ${root.unitOf(modelData)}`
            subtext: String(modelData.MESSAGE ?? "").slice(0, 300)
        }
    }
}
