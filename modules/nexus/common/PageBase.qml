pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus

ColumnLayout {
    id: root

    required property string title
    // Uma linha sob o titulo: o que a pagina cobre (template unico de pagina).
    property string description
    required property NexusState nState
    property bool isSubPage
    // Com a barra lateral recolhida o conteudo pode usar o espaco que ela deixou:
    // o teto sobe 1,5x (800 -> 1200 px), senao a pagina ficava estreita com um vazio ao lado
    readonly property int cappedWidth: Math.min(root.nState.navCollapsed ? Math.round(Tokens.sizes.nexus.maxContentWidth * 1.5) : Tokens.sizes.nexus.maxContentWidth, width)
    readonly property alias flickable: flickable
    // Abas = filtro fixo sob o titulo: [{ id, label }]; a pagina poe cada secao
    // num TabPane ligado a `tab`. Vazio = pagina sem abas. A aba corrente vem do
    // deep link (nState.requestedTab), senao da ultima desta pagina na sessao,
    // senao a primeira.
    property var tabs: []
    property string tab
    readonly property string pageId: PageRegistry.pages[root.nState.currentPageIdx]?.id ?? ""

    default property Item contentChild

    function hasTab(id: string): bool {
        return root.tabs.some(t => t.id === id);
    }

    function applyRequestedTab(): void {
        const wanted = root.nState.requestedTab;
        if (wanted && root.hasTab(wanted)) {
            root.tab = wanted;
            root.nState.requestedTab = "";
        }
    }

    spacing: Tokens.spacing.extraLargeIncreased

    onTabChanged: {
        if (!root.isSubPage && root.tab)
            root.nState.rememberTab(root.pageId, root.tab);
    }

    // Abas dinamicas (um mouse por aba): o deep link pode chegar antes delas
    onTabsChanged: root.applyRequestedTab()

    Component.onCompleted: {
        if (root.tabs.length === 0 || root.isSubPage)
            return;
        const remembered = root.nState.tabFor(root.pageId);
        root.tab = root.hasTab(remembered) ? remembered : root.tabs[0].id;
        root.applyRequestedTab();
    }

    Connections {
        function onRequestedTabChanged(): void {
            if (root.tabs.length > 0 && !root.isSubPage)
                root.applyRequestedTab();
        }

        target: root.nState
    }

    MouseArea { // Prevent clicks from reaching flickable
        z: 1
        implicitWidth: header.implicitWidth
        implicitHeight: header.implicitHeight - Layout.bottomMargin
        Layout.bottomMargin: -flickable.topMargin // Extra height to block clicks on flickable top margin
        onClicked: focus = true

        RowLayout {
            id: header

            spacing: Tokens.spacing.largeIncreased

            Loader {
                visible: active
                active: root.isSubPage
                asynchronous: true
                sourceComponent: IconButton {
                    icon: "arrow_back"
                    font: Tokens.font.icon.medium
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: Colours.tPalette.m3surfaceContainerHigh
                    inactiveOnColour: Colours.palette.m3onSurfaceVariant
                    onClicked: root.nState.closeSubPage()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font: Tokens.font.title.large
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.description !== ""
                    text: root.description
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }
        }
    }

    // Barra de abas: chips iguais aos de Essentials/All; fica fora do flickable,
    // entao acompanha a rolagem
    RowLayout {
        visible: root.tabs.length > 0
        Layout.fillWidth: true
        Layout.topMargin: -Tokens.spacing.large
        spacing: Tokens.spacing.small

        Repeater {
            model: root.tabs

            TextButton {
                required property var modelData

                type: root.tab === modelData.id ? TextButton.Filled : TextButton.Tonal
                isRound: true
                text: modelData.label
                onClicked: root.tab = modelData.id
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

    VerticalFadeFlickable {
        id: flickable

        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.topMargin: -topMargin
        topMargin: Tokens.padding.large
        bottomMargin: Tokens.padding.extraLarge

        contentHeight: root.contentChild?.implicitHeight ?? 0
        contentItem.children: [root.contentChild]

        TapHandler {
            onTapped: flickable.focus = true
        }
    }
}
