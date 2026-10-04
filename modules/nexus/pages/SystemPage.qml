pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Sistema: recursos ao vivo (CPU/GPU/memoria + temperaturas), processos que
// mais gastam com "End", servicos com falha e erros do log desde o boot.
// Substitui o uso diario do System Monitor e do Logs. Medidores ao vivo pelos
// servicos C++ (so contam com ServiceRef); o resto pelo caelestia-system.
PageBase {
    id: root

    property string sortBy: "cpu"
    property int armedPid: -1

    readonly property var info: bridge.info
    readonly property var processes: (root.sortBy === "cpu" ? root.info.top_cpu : root.info.top_mem) ?? []
    readonly property var failed: root.info.failed_units ?? []
    readonly property var journal: root.info.journal ?? ({})

    function temp(label: string): var {
        return (root.info.temps ?? []).find(t => t.label === label)?.c ?? null;
    }

    function tempText(c: var): string {
        if (c === null || c === undefined || isNaN(c))
            return "";
        const f = GlobalConfig.services.useFahrenheitPerformance;
        return `${Math.round(f ? c * 1.8 + 32 : c)}°${f ? "F" : "C"}`;
    }

    function uptimeText(s: int): string {
        const d = Math.floor(s / 86400);
        const h = Math.floor((s % 86400) / 3600);
        const m = Math.floor((s % 3600) / 60);
        if (d > 0)
            return qsTr("%1 d %2 h").arg(d).arg(h);
        return h > 0 ? qsTr("%1 h %2 min").arg(h).arg(m) : qsTr("%1 min").arg(m);
    }

    function endProcess(p: var): void {
        if (root.armedPid !== p.pid) {
            root.armedPid = p.pid;
            disarm.restart();
            return;
        }
        root.armedPid = -1;
        bridge.run({ id: `kill-${p.pid}` });
    }

    title: qsTr("System")
    description: qsTr("Resources, processes and system health")

    ToolBridge {
        id: bridge

        tool: "system"

        Timer {
            interval: 5000
            repeat: true
            running: root.visible
            onTriggered: bridge.refresh()
        }

        Timer {
            id: disarm

            interval: 4000
            onTriggered: root.armedPid = -1
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Os servicos C++ so medem enquanto alguem os referencia.
        ServiceRef {
            service: Cpu
        }

        ServiceRef {
            service: Gpu
        }

        ServiceRef {
            service: Memory
        }

        InfoRow {
            first: true
            last: true
            visible: bridge.error !== ""
            icon: "error"
            iconColour: Colours.palette.m3error
            label: qsTr("Could not read system information")
            subtext: bridge.error
        }

        // Recursos
        SectionHeader {
            first: bridge.error === ""
            text: qsTr("Resources")
        }

        MeterRow {
            first: true
            icon: "memory"
            label: qsTr("Processor")
            valueText: [`${Math.round(Cpu.percentage * 100)}%`, root.tempText(Cpu.temperature)].filter(x => x).join(" · ")
            value: Cpu.percentage
            subtext: root.info.cpu_model ? qsTr("%1 · %2 threads").arg(root.info.cpu_model).arg(root.info.cores) : Cpu.name
        }

        MeterRow {
            visible: Gpu.type !== Gpu.None
            icon: "desktop_windows"
            label: qsTr("Graphics")
            valueText: [`${Math.round(Gpu.percentage * 100)}%`, root.tempText(Gpu.temperature)].filter(x => x).join(" · ")
            value: Gpu.percentage
            subtext: Gpu.name
        }

        MeterRow {
            icon: "memory_alt"
            label: qsTr("Memory")
            readonly property var fmt: UsageFmt.formatKib(Memory.used, Memory.total)
            valueText: `${+fmt.value.toFixed(1)} / ${+fmt.total.toFixed(1)} ${fmt.unit}`
            value: Memory.percentage
        }

        InfoRow {
            last: true
            icon: "device_thermostat"
            label: qsTr("Temperatures")
            value: (root.info.temps ?? []).filter(t => t.c !== null).map(t => `${t.label} ${root.tempText(t.c)}`).join("  ·  ")
            subtext: root.temp("GPU") === null && (root.info.temps ?? []).some(t => t.label === "GPU") ? qsTr("NVIDIA GPU is asleep — saving power") : ""
        }

        // Processos
        SectionHeader {
            text: qsTr("Top processes")
        }

        ChipSelectRow {
            first: true
            label: qsTr("Sort by")
            options: [
                { value: "cpu", label: qsTr("Processor"), icon: "speed" },
                { value: "mem", label: qsTr("Memory"), icon: "memory_alt" }
            ]
            current: root.sortBy
            onPicked: v => root.sortBy = v
        }

        Repeater {
            model: root.processes

            ConnectedRect {
                id: proc

                required property var modelData
                required property int index

                readonly property bool armed: root.armedPid === modelData.pid
                readonly property bool ending: bridge.busyAction === `kill-${modelData.pid}`

                Layout.fillWidth: true
                last: index === root.processes.length - 1
                implicitHeight: procRow.implicitHeight + Tokens.padding.small * 2
                color: armed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer

                RowLayout {
                    id: procRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: proc.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("%1% processor · %2 MB · PID %3").arg(proc.modelData.cpu.toFixed(1)).arg(Math.round(proc.modelData.rss_mb)).arg(proc.modelData.pid)
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    TextButton {
                        visible: !proc.modelData.protected
                        text: proc.ending ? qsTr("Ending…") : proc.armed ? qsTr("Click to end") : qsTr("End")
                        type: proc.armed ? TextButton.Filled : TextButton.Text
                        isRound: true
                        enabled: !proc.ending
                        onClicked: root.endProcess(proc.modelData)
                    }

                    MaterialIcon {
                        visible: proc.modelData.protected
                        text: "shield"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }
                }
            }
        }

        ActionErrorRow {
            bridge: bridge
        }

        // Saude
        SectionHeader {
            text: qsTr("Health")
        }

        InfoRow {
            first: true
            icon: "schedule"
            label: qsTr("Up for %1").arg(root.uptimeText(root.info.uptime_s ?? 0))
            value: root.info.load ? qsTr("Load %1").arg(root.info.load[0].toFixed(2)) : ""
        }

        InfoRow {
            visible: root.failed.length === 0
            icon: "check_circle"
            iconColour: Colours.palette.m3primary
            label: qsTr("All services running")
        }

        Repeater {
            model: root.failed

            RowButton {
                required property var modelData

                icon: "error"
                iconLabel.color: Colours.palette.m3error
                text: qsTr("%1 failed").arg(modelData.description || modelData.unit)
                subtext: qsTr("%1 · %2 · click to restart").arg(modelData.unit).arg(modelData.scope === "user" ? qsTr("your session") : qsTr("system"))
                trailingIcon: modelData.scope === "system" ? "lock" : "restart_alt"
                disabled: bridge.busyAction !== ""
                onClicked: bridge.run({ id: `restart-unit-${modelData.scope}-${modelData.unit}` })
            }
        }

        InfoRow {
            visible: (root.info.shell_crashes_since_boot ?? 0) > 0
            icon: "bug_report"
            iconColour: Colours.palette.m3tertiary
            label: qsTr("The shell crashed %1 time(s) since boot").arg(root.info.shell_crashes_since_boot ?? 0)
            subtext: qsTr("Crash reports in ~/.cache/quickshell/crashes")
        }

        InfoRow {
            last: (root.journal.recent ?? []).length === 0
            icon: (root.journal.errors_since_boot ?? 0) > 0 ? "report" : "check_circle"
            iconColour: (root.journal.errors_since_boot ?? 0) > 0 ? Colours.palette.m3tertiary : Colours.palette.m3primary
            label: (root.journal.errors_since_boot ?? 0) > 0 ? qsTr("%1 errors in the system log since boot").arg((root.journal.errors_since_boot ?? 0) >= 200 ? "200+" : root.journal.errors_since_boot) : qsTr("No errors in the system log since boot")
            subtext: (root.journal.errors_since_boot ?? 0) > 0 ? qsTr("Most recent first. Many are harmless driver messages.") : ""
        }

        Repeater {
            model: (root.journal.recent ?? []).slice(0, 5)

            InfoRow {
                required property var modelData
                required property int index

                last: index === Math.min(5, (root.journal.recent ?? []).length) - 1
                label: `${modelData.time}  ${modelData.unit}`
                subtext: modelData.message
            }
        }

        AdvancedGroup {
            apps: [
                { id: "gnome-system-monitor-kde", text: qsTr("System Monitor"), subtext: qsTr("Every process, per-core graphs, file systems") },
                { id: "org.gnome.Logs", text: qsTr("Logs"), subtext: qsTr("Search the full system log") }
            ]
        }
    }
}
