pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.components.misc
import qs.services

Scope {
    id: root

    property bool blocked
    property ShellScreen targetScreen
    property string pendingAddress

    onBlockedChanged: {
        if (blocked) {
            pendingAddress = "";
            focusTimer.stop();
        }
    }

    function cycle(direction: int): void {
        pendingAddress = "";
        focusTimer.stop();
        if (!state.opened)
            targetScreen = ShellState.forActive()?.modelData ?? Quickshell.screens[0];
        state.cycle(direction);
    }

    function cancel(): void {
        pendingAddress = "";
        focusTimer.stop();
        state.cancel();
    }

    SwitcherState {
        id: state

        blocked: root.blocked
        activeAddress: Hypr.activeToplevel?.address ?? ""
        windows: Hypr.toplevels.values.filter(w => {
            const ipc = w.lastIpcObject;
            return ipc.mapped !== false && !ipc.hidden;
        }).map(w => ({
            address: w.address,
            title: w.title || w.lastIpcObject.class || qsTr("Untitled window"),
            appId: w.lastIpcObject.class || w.lastIpcObject.initialClass || "",
            workspace: w.workspace?.name ?? "",
            history: w.lastIpcObject.focusHistoryID >= 0 ? w.lastIpcObject.focusHistoryID : 99999
        }))

        onActivateRequested: address => {
            root.pendingAddress = address;
            if (!view.visible)
                focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer
        // Let Wayland process the unmap first. Focusing while the exclusive
        // layer still exists can be undone by Hyprland restoring its old focus.
        interval: 30
        onTriggered: {
            const address = root.pendingAddress;
            root.pendingAddress = "";
            if (root.blocked || state.opened || !Hypr.toplevels.values.some(w => w.address === address))
                return;
            const hex = address.replace(/^0x/, "");
            if (!/^[0-9a-fA-F]+$/.test(hex))
                return;
            Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${hex}" })` : `focuswindow address:0x${hex}`);
            Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.window.alter_zorder({ mode = "top" })' : "bringactivetotop");
        }
    }

    // Compositor shortcuts keep cycling independent of layer-surface key focus.
    CustomShortcut {
        name: "switcherNext"
        description: "Next window in the window switcher"
        onPressed: root.cycle(1)
    }

    CustomShortcut {
        name: "switcherPrevious"
        description: "Previous window in the window switcher"
        onPressed: root.cycle(-1)
    }

    CustomShortcut {
        name: "switcherAccept"
        description: "Select a window when Alt is released"
        // A release-triggered compositor bind can report either edge depending
        // on the global-shortcut implementation. accept() is intentionally idempotent.
        onPressed: state.accept()
        onReleased: state.accept()
    }

    IpcHandler {
        target: "switcher"
        function next(): void { root.cycle(1); }
        function previous(): void { root.cycle(-1); }
        function accept(): void { state.accept(); }
        function cancel(): void { root.cancel(); }
        function status(): string {
            return JSON.stringify({ opened: state.opened, selected: state.selected?.address ?? "", count: state.entries.length });
        }
    }

    SwitcherWindow {
        id: view
        state: state
        screen: root.targetScreen ?? Quickshell.screens[0]
        onVisibleChanged: {
            if (!visible && root.pendingAddress)
                focusTimer.restart();
        }
    }
}
