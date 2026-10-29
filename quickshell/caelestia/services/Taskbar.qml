pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Keep this QML-only so changing the bar edge/style needs no native plugin rebuild.
    property string orientation: "left"
    readonly property bool horizontal: orientation === "top"
    property string style: "unified"
    readonly property bool centerOnly: style === "center"
    readonly property bool notched: style === "notches" || centerOnly
    // Minimum main-axis length in logical pixels; zero sizes to the clock.
    property int centerNotchSize: 0
    property bool loaded

    function cycleStyle(): void {
        const styles = ["unified", "notches", "center"];
        style = styles[(styles.indexOf(style) + 1) % styles.length];
    }

    onOrientationChanged: {
        if (orientation !== "left" && orientation !== "top") {
            orientation = "left";
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    onStyleChanged: {
        if (style !== "unified" && style !== "notches" && style !== "center") {
            style = "unified";
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    onCenterNotchSizeChanged: {
        const clamped = Math.max(0, Math.min(1200, centerNotchSize));
        if (centerNotchSize !== clamped) {
            centerNotchSize = clamped;
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: storage.setText(JSON.stringify({ orientation: root.orientation, style: root.style, centerNotchSize: root.centerNotchSize }))
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
                if (settings.style === "unified" || settings.style === "notches" || settings.style === "center")
                    root.style = settings.style;
                if (Number.isInteger(settings.centerNotchSize))
                    root.centerNotchSize = Math.max(0, Math.min(1200, settings.centerNotchSize));
            } catch (error) {
                // Missing or invalid settings retain the default unified, left-edge bar.
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
