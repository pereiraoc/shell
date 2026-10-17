import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property DesktopEntry app: nState.selectedApp
    readonly property bool favouriteByRegex: app && matchedByRegex(GlobalConfig.launcher.favouriteApps, app.id)
    readonly property bool hiddenByRegex: app && matchedByRegex(GlobalConfig.launcher.hiddenApps, app.id)

    readonly property var placement: (appmon.info.apps ?? []).find(a => a.desktop_id === root.app?.id) ?? null
    readonly property var knownMonitors: appmon.info.monitors ?? []

    function monitorOptions(exclude: string): var {
        return root.knownMonitors.filter(m => m.id !== exclude).map(m => ({
            value: m.id,
            label: `${m.connected ? "● " : "○ "}${m.label}`
        }));
    }

    function setPriority(first: string, second: string): void {
        const ids = [first, second].filter(x => x);
        appmon.run({ id: `rule~${root.placement.key}~priority~${ids.join("~")}` });
    }

    function isRegexEntry(s: string): bool {
        return /^\^.*\$$/.test(s);
    }

    function matchedByRegex(filterList: list<string>, id: string): bool {
        return filterList.some(f => isRegexEntry(f) && new RegExp(f).test(id));
    }

    onAppChanged: {
        // Auto close when app lost
        if (!app)
            nState.closeSubPage();
    }

    title: Tr.tr("App info")
    isSubPage: true

    // Regras de monitor por app (caelestia-app-monitor)
    ToolBridge {
        id: appmon

        tool: "app-monitor"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.large
            spacing: Tokens.spacing.large

            IconImage {
                asynchronous: true
                implicitSize: Math.round(Tokens.font.icon.large.pointSize * 3)
                source: Quickshell.iconPath(root.app?.icon, "image-missing")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.app?.name ?? ""
                    font: Tokens.font.title.medium
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: text
                    text: (root.app?.comment || root.app?.genericName) ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Launcher
        SectionHeader {
            first: true
            text: Tr.tr("Launcher")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Favourite")
            subtext: root.favouriteByRegex ? Tr.tr("Matched by a regex in favouriteApps — edit the config file to change") : Tr.tr("Pin to the top of the launcher")
            enabled: !root.favouriteByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.favouriteApps;
                GlobalConfig.launcher.favouriteApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Hidden")
            subtext: root.hiddenByRegex ? Tr.tr("Matched by a regex in hiddenApps — edit the config file to change") : Tr.tr("Hide from the launcher")
            enabled: !root.hiddenByRegex
            checked: root.app && Strings.testRegexList(GlobalConfig.launcher.hiddenApps, root.app.id)
            onToggled: {
                const apps = GlobalConfig.launcher.hiddenApps;
                GlobalConfig.launcher.hiddenApps = checked ? [...apps, root.app.id] : apps.filter(a => a !== root.app.id);
            }
        }

        // Monitor de abertura (caelestia-app-monitor; o hook do Hyprland aplica)
        SectionHeader {
            visible: !!root.placement
            text: Tr.tr("Opens on")
        }

        ChipSelectRow {
            visible: !!root.placement
            label: Tr.tr("Open on")
            subtext: root.placement?.game ? Tr.tr("Default for games: the widest monitor, external first") : Tr.tr("Default: where the mouse is")
            options: [
                { value: "default", label: Tr.tr("Default") },
                { value: "mouse", label: Tr.tr("Where the mouse is"), icon: "mouse" },
                { value: "priority", label: Tr.tr("Priority monitors"), icon: "desktop_windows" }
            ]
            current: root.placement?.mode ?? "default"
            busy: appmon.busyAction.startsWith("rule~")
            onPicked: v => {
                if (v === "priority") {
                    const first = root.placement.opens_on?.id ?? root.knownMonitors[0]?.id ?? "";
                    if (first)
                        root.setPriority(first, "");
                } else {
                    appmon.run({ id: `rule~${root.placement.key}~${v}` });
                }
            }
        }

        ExpandSelectRow {
            visible: root.placement?.mode === "priority"
            icon: "looks_one"
            label: Tr.tr("1st choice")
            options: root.monitorOptions(root.placement?.monitors?.[1] ?? "")
            current: root.placement?.monitors?.[0] ?? ""
            onPicked: v => root.setPriority(v, root.placement.monitors[1] ?? "")
        }

        ExpandSelectRow {
            visible: root.placement?.mode === "priority"
            icon: "looks_two"
            label: Tr.tr("2nd choice")
            subtext: Tr.tr("Used if the 1st isn't connected")
            options: [{ value: "", label: Tr.tr("None") }, ...root.monitorOptions(root.placement?.monitors?.[0] ?? "")]
            current: root.placement?.monitors?.[1] ?? ""
            onPicked: v => root.setPriority(root.placement.monitors[0], v)
        }

        ToggleRow {
            visible: !!root.placement
            text: Tr.tr("Is a game")
            subtext: root.placement?.steam ? Tr.tr("Steam games are always games") : Tr.tr("Games use the game default")
            enabled: !root.placement?.steam
            checked: !!root.placement?.game
            onToggled: appmon.run({ id: `game~${root.placement.key}~${checked ? "on" : "off"}` })
        }

        InfoRow {
            visible: !!root.placement
            last: true
            icon: "open_in_new"
            label: Tr.tr("Opens on now")
            value: root.placement?.opens_on?.label ?? Tr.tr("Where the mouse is")
        }

        // Details
        SectionHeader {
            text: Tr.tr("Details")
        }

        WrapInfoRow {
            id: appId

            first: true
            label: Tr.tr("App ID")
            value: root.app?.id ?? ""
            labelComp.Layout.preferredWidth: Math.max(labelComp.implicitWidth, command.labelComp.implicitWidth)
        }

        WrapInfoRow {
            id: command

            last: true
            label: Tr.tr("Command")
            value: (root.app?.command ?? []).join(" ")
            labelComp.Layout.preferredWidth: Math.max(labelComp.implicitWidth, appId.labelComp.implicitWidth)
        }
    }

    component WrapInfoRow: ConnectedRect {
        id: row

        property alias label: label.text
        property alias value: value.text
        readonly property alias labelComp: label

        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                id: label

                Layout.alignment: Qt.AlignTop
                font: Tokens.font.body.small
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                id: value

                Layout.fillWidth: true
                Layout.maximumWidth: implicitWidth + 1 // Whyyyyyyyyy
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }
    }
}
