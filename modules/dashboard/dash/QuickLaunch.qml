pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Faixa de lancamento no dashboard (V3-02/03): atalhos do usuario
// (~/.config/caelestia/shortcuts.json) a esquerda e jogos favoritos da Steam
// (~/.config/caelestia/games.json, escrito pelo caelestia-games) a direita.
// Editados em Nexus > Panels > Dashboard > Shortcuts / Games. Lancar fecha o
// dashboard. Sem nada nas duas listas, a faixa some.
Item {
    id: root

    required property ScreenState screenState

    property list<var> shortcuts: []
    property list<var> games: []
    readonly property bool empty: shortcuts.length === 0 && games.length === 0
    readonly property real tile: Tokens.font.icon.large.pointSize * 2.1

    function parseShortcuts(text: string): void {
        try {
            root.shortcuts = (JSON.parse(text).shortcuts ?? []).filter(s => s && s.command && s.enabled !== false);
        } catch (e) {
            root.shortcuts = [];
        }
    }

    function parseGames(text: string): void {
        try {
            root.games = (JSON.parse(text).favourites ?? []).filter(g => g && g.appid);
        } catch (e) {
            root.games = [];
        }
    }

    function runShortcut(s: var): void {
        const opts = { command: ["sh", "-c", s.command] };
        if (s.cwd)
            opts.workingDirectory = s.cwd;
        Quickshell.execDetached(opts);
        root.screenState.dashboard = false;
    }

    function runGame(g: var): void {
        Quickshell.execDetached(["steam", `steam://rungameid/${g.appid}`]);
        root.screenState.dashboard = false;
    }

    implicitWidth: row.implicitWidth + Tokens.padding.large * 2
    implicitHeight: root.empty ? 0 : row.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        spacing: Tokens.spacing.small
        visible: !root.empty

        Repeater {
            model: root.shortcuts

            Tile {
                required property var modelData

                label: modelData.name ?? ""
                icon: modelData.icon ?? ""
                fallback: "bolt"
                onActivated: root.runShortcut(modelData)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Repeater {
            model: root.games

            Tile {
                required property var modelData

                label: modelData.name ?? ""
                icon: modelData.icon ?? ""
                fallback: "sports_esports"
                onActivated: root.runGame(modelData)
            }
        }
    }

    FileView {
        path: `${Paths.config}/shortcuts.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseShortcuts(text())
        onLoadFailed: root.shortcuts = []
    }

    FileView {
        path: `${Paths.config}/games.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseGames(text())
        onLoadFailed: root.games = []
    }

    // Icone + nome curto embaixo; o nome inteiro no hover (a linha estica)
    component Tile: Item {
        id: tile

        property string label
        property string icon
        property string fallback
        readonly property bool isImage: icon.includes("/")
        readonly property string themePath: !isImage && icon ? Quickshell.iconPath(icon, true) : ""

        signal activated

        Layout.preferredWidth: root.tile * 1.9
        implicitHeight: col.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            radius: Tokens.rounding.medium
            onClicked: tile.activated()
        }

        Column {
            id: col

            anchors.centerIn: parent
            width: parent.width - Tokens.padding.small * 2
            spacing: Tokens.spacing.extraSmall

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.tile
                height: root.tile

                IconImage {
                    anchors.fill: parent
                    visible: tile.isImage || tile.themePath !== ""
                    asynchronous: true
                    source: tile.isImage ? `file://${tile.icon}` : tile.themePath
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: !tile.isImage && tile.themePath === ""
                    text: tile.icon || tile.fallback
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.large
                }
            }

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.label
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
