pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config

// Uma coluna da pagina: cartoes (ShortcutCard) empilhados, cada um encostado no
// de cima (sem buracos).
Column {
    id: root

    // [{ name, col, groups }] (shortcuts.js: distribute)
    required property var categories
    required property bool showAll
    required property int capHeight

    spacing: Tokens.spacing.medium

    Repeater {
        model: root.categories

        ShortcutCard {
            required property var modelData

            width: parent.width
            category: modelData
            showAll: root.showAll
            capHeight: root.capHeight
        }
    }
}
