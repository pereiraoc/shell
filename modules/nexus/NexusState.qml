import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen
    // Menu lateral so com icones (toggle no topo; Super+/ abre assim)
    property bool navCollapsed
    property string searchText
    // Abas das paginas (PageBase.tabs): a pedida por um deep link (busca, IPC,
    // Super+/) e a ultima de cada pagina nesta sessao (id da pagina -> aba)
    property string requestedTab
    // Rolagem pedida por IPC (`nexus scroll <px>`): a pagina visivel leva o
    // conteudo a essa altura e zera. -1 = nada pedido.
    property int requestedScroll: -1
    property var pageTabs: ({})

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved
    property string storagePath
    property string selectedRgbDevice
    property string selectedMouse
    property string selectedHeadphone

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    function tabFor(page: string): string {
        return pageTabs[page] ?? "";
    }

    function rememberTab(page: string, tab: string): void {
        if (!page || pageTabs[page] === tab)
            return;
        const next = Object.assign({}, pageTabs);
        next[page] = tab;
        pageTabs = next;
    }

    // Abre uma pagina pelo id do PageRegistry (e, opcionalmente, uma subpagina
    // do StackPage dela e/ou uma aba). Ninguem de fora deve usar currentPageIdx
    // com numero.
    function openPage(id: string, sub: int, tab: string): void {
        const idx = PageRegistry.indexOf(id);
        if (idx < 0)
            return;
        // A aba vai ANTES da troca: a pagina nova le requestedTab ao nascer; a
        // mesma pagina ja aberta reage a mudanca
        requestedTab = tab ?? "";
        if (idx === currentPageIdx) {
            // Mesma pagina: volta ao topo antes (busca por "Wi-Fi" de dentro de
            // All networks nao fazia nada) e nao empilha o que ja esta no topo
            while (subPageIdxStack.length > 0 && subPageIdxStack[subPageIdxStack.length - 1] !== sub)
                closeSubPage();
            if (sub > 0 && subPageIdxStack[subPageIdxStack.length - 1] !== sub)
                openSubPage(sub);
            return;
        }
        // Trocando de pagina: so empilha. O StackPage NOVO reaplica
        // subPageIdxStack ao nascer; emitir subPageOpened agora acertaria o
        // StackPage ANTIGO, ainda vivo durante o fade (ele nao tem o indice,
        // loga "invalid sub-page" e desempilha -- o atalho se perdia).
        currentPageIdx = idx;
        if (sub > 0)
            subPageIdxStack.push(sub);
    }

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
