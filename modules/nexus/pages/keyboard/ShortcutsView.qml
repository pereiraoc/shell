pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import "shortcuts.js" as Shortcuts

// Aba Shortcuts de Keyboard (Super+/): todos os atalhos de teclado, lidos ao
// vivo do Hyprland (`hyprctl binds -j`) e relidos a cada reload dele.
// Categoria = 1o campo do desc do binds.lua; "Grupo › variante" na acao agrupa
// variantes sob um titulo curto; @main marca os principais (Essentials, a vista
// que o Super+/ abre), @icon da o simbolo, @col a coluna e @row a linha do grupo
// (divisorias alinhadas entre cartoes). Trocar Essentials/All so muda
// visibilidade -- nada e recriado.
ColumnLayout {
    id: root

    // [{ name, col, groups: [{ title, icon, main, row, items: [{ variant, note, level, icon, main, combos: [{ label, prefix, alts, tap }] }] }] }]
    property var categories: []
    property bool failed
    // Essentials (so @main) a cada abertura; "All" e escolha do momento
    property bool showAll

    // Calculado por leitura, nao por vista: a vista so esconde linhas. Vazio
    // enquanto a aba nao tem largura: criar os cartoes antes de ela estar
    // anexada caia em incubacao assincrona aninhada e, ao chegar a largura,
    // tudo era recriado para 3 colunas. Uma expressao so: `columns` e `width`
    // mudando em separado reconstruiam os cartoes duas vezes.
    readonly property var columnsModel: root.width > 0 ? Shortcuts.distribute(root.categories, root.width >= 760 ? 3 : root.width >= 500 ? 2 : 1) : []
    // Altura de um keycap (KeyCap.qml): separadores "+", "/" e "tap" se alinham a ela
    readonly property int capHeight: capMetrics.height + Tokens.padding.extraSmall * 2 + 2

    function reload(): void {
        proc.running = true;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.medium

    Component.onCompleted: reload()

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

    // Colunas de largura igual; cada cartao encosta no de cima (sem buracos),
    // as divisorias dos 1os cartoes batem entre colunas (@row) e as colunas
    // terminam na mesma linha (a mais alta manda).
    Row {
        id: grid

        readonly property int cols: root.columnsModel.length
        readonly property int colWidth: grid.cols > 0 ? Math.floor((width - spacing * (grid.cols - 1)) / grid.cols) : 0
        // Alturas dos grupos dos 1os cartoes, por coluna, com as linhas alinhadas
        readonly property var rowFills: {
            const specs = [];
            for (let i = 0; i < columns.count; i++) {
                const c = columns.itemAt(i);
                specs.push(c ? c.rowSpec : []);
            }
            return Shortcuts.alignRows(specs, Tokens.spacing.largeIncreased);
        }
        // Altura natural da coluna mais alta, lida das colunas criadas
        readonly property int tallest: {
            let h = 0;
            for (let i = 0; i < columns.count; i++) {
                const c = columns.itemAt(i);
                if (c)
                    h = Math.max(h, c.layout.natural);
            }
            return h;
        }

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        Repeater {
            id: columns

            model: root.columnsModel

            ShortcutColumn {
                id: column

                required property int index
                required property var modelData

                width: grid.colWidth
                categories: modelData
                showAll: root.showAll
                capHeight: root.capHeight
                fill: grid.tallest
                rowFill: grid.rowFills[column.index] || []
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
