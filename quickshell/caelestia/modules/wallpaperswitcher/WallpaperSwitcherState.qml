import QtQuick

// Selection state for the standalone wallpaper strip. The wallpaper model is
// owned by the Wallpapers service, so this object never snapshots or mutates
// it; it only remembers the path under the cursor. That keeps the selection
// stable while the filesystem model behind the strip loads or refreshes.
QtObject {
    id: root

    property var entries: []
    property bool blocked
    property bool opened: false
    property string selectedPath
    // Live filter typed into the strip's search box. Space-separated terms must
    // all match the relative path, mirroring the launcher's wallpaper search.
    property string search: ""

    readonly property var filteredEntries: matchesFor(search)

    // Build the filtered list directly (instead of reading filteredEntries in
    // onSearchChanged) so a search change never sees the previous binding value.
    function matchesFor(term: string): var {
        const terms = term.trim().toLowerCase().split(/\s+/).filter(part => part.length > 0);
        if (terms.length === 0)
            return entries;
        return entries.filter(entry => {
            const name = (entry.relativePath ?? entry.path ?? "").toLowerCase();
            return terms.every(part => name.includes(part));
        });
    }
    readonly property int selectedIndex: {
        if (filteredEntries.length === 0)
            return 0;
        const index = filteredEntries.findIndex(entry => entry.path === selectedPath);
        return index >= 0 ? index : 0;
    }
    readonly property var selected: filteredEntries.length > 0 ? filteredEntries[selectedIndex] : null
    // Resolved path for the highlighted card. Falls back to the first entry if
    // the remembered path disappears while the switcher is open.
    readonly property string activePath: selected?.path ?? ""

    signal previewRequested(path: string)
    signal accepted(path: string)
    signal closed()

    onBlockedChanged: {
        if (blocked)
            close();
    }

    // Keep the highlight on a visible card while the search narrows the strip.
    onSearchChanged: {
        if (!opened)
            return;
        const list = matchesFor(search);
        if (list.length === 0) {
            selectedPath = "";
            return;
        }
        if (!list.some(entry => entry.path === selectedPath)) {
            selectedPath = list[0].path;
            previewRequested(selectedPath);
        }
    }

    function open(currentPath: string): void {
        if (blocked || opened)
            return;
        search = "";
        const list = matchesFor("");
        const index = list.findIndex(entry => entry.path === currentPath);
        // Land on the wallpaper that is actually applied. If it is not in the
        // current list (for example the bundled fallback), start at the first
        // card but do not preview it until the user moves the selection.
        selectedPath = index >= 0 ? currentPath : (list.length > 0 ? list[0].path : "");
        opened = true;
    }

    function close(): void {
        if (!opened)
            return;
        opened = false;
        search = "";
        closed();
    }

    function select(index: int): void {
        if (!opened || filteredEntries.length === 0)
            return;
        const wrapped = ((index % filteredEntries.length) + filteredEntries.length) % filteredEntries.length;
        if (filteredEntries[wrapped].path === activePath)
            return;
        selectedPath = filteredEntries[wrapped].path;
        previewRequested(selectedPath);
    }

    function cycle(direction: int): void {
        if (!opened || filteredEntries.length === 0)
            return;
        select(selectedIndex + (direction < 0 ? -1 : 1));
    }

    // Apply a card directly, without a preview round-trip. Used by clicks so a
    // short-lived preview process cannot race the real wallpaper change. The
    // highlight is left alone: moving it here would make the closing strip
    // scroll (and re-morph the clicked card) while the surface slides away.
    function commit(index: int): void {
        if (!opened || filteredEntries.length === 0)
            return;
        const wrapped = ((index % filteredEntries.length) + filteredEntries.length) % filteredEntries.length;
        const path = filteredEntries[wrapped].path;
        opened = false;
        search = "";
        if (path)
            accepted(path);
        else
            closed();
    }

    function accept(): void {
        if (!opened)
            return;
        const path = activePath;
        opened = false;
        search = "";
        if (path)
            accepted(path);
        else
            closed();
    }
}
