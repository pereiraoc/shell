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
    property string searchText

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    // Abre uma pagina pelo id do PageRegistry (e, opcionalmente, uma subpagina
    // do StackPage dela). Ninguem de fora deve usar currentPageIdx com numero.
    function openPage(id: string, sub: int): void {
        const idx = PageRegistry.indexOf(id);
        if (idx < 0)
            return;
        currentPageIdx = idx;
        if (sub > 0)
            Qt.callLater(() => openSubPage(sub));
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
