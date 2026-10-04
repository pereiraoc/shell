pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.nexus
import qs.modules.nexus.common

// Resultados da busca no lugar do menu: cada linha leva a pagina (e
// subpagina) dona da configuracao. Vazio diz o que nao casou.
VerticalFadeFlickable {
    id: root

    required property NexusState nState
    required property string query

    readonly property var results: SettingsIndex.search(root.query)

    signal picked

    function openFirst(): void {
        if (root.results.length > 0)
            root.open(root.results[0]);
    }

    function open(result: var): void {
        root.nState.openPage(result.page, result.sub);
        root.picked();
    }

    topMargin: Tokens.padding.large
    bottomMargin: Tokens.padding.large
    contentHeight: content.implicitHeight

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: root.results

            RowButton {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.results.length - 1
                icon: modelData.icon
                text: modelData.title
                subtext: `${modelData.pageLabel} · ${modelData.subtitle}`
                trailingIcon: "chevron_right"
                onClicked: root.open(modelData)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.extraLarge
            visible: root.results.length === 0
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "search_off"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: qsTr("No settings match “%1”").arg(root.query)
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }
    }
}
