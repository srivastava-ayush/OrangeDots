pragma ComponentBehavior: Bound

import QtQuick
import QtTest as QtTest
import Quickshell
import Quickshell.Wayland
import qs.modules.switcher

// Real layout and native Qt keyboard events, but never grab the user's keyboard,
// connect to Hyprland, or focus a real window. integration.py isolates state.
ShellRoot {
    id: root
    settings.watchFiles: false
    property int step: 0
    property var activated: []

    function check(condition: bool, message: string): void {
        if (!condition)
            throw new Error(message);
    }

    function window(address: string, history: int): var {
        return { address, history, appId: "kitty", title: "Test " + address, workspace: "1" };
    }

    SwitcherState {
        id: state
        activeAddress: "a"
        onActivateRequested: address => root.activated = [...root.activated, address]
    }

    SwitcherWindow {
        id: view
        state: state
        contentItem.opacity: 0
        mask: Region {}
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Background

        QtTest.TestEvent { id: keys }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: {
            try {
                switch (root.step++) {
                case 0:
                    state.cycle(1);
                    root.check(!state.opened, "No windows must not open an empty switcher");
                    state.windows = [root.window("c", 2), root.window("a", 0), root.window("b", 1)];
                    state.cycle(1);
                    root.check(state.opened && state.selected.address === "b", "First Alt+Tab must select the previous window in MRU order");
                    break;
                case 1:
                    root.check(view.visible && view.width > 0 && view.height > 0, "The real switcher surface must load and lay out");
                    state.cycle(1);
                    root.check(state.selected.address === "c", "Forward cycling");
                    state.cycle(1);
                    root.check(state.selected.address === "a", "Wraparound");
                    state.cycle(-1);
                    root.check(state.selected.address === "c", "Backward cycling");
                    state.cancel();
                    root.check(root.activated.length === 0, "Cancel must never focus a window");
                    state.cycle(-1);
                    root.check(state.selected.address === "c", "First reverse invocation must select the last MRU entry");
                    state.accept();
                    state.accept();
                    root.check(root.activated.join() === "c", "Commit must focus exactly once even if both release paths fire");
                    state.cycle(1);
                    state.windows = [root.window("b", 7), root.window("d", 1), root.window("a", 3)];
                    root.check(state.entries.map(w => w.address).join() === "a,b", "Freeze order, prune closed windows, and defer new windows");
                    root.check(state.selected.address === "b", "Selection must survive a model reorder");
                    state.windows = [root.window("a", 0)];
                    root.check(state.selected.address === "a", "A closed selection must fall back to a live window");
                    state.windows = [];
                    root.check(!state.opened, "Closing all windows must dismiss the overlay");
                    state.windows = [root.window("a", 0)];
                    state.cycle(1);
                    root.check(state.selected.address === "a", "Single-window cycle must stay in bounds");
                    state.blocked = true;
                    root.check(!state.opened, "Locking must cancel the overlay");
                    state.cycle(1);
                    root.check(!state.opened, "Cannot open on the lockscreen");
                    state.blocked = false;
                    state.windows = [root.window("a", 0), root.window("b", 1), root.window("c", 2)];
                    state.cycle(1);
                    break;
                case 2:
                    view.contentItem.forceActiveFocus();
                    // The focus scope is the child with the key handlers.
                    view.contentItem.children[0].forceActiveFocus();
                    root.check(keys.keyClick(Qt.Key_Tab, Qt.NoModifier, 0), "Deliver Tab to the isolated overlay");
                    root.check(state.selected.address === "c", "Native Tab must advance the highlight");
                    keys.keyClick(Qt.Key_Backtab, Qt.ShiftModifier, 0);
                    root.check(state.selected.address === "b", "Native Shift+Tab must move backward");
                    keys.keyClick(Qt.Key_Escape, Qt.NoModifier, 0);
                    root.check(!state.opened && root.activated.length === 1, "Escape must cancel without activation");
                    state.cycle(1);
                    break;
                case 3:
                    view.contentItem.children[0].forceActiveFocus();
                    keys.keyRelease(Qt.Key_Alt, Qt.NoModifier, 0);
                    root.check(!state.opened && root.activated.join() === "c,b", "Native Alt release must commit the selected window");
                    state.windows = Array.from({ length: 30 }, (_, i) => root.window("window" + i, i));
                    state.cycle(1);
                    for (let i = 0; i < 26; i++) state.cycle(1);
                    break;
                case 4:
                    root.check(view.width <= view.screen.width && state.selectedIndex === 27, "Many-window selection must remain bounded and scrollable");
                    state.cancel();
                    break;
                case 5:
                    root.check(!view.visible, "Close animation must finish and unmap the surface");
                    console.log("TASKBAR TEST PASS");
                    Qt.quit();
                    break;
                }
            } catch (error) {
                console.error("SWITCHER TEST FAIL: " + error);
                Qt.exit(1);
            }
        }
    }
}
