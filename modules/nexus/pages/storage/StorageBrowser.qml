pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

// Arvore de uso de disco (o "baobab" do Nexus): o que ha dentro de uma pasta,
// maior primeiro, com barra relativa ao maior item. Clicar numa pasta desce;
// "Up" sobe. So leitura: `caelestia-storage browse <pasta> --json` (du -x,
// nao atravessa para outra particao). Resultados ficam em cache enquanto a
// pagina esta aberta, entao voltar e instantaneo.
PageBase {
    id: root

    property string path: root.nState.storagePath || "/"
    property var cache: ({})
    property int shown: 40

    readonly property var doc: root.cache[root.path] ?? null
    readonly property var entries: root.doc?.entries ?? []
    readonly property real biggest: root.entries.length > 0 ? Math.max(1, root.entries[0].size) : 1
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/caelestia-storage`

    function fmt(bytes: var): string {
        if (bytes === null || bytes === undefined)
            return "?";
        const units = [["TB", 1099511627776], ["GB", 1073741824], ["MB", 1048576], ["KB", 1024]];
        for (const [u, s] of units)
            if (bytes >= s)
                return `${(bytes / s).toFixed(1)} ${u}`;
        return `${bytes} B`;
    }

    function go(p: string): void {
        root.shown = 40;
        root.path = p;
        root.nState.storagePath = p;
        root.load(false);
        root.flickable.contentY = -root.flickable.topMargin;
    }

    function load(force: bool): void {
        if (!force && root.cache[root.path])
            return;
        proc.target = root.path;
        proc.running = false;
        proc.running = true;
    }

    title: root.path === "/" ? "/" : root.path.split("/").filter(x => x).pop()
    description: root.path
    isSubPage: true

    Component.onCompleted: root.load(false)

    // O Process vive dentro de um Item (o PageBase so aceita Item como filho).
    Item {
        Process {
            id: proc

            property string target

            command: [root.bin, "browse", proc.target, "--json"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const d = JSON.parse(text);
                        const c = Object.assign({}, root.cache);
                        c[d.path] = d;
                        root.cache = c;
                    } catch (e) {
                        const c = Object.assign({}, root.cache);
                        c[proc.target] = { path: proc.target, entries: [], total: 0, denied: 0, error: qsTr("Could not read this folder") };
                        root.cache = c;
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Resumo + navegacao
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: summary.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: summary

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "folder_open"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.large
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: proc.running && !root.doc ? qsTr("Measuring…") : qsTr("%1 in %2 items").arg(root.fmt(root.doc?.total ?? 0)).arg(root.entries.length + (root.doc?.more ?? 0))
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: (root.doc?.denied ?? 0) > 0 ? qsTr("%1 folder(s) need admin access — real size may be larger").arg(root.doc.denied) : (root.doc?.error ?? "")
                        color: Colours.palette.m3tertiary
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                CircularIndicator {
                    visible: proc.running
                    running: visible
                    implicitSize: Tokens.font.icon.large.pointSize * 1.6
                }

                IconButton {
                    icon: "arrow_upward"
                    type: IconButton.Tonal
                    isRound: true
                    disabled: !root.doc?.parent
                    onClicked: root.go(root.doc.parent)
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Tonal
                    isRound: true
                    disabled: proc.running
                    onClicked: root.load(true)
                }

                IconButton {
                    icon: "open_in_new"
                    type: IconButton.Tonal
                    isRound: true
                    onClicked: Quickshell.execDetached([...GlobalConfig.general.apps.explorer, root.path])
                }
            }
        }

        SectionHeader {
            visible: root.entries.length > 0
            text: qsTr("Largest first")
        }

        Repeater {
            model: root.entries.slice(0, root.shown)

            ConnectedRect {
                id: entry

                required property var modelData
                required property int index

                readonly property real share: entry.modelData.size / root.biggest

                Layout.fillWidth: true
                first: entry.index === 0
                last: entry.index === Math.min(root.shown, root.entries.length) - 1 && root.entries.length <= root.shown
                implicitHeight: entryCol.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    disabled: !entry.modelData.dir
                    onClicked: root.go(entry.modelData.path)
                }

                ColumnLayout {
                    id: entryCol

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.extraSmall

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: entry.modelData.dir ? "folder" : "draft"
                            color: entry.modelData.dir ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                            fill: entry.modelData.dir ? 1 : 0
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: entry.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideMiddle
                        }

                        StyledText {
                            text: root.fmt(entry.modelData.size)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.medium
                        }

                        MaterialIcon {
                            text: "chevron_right"
                            opacity: entry.modelData.dir ? 1 : 0
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }
                    }

                    // Barra relativa ao MAIOR item: mostra de cara quem domina.
                    StyledRect {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.font.icon.medium.pointSize * 1.6 + Tokens.spacing.medium
                        implicitHeight: Tokens.padding.small / 1.5
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainerHighest

                        StyledRect {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0.005, entry.share)
                            radius: Tokens.rounding.full
                            color: entry.modelData.dir ? Colours.palette.m3primary : Colours.palette.m3secondary
                        }
                    }
                }
            }
        }

        RowButton {
            last: true
            visible: root.entries.length > root.shown
            icon: "expand_more"
            text: qsTr("Show %1 more").arg(Math.min(40, root.entries.length - root.shown))
            subtext: qsTr("Smaller items")
            onClicked: root.shown += 40
        }

        InfoRow {
            first: true
            last: true
            visible: !!root.doc && root.entries.length === 0 && !proc.running
            icon: "folder_off"
            label: qsTr("This folder is empty")
        }
    }
}
