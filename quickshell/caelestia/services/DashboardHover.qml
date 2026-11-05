pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Keep the dashboard's edge-trigger geometry QML-only so tuning it needs no
// native plugin rebuild. Stored separately from shell.json like Taskbar style.
Singleton {
    id: root

    // Trigger width in logical pixels; 0 means match the dashboard width + margin.
    property int width: 0
    // How far down from the screen edge the cursor opens the dashboard.
    property int height: 12
    property bool loaded

    onWidthChanged: {
        const clamped = Math.max(0, Math.min(4000, width));
        if (width !== clamped) {
            width = clamped;
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    onHeightChanged: {
        const clamped = Math.max(2, Math.min(200, height));
        if (height !== clamped) {
            height = clamped;
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: storage.setText(JSON.stringify({ width: root.width, height: root.height }))
    }

    FileView {
        id: storage

        path: `${Paths.state}/dashboard-hover.json`
        printErrors: false
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                if (Number.isInteger(settings.width))
                    root.width = Math.max(0, Math.min(4000, settings.width));
                if (Number.isInteger(settings.height))
                    root.height = Math.max(2, Math.min(200, settings.height));
            } catch (error) {
                // Missing or invalid settings keep the default edge trigger.
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
