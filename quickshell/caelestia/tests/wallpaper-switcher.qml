pragma ComponentBehavior: Bound

import QtQuick
import QtTest as QtTest
import Quickshell
import Quickshell.Wayland
import Caelestia
import qs.modules.wallpaperswitcher

// Real layout and native Qt key events, but no keyboard grab, no Hyprland
// connection, and no real wallpaper application.
ShellRoot {
    id: root
    settings.watchFiles: false
    property int step: 0
    property var previewed: []
    property var accepted: []
    property int closedCount: 0
    property int imageWait: 0

    function check(condition: bool, message: string): void {
        if (!condition)
            throw new Error(message);
    }

    // Real image files from integration.py so the delegates exercise the same
    // CachingImage pipeline as the launcher picker. Fall back to stable fake
    // paths when the fixture is loaded on its own.
    readonly property var wallpapers: [
        Quickshell.env("WALLPAPER_TEST_FIRST") || "/wallpapers/aurora.jpg",
        Quickshell.env("WALLPAPER_TEST_SECOND") || "/wallpapers/beach.jpg",
        Quickshell.env("WALLPAPER_TEST_THIRD") || "/wallpapers/city.jpg"
    ]

    function entry(index: int): var {
        return { path: wallpapers[index], relativePath: ["aurora.jpg", "beach.jpg", "city.jpg"][index] };
    }

    WallpaperSwitcherState {
        id: state
        entries: [root.entry(0), root.entry(1), root.entry(2)]
        onPreviewRequested: path => root.previewed = [...root.previewed, path]
        onAccepted: path => root.accepted = [...root.accepted, path]
        onClosed: root.closedCount++
    }

    WallpaperSwitcherWindow {
        id: view
        state: state
        screen: Quickshell.screens[0]
        contentItem.opacity: 0
        mask: Region {}
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Background

        QtTest.TestEvent { id: keys }
    }

    // Load the production scope (layout, IPC registration, service wiring).
    // Do not open it here: its real window takes exclusive keyboard focus.
    WallpaperSwitcher {
        id: scope
    }

    Timer {
        interval: 250
        repeat: true
        running: true

        onTriggered: {
            try {
                switch (root.step++) {
                case 0:
                    state.open(root.wallpapers[1]);
                    root.check(state.opened, "Opening must show the strip");
                    root.check(state.selectedIndex === 1 && state.activePath === root.wallpapers[1], "Opening must land on the applied wallpaper");
                    state.cycle(1);
                    root.check(state.selectedIndex === 2 && root.previewed.join() === root.wallpapers[2], "Forward browsing must preview");
                    state.cycle(-1);
                    state.cycle(-1);
                    root.check(state.selectedIndex === 0, "Backward browsing must wrap");
                    break;
                case 1:
                    root.check(view.visible && view.width > 0 && view.height > 0, "The real strip surface must load and lay out");
                    const strip = CUtils.findChild(view.contentItem, "wallpaperSwitcherStrip");
                    root.check(strip !== null, "The strip must exist in the real layout");
                    root.check(CUtils.findChild(view.contentItem, "wallpaperSwitcherSearch") !== null, "The header search box must exist");
                    // Reuse the launcher picker's image pipeline: every tile must
                    // request one fixed-size thumbnail. A size that follows the
                    // morph animation would re-decode on each frame and blank
                    // the tile while the strip closes.
                    const images = CUtils.findChildren(strip, "wallpaperSwitcherImage");
                    if (images.length < 3 || images.some(image => image.status !== Image.Ready)) {
                        root.check(root.imageWait++ < 40, "Switcher thumbnails must load from the shared image cache");
                        root.step--;
                        return;
                    }
                    const dpr = view.screen.devicePixelRatio;
                    const fixedWidth = Math.round(view.cardWidth * dpr);
                    const fixedHeight = Math.round(view.cardHeight * dpr);
                    root.check(images.every(image => image.sourceSize.width === fixedWidth && image.sourceSize.height === fixedHeight), "Switcher thumbnails must request one fixed, cacheable size");
                    // The reveal must be synchronised: every tile animates at
                    // the same time and finishes fully presented, never leaving
                    // cards stuck hidden behind a per-tile cascade.
                    const tiles = CUtils.findChildren(strip, "wallpaperSwitcherTile");
                    const center = tiles.find(tile => tile.modelData.path === root.wallpapers[0]);
                    root.check(tiles.length >= 3 && tiles.every(tile => Math.abs(tile.entrance - tiles[0].entrance) < 0.01), "Every wallpaper tile must animate in at the same time");
                    // The fade/scale layer stays synchronised, but the slide
                    // fans out from the highlight: neighbours come from their
                    // own side a little later, and exit reverses the wave.
                    const paced = tiles.slice().sort((a, b) => a.staggerOrder - b.staggerOrder);
                    root.check(paced[0].staggerOrder === 0 && paced.some(tile => tile.staggerOrder > 0), "The toggle slide must fan out from the highlighted tile");
                    root.check(paced.every((tile, i) => i === 0 || tile.slideInDelay >= paced[i - 1].slideInDelay), "Neighbouring tiles must slide in later than the highlight");
                    root.check(paced.every((tile, i) => i === 0 || tile.slideOutDelay <= paced[i - 1].slideOutDelay), "Closing must reverse the stagger");
                    root.check(paced.every(tile => tile.slotDelta === 0 || Math.sign(tile.slideFrom) === Math.sign(tile.slotDelta)), "Each neighbour must slide in from its own side of the strip");
                    if (!center || tiles.some(tile => tile.entrance < 1)) {
                        root.check(root.imageWait++ < 40, "Wallpaper tiles must finish their reveal");
                        root.step--;
                        return;
                    }
                    root.check(center.current, "The highlighted tile must be the selected one");
                    // Tiles glide home after the toggle/selection slide; wait
                    // for that settle before measuring the resting gaps.
                    if (tiles.some(tile => Math.abs(tile.slideOffset) > 0.01)) {
                        root.check(root.imageWait++ < 40, "The highlighted tile must finish sliding into the centre");
                        root.step--;
                        return;
                    }
                    // Only the highlighted card expands to the full tile width;
                    // every other card stays compact, and the strip nudges them
                    // so the gap on each side matches the gap between the rest.
                    const cards = CUtils.findChildren(strip, "wallpaperSwitcherCard");
                    root.check(cards.length > 0, "The strip must instantiate wallpaper cards");
                    const expanded = cards.filter(card => Math.abs(card.width - view.cardWidth) < 0.5);
                    const neighbours = cards.filter(card => card !== expanded[0]);
                    root.check(expanded.length === 1, "Only the highlighted wallpaper card may be expanded");
                    root.check(neighbours.every(card => Math.abs(card.width - view.compactWidth) < 0.5), "Non-highlighted cards must share the compact width");
                    root.check(view.compactWidth < view.cardWidth - 1, "Non-highlighted cards must stay narrower than the highlight");
                    const ordered = cards.map(card => ({ x: card.mapToItem(strip, 0, 0).x, w: card.width })).sort((a, b) => a.x - b.x);
                    const gaps = ordered.slice(1).map((card, i) => card.x - (ordered[i].x + ordered[i].w));
                    root.check(gaps.length > 0 && gaps.every(gap => Math.abs(gap - view.tileGap) < 1), "Every gap between wallpaper cards must be the same size: " + JSON.stringify(gaps) + " expected " + view.tileGap);
                    const labels = CUtils.findChildren(strip, "wallpaperSwitcherLabel");
                    root.check(labels.filter(label => label.visible).length === 1, "Only the highlighted wallpaper may show its title");
                    root.check(CUtils.findChild(center, "wallpaperSwitcherLabel").visible, "The highlighted tile must show its title");
                    // PathView assigns currentIndex while the mouse drags it;
                    // that must drive selection and preview back into the state.
                    strip.currentIndex = 2;
                    root.check(view.slideDirection === 1, "Moving forward must slide the highlight in from the right");
                    // PathView is still scrolling here. The stagger must still
                    // be anchored to the highlight, not to animated positions.
                    root.check(tiles.find(tile => tile.current)?.staggerOrder === 0 && tiles.filter(tile => tile.staggerOrder > 0).length === tiles.length - 1, "Browsing must not collapse the toggle stagger");
                    root.check(state.selectedIndex === 2, "Dragging must move the selection");
                    root.check(root.previewed[root.previewed.length - 1] === root.wallpapers[2], "Dragging must preview the card under the cursor");
                    state.select(99);
                    root.check(state.selectedIndex === 0, "Selecting an index must wrap into the list");
                    root.check(view.slideDirection === -1, "Wrapping backwards must slide the highlight in from the left");
                    // The search must filter in place and jump to the first match.
                    state.search = "be";
                    root.check(state.filteredEntries.length === 1, "Search must narrow the strip");
                    root.check(state.activePath === root.wallpapers[1], "Search must select the first match");
                    root.check(root.previewed[root.previewed.length - 1] === root.wallpapers[1], "Search must preview the first match");
                    state.search = "zzz";
                    root.check(state.filteredEntries.length === 0 && state.activePath === "", "Search without matches must empty the strip");
                    state.search = "";
                    root.check(state.filteredEntries.length === 3, "Clearing the search must restore every wallpaper");
                    root.check(state.activePath === root.wallpapers[0], "Clearing the search must restore a selection");
                    // Clicking a card applies that card and leaves the strip's
                    // highlight alone, so the surface never scrolls or re-morphs
                    // while it slides away.
                    strip.currentIndex = 1;
                    state.commit(0);
                    root.check(root.accepted.length === 1 && root.accepted[0] === root.wallpapers[0], "Clicking a card must apply that card");
                    root.check(!state.opened && state.selectedIndex === 1, "Clicking a card must keep the highlight still while the strip closes");
                    root.accepted = [];
                    state.open(root.wallpapers[1]);
                    root.check(state.opened, "The strip must reopen after applying a card");
                    state.close();
                    root.check(!state.opened, "Closing must dismiss the strip");
                    break;
                case 2:
                    state.open(root.wallpapers[0]);
                    view.contentItem.children[0].forceActiveFocus();
                    root.check(keys.keyClick(Qt.Key_Right, Qt.NoModifier, 0), "Deliver Right to the isolated overlay");
                    root.check(state.selectedIndex === 1, "Right must advance the highlight");
                    keys.keyClick(Qt.Key_Left, Qt.NoModifier, 0);
                    root.check(state.selectedIndex === 0, "Left must move the highlight back");
                    keys.keyClick(Qt.Key_Return, Qt.NoModifier, 0);
                    root.check(!state.opened && root.accepted.join() === root.wallpapers[0], "Enter must apply the highlighted wallpaper");
                    break;
                case 3:
                    state.open(root.wallpapers[2]);
                    view.contentItem.children[0].forceActiveFocus();
                    keys.keyClick(Qt.Key_Right, Qt.NoModifier, 0);
                    keys.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
                    root.check(!state.opened && root.accepted.length === 1, "Escape must close without applying");
                    state.blocked = true;
                    root.check(!state.opened, "Locking must keep the strip closed");
                    state.blocked = false;
                    state.open(root.wallpapers[2]);
                    state.blocked = true;
                    root.check(!state.opened && root.closedCount >= 2, "Locking while open must dismiss the strip");
                    state.blocked = false;
                    state.open(root.wallpapers[1]);
                    break;
                case 4:
                    root.check(state.opened, "The strip must reopen after unlocking");
                    root.check(root.closedCount === 3, "Each dismissal must report exactly one close");
                    state.close();
                    root.check(!state.opened, "Closing must finish immediately in state");
                    scope.blocked = true;
                    scope.toggle();
                    scope.open();
                    root.check(!scope.opened, "Locking must keep the production scope closed");
                    break;
                case 5:
                    root.check(root.closedCount === 4, "The final close must report exactly once");
                    break;
                case 6:
                    root.check(!view.visible, "The close animation must finish and unmap the surface");
                    console.log("TASKBAR TEST PASS");
                    Qt.quit();
                    break;
                }
            } catch (error) {
                console.error("WALLPAPER SWITCHER TEST FAIL: " + error);
                Qt.exit(1);
            }
        }
    }
}
