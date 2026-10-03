pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Uso de disco e limpezas seguras. Tudo vem do caelestia-storage (repositorio
// de setup) pela ToolBridge; a pagina so desenha e dispara.
//
// Limpeza pede dois cliques: o shell nao tem dialogo de confirmacao, e um
// clique perdido nao pode apagar 10 GB.
PageBase {
    id: root

    property string armed: ""

    readonly property var partitions: storage.info.partitions ?? []

    function fmt(bytes: var): string {
        if (bytes === null || bytes === undefined)
            return "?";
        const units = [["TB", 1099511627776], ["GB", 1073741824], ["MB", 1048576], ["KB", 1024]];
        for (const [u, s] of units)
            if (bytes >= s)
                return `${(bytes / s).toFixed(1)} ${u}`;
        return `${bytes} B`;
    }

    function levelColour(level: string): color {
        if (level === "error")
            return Colours.palette.m3error;
        if (level === "warn")
            return Colours.palette.m3tertiary;
        return Colours.palette.m3primary;
    }

    function press(action: var): void {
        if (root.armed !== action.id) {
            root.armed = action.id;
            disarm.restart();
            return;
        }
        root.armed = "";
        storage.run(action);
    }

    title: qsTr("Storage")

    // O PageBase so aceita Item como filho; o Timer mora dentro da ponte
    // (que e Item). Direto na pagina, "Type StoragePage unavailable" -- e no
    // shell vivo isso derruba tudo (pego pelo harness).
    ToolBridge {
        id: storage

        tool: "storage"

        Timer {
            id: disarm

            interval: 4000
            onTriggered: root.armed = ""
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Disk usage and safe cleanups from caelestia-storage — also usable in a terminal (caelestia-storage status). Cleanups with a lock ask for your password in the Caelestia authentication dialog. Old system logs are archived compressed, not deleted (search: caelestia-journal-search).")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        InfoRow {
            visible: storage.error !== ""
            first: true
            last: true
            icon: "error"
            iconColour: Colours.palette.m3error
            label: qsTr("Could not read storage")
            subtext: storage.error
        }

        // --- Particoes
        SectionHeader {
            first: true
            text: storage.loading ? qsTr("PARTITIONS  ·  refreshing…") : qsTr("PARTITIONS")
        }

        Repeater {
            model: root.partitions

            ConnectedRect {
                id: part

                required property var modelData
                required property int index

                Layout.fillWidth: true
                implicitHeight: partCol.implicitHeight + Tokens.padding.medium * 2
                first: part.index === 0
                last: part.index === root.partitions.length - 1

                ColumnLayout {
                    id: partCol

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.small

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: part.modelData.level === "ok" ? "hard_drive" : "warning"
                            color: root.levelColour(part.modelData.level)
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: part.modelData.mount
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            text: qsTr("%1 free of %2  ·  %3%").arg(root.fmt(part.modelData.avail)).arg(root.fmt(part.modelData.size)).arg(part.modelData.pct)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }

                    // Barra de uso
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainerHighest

                        StyledRect {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(part.modelData.pct, 100) / 100
                            radius: Tokens.rounding.full
                            color: root.levelColour(part.modelData.level)
                        }
                    }
                }
            }
        }

        // --- Limpezas
        SectionHeader {
            text: qsTr("SAFE CLEANUPS  ·  %1 available").arg(root.fmt(storage.actions.reduce((acc, a) => acc + (a.estimate_bytes ?? 0), 0)))
        }

        InfoRow {
            visible: storage.actions.length === 0
            first: true
            last: true
            icon: "check_circle"
            label: qsTr("Nothing worth cleaning")
            subtext: qsTr("Only cleanups that free more than 100 MB are listed")
        }

        Repeater {
            model: storage.actions

            RowButton {
                id: act

                required property var modelData
                required property int index

                readonly property bool isArmed: root.armed === act.modelData.id
                readonly property bool isBusy: storage.busyAction === act.modelData.id

                first: act.index === 0
                last: act.index === storage.actions.length - 1
                color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
                icon: act.isBusy ? "hourglass_top" : (act.modelData.risk === "medium" ? "delete_forever" : "cleaning_services")
                text: act.isArmed ? qsTr("Click again to free %1").arg(root.fmt(act.modelData.estimate_bytes)) : act.isBusy ? qsTr("%1 — running…").arg(act.modelData.label) : `${act.modelData.label}  ·  ${root.fmt(act.modelData.estimate_bytes)}`
                subtext: act.modelData.detail
                trailingIcon: act.modelData.root ? "lock" : ""
                disabled: storage.busyAction !== "" && !act.isBusy
                onClicked: {
                    if (!act.isBusy)
                        root.press(act.modelData);
                }
            }
        }

        InfoRow {
            visible: storage.lastResult !== null
            Layout.topMargin: Tokens.spacing.small
            first: true
            last: true
            icon: storage.lastResult?.ok ? "task_alt" : "error"
            iconColour: storage.lastResult?.ok ? Colours.palette.m3primary : Colours.palette.m3error
            label: storage.lastResult?.ok ? qsTr("Last cleanup: %1 freed").arg(root.fmt(storage.lastResult?.freed_bytes)) : qsTr("Last cleanup failed")
            subtext: `${storage.last.action ?? ""}  ·  ${storage.last.at ? Qt.formatDateTime(new Date(storage.last.at * 1000), "dd/MM hh:mm") : ""}${storage.lastResult?.ok ? "" : "  ·  " + (storage.lastResult?.message ?? "")}`
        }

        RowButton {
            Layout.topMargin: Tokens.spacing.small
            first: true
            last: true
            icon: "refresh"
            text: qsTr("Refresh")
            subtext: storage.info.checked_at ? qsTr("Checked %1").arg(Qt.formatDateTime(new Date(storage.info.checked_at * 1000), "dd/MM hh:mm")) : ""
            disabled: storage.loading
            onClicked: storage.refresh()
        }

        // --- Maiores pastas, por particao
        Repeater {
            model: root.partitions.filter(p => (p.largest ?? []).length > 0)

            ColumnLayout {
                id: big

                required property var modelData

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: qsTr("LARGEST IN %1").arg(big.modelData.mount)
                }

                Repeater {
                    model: big.modelData.largest

                    RowButton {
                        id: dir

                        required property var modelData
                        required property int index

                        first: dir.index === 0
                        last: dir.index === big.modelData.largest.length - 1
                        icon: "folder"
                        text: dir.modelData.path
                        subtext: root.fmt(dir.modelData.size)
                        trailingIcon: "open_in_new"
                        onClicked: Quickshell.execDetached([...GlobalConfig.general.apps.explorer, dir.modelData.path])
                    }
                }
            }
        }
    }
}
