pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Em que monitor cada app abre (caelestia-app-monitor). Personalizados no topo;
// o resto com busca e filtro Jogos/Outros. Clicar abre o App info, onde fica a escolha.
PageBase {
    id: root

    property string filter: "all"
    property string query: ""

    readonly property var apps: (bridge.info.apps ?? []).filter(a => {
        if (root.filter === "games" && !a.game)
            return false;
        if (root.filter === "others" && a.game)
            return false;
        return !root.query || a.name.toLowerCase().includes(root.query.toLowerCase());
    })
    readonly property var custom: root.apps.filter(a => a.custom)
    readonly property var rest: root.apps.filter(a => !a.custom)

    function summary(a: var): string {
        if (a.mode === "mouse")
            return Tr.tr("Where the mouse is");
        const on = a.opens_on ? a.opens_on.label : Tr.tr("where the mouse is");
        if (a.mode === "priority")
            return Tr.tr("Priority · opens on %1 now").arg(on);
        return a.game ? Tr.tr("Default for games · opens on %1 now").arg(on) : Tr.tr("Default · where the mouse is");
    }

    title: Tr.tr("App placement")
    description: Tr.tr("Which monitor each app opens on")
    isSubPage: true

    ToolBridge {
        id: bridge

        tool: "app-monitor"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: bridge.error !== ""
            icon: "error"
            iconColour: Colours.palette.m3error
            label: Tr.tr("Could not read app placement")
            subtext: bridge.error
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Search")
            value: root.query
            placeholderText: Tr.tr("App name")
            onValueEdited: v => root.query = v
        }

        ChipSelectRow {
            last: true
            label: Tr.tr("Show")
            options: [
                { value: "all", label: Tr.tr("All") },
                { value: "games", label: Tr.tr("Games"), icon: "sports_esports" },
                { value: "others", label: Tr.tr("Others"), icon: "apps" }
            ]
            current: root.filter
            onPicked: v => root.filter = v
        }

        SectionHeader {
            visible: root.custom.length > 0
            text: Tr.tr("Customized")
        }

        Repeater {
            model: root.custom.length

            AppRow {
                required property int index

                app: root.custom[index] ?? ({})
                first: index === 0
                last: index === root.custom.length - 1
            }
        }

        SectionHeader {
            visible: root.rest.length > 0
            text: Tr.tr("All apps")
        }

        Repeater {
            model: root.rest.length

            AppRow {
                required property int index

                app: root.rest[index] ?? ({})
                first: index === 0
                last: index === root.rest.length - 1
            }
        }
    }

    component AppRow: ConnectedRect {
        id: row

        property var app: ({})

        Layout.fillWidth: true
        implicitHeight: appRow.implicitHeight + appRow.anchors.margins * 2

        StateLayer {
            onClicked: {
                const entry = DesktopEntries.byId(row.app.desktop_id);
                if (!entry)
                    return;
                root.nState.selectedApp = entry;
                root.nState.openSubPage(2);
            }
        }

        RowLayout {
            id: appRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            IconImage {
                asynchronous: true
                implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                source: Quickshell.iconPath(row.app.icon ?? "", "image-missing")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: row.app.name ?? ""
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.summary(row.app)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                visible: !!row.app.game
                text: "sports_esports"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }
        }
    }
}
