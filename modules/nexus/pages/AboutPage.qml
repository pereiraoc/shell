import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    property string quickshellVersion
    property string hyprlandVersion
    property bool copied

    readonly property string memoryText: {
        const f = UsageFmt.formatKib(Memory.total, Memory.total);
        return f.total > 0 ? `${Math.round(f.total)} ${f.unit}` : "…";
    }

    // Texto para colar em relato de bug (padrao Win11/GNOME "Copy").
    function systemInfoText(): string {
        return [
            `Device: ${SysInfo.device}`,
            `OS: ${SysInfo.osPrettyName || SysInfo.osName}`,
            `Kernel: ${SysInfo.kernel}`,
            `Firmware: ${SysInfo.firmware}`,
            `CPU: ${systemBridge.info.cpu_model ?? Cpu.name}`,
            `GPU: ${Gpu.name}`,
            `Memory: ${root.memoryText}`,
            `Hyprland: ${root.hyprlandVersion}`,
            `Quickshell: ${root.quickshellVersion}`,
            `Caelestia shell: ${CUtils.version}`,
            `Qt: ${CUtils.qtVersion}`,
            `Graphics mode: ${GpuModeService.getModeName(GpuModeService.activeMode)}`
        ].join("\n");
    }
    property string cliVersion

    title: qsTr("About")
    description: qsTr("Hardware, versions and system information")

    ToolBridge {
        id: systemBridge

        tool: "system"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ServiceRef {
            service: Gpu
        }

        ServiceRef {
            service: Memory
        }

        Process {
            running: true
            command: ["hyprctl", "version", "-j"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const v = JSON.parse(text);
                        root.hyprlandVersion = v.version || v.tag || "";
                    } catch (e) {
                        root.hyprlandVersion = "";
                    }
                }
            }
        }

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                AnimatedLogo {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Caelestia"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: CUtils.version ? `v${CUtils.version}` : "…"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // System
        SectionHeader {
            text: qsTr("System")
        }

        InfoRow {
            first: true
            label: qsTr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            label: qsTr("Device")
            value: SysInfo.device
        }

        InfoRow {
            label: qsTr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            label: qsTr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            label: qsTr("Firmware")
            value: SysInfo.firmware
        }

        // Hardware
        SectionHeader {
            text: qsTr("Hardware")
        }

        InfoRow {
            first: true
            label: qsTr("Processor")
            value: systemBridge.info.cpu_model ?? Cpu.name
        }

        InfoRow {
            label: qsTr("Graphics")
            value: Gpu.name || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Memory")
            value: root.memoryText
        }

        // Software
        SectionHeader {
            text: qsTr("Software")
        }

        InfoRow {
            first: true
            label: qsTr("Shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            label: qsTr("CLI")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: qsTr("Hyprland")
            value: root.hyprlandVersion || "…"
        }

        InfoRow {
            label: qsTr("Quickshell")
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Qt")
            value: CUtils.qtVersion || "…"
        }

        RowButton {
            Layout.topMargin: Tokens.spacing.large
            first: true
            last: true
            icon: root.copied ? "check" : "content_copy"
            text: root.copied ? qsTr("Copied") : qsTr("Copy system information")
            subtext: qsTr("Paste it into a bug report or a support chat")
            onClicked: {
                Quickshell.clipboardText = root.systemInfoText();
                root.copied = true;
                copiedTimer.restart();
            }

            Timer {
                id: copiedTimer

                interval: 2500
                onTriggered: root.copied = false
            }
        }
    }
}
