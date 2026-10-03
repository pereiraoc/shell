pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Uma secao de ponta solta: cabecalho com contagem, explicacao e a lista (ou
// o "tudo certo" quando vazia). labelOf/subOf traduzem cada item -- servem
// tanto para strings (caminhos) quanto para objetos do trace.
ColumnLayout {
    id: root

    property string title
    property string help
    property var values: []
    property string icon: "link_off"
    property string okText
    property var labelOf: v => `${v}`
    property var subOf: v => ""
    property var openOf: v => ""
    signal open(string rel)

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    SectionHeader {
        text: `${root.title}  ·  ${root.values.length}`
    }

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.extraSmall
        text: root.help
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    ItemList {
        id: list

        showList: true
        placeholderIcon: "check_circle"
        placeholderText: root.okText
        list.spacing: Tokens.spacing.extraSmall / 2

        model: ScriptModel {
            values: [...root.values]
        }

        delegate: RowButton {
            id: row

            required property var modelData
            required property int index

            anchors.left: list.list.contentItem.left
            anchors.right: list.list.contentItem.right
            first: row.index === 0
            last: row.index === root.values.length - 1
            icon: root.icon
            iconLabel.color: Colours.palette.m3error
            text: root.labelOf(row.modelData)
            subtext: root.subOf(row.modelData)
            trailingIcon: root.openOf(row.modelData) ? "open_in_new" : ""
            onClicked: {
                const rel = root.openOf(row.modelData);
                if (rel)
                    root.open(rel);
            }
        }
    }
}
