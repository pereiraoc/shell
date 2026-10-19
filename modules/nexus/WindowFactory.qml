pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    // Janelas abertas, para o botao da barra alternar em vez de empilhar.
    property list<QtObject> windows: []

    function create(parent: Item, props: var): QtObject {
        const w = nexusComp.createObject(parent ?? dummy, props);
        root.windows = [...root.windows, w];
        return w;
    }

    // IPC: abre (ou reaproveita) o Nexus direto numa pagina/subpagina/aba.
    // Janela nova ja nasce na pagina pedida (sem incubar a Home para depois
    // trocar); `collapsed` recolhe o menu lateral (Super+/).
    function openAt(page: string, sub: int, mouse: string, collapsed: bool, tab: string): void {
        let w = root.windows[0];
        if (!w) {
            const idx = PageRegistry.indexOf(page);
            w = root.create(null, {
                initialPage: idx < 0 ? 0 : idx,
                initialNavCollapsed: !!collapsed
            });
        } else if (collapsed) {
            w.nState.navCollapsed = true;
        }
        if (mouse)
            w.nState.selectedMouse = mouse;
        w.nState.openPage(page, sub, tab ?? "");
    }

    // IPC `nexus scroll <px>`: rola a pagina aberta (nada sem janela)
    function scrollTo(px: int): void {
        const w = root.windows[0];
        if (w)
            w.nState.requestedScroll = Math.max(0, px);
    }

    // Botao da barra: fecha se ja houver Nexus aberto, senao abre.
    function toggle(): void {
        if (root.windows.length > 0) {
            for (const w of [...root.windows])
                w.destroy();
        } else {
            root.create();
        }
    }

    // Super+/: abre o Nexus nesta pagina/subpagina/aba; se a janela ja esta
    // exatamente nela, fecha (mesma tecla abre e fecha).
    function toggleAt(page: string, sub: int, collapsed: bool, tab: string): void {
        const w = root.windows[0];
        if (w) {
            const stack = w.nState.subPageIdxStack;
            const top = stack.length > 0 ? stack[stack.length - 1] : 0;
            const sameTab = !tab || w.nState.tabFor(page) === tab;
            if (w.nState.currentPageIdx === PageRegistry.indexOf(page) && top === sub && sameTab) {
                root.toggle();
                return;
            }
        }
        root.openAt(page, sub, "", collapsed, tab ?? "");
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            readonly property alias nState: nexus.nState
            // Estado inicial (WindowFactory.openAt): pagina e menu recolhido
            property int initialPage: 0
            property bool initialNavCollapsed: false

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Component.onDestruction: root.windows = root.windows.filter(x => x !== win)

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                nState.currentPageIdx: win.initialPage
                nState.navCollapsed: win.initialNavCollapsed
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
