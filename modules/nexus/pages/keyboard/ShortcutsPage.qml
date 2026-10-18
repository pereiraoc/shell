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
// do Hyprland (`hyprctl binds -j`) e relidos a cada reload dele. Categoria =
// 1o campo do desc do binds.lua; "Grupo › variante" na acao agrupa variantes
// sob um titulo curto; @main marca os principais (Essentials, a vista que o
// Super+/ abre) e @icon da o simbolo. Cartoes repartidos em colunas (masonry);
// trocar Essentials/All so muda visibilidade -- nada e recriado.
PageBase {
    id: root

    // [{ name, groups: [{ title, icon, main, items: [{ variant, main, combos: [{ label, prefix, alts, tap }] }] }] }]
    property var categories: []
    property bool failed
    // Essentials (so @main) a cada abertura; "All" e escolha do momento
    property bool showAll

    // Calculado por leitura, nao por vista: a vista so esconde linhas. Vazio
    // enquanto a pagina nao tem largura: criar os cartoes antes de ela estar
    // anexada caia em incubacao assincrona aninhada (pingando por ~2 s) e, ao
    // chegar a largura, tudo era recriado para 3 colunas.
    // Uma expressao so: `columns` e `cappedWidth` mudando em separado
    // reconstruiam os cartoes duas vezes (1 coluna, depois 3).
    readonly property var columnsModel: root.cappedWidth > 0 ? Shortcuts.distribute(root.categories, root.cappedWidth >= 760 ? 3 : root.cappedWidth >= 500 ? 2 : 1) : []
    // Altura de um keycap (KeyCap.qml): separadores "+", "/" e "tap" se alinham a ela
    readonly property int capHeight: capMetrics.height + Tokens.padding.extraSmall * 2 + 2

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
        FontMetrics {
            id: capMetrics

            font: Tokens.font.label.small
        }

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

        // Colunas independentes: cada cartao encosta no de cima (sem buracos).
        // Com 3 colunas, Manipulate (combos longos como Super + Shift + F1/F2/F3)
        // leva mais; Navigate sobra espaco e a 3a precisa caber "Capture region".
        Row {
            id: grid

            readonly property var weights: root.columnsModel.length === 3 ? [0.95, 1.15, 0.9] : root.columnsModel.map(() => 1)
            readonly property real unit: root.columnsModel.length > 0 ? (width - spacing * (root.columnsModel.length - 1)) / grid.weights.reduce((a, b) => a + b, 0) : 0

            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                model: root.columnsModel

                Column {
                    id: column

                    required property int index
                    required property var modelData

                    width: Math.floor(grid.unit * grid.weights[column.index])
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: column.modelData

                        StyledRect {
                            id: card

                            required property var modelData

                            readonly property bool hasMain: card.modelData.groups.some(g => g.main)

                            width: parent.width
                            visible: root.showAll || card.hasMain
                            implicitHeight: col.implicitHeight + Tokens.padding.large * 2
                            radius: Tokens.rounding.large
                            color: Colours.tPalette.m3surfaceContainer

                            // Posicionadores (Column/Row/Flow) de proposito: com Layouts
                            // por grupo e por item a pagina levava ~250 ms so para nascer.
                            Column {
                                id: col

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Tokens.padding.large
                                spacing: Tokens.spacing.largeIncreased

                                StyledText {
                                    width: parent.width
                                    text: card.modelData.name
                                    font: Tokens.font.title.small
                                    color: Colours.palette.m3primary
                                }

                                Repeater {
                                    model: card.modelData.groups

                                    // Grupo: icone + titulo curto; embaixo as variantes.
                                    // Entre grupos, uma linha bem leve.
                                    Column {
                                        id: grp

                                        required property int index
                                        required property var modelData

                                        width: parent.width
                                        visible: root.showAll || grp.modelData.main
                                        spacing: Tokens.spacing.extraSmall

                                        Rectangle {
                                            width: parent.width
                                            height: 1
                                            visible: grp.index > 0
                                            color: Colours.palette.m3outlineVariant
                                            opacity: 0.5
                                        }

                                        Row {
                                            id: grpHeader

                                            width: parent.width
                                            // Cartao com um grupo so e o mesmo nome (Float): nao repetir
                                            visible: !(card.modelData.groups.length === 1 && grp.modelData.title === card.modelData.name)
                                            spacing: Tokens.spacing.small

                                            MaterialIcon {
                                                id: grpIcon

                                                anchors.verticalCenter: parent.verticalCenter
                                                text: grp.modelData.icon || "keyboard"
                                                color: Colours.palette.m3primary
                                            }

                                            StyledText {
                                                width: grpHeader.width - grpIcon.width - grpHeader.spacing
                                                text: grp.modelData.title
                                                font: Tokens.font.body.medium
                                                wrapMode: Text.WordWrap
                                            }
                                        }

                                        Repeater {
                                            model: grp.modelData.items

                                            Column {
                                                id: item

                                                required property var modelData

                                                // nivel 2 ("pin" sob "toggle"): recuo a mais
                                                x: Tokens.padding.largeIncreased + (item.modelData.level > 1 ? Tokens.padding.large : 0)
                                                width: parent.width - x
                                                visible: root.showAll || item.modelData.main
                                                spacing: Tokens.spacing.extraSmall / 2

                                                // Variante + nota "(all monitors)" ao lado, menor e mais apagada.
                                                // Text puro (sem Behaviors do StyledText): sao dezenas por pagina.
                                                Row {
                                                    visible: item.modelData.variant !== ""
                                                    spacing: Tokens.spacing.extraSmall

                                                    // nivel 2: "↳" deixa claro que depende da variante de cima
                                                    Text {
                                                        anchors.baseline: note.baseline
                                                        visible: item.modelData.level > 1
                                                        text: "↳"
                                                        color: Colours.palette.m3outline
                                                        font: Tokens.font.label.medium
                                                        renderType: Text.NativeRendering
                                                    }

                                                    Text {
                                                        anchors.baseline: note.baseline
                                                        text: item.modelData.variant
                                                        color: Colours.palette.m3onSurfaceVariant
                                                        font: Tokens.font.label.medium
                                                        renderType: Text.NativeRendering
                                                    }

                                                    Text {
                                                        id: note

                                                        visible: item.modelData.note !== ""
                                                        text: "(" + item.modelData.note + ")"
                                                        color: Colours.palette.m3outline
                                                        font: Tokens.font.label.small
                                                        renderType: Text.NativeRendering
                                                    }
                                                }

                                                // Uma combinacao por linha; se nao couber, as teclas quebram linha
                                                Repeater {
                                                    model: item.modelData.combos

                                                    Flow {
                                                        id: combo

                                                        required property var modelData

                                                        width: parent.width
                                                        spacing: Tokens.spacing.extraSmall / 2

                                                        Repeater {
                                                            model: combo.modelData.prefix

                                                            Row {
                                                                id: tok

                                                                required property int index
                                                                required property string modelData

                                                                spacing: Tokens.spacing.extraSmall / 2

                                                                KeySeparator {
                                                                    height: root.capHeight
                                                                    visible: tok.index > 0
                                                                }

                                                                KeyCap {
                                                                    text: tok.modelData
                                                                    kind: Shortcuts.modKind(tok.modelData)
                                                                }
                                                            }
                                                        }

                                                        Row {
                                                            spacing: Tokens.spacing.extraSmall / 2

                                                            KeySeparator {
                                                                height: root.capHeight
                                                                visible: combo.modelData.prefix.length > 0
                                                            }

                                                            KeyCap {
                                                                visible: combo.modelData.alts.length === 1
                                                                text: combo.modelData.alts[0]
                                                                kind: Shortcuts.modKind(combo.modelData.alts[0])
                                                            }

                                                            KeyAlternatives {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                visible: combo.modelData.alts.length > 1
                                                                alts: combo.modelData.alts
                                                                capHeight: root.capHeight
                                                            }

                                                            KeySeparator {
                                                                height: root.capHeight
                                                                visible: combo.modelData.tap
                                                                text: Tr.tr("tap")
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
