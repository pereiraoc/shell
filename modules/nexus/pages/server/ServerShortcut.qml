pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common

// Aba-atalho do Server (Storage, Network, Home Devices): o conteudo mora na
// pagina do assunto (Storage > NAS, Network > Home, Network > Home Devices) e
// aqui fica so o que e e o botao que leva la, na aba certa. Opcional: uma
// linha de resumo do NAS (ex.: espaco livre) para nao ser uma aba vazia.
ColumnLayout {
    id: root

    required property var page
    // Destino: id do PageRegistry e aba dele
    required property string target
    required property string targetTab
    // "Storage › NAS": onde o conteudo esta agora
    required property string where
    property string icon: "arrow_forward"
    property string explanation
    property string summary
    property string summaryIcon: "info"

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        visible: text !== ""
        text: root.explanation
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        first: true
        visible: root.summary !== ""
        icon: root.summaryIcon
        label: root.summary
    }

    RowButton {
        first: root.summary === ""
        last: true
        icon: root.icon
        text: Tr.tr("Open %1").arg(root.where)
        subtext: Tr.tr("This tab is a shortcut; the content lives there now")
        trailingIcon: "arrow_forward"
        onClicked: root.page.nState.openPage(root.target, 0, root.targetTab)
    }
}
