pragma ComponentBehavior: Bound

import "launch"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.utils

// Aba "Launch" do dashboard (V3-02/03): atalhos do usuario (esq.) e a
// biblioteca da Steam (dir.) -- os jogos instalados separados por tipo (inferido
// pelas tags da loja no caelestia-games), favoritos primeiro no tipo e com estrela.
// Icones monocromaticos como a barra lateral: silhueta propria do jogo
// (~/.config/caelestia/launch-icons) ou o simbolo Material do tipo; atalho usa a
// imagem/silhueta (obsidian:// -> launch-icons/obsidian.svg) ou um simbolo.
// Dados lidos no Content.qml; editados em Nexus > Panels > Dashboard.
Item {
    id: root

    required property ScreenState screenState
    required property list<var> shortcuts
    required property list<var> groups

    readonly property bool hasGames: groups.length > 0

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

    // Simbolo de traco do atalho: nome Material gravado (sem ponto nem barra),
    // senao pelo que ele abre
    function shortcutGlyph(s: var): string {
        const ic = s.icon ?? "";
        if (ic && !ic.includes(".") && !ic.includes("/"))
            return ic;
        const c = s.command ?? "";
        if (c.includes("obsidian://"))
            return "book_2";
        if (s.cwd)
            return "folder";
        return "bolt";
    }

    // Silhueta do atalho: caminho de imagem gravado, ou a do app que ele abre
    function shortcutArt(s: var): string {
        const ic = s.icon ?? "";
        if (ic.includes("/"))
            return ic;
        if ((s.command ?? "").includes("obsidian://"))
            return `${Paths.config}/launch-icons/obsidian.svg`;
        return "";
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
            visible: root.shortcuts.length === 0 && !root.hasGames
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

        // Atalhos
        LaunchCard {
            visible: root.shortcuts.length > 0
            Layout.preferredWidth: root.hasGames ? 280 : -1
            Layout.fillWidth: !root.hasGames
            title: Tr.tr("Shortcuts")
            icon: "bolt"

            Repeater {
                model: root.shortcuts

                LaunchRow {
                    required property var modelData

                    Layout.fillWidth: true
                    glyph: root.shortcutGlyph(modelData)
                    art: root.shortcutArt(modelData)
                    label: modelData.name ?? ""
                    sublabel: {
                        const c = modelData.command ?? "";
                        if (c.includes("obsidian://open?vault="))
                            return Tr.tr("Obsidian vault");
                        return modelData.cwd || c;
                    }
                    onActivated: root.runShortcut(modelData)
                }
            }
        }

        // Jogos: favoritos + biblioteca por tipo
        LaunchCard {
            visible: root.hasGames
            Layout.fillWidth: true
            title: Tr.tr("Games")
            icon: "sports_esports"

            VerticalFadeFlickable {
                Layout.fillWidth: true
                implicitHeight: Math.min(sections.implicitHeight, 460)
                contentHeight: sections.implicitHeight
                clip: true

                ColumnLayout {
                    id: sections

                    width: parent.width
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: root.groups

                        GameSection {
                            required property var modelData

                            name: modelData.name === "Other" ? Tr.tr("Other") : modelData.name
                            glyph: modelData.glyph
                            model: modelData.games
                            onLaunched: game => root.runGame(game)
                        }
                    }
                }
            }
        }
    }
}
