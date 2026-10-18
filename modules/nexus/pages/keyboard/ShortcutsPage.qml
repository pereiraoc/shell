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
// e o prefixo "Cat · " que o binds.lua poe em cada desc; teclas da mesma
// acao viram chips na mesma linha. Cartoes por categoria em ate 3 colunas.
PageBase {
    id: root

    // [{ name, rows: [{ action, combos: [string] }] }] (shortcuts.js)
    property var categories: []
    property bool failed

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
                model: root.categories

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
                                spacing: Tokens.spacing.extraSmall

                                StyledText {
                                    Layout.fillWidth: true
                                    text: row.modelData.action
                                    font: Tokens.font.body.medium
                                    wrapMode: Text.WordWrap
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.extraSmall

                                    Repeater {
                                        model: row.modelData.combos

                                        KeyChip {
                                            required property string modelData

                                            text: modelData
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

    // Tecla no estilo kbd: fundo um tom acima do cartao, borda fina
    component KeyChip: StyledRect {
        id: chip

        property alias text: label.text

        implicitWidth: label.implicitWidth + Tokens.padding.small * 2
        implicitHeight: label.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.small
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        StyledText {
            id: label

            anchors.centerIn: parent
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurface
        }
    }
}
