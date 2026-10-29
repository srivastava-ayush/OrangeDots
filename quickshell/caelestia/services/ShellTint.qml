pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    property bool enabled: false
    property string colour: "#243447"
    property real strength: 0.65
    readonly property color colourValue: colour
    property bool loaded

    // Surface roles only: accents, warning colours, shadows and scrims still
    // come from the Material scheme. Keep the different surface elevations.
    readonly property var surfaceOffsets: ({
        m3background: 0,
        m3surface: 0,
        m3surfaceDim: -0.02,
        m3surfaceBright: 0.12,
        m3surfaceContainerLowest: -0.025,
        m3surfaceContainerLow: 0.035,
        m3surfaceContainer: 0.055,
        m3surfaceContainerHigh: 0.095,
        m3surfaceContainerHighest: 0.14,
        m3surfaceVariant: 0.18
    })

    function normaliseColour(value: string): string {
        const hex = value.trim().toLowerCase();
        if (/^#[0-9a-f]{6}$/.test(hex))
            return hex;
        if (/^#[0-9a-f]{3}$/.test(hex))
            return "#" + hex.slice(1).split("").map(c => c + c).join("");
        return "";
    }

    function setColour(value: string): bool {
        const hex = normaliseColour(value);
        if (!hex)
            return false;
        colour = hex;
        enabled = true;
        return true;
    }

    function setChannel(channel: string, value: real): void {
        if (!["r", "g", "b"].includes(channel) || !Number.isFinite(value))
            return;
        const channels = { r: colourValue.r, g: colourValue.g, b: colourValue.b };
        channels[channel] = Math.max(0, Math.min(1, value));
        setColour("#" + [channels.r, channels.g, channels.b].map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join(""));
    }

    function reset(): void {
        enabled = false;
        colour = "#243447";
        strength = 0.65;
    }

    function luminance(c: color): real {
        const linear = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
    }

    function contrast(a: color, b: color): real {
        const x = luminance(a);
        const y = luminance(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    function apply(role: string, original: color, surface: color): color {
        if (!enabled || strength <= 0)
            return original;

        if (Object.prototype.hasOwnProperty.call(surfaceOffsets, role)) {
            const lightTint = luminance(colourValue) > 0.3;
            let offset = surfaceOffsets[role] * (lightTint ? -1 : 1);
            if (role === "m3surfaceDim")
                offset = lightTint ? -0.10 : -0.02;
            else if (role === "m3surfaceBright")
                offset = lightTint ? 0.025 : 0.12;
            const component = (before, tint) => before * (1 - strength) + Math.max(0, Math.min(1, tint + offset)) * strength;
            return Qt.rgba(component(original.r, colourValue.r), component(original.g, colourValue.g), component(original.b, colourValue.b), original.a);
        }

        // A light custom tint must not leave light text unreadable. Preserve
        // the theme's foreground whenever it already has enough contrast.
        if (["m3onSurface", "m3onBackground", "m3onSurfaceVariant", "m3outline"].includes(role)) {
            const base = apply("m3surface", surface, surface);
            const raised = apply("m3surfaceContainerHighest", Qt.lighter(surface, 1.5), surface);
            const score = c => Math.min(contrast(c, base), contrast(c, raised));
            if (score(original) >= (role === "m3outline" ? 3 : 4.5))
                return original;
            const dark = Qt.rgba(0.04, 0.04, 0.04, original.a);
            const light = Qt.rgba(0.98, 0.98, 0.98, original.a);
            return score(dark) > score(light) ? dark : light;
        }
        return original;
    }

    onEnabledChanged: { if (loaded) saveTimer.restart(); }
    onColourChanged: {
        const normalised = normaliseColour(colour) || "#243447";
        if (colour !== normalised) {
            colour = normalised;
            return;
        }
        if (loaded)
            saveTimer.restart();
    }
    onStrengthChanged: {
        const clamped = Number.isFinite(strength) ? Math.max(0, Math.min(1, strength)) : 0.65;
        if (strength !== clamped) {
            strength = clamped;
            return;
        }
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: storage.setText(JSON.stringify({ enabled: root.enabled, colour: root.colour, strength: root.strength }))
    }

    FileView {
        id: storage

        path: `${Paths.state}/shell-tint.json`
        printErrors: false
        onLoaded: {
            try {
                const settings = JSON.parse(text());
                if (typeof settings.enabled === "boolean")
                    root.enabled = settings.enabled;
                if (typeof settings.colour === "string" && root.normaliseColour(settings.colour))
                    root.colour = root.normaliseColour(settings.colour);
                if (typeof settings.strength === "number" && Number.isFinite(settings.strength))
                    root.strength = Math.max(0, Math.min(1, settings.strength));
            } catch (error) {
                // Invalid or missing saved settings leave the wallpaper theme intact.
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
