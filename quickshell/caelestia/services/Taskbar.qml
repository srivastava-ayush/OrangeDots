pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Keep this QML-only so changing the bar edge needs no native plugin rebuild.
    property string orientation: "left"
    readonly property bool horizontal: orientation === "top"
    property bool loaded

    onOrientationChanged: {
        if (orientation !== "left" && orientation !== "top") {
            orientation = "left";
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: storage.setText(JSON.stringify({ orientation: root.orientation }))
    }

    FileView {
        id: storage

        path: `${Paths.state}/taskbar.json`
        printErrors: false
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                if (settings.orientation === "left" || settings.orientation === "top")
                    root.orientation = settings.orientation;
            } catch (error) {
                // Missing or invalid settings leave the bar on its default left edge.
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
