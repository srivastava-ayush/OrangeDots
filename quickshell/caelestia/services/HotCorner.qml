pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool enabled: true
    property int width: 16
    property int interval: 0
    property bool loaded

    onEnabledChanged: { if (loaded) saveTimer.restart(); }
    onWidthChanged: { if (loaded) saveTimer.restart(); }
    onIntervalChanged: { if (loaded) saveTimer.restart(); }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: storage.setText(JSON.stringify({
                    enabled: root.enabled,
                    width: root.width,
                    interval: root.interval
                }))
    }

    FileView {
        id: storage

        path: `${Paths.state}/hot-corner.json`
        printErrors: false
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                if (typeof settings.enabled === "boolean")
                    root.enabled = settings.enabled;
                if (Number.isInteger(settings.width))
                    root.width = Math.max(8, Math.min(128, settings.width));
                if (Number.isInteger(settings.interval))
                    root.interval = Math.max(0, Math.min(2000, settings.interval));
            } catch (error) {
                // Keep the defaults if the saved settings are invalid.
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
