pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Jogos favoritos da Steam na barra (V3-03): ~/.config/caelestia/games.json,
// escrito pelo caelestia-games (Nexus > Panels > Taskbar > Games). Clique =
// steam://rungameid/<appid>.
Column {
    id: root

    property list<var> games: []
    readonly property int count: games.length

    function parse(text: string): void {
        try {
            root.games = (JSON.parse(text).favourites ?? []).filter(g => g && g.appid);
        } catch (e) {
            console.warn("games.json:", e);
            root.games = [];
        }
    }

    spacing: Tokens.spacing.small

    Repeater {
        model: root.games

        Item {
            id: item

            required property var modelData

            implicitWidth: Tokens.font.body.small.pointSize * 2
            implicitHeight: implicitWidth

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: Quickshell.execDetached(["steam", `steam://rungameid/${item.modelData.appid}`])
            }

            IconImage {
                anchors.fill: parent
                visible: !!item.modelData.icon
                asynchronous: true
                source: item.modelData.icon ? `file://${item.modelData.icon}` : ""
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !item.modelData.icon
                text: "sports_esports"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }
        }
    }

    FileView {
        path: `${Paths.config}/games.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.games = []
    }
}
