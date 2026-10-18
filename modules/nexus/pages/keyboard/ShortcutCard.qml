pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Cartao de uma categoria: titulo + grupos (ShortcutGroup), com uma linha bem
// leve entre eles. Um grupo so com o mesmo nome (Float, Capture): o cabecalho
// do grupo some e o icone dele vem para o titulo. Em Essentials so aparece se
// algum grupo e @main.
StyledRect {
    id: root

    // { name, col, groups: [...] } (shortcuts.js)
    required property var category
    required property bool showAll
    required property int capHeight

    readonly property bool hasMain: root.category.groups.some(g => g.main)
    readonly property bool single: root.category.groups.length === 1 && root.category.groups[0].title === root.category.name

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
            model: root.category.groups

            ShortcutGroup {
                required property int index
                required property var modelData

                width: parent.width
                group: modelData
                showAll: root.showAll
                capHeight: root.capHeight
                showHeader: !root.single
                divider: index > 0
            }
        }
    }
}
