pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("System apps")

    // Ferramentas do sistema que antes eram menus de terminal (font-scaling-manager,
    // howdy-manager) agora sao nativas: secao do contrato aqui ou na pagina
    // dona do assunto. Abaixo ficam so os launchers de apps graficos de verdade.
    function openPage(label: string): void {
        const idx = PageRegistry.pages.findIndex(p => p.label === label);
        if (idx >= 0)
            root.nState.currentPageIdx = idx;
    }

    // Application launchers grouped by category (US-007: portado do controlcenter)
    readonly property var appCategories: [
        {
            name: qsTr("Audio"),
            icon: "graphic_eq",
            apps: [
                { name: "qpwgraph", icon: "cable", command: ["qpwgraph"], description: qsTr("PipeWire Graph Manager") },
                { name: "EasyEffects", icon: "tune", command: ["easyeffects"], description: qsTr("Audio Effects & Equalizer") },
                { name: "PulseAudio Volume", icon: "volume_up", command: ["pavucontrol"], description: qsTr("Volume Control") }
            ]
        },
        {
            name: qsTr("Display"),
            icon: "monitor",
            apps: [
                { name: "nwg-displays", icon: "desktop_windows", command: ["nwg-displays"], description: qsTr("Monitor layout, resolution, refresh rate") }
            ]
        },
        {
            name: qsTr("System"),
            icon: "settings",
            apps: [
                { name: "System Monitor", icon: "monitoring", command: ["gnome-system-monitor"], description: qsTr("Resource Monitor") },
                { name: "Logs", icon: "article", command: ["gnome-logs"], description: qsTr("System Logs") },
                { name: "Disk Usage", icon: "storage", command: ["baobab"], description: qsTr("Disk Usage Analyzer") }
            ]
        },
        {
            name: qsTr("Hardware"),
            icon: "memory",
            apps: [
                { name: "Qt Camera", icon: "videocam", command: ["qcam"], description: qsTr("Camera Viewer (V4L2)") },
                { name: "ROG Control", icon: "sports_esports", command: ["rog-control-center"], description: qsTr("ASUS ROG Settings") }
            ]
        },
        {
            name: qsTr("Sharing"),
            icon: "share",
            apps: [
                { name: "LocalSend", icon: "send", command: ["localsend_app"], description: qsTr("Local File Sharing") },
                { name: "Snapdrop", icon: "language", command: ["xdg-open", "https://snapdrop.net"], description: qsTr("Web-based Sharing") }
            ]
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Logica no caelestia-display-scale (repositorio de setup).
        ToolSection {
            first: true
            tool: "display-scale"
            title: qsTr("Display scale")
            icon: "text_fields"
            hint: qsTr("Screen scale resizes the shell and Wayland apps now. X11 font size is for Steam and games; restart them after changing.")
        }

        SectionHeader {
            text: qsTr("Built-in settings")
        }

        NavRow {
            first: true
            icon: "face"
            text: qsTr("Face recognition")
            subtext: qsTr("Add or remove Howdy models, turn it off — in Security")
            onClicked: root.openPage(qsTr("Security"))
        }

        NavRow {
            last: true
            icon: "mic"
            text: qsTr("Microphone hardware gain")
            subtext: qsTr("Internal mic boost presets — in Audio")
            onClicked: root.openPage(qsTr("Audio"))
        }

        Repeater {
            model: root.appCategories

            ColumnLayout {
                id: catDelegate

                required property var modelData
                required property int index

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: catDelegate.modelData.name
                }

                Repeater {
                    model: catDelegate.modelData.apps

                    NavRow {
                        required property var modelData
                        required property int index

                        icon: modelData.icon
                        text: modelData.name
                        subtext: modelData.description
                        first: index === 0
                        last: index === catDelegate.modelData.apps.length - 1
                        onClicked: Quickshell.execDetached(modelData.command)
                    }
                }
            }
        }
    }
}
