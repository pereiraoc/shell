pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common
import "shortcuts.js" as Shortcuts

// Devices > Keyboard > Shortcuts: todos os atalhos de teclado, lidos ao vivo
// do Hyprland (`hyprctl binds -j`) e relidos a cada reload dele. A categoria
// e o 1o campo do desc que o binds.lua poe; @main marca os principais
// (Essentials, a vista que o Super+/ abre) e @icon da o simbolo da linha.
// Cartoes por categoria repartidos em colunas (masonry); trocar Essentials/All
// so muda visibilidade -- nada e recriado.
PageBase {
    id: root

    // [{ name, rows: [{ action, icon, main, combos: [{ label, tokens, tap }] }] }] (shortcuts.js)
    property var categories: []
    property bool failed
    // Essentials (so @main) a cada abertura; "All" e escolha do momento
    property bool showAll

    readonly property int columns: root.cappedWidth >= 760 ? 3 : root.cappedWidth >= 500 ? 2 : 1
    // Calculado por leitura, nao por vista: a vista so esconde linhas
    readonly property var columnsModel: Shortcuts.distribute(root.categories, root.columns)

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

        // Seletor compacto: dois botoes, o ativo preenchido
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.showAll ? Tr.tr("Every key binding") : Tr.tr("The essentials — what Super + / opens")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            TextButton {
                type: root.showAll ? TextButton.Tonal : TextButton.Filled
                isRound: true
                text: Tr.tr("Essentials")
                onClicked: root.showAll = false
            }

            TextButton {
                type: root.showAll ? TextButton.Filled : TextButton.Tonal
                isRound: true
                text: Tr.tr("All")
                onClicked: root.showAll = true
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.failed
            text: Tr.tr("Could not read the Hyprland key bindings")
            color: Colours.palette.m3error
            font: Tokens.font.body.medium
        }

        // Colunas independentes: cada cartao encosta no de cima (sem buracos)
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                model: root.columnsModel

                ColumnLayout {
                    id: column

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: column.modelData

                        StyledRect {
                            id: card

                            required property var modelData

                            readonly property bool hasMain: card.modelData.rows.some(r => r.main)

                            Layout.fillWidth: true
                            visible: root.showAll || card.hasMain
                            implicitHeight: col.implicitHeight + Tokens.padding.large * 2
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: col

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.small

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
                                        visible: root.showAll || row.modelData.main
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

                                        // Uma combinacao por linha
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
                                                            kind: Shortcuts.modKind(tok.modelData)
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
        }

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Defined in ~/.config/hypr/caelestia/binds.lua · updates when Hyprland reloads")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
