pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Cartao da Home: um assunto, seu estado em uma palavra/numero e uma linha de
// detalhe. A cor do icone diz o nivel (ok/warn/error). Clique abre a pagina.
StyledRect {
    id: root

    property string icon
    property string title
    property string value
    property string detail
    property string level: "ok"

    readonly property color levelColour: root.level === "error" ? Colours.palette.m3error : root.level === "warn" ? Colours.palette.m3tertiary : Colours.palette.m3primary
    readonly property color levelContainer: root.level === "error" ? Colours.palette.m3errorContainer : root.level === "warn" ? Colours.palette.m3tertiaryContainer : Colours.palette.m3primaryContainer
    readonly property color onLevelContainer: root.level === "error" ? Colours.palette.m3onErrorContainer : root.level === "warn" ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onPrimaryContainer

    signal clicked

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    StateLayer {
        radius: root.radius
        onClicked: root.clicked()
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.alignment: Qt.AlignTop
            implicitWidth: iconLabel.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: implicitWidth
            radius: Tokens.rounding.full
            color: root.levelContainer

            MaterialIcon {
                id: iconLabel

                anchors.centerIn: parent
                text: root.icon
                color: root.onLevelContainer
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.value
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.detail
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
