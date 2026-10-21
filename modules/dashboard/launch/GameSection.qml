pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Um tipo: cabecalho (glifo + nome em caixa alta) e os jogos em 2 colunas,
// cada um com a propria silhueta
ColumnLayout {
    id: section

    property string name
    property string glyph
    property var model: []

    signal launched(game: var)

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall

    RowLayout {
        Layout.leftMargin: Tokens.padding.medium
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: section.glyph
            color: Colours.palette.m3outline
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            text: section.name.toUpperCase()
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Tokens.spacing.extraSmall
        rowSpacing: 0

        Repeater {
            model: section.model

            LaunchRow {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                compact: true
                glyph: modelData.glyph || "stadia_controller"
                art: modelData.art ?? ""
                favourite: modelData.favourite === true
                label: modelData.name ?? ""
                onActivated: section.launched(modelData)
            }
        }
    }
}
