pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// "Keep these display settings?" com contagem regressiva (padrao Windows /
// GNOME para o que pode deixar a tela inutilizavel). O PRAZO NAO E DAQUI: quem
// reverte sem resposta e a ferramenta (caelestia-display agenda um processo
// destacado), porque mudar a escala pode recriar o painel no meio da
// contagem. O banner so mostra quanto falta ate `deadline` (epoch, s).
ConnectedRect {
    id: root

    property string text: qsTr("Keep these display settings?")
    property real deadline
    property real now: Date.now() / 1000
    readonly property int remaining: Math.max(0, Math.ceil(root.deadline - root.now))
    readonly property bool running: root.deadline > 0 && root.remaining > 0

    signal keep
    signal revert

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    color: Colours.palette.m3secondaryContainer

    Timer {
        interval: 500
        repeat: true
        running: root.visible && root.deadline > 0
        triggeredOnStart: true
        onTriggered: root.now = Date.now() / 1000
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "timer"
            color: Colours.palette.m3onSecondaryContainer
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.text
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.running ? qsTr("Reverting in %1 s").arg(root.remaining) : qsTr("Reverting…")
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        TextButton {
            text: qsTr("Revert")
            type: TextButton.Text
            isRound: true
            onClicked: root.revert()
        }

        TextButton {
            text: qsTr("Keep")
            type: TextButton.Filled
            isRound: true
            onClicked: root.keep()
        }
    }
}
