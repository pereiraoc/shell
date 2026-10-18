pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config

// Uma coluna da pagina: cartoes (ShortcutCard) empilhados, cada um encostado no
// de cima (sem buracos). Com `fill`, o ultimo cartao visivel estica ate a
// coluna ter essa altura -- as tres colunas terminam na mesma linha.
Column {
    id: root

    // [{ name, col, groups }] (shortcuts.js: distribute)
    required property var categories
    required property bool showAll
    required property int capHeight
    // Altura alvo da coluna (0 = natural)
    property int fill

    // Altura natural (cartoes visiveis + espacos) e indice do ultimo visivel,
    // lidos das alturas implicitas: a altura esticada nao entra, sem laco.
    readonly property var layout: {
        let natural = 0, last = -1, n = 0;
        for (let i = 0; i < repeater.count; i++) {
            const card = repeater.itemAt(i);
            if (!card || !card.visible)
                continue;
            natural += card.implicitHeight;
            last = i;
            n++;
        }
        return { natural: natural + Math.max(0, n - 1) * root.spacing, last: last };
    }

    spacing: Tokens.spacing.medium

    Repeater {
        id: repeater

        model: root.categories

        ShortcutCard {
            id: card

            required property int index
            required property var modelData

            width: parent.width
            height: card.implicitHeight + (card.index === root.layout.last ? Math.max(0, root.fill - root.layout.natural) : 0)
            category: modelData
            showAll: root.showAll
            capHeight: root.capHeight
        }
    }
}
