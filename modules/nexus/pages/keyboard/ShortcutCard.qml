pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Cartao de uma categoria: titulo + grupos (ShortcutGroup), com uma linha bem
// leve entre eles. Um grupo so com o mesmo nome (Float, Capture): o cabecalho
// do grupo some e o icone dele vem para o titulo. Em Essentials so aparece se
// algum grupo e @main. Com `rowFill`, cada grupo visivel estica ate a altura
// dada (shortcuts.js: alignRows), para as divisorias baterem com as dos
// cartoes vizinhos.
StyledRect {
    id: root

    // { name, col, groups: [...] } (shortcuts.js)
    required property var category
    required property bool showAll
    required property int capHeight
    // Alturas alvo dos grupos visiveis, em ordem ([] = natural)
    property var rowFill: []

    readonly property bool hasMain: root.category.groups.some(g => g.main)
    readonly property bool single: root.category.groups.length === 1 && root.category.groups[0].title === root.category.name
    // Indice de cada grupo entre os visiveis (-1 = escondido nesta vista)
    readonly property var rows: {
        let n = 0;
        return root.category.groups.map(g => root.showAll || g.main ? n++ : -1);
    }
    // Linha leve acima do grupo: entre grupos visiveis, menos quando o grupo
    // divide a @row com o anterior (Lock, Log out, Suspend, Power menu)
    readonly property var dividers: {
        let prevRow = -1;
        return root.category.groups.map(g => {
            if (!(root.showAll || g.main))
                return false;
            const show = prevRow >= 0 && !(g.row > 0 && g.row === prevRow);
            prevRow = g.row;
            return show;
        });
    }
    // Grupos visiveis com linha e altura natural, para o alignRows da pagina.
    // Le implicitHeight (nao height): a altura esticada nao entra, sem laco.
    readonly property var rowSpec: {
        const out = [];
        for (let i = 0; i < groups.count; i++) {
            const g = groups.itemAt(i);
            if (g && g.visible)
                out.push({ row: g.group.row, height: g.implicitHeight });
        }
        return out;
    }

    visible: root.showAll || root.hasMain
    implicitHeight: col.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Column {
        id: col

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.largeIncreased

        Row {
            width: parent.width
            spacing: Tokens.spacing.small

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.single
                text: root.category.groups[0]?.icon || "keyboard"
                color: Colours.palette.m3primary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.category.name
                font: Tokens.font.title.small
                color: Colours.palette.m3primary
            }
        }

        Repeater {
            id: groups

            model: root.category.groups

            ShortcutGroup {
                id: grp

                required property int index
                required property var modelData

                width: parent.width
                height: Math.max(grp.implicitHeight, root.rowFill[root.rows[grp.index]] || 0)
                group: modelData
                showAll: root.showAll
                capHeight: root.capHeight
                showHeader: !root.single
                divider: root.dividers[grp.index]
            }
        }
    }
}
