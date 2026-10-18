pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import "shortcuts.js" as Shortcuts

// Um grupo de atalhos: icone + titulo curto; embaixo as variantes, cada uma com
// suas combinacoes em keycaps. Usado nos cartoes comuns (ShortcutCard) e nos
// pares (ShortcutPairCard). Posicionadores (Column/Row/Flow) de proposito: com
// Layouts por grupo e por item a pagina levava ~250 ms so para nascer.
Column {
    id: root

    // { title, icon, main, items: [{ variant, note, level, icon, main, combos: [{ label, prefix, alts, tap }] }] }
    required property var group
    required property bool showAll
    // Altura de um keycap (KeyCap.qml): separadores "+", "/" e "tap" se alinham a ela
    required property int capHeight
    // Cartao de um grupo so com o mesmo nome (Float): nao repetir o titulo
    property bool showHeader: true
    // Linha bem leve acima (entre grupos do mesmo cartao)
    property bool divider

    // Recuo das subvariantes ("pin" sob "toggle"): a seta "↳" vem de fonte de
    // reserva e e mais larga que parece -- medir, senao o texto monta nela
    readonly property int arrowSlot: Math.ceil(arrowMetrics.advanceWidth) + Tokens.spacing.small

    visible: root.showAll || root.group.main
    spacing: Tokens.spacing.extraSmall

    TextMetrics {
        id: arrowMetrics

        font: Tokens.font.label.medium
        text: "↳"
    }

    Rectangle {
        width: parent.width
        height: 1
        visible: root.divider
        color: Colours.palette.m3outlineVariant
        opacity: 0.5
    }

    Row {
        id: header

        width: parent.width
        visible: root.showHeader
        spacing: Tokens.spacing.small

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            text: root.group.icon || "keyboard"
            color: Colours.palette.m3primary
        }

        StyledText {
            width: header.width - icon.width - header.spacing
            text: root.group.title
            font: Tokens.font.body.medium
            wrapMode: Text.WordWrap
        }
    }

    Repeater {
        model: root.group.items

        Column {
            id: item

            required property var modelData

            // nivel 2 ("pin" sob "toggle"): texto E keycaps recuam juntos;
            // a seta fica na margem, alinhada com a variante de cima
            x: Tokens.padding.largeIncreased + (item.modelData.level > 1 ? root.arrowSlot : 0)
            width: parent.width - x
            visible: root.showAll || item.modelData.main
            spacing: Tokens.spacing.extraSmall / 2

            // Variante + nota "(all monitors)" ao lado, menor e mais apagada.
            // Text puro (sem Behaviors do StyledText): sao dezenas por pagina.
            Row {
                x: item.modelData.level > 1 ? -root.arrowSlot : 0
                visible: item.modelData.variant !== ""
                spacing: Tokens.spacing.extraSmall

                // nivel 2: "↳" na margem, no nivel da variante de cima
                Text {
                    anchors.baseline: note.baseline
                    width: root.arrowSlot - parent.spacing
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
