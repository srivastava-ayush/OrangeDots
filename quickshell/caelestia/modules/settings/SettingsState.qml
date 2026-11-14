import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property string searchQuery

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
    signal navigationRequested(page: string, subPages: var)

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    // Deep-link requests come from search results, which can target any
    // top-level page and a chain of sub-pages below it.
    function requestNavigation(page: string, subPages: var): void {
        searchQuery = "";
        navigationRequested(page, subPages ?? []);
    }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
