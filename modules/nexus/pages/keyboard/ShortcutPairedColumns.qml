pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "shortcuts.js" as Shortcuts

// Colunas 1-2 fundidas: o primeiro cartao de cada uma (Navigate, Manipulate)
// hospeda os pares (@col:12). Cada par e uma linha com o grupo de navegar a
// esquerda e o de manipular a direita, na mesma altura, cercada so por um
// pontilhado (o das teclas alternativas) que atravessa o vao entre os cartoes
// -- sem cartao, titulo nem divisoria propria. Depois dos pares cada cartao
// segue com os proprios grupos, e os demais cartoes da coluna ficam embaixo.
Item {
    id: root

    // Pares: [{ name, groups }] (shortcuts.js: pairs, sides); colunas 1-2: [{ name, groups }]
    // (`left`/`right` sao linhas de ancora do Item, dai os nomes)
    required property var pairs
    required property var leftCats
    required property var rightCats
    required property bool showAll
    required property int capHeight
    required property int leftWidth
    required property int rightWidth
    required property int gap

    readonly property var leftHost: root.leftCats.length > 0 ? root.leftCats[0] : null
    readonly property var rightHost: root.rightCats.length > 0 ? root.rightCats[0] : null
    readonly property bool pairsMain: root.pairs.some(p => p.groups.some(g => g.main))
    readonly property int pad: Tokens.padding.large
    readonly property int rightX: root.leftWidth + root.gap

    implicitWidth: root.rightWidth > 0 ? root.rightX + root.rightWidth : root.leftWidth
    implicitHeight: Math.max(leftMore.height > 0 ? leftMore.y + leftMore.height : leftBg.height, rightMore.height > 0 ? rightMore.y + rightMore.height : rightBg.height)
    width: root.implicitWidth
    height: root.implicitHeight

    // Fundos dos dois cartoes hospedeiros, cada um com a propria altura:
    // ate o fim do proprio resto (ou do ultimo par, se nao ha resto)
    StyledRect {
        id: leftBg

        width: root.leftWidth
        height: body.y + rest.y + (leftRest.height > 0 ? leftRest.height : -body.spacing) + root.pad
        visible: root.leftHost !== null && (root.showAll || root.pairsMain || root.leftHost.groups.some(g => g.main))
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
    }

    StyledRect {
        id: rightBg

        x: root.rightX
        width: root.rightWidth
        height: body.y + rest.y + (rightRest.height > 0 ? rightRest.height : -body.spacing) + root.pad
        visible: root.rightHost !== null && (root.showAll || root.pairsMain || root.rightHost.groups.some(g => g.main))
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
    }

    Column {
        id: body

        y: root.pad
        width: root.width
        spacing: Tokens.spacing.largeIncreased

        // Titulos dos dois cartoes, lado a lado
        Item {
            width: parent.width
            height: Math.max(leftTitle.visible ? leftTitle.height : 0, rightTitle.visible ? rightTitle.height : 0)

            StyledText {
                id: leftTitle

                x: root.pad
                visible: leftBg.visible
                text: root.leftHost ? root.leftHost.name : ""
                font: Tokens.font.title.small
                color: Colours.palette.m3primary
            }

            StyledText {
                id: rightTitle

                x: root.rightX + root.pad
                visible: rightBg.visible
                text: root.rightHost ? root.rightHost.name : ""
                font: Tokens.font.title.small
                color: Colours.palette.m3primary
            }
        }

        // Um par por linha: os dois lados comecam na mesma altura, o pontilhado
        // cerca o mais alto deles e atravessa o vao
        Repeater {
            model: root.pairs

            Item {
                id: pairRow

                required property var modelData

                readonly property var sides: Shortcuts.sides(pairRow.modelData)
                // folga do pontilhado em volta dos grupos
                readonly property int inset: Tokens.padding.small

                width: parent.width
                height: Math.max(leftSide.height, rightSide.height) + pairRow.inset * 2
                visible: leftSide.height > 0 || rightSide.height > 0

                BorderImage {
                    anchors.fill: parent
                    anchors.leftMargin: pairRow.inset
                    anchors.rightMargin: pairRow.inset
                    source: Qt.resolvedUrl("../../../../assets/dotted-outline.png")
                    border.left: 4
                    border.top: 4
                    border.right: 4
                    border.bottom: 4
                    horizontalTileMode: BorderImage.Repeat
                    verticalTileMode: BorderImage.Repeat
                    opacity: Colours.light ? 0.7 : 0.9
                }

                Column {
                    id: leftSide

                    x: root.pad
                    y: pairRow.inset
                    width: root.leftWidth - root.pad * 2
                    spacing: Tokens.spacing.largeIncreased

                    Repeater {
                        model: pairRow.sides[0]

                        ShortcutGroup {
                            required property int index
                            required property var modelData

                            width: parent.width
                            group: modelData
                            showAll: root.showAll
                            capHeight: root.capHeight
                            divider: index > 0
                        }
                    }
                }

                Column {
                    id: rightSide

                    x: root.rightX + root.pad
                    y: pairRow.inset
                    width: root.rightWidth - root.pad * 2
                    spacing: Tokens.spacing.largeIncreased

                    Repeater {
                        model: pairRow.sides[1]

                        ShortcutGroup {
                            required property int index
                            required property var modelData

                            width: parent.width
                            group: modelData
                            showAll: root.showAll
                            capHeight: root.capHeight
                            divider: index > 0
                        }
                    }
                }
            }
        }

        // O resto de cada cartao hospedeiro, cada lado com a sua altura. Fica
        // sempre visivel (mesmo vazio) para o `rest.y` dos fundos valer.
        Item {
            id: rest

            width: parent.width
            height: Math.max(leftRest.height, rightRest.height)

            Column {
                id: leftRest

                x: root.pad
                width: root.leftWidth - root.pad * 2
                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: root.leftHost ? root.leftHost.groups : []

                    ShortcutGroup {
                        required property int index
                        required property var modelData

                        width: parent.width
                        group: modelData
                        showAll: root.showAll
                        capHeight: root.capHeight
                        divider: index > 0
                    }
                }
            }

            Column {
                id: rightRest

                x: root.rightX + root.pad
                width: root.rightWidth - root.pad * 2
                spacing: Tokens.spacing.largeIncreased

                Repeater {
                    model: root.rightHost ? root.rightHost.groups : []

                    ShortcutGroup {
                        required property int index
                        required property var modelData

                        width: parent.width
                        group: modelData
                        showAll: root.showAll
                        capHeight: root.capHeight
                        divider: index > 0
                    }
                }
            }
        }
    }

    // Demais cartoes de cada coluna, embaixo do hospedeiro
    ShortcutColumn {
        id: leftMore

        y: leftBg.visible ? leftBg.height + Tokens.spacing.medium : 0
        width: root.leftWidth
        categories: root.leftCats.slice(1)
        showAll: root.showAll
        capHeight: root.capHeight
    }

    ShortcutColumn {
        id: rightMore

        x: root.rightX
        y: rightBg.visible ? rightBg.height + Tokens.spacing.medium : 0
        width: root.rightWidth
        categories: root.rightCats.slice(1)
        showAll: root.showAll
        capHeight: root.capHeight
    }
}
