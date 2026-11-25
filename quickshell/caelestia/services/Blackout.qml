pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services

Singleton {
    id: root

    property bool enabled: false
    // True once the DPMS-off request has actually been sent. The wake probe
    // only runs in that state, so it cannot race the 500ms hand-off below.
    property bool displayOff: false

    function setDisplay(on: bool): void {
        // Hyprland's dpms dispatcher only accepts on/off/toggle; "disable" and
        // "enable" are silently ignored and leave the panels in their old state.
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "${on ? "on" : "off"}" })` : `dpms ${on ? "on" : "off"}`);
    }

    onEnabledChanged: {
        if (enabled)
            displayOffTimer.restart();
        else {
            displayOffTimer.stop();
            displayOff = false;
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
            if (root.enabled && lidInhibitor.running) {
                root.setDisplay(false);
                root.displayOff = true;
            } else {
                root.enabled = false;
            }
        }
    }

    // Hyprland turns the panels back on for the first key press or mouse move
    // (misc.key_press_enables_dpms / mouse_move_enables_dpms), but it does not
    // report that DPMS change. A very short idle timeout gives us the same
    // event: once the session reports idle, the next input emits "resumed"
    // and we can clear the toggle immediately.
    IdleMonitor {
        id: activityMonitor

        enabled: root.displayOff
        timeout: 100
        respectInhibitors: false
        onIsIdleChanged: {
            if (root.displayOff && !isIdle)
                root.enabled = false;
        }
    }

    // Safety net for the idle protocol (or a display woken by something other
    // than user input): slow DPMS state checks instead of a tight poll.
    Timer {
        id: wakeTimer

        interval: 10000
        repeat: true
        running: root.displayOff
        onTriggered: wakeProbe.running = true
    }

    Process {
        id: wakeProbe

        command: ["hyprctl", "-j", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.displayOff)
                    return;
                try {
                    const monitors = JSON.parse(text);
                    if (Array.isArray(monitors) && monitors.some(m => m.dpmsStatus))
                        root.enabled = false;
                } catch (e) {}
            }
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
