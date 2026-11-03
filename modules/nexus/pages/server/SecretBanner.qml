pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// Segredo mostrado UMA vez (senha temporaria, codigo de confirmacao do 2FA):
// valor grande em fonte mono, Copy e fechar. Nao fica gravado em lugar nenhum:
// ao fechar (ou trocar de pagina) some.
ConnectedRect {
    id: root

    property string title
    property string value
    property string detail
    property bool copied

    signal dismissed

    Layout.fillWidth: true
    first: true
    last: true
    visible: root.value !== ""
    color: Colours.palette.m3primaryContainer
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    onValueChanged: root.copied = false

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignTop
            text: "key"
            color: Colours.palette.m3onPrimaryContainer
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            StyledText {
                Layout.fillWidth: true
                text: root.title
                color: Colours.palette.m3onPrimaryContainer
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: root.value
                color: Colours.palette.m3onPrimaryContainer
                font: Tokens.font.mono.medium
                wrapMode: Text.WrapAnywhere
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.detail
                color: Colours.palette.m3onPrimaryContainer
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        TextButton {
            Layout.alignment: Qt.AlignVCenter
            text: root.copied ? Tr.tr("Copied") : Tr.tr("Copy")
            type: TextButton.Filled
            onClicked: {
                Quickshell.clipboardText = root.value;
                root.copied = true;
            }
        }

        IconButton {
            Layout.alignment: Qt.AlignVCenter
            icon: "close"
            type: IconButton.Text
            onClicked: root.dismissed()
        }
    }
}
