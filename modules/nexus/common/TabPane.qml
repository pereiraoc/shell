import QtQuick
import QtQuick.Layouts
import Caelestia.Config

// Conteudo de uma aba de pagina (PageBase.tabs): a pagina poe cada secao num
// TabPane e liga `active` a aba corrente. So visibilidade -- nada e recriado ao
// trocar de aba, e o espacamento e o mesmo da coluna da pagina, entao as linhas
// (first/last dos ConnectedRect) ficam iguais a antes.
ColumnLayout {
    id: root

    required property bool active

    visible: root.active
    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2
}
