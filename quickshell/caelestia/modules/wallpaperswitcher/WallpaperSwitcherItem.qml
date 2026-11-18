pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

// One card in the wallpaper strip: a 16:9 thumbnail, the current selection ring
// and the wallpaper's relative name.
Item {
    id: root

    objectName: "wallpaperSwitcherTile"

    required property var modelData
    required property int index
    required property bool current
    required property bool applied
    required property real fullTileWidth
    // Width of a card that is not highlighted, and the even gap the strip
    // keeps between every pair of cards.
    required property real compactTileWidth
    required property real slotStep
    required property real tileGap
    // True while the strip is open. Delegates are created long before the
    // switcher is shown, so this drives the staggered reveal.
    required property bool presented

    signal clicked

    Accessible.role: Accessible.ListItem
    Accessible.name: root.modelData.relativePath

    // 0 = compact, 1 = full-sized. Selecting a card animates between the
    // compact and full-sized parallelogram forms.
    property real morph: current ? 1 : 0

    // 0 = hidden/staggered out, 1 = fully presented. Same cadence as the
    // session menu buttons, but the wave radiates from the highlighted card.
    property real entrance: 0
    property bool ready: false

    // Each tile drops in from slightly above its resting position. The wave
    // starts with the highlight and fans outwards on every open.
    readonly property real staggerOffset: Tokens.spacing.extraLarge + Tokens.spacing.medium

    readonly property int order: {
        const view = PathView.view;
        return Math.min(4, Math.abs(index - (view ? view.currentIndex : index)));
    }

    // Slot offset from the highlighted card, measured from where PathView has
    // actually placed each delegate. Reading the real offset keeps this correct
    // even when a short, filtered list wraps around the path. The nudge that
    // follows keeps the gap on both sides of every card identical: PathView
    // spaces delegates evenly, but an expanded highlight would otherwise eat
    // into the gaps next to it.
    readonly property int slotIndex: {
        const view = PathView.view;
        if (!view || !view.currentItem || view.currentItem === root || slotStep <= 0)
            return 0;
        return Math.round((root.x - view.currentItem.x) / slotStep);
    }
    readonly property real morphShift: {
        const distance = Math.abs(slotIndex);
        if (distance === 0)
            return 0;

        const direction = slotIndex < 0 ? -1 : 1;
        const wanted = (fullTileWidth + compactTileWidth) / 2 + tileGap + (distance - 1) * (compactTileWidth + tileGap);
        return direction * (wanted - distance * slotStep);
    }

    implicitWidth: fullTileWidth
    implicitHeight: tile.height + Tokens.spacing.extraSmall + label.height

    readonly property real fullHeight: fullTileWidth / 16 * 9

    opacity: (0.65 + 0.35 * morph) * entrance
    scale: 0.9 + entrance * 0.1

    transform: Translate {
        x: root.morphShift
        y: (1 - root.entrance) * -Tokens.spacing.extraLargeIncreased

        Behavior on x {
            Anim { type: Anim.FastSpatial }
        }
    }

    Behavior on morph {
        Anim {
            type: Anim.FastSpatial
        }
    }

    Component.onCompleted: {
        ready = true;
        entrance = presented ? 1 : 0;
    }

    onPresentedChanged: {
        if (!ready)
            return;

        if (presented) {
            exitAnimation.stop();
            playEntrance();
        } else {
            enterAnimation.stop();
            exitAnimation.restart();
        }
    }

    function playEntrance(): void {
        // Reset first so a tile that was mid-exit always restarts hidden, and
        // every open replays the wave rather than only the first one.
        entrance = 0;
        enterAnimation.restart();
    }

    SequentialAnimation {
        id: enterAnimation

        // Compact cascade: neighbouring tiles lag the highlight by ~38 ms so
        // the wave still reads clearly, but the whole strip has landed just
        // after the faster panel reveal finishes.
        PauseAnimation { duration: root.order * Tokens.anim.durations.expressiveFastEffects * 0.25 }
        Anim {
            target: root
            property: "entrance"
            from: 0
            to: 1
            type: Anim.FastSpatial
            duration: Tokens.anim.durations.expressiveFastSpatial * 0.62
            easing.type: Easing.OutBack
            easing.overshoot: 0.65
        }
    }

    Anim {
        id: exitAnimation

        target: root
        property: "entrance"
        to: 0
        type: Anim.FastEffects
        easing.type: Easing.InCubic
    }

    Item {
        id: tile

        objectName: "wallpaperSwitcherCard"

        readonly property real w: width
        readonly property real h: height
        readonly property real s: Math.min(h * 0.22, w * 0.28)
        readonly property real side: Math.sqrt(s * s + h * h)
        // Non-selected cards keep more pronounced rounding; selection eases it.
        readonly property real cr: Math.max(0, Math.min(h * (0.2 - 0.06 * root.morph), s * 0.9, (w - s) * 0.35, side * 0.22))
        readonly property real nx: side > 0 ? s / side : 0
        readonly property real ny: side > 0 ? h / side : 0

        // Rounded-parallelogram path points (clockwise from after the top-left corner).
        readonly property real ax: s + cr
        readonly property real ay: 0
        readonly property real bx: w - cr
        readonly property real by: 0
        readonly property real cx: w - nx * cr
        readonly property real cy: ny * cr
        readonly property real dx: w - s + nx * cr
        readonly property real dy: h - ny * cr
        readonly property real ex: w - s - cr
        readonly property real ey: h
        readonly property real fx: cr
        readonly property real fy: h
        readonly property real gx: nx * cr
        readonly property real gy: h - ny * cr
        readonly property real hx: s - nx * cr
        readonly property real hy: ny * cr

        // Non-selected cards stay compact; only the highlight expands to the
        // full card width. The strip compensates with a matching nudge so the
        // gaps between all cards remain equal. Every card keeps the same height
        // and its parallelogram shape, so the strip stays one aligned row.
        width: root.compactTileWidth + (root.fullTileWidth - root.compactTileWidth) * root.morph
        height: root.fullHeight
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // Offscreen rounded parallelogram used as the alpha mask for the thumbnail.
    Item {
        id: tileMask

        anchors.fill: tile
        visible: false
        layer.enabled: true

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: -1
                fillColor: "white"

                startX: tile.ax
                startY: tile.ay
                PathLine { x: tile.bx; y: tile.by }
                PathQuad { x: tile.cx; y: tile.cy; controlX: tile.w; controlY: 0 }
                PathLine { x: tile.dx; y: tile.dy }
                PathQuad { x: tile.ex; y: tile.ey; controlX: tile.w - tile.s; controlY: tile.h }
                PathLine { x: tile.fx; y: tile.fy }
                PathQuad { x: tile.gx; y: tile.gy; controlX: 0; controlY: tile.h }
                PathLine { x: tile.hx; y: tile.hy }
                PathQuad { x: tile.ax; y: tile.ay; controlX: tile.s; controlY: 0 }
            }
        }
    }

    Item {
        id: imageLayer

        anchors.fill: tile
        layer.enabled: true
        layer.effect: Mask {
            maskSource: tileMask
        }

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainerHigh
        }

        CachingImage {
            objectName: "wallpaperSwitcherImage"
            anchors.fill: parent
            path: root.modelData.path
            smooth: !root.PathView.view.moving
            // Keep the request size fixed while the card morphs. The launcher
            // picker does the same; a size that follows the animated width
            // creates a fresh cache entry (and a full image decode) on every
            // animation frame, which blanks the thumbnail and starves the
            // background wallpaper of image threads.
            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(Math.round(root.fullTileWidth * dpr), Math.round(root.fullHeight * dpr));
            }
        }
    }

    // Draw the selection ring above the thumbnail; Rectangle borders are
    // painted underneath child items, so the image would otherwise hide it.
    Shape {
        anchors.fill: tile
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeWidth: root.current ? 2 : 0
            strokeColor: Colours.palette.m3primary
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap

            startX: tile.ax
            startY: tile.ay
            PathLine { x: tile.bx; y: tile.by }
            PathQuad { x: tile.cx; y: tile.cy; controlX: tile.w; controlY: 0 }
            PathLine { x: tile.dx; y: tile.dy }
            PathQuad { x: tile.ex; y: tile.ey; controlX: tile.w - tile.s; controlY: tile.h }
            PathLine { x: tile.fx; y: tile.fy }
            PathQuad { x: tile.gx; y: tile.gy; controlX: 0; controlY: tile.h }
            PathLine { x: tile.hx; y: tile.hy }
            PathQuad { x: tile.ax; y: tile.ay; controlX: tile.s; controlY: 0 }
        }
    }

    // The applied wallpaper keeps a small badge even while another card is
    // highlighted, so previewing never hides what is currently active.
    Item {
        anchors.top: tile.top
        anchors.right: tile.right
        anchors.margins: Tokens.spacing.medium
        width: 20
        height: 20
        visible: root.applied
        z: 2

        StyledRect {
            anchors.fill: parent
            radius: width / 2
            color: Colours.palette.m3primary
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: "check"
            color: Colours.palette.m3onPrimary
            fontStyle: Tokens.font.icon.small
        }
    }

    StateLayer {
        anchors.fill: tile
        radius: Tokens.rounding.large
        onClicked: root.clicked()
    }

    // Only the highlighted card shows its name; the rest of the strip stays
    // clean, and the single title follows the selection as it morphs.
    StyledText {
        id: label

        objectName: "wallpaperSwitcherLabel"
        anchors.top: tile.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fullTileWidth
        text: root.modelData.relativePath
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideMiddle
        renderType: Text.QtRendering
        color: Colours.palette.m3onSurface
        font: Tokens.font.label.small
        opacity: root.morph
        visible: root.morph > 0.001
    }
}
