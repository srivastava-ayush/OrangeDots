pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.utils

Singleton {
    id: root
    property var entries: []
    property string error: ""
    property string message: ""
    readonly property bool busy: worker.running
    readonly property bool refreshing: busy && request.action === "list"
    property var request: ({ action: "list" })
    property bool refreshPending: false
    property int consumers: 0

    function retain(): void {
        consumers++;
        eviction.stop();
    }
    function release(): void {
        consumers = Math.max(0, consumers - 1);
        if (!consumers) {
            refreshPending = false;
            eviction.restart();
        }
    }

    function refresh(): void {
        if (busy) { refreshPending = true; return; }
        perform("list", "");
    }
    function perform(action: string, id: string): bool {
        if (busy) return false;
        request = { action: action, id: id ?? "" };
        error = "";
        if (action !== "list") {
            feedback.stop();
            message = "";
        }
        worker.exec(["python3", Paths.toLocalFile(Qt.resolvedUrl("../utils/scripts/sidebar-clipboard.py"))]);
        return true;
    }

    Timer {
        id: feedback
        interval: 2000
        onTriggered: root.message = ""
    }

    Timer {
        id: eviction
        interval: 3000
        onTriggered: {
            if (!root.consumers && !root.busy) {
                // This is only the decoded display cache. cliphist, pins and
                // their files remain untouched and are reloaded on next open.
                root.entries = [];
                root.message = "";
            }
        }
    }

    Process {
        id: worker
        stdinEnabled: true
        onStarted: write(JSON.stringify(root.request) + "\n")
        // The helper emits one JSON line. Do not retain another full copy of
        // history in a StdioCollector after parsing it into entries.
        stdout: SplitParser {
            onRead: line => {
                try {
                    const response = JSON.parse(line);
                    root.error = response.error ?? "";
                    if (root.error && root.request.action === "paste")
                        Toaster.toast(qsTr("Clipboard"), root.error, "content_paste");
                    if (response.entries) root.entries = response.entries;
                    if (response.message) {
                        root.message = response.message;
                        feedback.restart();
                    }
                } catch (_) {
                    root.error = qsTr("Clipboard helper returned an invalid response.");
                }
            }
        }
        onExited: (code, status) => {
            if (code !== 0) root.error = qsTr("Could not load clipboard. Install cliphist, wl-clipboard and Python 3.");
            const refresh = root.refreshPending && root.consumers > 0;
            root.refreshPending = false;
            if (refresh) Qt.callLater(root.refresh);
            if (!root.consumers) eviction.restart();
        }
    }
}
