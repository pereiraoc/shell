import QtQuick
import QtQuick.Layouts
import Caelestia.Config

// Conteudo de uma aba de pagina (PageBase.tabs): a pagina poe cada secao num
// TabPane e liga `active` a aba corrente. So visibilidade -- nada e recriado ao
// trocar de aba, e o espacamento e o mesmo da coluna da pagina, entao as linhas
// (first/last dos ConnectedRect) ficam iguais a antes. `opened` fica true da
// primeira vez que a aba abre e nao volta: e o que um Loader pesado liga em
// `active` para nascer so na 1a abertura e depois ficar vivo (ligar o Loader
// no proprio `active` dele e escrever `opened` no onActiveChanged faz loop).
ColumnLayout {
    id: root

    required property bool active
    property bool opened

    visible: root.active
    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    onActiveChanged: if (active) opened = true
}
