import QtQuick

// Window identities are strings, never retained compositor QObject references.
QtObject {
    id: root

    property var windows: []
    property string activeAddress
    property bool blocked
    property bool opened: false
    property var entries: []
    property int selectedIndex: 0
    readonly property var selected: entries[selectedIndex] ?? null

    signal activateRequested(address: string)

    onBlockedChanged: {
        if (blocked)
            cancel();
    }
    onWindowsChanged: reconcile()

    function cycle(direction: int): void {
        if (blocked)
            return;
        if (!opened) {
            // Freeze MRU order until this invocation ends. Changing selection
            // does not focus windows or shuffle the list underneath the user.
            entries = windows.slice().sort((a, b) => {
                if (a.address === activeAddress) return -1;
                if (b.address === activeAddress) return 1;
                return (a.history ?? 99999) - (b.history ?? 99999);
            });
            if (entries.length === 0)
                return;
            selectedIndex = 0;
            opened = true;
        }
        selectedIndex = (selectedIndex + direction + entries.length) % entries.length;
    }

    function reconcile(): void {
        if (!opened)
            return;
        const address = selected?.address;
        const previousIndex = selectedIndex;
        // Refresh titles, prune closed windows, but don't insert/reorder windows
        // until the next invocation. Preserve selection by identity, not index.
        const live = new Map(windows.map(w => [w.address, w]));
        entries = entries.filter(w => live.has(w.address)).map(w => live.get(w.address));
        if (entries.length === 0) {
            cancel();
            return;
        }
        const index = entries.findIndex(w => w.address === address);
        selectedIndex = index >= 0 ? index : Math.min(previousIndex, entries.length - 1);
    }

    function accept(): void {
        if (!opened)
            return;
        const address = selected?.address;
        opened = false;
        if (!blocked && address && windows.some(w => w.address === address))
            activateRequested(address);
    }

    function cancel(): void {
        opened = false;
    }
}
