pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services

// Aba "Launch" do dashboard (V3-02/03): atalhos do usuario e jogos favoritos
// da Steam em dois cartoes lado a lado, linhas no estilo do launcher (icone
// de app, nome, linha cinza embaixo). Dados lidos no Content.qml
// (shortcuts.json / games.json); a aba so existe com algo nas listas.
// Editados em Nexus > Panels > Dashboard > Shortcuts / Games.
Item {
    id: root

    required property ScreenState screenState
    required property list<var> shortcuts
    required property list<var> games

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

    implicitWidth: 840
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Tokens.spacing.medium

        // Nada configurado ainda
        StyledRect {
            visible: root.shortcuts.length === 0 && root.games.length === 0
            Layout.fillWidth: true
            implicitHeight: emptyCol.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: emptyCol

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "rocket_launch"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Add shortcuts and games in Settings › Panels › Dashboard")
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                }
            }
        }

        Card {
            visible: root.shortcuts.length > 0
            title: Tr.tr("Shortcuts")
            icon: "bolt"
            model: root.shortcuts
            kind: "shortcut"
        }

        Card {
            visible: root.games.length > 0
            title: Tr.tr("Games")
            icon: "sports_esports"
            model: root.games
            kind: "game"
        }
    }

    component Card: StyledRect {
        id: card

        property string title
        property string icon
        property var model: []
        property string kind

        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: cardCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.leftMargin: Tokens.padding.medium
                Layout.bottomMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: card.icon
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    text: card.title
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.title.small
                }
            }

            Repeater {
                model: card.model

                Item {
                    id: row

                    required property var modelData

                    readonly property bool isGame: card.kind === "game"
                    readonly property string iconRef: modelData.icon ?? ""
                    readonly property string iconSource: {
                        if (!iconRef)
                            return "";
                        if (iconRef.includes("/"))
                            return `file://${iconRef}`;
                        return Quickshell.iconPath(iconRef, true);
                    }

                    Layout.fillWidth: true
                    implicitHeight: Tokens.sizes.launcher.itemHeight

                    StateLayer {
                        radius: Tokens.rounding.large
                        onClicked: row.isGame ? root.runGame(row.modelData) : root.runShortcut(row.modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        Item {
                            implicitWidth: Math.round(Tokens.sizes.launcher.itemHeight * 0.7)
                            implicitHeight: implicitWidth

                            IconImage {
                                anchors.fill: parent
                                visible: row.iconSource !== ""
                                asynchronous: true
                                source: row.iconSource
                            }

                            // Simbolo Material (atalho com icone por nome) ou sem icone
                            MaterialIcon {
                                anchors.centerIn: parent
                                visible: row.iconSource === ""
                                text: row.iconRef || (row.isGame ? "sports_esports" : "bolt")
                                color: Colours.palette.m3secondary
                                fontStyle: Tokens.font.icon.large
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.name ?? ""
                                font: Tokens.font.body.medium
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: {
                                    if (row.isGame)
                                        return Tr.tr("Steam");
                                    const c = row.modelData.command ?? "";
                                    if (c.includes("obsidian://open?vault="))
                                        return Tr.tr("Obsidian vault");
                                    return row.modelData.cwd || c;
                                }
                                font: Tokens.font.body.small
                                color: Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
