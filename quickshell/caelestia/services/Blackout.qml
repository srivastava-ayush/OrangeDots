pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root

    property bool enabled: false

    function setDisplay(on: bool): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "${on ? "enable" : "disable"}" })` : `dpms ${on ? "on" : "off"}`);
    }

    onEnabledChanged: {
        if (enabled)
            displayOffTimer.restart();
        else {
            displayOffTimer.stop();
            lidInhibitor.write("\n");
            setDisplay(true);
        }
    }

    Component.onDestruction: {
        if (enabled)
            setDisplay(true);
    }

    // A low-level lid-switch inhibitor is respected even when logind's
    // LidSwitchIgnoreInhibited=yes ignores ordinary sleep inhibitors.
    Process {
        id: lidInhibitor

        running: root.enabled
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=handle-lid-switch", "--mode=block", "--who=OrangeShell Blackout", "--why=Keep audio and network running with the lid closed", "--", "sh", "-c", "read -r line"]
        onExited: {
            if (root.enabled) {
                console.warn("Blackout: lid inhibitor exited; restoring the display");
                root.enabled = false;
            }
        }
    }

    Timer {
        id: displayOffTimer

        interval: 500
        onTriggered: {
            if (root.enabled && lidInhibitor.running)
                root.setDisplay(false);
            else
                root.enabled = false;
        }
    }

    IpcHandler {
        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function disable(): void {
            root.enabled = false;
        }

        target: "blackout"
    }
}
