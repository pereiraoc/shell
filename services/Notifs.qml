pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components.misc
import qs.services
import qs.utils

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property alias dnd: props.dnd

    property bool loaded
    // Regras por app (~/.config/caelestia/notifs-rules.json, escritas pelo
    // caelestia-notifs): apps bloqueados nem viram NotifData -- vao direto ao
    // historico, marcados -- e `icons` e o glifo Material que substitui o icone
    // de um app (Icons.getNotifGlyph). V3-10.
    property var blockedApps: []
    property var iconOverrides: ({})
    readonly property string historyCli: `${Quickshell.env("HOME")}/.local/bin/caelestia-notifs`
    // Fila de gravacao no historico (um processo por vez, na ordem)
    property var recordQueue: []

    function isBlocked(app: string): bool {
        return root.blockedApps.includes(app ?? "");
    }

    // Historico em SQLite (caelestia-notifs add): nao e a lista viva da barra
    function record(notif: var, blocked: bool): void {
        const payload = {
            time: new Date().toISOString(),
            appName: notif.appName ?? "",
            summary: notif.summary ?? "",
            body: notif.body ?? "",
            appIcon: notif.appIcon ?? "",
            image: notif.image ?? "",
            urgency: notif.urgency ?? 1,
            blocked: blocked
        };
        root.recordQueue = [...root.recordQueue, JSON.stringify(payload)];
        root.pumpRecord();
    }

    function pumpRecord(): void {
        if (recorder.running || root.recordQueue.length === 0)
            return;
        const next = root.recordQueue[0];
        root.recordQueue = root.recordQueue.slice(1);
        recorder.command = [root.historyCli, "add", next];
        recorder.running = true;
    }

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    function shouldShowPopup(): bool {
        if (props.dnd || ShellState.anySidebarOpen())
            return false;
        if (GlobalConfig.notifs.fullscreen === NotifsFullscreen.Off && hasFullscreen())
            return false;
        return true;
    }

    onDndChanged: {
        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    onListChanged: {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 1000
        onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
                    time: n.time,
                    id: n.id,
                    summary: n.summary,
                    body: n.body,
                    appIcon: n.appIcon,
                    appName: n.appName,
                    image: n.image,
                    expireTimeout: n.expireTimeout,
                    urgency: n.urgency,
                    resident: n.resident,
                    hasActionIcons: n.hasActionIcons,
                    actions: n.actions
                }))))
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // App bloqueado: nao entra na lista nem aparece; fica so no
            // historico, marcado, para dar para rever e desbloquear
            if (root.isBlocked(notif.appName)) {
                root.record(notif, true);
                notif.dismiss();
                return;
            }
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
            root.record(notif, false);
        }
    }

    Process {
        id: recorder

        onExited: root.pumpRecord()
    }

    FileView {
        id: rulesFile

        path: `${Paths.config}/notifs-rules.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.blockedApps = Array.isArray(d?.blocked) ? d.blocked : [];
                root.iconOverrides = d?.icons && typeof d.icons === "object" ? d.icons : {};
            } catch (e) {
                root.blockedApps = [];
                root.iconOverrides = {};
            }
        }
        onLoadFailed: {
            root.blockedApps = [];
            root.iconOverrides = {};
        }
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/notifs.json`
        onLoaded: {
            const data = JSON.parse(text());
            for (const notif of data) {
                const properties = Object.assign({}, notif);

                // Backwards compatibility for old notifications
                if (properties.notificationId === undefined && properties.id !== undefined)
                    properties.notificationId = properties.id;

                delete properties.id;
                root.list.push(notifComp.createObject(root, properties));
            }
            root.list.sort((a, b) => b.time - a.time);
            root.loaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.loaded = true;
                Qt.callLater(() => setText("[]"));
            }
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: {
            for (const notif of root.list.slice())
                notif.close();
        }
    }

    IpcHandler {
        function clear(): void {
            for (const notif of root.list.slice())
                notif.close();
        }

        function isDndEnabled(): bool {
            return props.dnd;
        }

        function toggleDnd(): void {
            props.dnd = !props.dnd;
        }

        function enableDnd(): void {
            props.dnd = true;
        }

        function disableDnd(): void {
            props.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
