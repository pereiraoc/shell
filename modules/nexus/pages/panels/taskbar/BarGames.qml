pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Jogos da Steam no dashboard (V3-03): caelestia-games lista os instalados e
// grava os favoritos em ~/.config/caelestia/games.json, que o widget
// modules/dashboard/dash/QuickLaunch.qml observa.
PageBase {
    id: root

    readonly property var all: games.info.games ?? []
    readonly property var favs: games.info.favourites ?? []

    title: Tr.tr("Games")
    isSubPage: true

    ToolBridge {
        id: games

        tool: "games"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("In the dashboard")
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: root.favs.length === 0
            first: true
            last: true
            implicitHeight: emptyText.implicitHeight + Tokens.padding.large * 2

            StyledText {
                id: emptyText

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("No game picked yet. Switch one on below; they show at the bottom of the dashboard.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }

        ListEditor {
            function labelFor(item: var): string {
                return item.name;
            }

            function toggledFor(item: var): bool {
                return true;
            }

            z: 1
            first: true
            visible: root.favs.length > 0
            values: root.favs
            onItemMoved: (from, to) => games.run({ id: `move~${root.favs[from].appid}~${to}` })
            onItemRemoved: index => games.run({ id: `unfavourite~${root.favs[index].appid}` })
            onItemToggled: (index, checked) => {
                if (!checked)
                    games.run({ id: `unfavourite~${root.favs[index].appid}` });
            }
        }

        SectionHeader {
            text: Tr.tr("Installed games")
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: root.all.length === 0
            first: true
            implicitHeight: noneText.implicitHeight + Tokens.padding.large * 2

            StyledText {
                id: noneText

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: games.info.summary ?? Tr.tr("No Steam game found")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }

        Repeater {
            model: root.all

            ConnectedRect {
                id: gameRow

                required property var modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    IconImage {
                        visible: !!gameRow.modelData.icon
                        asynchronous: true
                        implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                        source: gameRow.modelData.icon ? `file://${gameRow.modelData.icon}` : ""
                    }

                    MaterialIcon {
                        visible: !gameRow.modelData.icon
                        text: "sports_esports"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: gameRow.modelData.name
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: gameRow.modelData.library
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledSwitch {
                        checked: gameRow.modelData.favourite
                        disabled: games.busyAction !== ""
                        onToggled: games.run({ id: `${checked ? "favourite" : "unfavourite"}~${gameRow.modelData.appid}` })
                    }
                }
            }
        }

        RowButton {
            last: true
            icon: "refresh"
            text: Tr.tr("Refresh names and icons")
            subtext: Tr.tr("Also drops uninstalled games from the dashboard")
            disabled: games.busyAction !== ""
            onClicked: games.run({ id: "refresh" })
        }
    }
}
