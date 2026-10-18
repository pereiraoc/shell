import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property NexusState nState

    // Largura do menu recolhido: o circulo do icone (36) + margens do item
    readonly property int collapsedWidth: 36 + Tokens.padding.large * 2

    spacing: Tokens.spacing.large

    // Recolhido: so a seta para reabrir, centrada
    IconButton {
        Layout.alignment: Qt.AlignHCenter
        visible: root.nState.navCollapsed
        type: IconButton.Text
        icon: "chevron_right"
        onClicked: root.nState.navCollapsed = false
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !root.nState.navCollapsed
        spacing: Tokens.spacing.small

        SearchBar {
            id: searchField

            Layout.fillWidth: true

            placeholderText: Tr.tr("Search settings")
            font: Tokens.font.body.large

            bg.color: Colours.tPalette.m3surfaceContainerLowest
            bg.border.color: Colours.palette.m3outlineVariant
            searchIcon.fontStyle: Tokens.font.icon.medium
            searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
            clearIcon.font: Tokens.font.icon.medium
            clearIcon.padding: Tokens.padding.extraSmall

            Behavior on bg.border.color {
                CAnim {}
            }

            Binding {
                target: root.nState
                property: "searchOpen"
                value: searchField.text.trim().length > 0
            }

            Binding {
                target: root.nState
                property: "searchText"
                value: searchField.text
            }

            // Enter abre o melhor resultado; Esc limpa a busca.
            onAccepted: results.openFirst()
            Keys.onEscapePressed: event => {
                if (searchField.text.length > 0) {
                    searchField.text = "";
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }

        // Recolhe o menu a so icones (Super+/ ja abre recolhido)
        IconButton {
            type: IconButton.Text
            icon: "chevron_left"
            onClicked: root.nState.navCollapsed = true
        }
    }

    NavLocations {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        visible: !root.nState.searchOpen
        nState: root.nState
    }

    SearchResults {
        id: results

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        visible: root.nState.searchOpen && !root.nState.navCollapsed
        nState: root.nState
        query: searchField.text
        onPicked: searchField.text = ""
    }
}
