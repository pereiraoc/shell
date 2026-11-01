pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Logs: o journal de uma unidade do NAS (e, nas stacks, os logs dos
// containers), lido por `caelestia-nas logs <unidade> -n 200 --json` a cada 5 s
// enquanto a aba esta visivel. Modelo: modules/nexus/pages/system/LogsView.qml.
// A unidade escolhida mora na pagina (page.logsUnit): "Show log" na aba Services
// troca aqui tambem.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    property string query
    property var lines: []
    property bool failed
    property string failMessage

    readonly property var units: S.unitsForLogs(root.bridge.info)
    readonly property string unit: root.page.logsUnit || (root.units[0]?.value ?? "")
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/caelestia-nas`
    readonly property var shown: {
        const q = root.query.trim().toLowerCase();
        const base = q === "" ? root.lines : root.lines.filter(l => String(l).toLowerCase().includes(q));
        return base.slice().reverse();
    }

    function reload(): void {
        if (root.unit === "")
            return;
        proc.running = false;
        proc.command = [root.bin, "logs", root.unit, "-n", "200", "--json"];
        proc.running = true;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Component.onCompleted: reload()
    onUnitChanged: reload()

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.lines = d.lines ?? [];
                    root.failed = !d.ok;
                    root.failMessage = d.message ?? "";
                } catch (e) {
                    root.failed = true;
                    root.failMessage = Tr.tr("unreadable answer from caelestia-nas");
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        onTriggered: root.reload()
    }

    ChipSelectRow {
        first: true
        label: Tr.tr("Unit")
        subtext: Tr.tr("Stacks first, then the NixOS services")
        options: root.units
        current: root.unit
        onPicked: v => root.page.logsUnit = v
    }

    TextFieldRow {
        last: true
        label: Tr.tr("Filter")
        placeholderText: Tr.tr("Text in the line")
        value: root.query
        onValueEdited: v => root.query = v
    }

    SectionHeader {
        text: root.shown.length === 0 ? Tr.tr("Lines") : Tr.trN("%n line · newest first", "%n lines · newest first", root.shown.length)
    }

    InfoRow {
        first: true
        last: true
        visible: root.shown.length === 0
        icon: root.failed ? "error" : proc.running ? "hourglass_empty" : "check_circle"
        iconColour: root.failed ? Colours.palette.m3error : Colours.palette.m3primary
        label: root.failed ? Tr.tr("Could not read the log") : proc.running ? Tr.tr("Reading from the NAS…") : root.unit === "" ? Tr.tr("No unit to read") : Tr.tr("Nothing matches")
        subtext: root.failed ? root.failMessage : ""
    }

    Repeater {
        model: root.shown.length

        InfoRow {
            id: line

            required property int index
            property var modelData: root.shown[index] ?? ""
            readonly property var liveItem: root.shown[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: line.index === 0
            last: line.index === root.shown.length - 1
            icon: /(error|fail|denied|crit)/i.test(String(line.modelData)) ? "error" : /warn/i.test(String(line.modelData)) ? "warning" : "subject"
            iconColour: /(error|fail|denied|crit)/i.test(String(line.modelData)) ? Colours.palette.m3error : /warn/i.test(String(line.modelData)) ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            label: String(line.modelData).slice(0, 300)
        }
    }
}
