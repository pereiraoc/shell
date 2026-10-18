pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "shortcuts.js" as Shortcuts

// Devices > Keyboard > Shortcuts: todos os atalhos de teclado, lidos ao vivo
// do Hyprland (`hyprctl binds -j`) e relidos a cada reload dele. A categoria
// e o 1o campo do desc que o binds.lua poe; @main marca os principais
// (Essentials, a vista que o Super+/ abre) e @icon da o simbolo da linha.
// Teclas da mesma acao viram keycaps na mesma linha; cartoes por categoria
// em ate 3 colunas.
PageBase {
    id: root

    // [{ name, rows: [{ action, icon, main, combos: [{ label, tokens, tap }] }] }] (shortcuts.js)
    property var categories: []
    property bool failed
    // Essentials (so @main) a cada abertura; "All" e escolha do momento
    property bool showAll

    readonly property var shown: root.showAll ? root.categories : root.categories.map(c => ({
                name: c.name,
                rows: c.rows.filter(r => r.main)
            })).filter(c => c.rows.length > 0)
    readonly property int columns: root.cappedWidth >= 760 ? 3 : root.cappedWidth >= 500 ? 2 : 1

    function reload(): void {
        proc.running = true;
    }

    title: Tr.tr("Keyboard shortcuts")
    description: Tr.tr("Every Hyprland and Caelestia key binding")
    isSubPage: true

    Component.onCompleted: reload()

    // Process e Connections vivem dentro de um Item (o PageBase so aceita Item
    // como filho), como no StorageBrowser.
    Item {
        Process {
            id: proc

            command: ["hyprctl", "binds", "-j"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const cats = Shortcuts.parse(text);
                    root.failed = cats.length === 0;
                    root.categories = cats;
                }
            }
        }

        Connections {
            function onConfigReloaded(): void {
                root.reload();
            }

            target: Hypr
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.medium

        ChipSelectRow {
            first: true
            last: true
            label: Tr.tr("Show")
            subtext: root.showAll ? Tr.tr("Every key binding") : Tr.tr("The essentials — what Super + / opens")
            options: [
                { value: "main", label: Tr.tr("Essentials"), icon: "star" },
                { value: "all", label: Tr.tr("All"), icon: "list" }
            ]
            current: root.showAll ? "all" : "main"
            onPicked: v => root.showAll = v === "all"
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.failed
            text: Tr.tr("Could not read the Hyprland key bindings")
            color: Colours.palette.m3error
            font: Tokens.font.body.medium
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.columns
            columnSpacing: Tokens.spacing.medium
            rowSpacing: Tokens.spacing.medium

            Repeater {
                model: root.shown

                StyledRect {
                    id: card

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: col.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: col

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            font: Tokens.font.title.small
                            color: Colours.palette.m3primary
                        }

                        Repeater {
                            model: card.modelData.rows

                            ColumnLayout {
                                id: row

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Tokens.spacing.extraSmall

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    MaterialIcon {
                                        text: row.modelData.icon || "keyboard"
                                        color: Colours.palette.m3primary
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: row.modelData.action
                                        font: Tokens.font.body.medium
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.medium

                                    Repeater {
                                        model: row.modelData.combos

                                        Row {
                                            id: combo

                                            required property var modelData

                                            spacing: Tokens.spacing.extraSmall / 2

                                            Repeater {
                                                model: combo.modelData.tokens

                                                Row {
                                                    id: tok

                                                    required property int index
                                                    required property string modelData

                                                    spacing: Tokens.spacing.extraSmall / 2

                                                    StyledText {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        visible: tok.index > 0
                                                        text: "+"
                                                        color: Colours.palette.m3outline
                                                        font: Tokens.font.label.small
                                                    }

                                                    KeyCap {
                                                        text: tok.modelData
                                                    }
                                                }
                                            }

                                            StyledText {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: combo.modelData.tap
                                                text: Tr.tr("tap")
                                                color: Colours.palette.m3outline
                                                font: Tokens.font.label.small
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Defined in ~/.config/hypr/caelestia/binds.lua · updates when Hyprland reloads")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }

    // Keycap: tampa com borda fina sobre uma base 2 px mais escura (relevo)
    component KeyCap: Item {
        id: cap

        property alias text: capLabel.text

        implicitWidth: Math.max(capLabel.implicitWidth + Tokens.padding.small * 2, implicitHeight)
        implicitHeight: capLabel.implicitHeight + Tokens.padding.extraSmall * 2 + 2

        StyledRect {
            anchors.fill: parent
            anchors.topMargin: 2
            radius: Tokens.rounding.small
            color: Colours.palette.m3outlineVariant
        }

        StyledRect {
            anchors.fill: parent
            anchors.bottomMargin: 2
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHigh
            border.width: 1
            border.color: Colours.palette.m3outlineVariant

            StyledText {
                id: capLabel

                anchors.centerIn: parent
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurface
            }
        }
    }
}
