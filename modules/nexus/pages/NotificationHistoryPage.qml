pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common

// Notificacoes (Nexus > Notifications), em abas: History (tudo o que foi
// mostrado -- e o que foi bloqueado --, com busca e filtro por app; vem do
// SQLite do caelestia-notifs, nao da lista viva da barra), Apps (um por app:
// quantas, a ultima, bloquear e o glifo Material que substitui o icone) e
// Settings (atalho para a pagina de comportamento: toasts, tempos). V3-10.
PageBase {
    id: root

    readonly property var info: bridge.info
    readonly property var history: root.info.history ?? []
    readonly property var apps: root.info.apps ?? []
    property string query
    property string appFilter
    // Linhas da aba History depois da busca e do filtro (no maximo 300 vem do CLI)
    readonly property var shown: {
        const q = root.query.trim().toLowerCase();
        return root.history.filter(h => (!root.appFilter || h.app === root.appFilter) && (!q || `${h.app} ${h.summary} ${h.body}`.toLowerCase().includes(q)));
    }
    // App escolhido na aba Apps (para o campo do glifo)
    property string editingApp

    function when(ts: string): string {
        const d = new Date(ts);
        if (isNaN(d.getTime()))
            return ts;
        const today = new Date();
        const sameDay = d.toDateString() === today.toDateString();
        return sameDay ? d.toLocaleTimeString(Qt.locale(), "HH:mm") : d.toLocaleString(Qt.locale(), "dd/MM HH:mm");
    }

    function glyphFor(h: var): string {
        return Icons.getNotifGlyph({ summary: h.summary, body: h.body, appIcon: h.icon, image: h.image, appName: h.app, urgency: h.urgency, iconOverride: (root.info.overrides ?? {})[h.app] ?? "" });
    }

    title: qsTr("Notifications")
    description: qsTr("History, blocked apps, icons")
    tabs: [
        { id: "history", label: qsTr("History") },
        { id: "apps", label: qsTr("Apps") },
        { id: "settings", label: qsTr("Settings") }
    ]

    onVisibleChanged: if (visible) bridge.refresh()

    ToolBridge {
        id: bridge

        tool: "notifs"
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
            label: qsTr("Could not read the notification history")
            subtext: bridge.error
        }

        // ----------------------------------------------------------- History
        TabPane {
            active: root.tab === "history"

            TextFieldRow {
                first: true
                label: qsTr("Search")
                subtext: root.appFilter ? qsTr("Only %1 — tap the app again in Apps to show all").arg(root.appFilter) : qsTr("%n notification(s) kept", "", root.info.total ?? 0)
                placeholderText: qsTr("app, title or text")
                value: root.query
                onValueEdited: v => root.query = v
            }

            ChipSelectRow {
                last: true
                visible: !!root.appFilter
                label: qsTr("App")
                options: [{ value: root.appFilter, label: root.appFilter }, { value: "", label: qsTr("All apps") }]
                current: root.appFilter
                onPicked: v => root.appFilter = v
            }

            InfoRow {
                first: true
                last: true
                visible: root.shown.length === 0
                icon: "notifications_off"
                label: root.history.length === 0 ? qsTr("Nothing yet") : qsTr("No match")
                subtext: root.history.length === 0 ? qsTr("New notifications are recorded as they arrive") : ""
            }

            Repeater {
                model: Math.min(root.shown.length, 150)

                InfoRow {
                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: root.shown[index] ?? ({})
                    readonly property var liveItem: root.shown[index]
                    required property int index

                    first: index === 0
                    last: index === Math.min(root.shown.length, 150) - 1
                    icon: root.glyphFor(modelData)
                    iconColour: modelData.blocked ? Colours.palette.m3outline : modelData.urgency === 2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    label: [modelData.summary || qsTr("(no title)"), modelData.blocked ? qsTr("blocked") : ""].filter(x => x).join(" · ")
                    subtext: [modelData.app, (modelData.body ?? "").replace(/\s+/g, " ").slice(0, 140)].filter(x => x).join(" · ")
                    value: root.when(modelData.time ?? "")
                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                visible: root.shown.length > 150
                text: qsTr("Showing the first 150 of %1 — refine the search").arg(root.shown.length)
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            SectionHeader {
                visible: (root.info.total ?? 0) > 0
                text: qsTr("Housekeeping")
            }

            RowButton {
                first: true
                visible: (root.info.total ?? 0) > 0
                icon: "auto_delete"
                text: qsTr("Delete older than 30 days")
                disabled: bridge.busyAction !== ""
                onClicked: bridge.run({ id: "prune-30" })
            }

            RowButton {
                last: true
                visible: (root.info.total ?? 0) > 0
                icon: "delete_sweep"
                iconLabel.color: Colours.palette.m3error
                text: qsTr("Clear the whole history")
                subtext: qsTr("%n notification(s)", "", root.info.total ?? 0)
                disabled: bridge.busyAction !== ""
                onClicked: bridge.run({ id: "clear-history" })
            }

            ActionErrorRow {
                bridge: bridge
            }
        }

        // -------------------------------------------------------------- Apps
        TabPane {
            active: root.tab === "apps"

            InfoRow {
                first: true
                last: true
                visible: root.apps.length === 0
                icon: "apps"
                label: qsTr("No app has notified yet")
            }

            Repeater {
                model: root.apps.length

                ColumnLayout {
                    id: app

                    // Modelo = quantidade: atualizar o status nao recria a linha
                    // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                    // que vai sumir guarda o ultimo item ate ser destruida.
                    property var modelData: root.apps[index] ?? ({})
                    readonly property var liveItem: root.apps[index]
                    required property int index
                    readonly property bool editing: root.editingApp === app.modelData.name

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall / 2

                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

                    RowButton {
                        first: true
                        last: !app.editing
                        icon: app.modelData.glyph || Icons.getNotifGlyph({ appName: app.modelData.name, appIcon: app.modelData.icon, summary: "" })
                        iconLabel.color: app.modelData.blocked ? Colours.palette.m3outline : Colours.palette.m3onSurfaceVariant
                        text: app.modelData.name
                        subtext: [qsTr("%n notification(s)", "", app.modelData.count ?? 0), app.modelData.last ? qsTr("last %1").arg(root.when(app.modelData.last)) : "", app.modelData.blocked ? qsTr("blocked") : ""].filter(x => x).join(" · ")
                        trailingIcon: app.editing ? "expand_less" : "expand_more"
                        onClicked: root.editingApp = app.editing ? "" : app.modelData.name
                    }

                    ToggleRow {
                        visible: app.editing
                        text: qsTr("Block notifications")
                        subtext: qsTr("They are still kept in the history, marked as blocked")
                        checked: !!app.modelData.blocked
                        disabled: bridge.busyAction !== ""
                        onToggled: bridge.run({ id: `${checked ? "block" : "unblock"}~${app.modelData.name}` })
                    }

                    TextFieldRow {
                        visible: app.editing
                        label: qsTr("Icon")
                        subtext: app.modelData.glyph ? qsTr("Material Symbol “%1” replaces this app's icon").arg(app.modelData.glyph) : qsTr("Material Symbol name (e.g. chat_bubble); empty = the usual icon")
                        placeholderText: "chat_bubble"
                        value: app.modelData.glyph ?? ""
                        smallField: true
                        validate: v => /^[a-z0-9_]*$/.test(v)
                        onEditingFinished: v => {
                            if (v === (app.modelData.glyph ?? ""))
                                return;
                            bridge.run({ id: v ? `icon~${app.modelData.name}~${v}` : `icon-clear~${app.modelData.name}` });
                        }
                    }

                    RowButton {
                        last: true
                        visible: app.editing
                        icon: "history"
                        text: qsTr("Show its notifications")
                        trailingIcon: "chevron_right"
                        onClicked: {
                            root.appFilter = app.modelData.name;
                            root.tab = "history";
                        }
                    }
                }
            }

            ActionErrorRow {
                bridge: bridge
            }
        }

        // ---------------------------------------------------------- Settings
        TabPane {
            active: root.tab === "settings"

            NavRow {
                first: true
                icon: "tune"
                text: qsTr("Behaviour")
                subtext: qsTr("Toasts, timeouts, do not disturb over fullscreen")
                onClicked: root.nState.openPage("shell", 1, "")
            }

            InfoRow {
                last: true
                icon: "database"
                label: qsTr("Where the history lives")
                subtext: root.info.db ?? ""
                value: qsTr("%n notification(s)", "", root.info.total ?? 0)
            }
        }
    }
}
