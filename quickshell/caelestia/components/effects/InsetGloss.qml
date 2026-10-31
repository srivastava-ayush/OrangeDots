pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

// Continuous, subtle inset along the sides/bottom; the shell's top join is open.
Canvas {
    id: root
    property real radius: Tokens.rounding.extraLarge
    readonly property real cornerRadius: Math.min(radius, width / 2, height / 2)
    readonly property bool light: Colours.light

    opacity: 0.25
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onCornerRadiusChanged: requestPaint()
    onLightChanged: requestPaint()
    onVisibleChanged: if (visible) requestPaint()
    onAvailableChanged: if (available) requestPaint()

    function rim(ctx: var, inset: real): void {
        const r = Math.max(0, cornerRadius - inset);
        ctx.beginPath();
        ctx.moveTo(inset, 0);
        ctx.lineTo(inset, height - inset - r);
        ctx.arcTo(inset, height - inset, inset + r, height - inset, r);
        ctx.lineTo(width - inset - r, height - inset);
        ctx.arcTo(width - inset, height - inset, width - inset, height - inset - r, r);
        ctx.lineTo(width - inset, 0);
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        // Begin flush with the edge and diffuse inward without a hard border.
        for (let inset = 26; inset >= 0; inset--) {
            const shadowAlpha = (light ? 0.035 : 0.055) * Math.exp(-Math.pow((inset - 16) / 9, 2));
            const shade = ctx.createLinearGradient(0, 0, 0, height);
            shade.addColorStop(0, "transparent");
            shade.addColorStop(0.3, Qt.rgba(0, 0, 0, shadowAlpha * 0.6));
            shade.addColorStop(1, Qt.rgba(0, 0, 0, shadowAlpha));
            ctx.strokeStyle = shade;
            ctx.lineWidth = 2;
            rim(ctx, inset);
            ctx.stroke();

            const glowAlpha = (light ? 0.12 : 0.09) * Math.exp(-Math.pow(inset / 10, 2));
            const glow = ctx.createLinearGradient(0, 0, 0, height);
            glow.addColorStop(0, "transparent");
            glow.addColorStop(0.3, Qt.rgba(1, 1, 1, glowAlpha * 0.55));
            glow.addColorStop(1, Qt.rgba(1, 1, 1, glowAlpha));
            ctx.strokeStyle = glow;
            rim(ctx, inset);
            ctx.stroke();
        }
    }
}
