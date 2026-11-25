pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.services

// Standalone wallpaper switcher. The launcher-based picker
// (`orangeos shell wallpapers pick`, SUPER+SHIFT+W) stays untouched; this
// scope only owns the dedicated centred strip opened by SUPER+TAB.
Scope {
    id: root

    property bool blocked
    property ShellScreen targetScreen

    readonly property alias opened: state.opened

    function open(): void {
        if (blocked || opened)
            return;

        // The switcher replaces the shell surfaces that would otherwise compete
        // for the same keys and space. Their normal close animations still run.
        const screenState = ShellState.forActive();
        if (screenState) {
            screenState.launcher = false;
            screenState.dashboard = false;
            screenState.session = false;
            screenState.emoji = false;
        }

        targetScreen = screenState?.modelData ?? Quickshell.screens[0];
        state.open(Wallpapers.actualCurrent);
    }

    function close(): void {
        state.close();
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

    WallpaperSwitcherState {
        id: state

        blocked: root.blocked
        entries: Wallpapers.list

        // Preview on the live background while browsing; only Enter/Space or a
        // click commits the file. Closing always drops the preview.
        onPreviewRequested: path => Wallpapers.preview(path)
        onAccepted: path => {
            // Mirror the launcher picker: hold the preview palette until the
            // CLI has written the new scheme, so applying never flashes the
            // previous colours while the wallpaper command is still running.
            if (Colours.scheme === "dynamic" && path !== Wallpapers.actualCurrent)
                Wallpapers.previewColourLock = true;
            Wallpapers.setWallpaper(path);
            Wallpapers.stopPreview();
        }
        onClosed: Wallpapers.stopPreview()
    }

    IpcHandler {
        target: "wallpaperswitcher"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function next(): void { state.cycle(1); }
        function previous(): void { state.cycle(-1); }
        function select(index: string): void {
            const parsed = Number(index);
            if (Number.isFinite(parsed))
                state.select(Math.trunc(parsed));
        }
        function isOpen(): bool { return root.opened; }
        function status(): string {
            return JSON.stringify({
                opened: state.opened,
                index: state.selectedIndex,
                count: state.entries.length,
                path: state.activePath
            });
        }
    }

    WallpaperSwitcherWindow {
        id: view

        state: state
        screen: root.targetScreen ?? Quickshell.screens[0]
    }
}
