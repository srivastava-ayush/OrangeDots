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
    // switcher is shown, so this drives the drop-in reveal.
    required property bool presented
    // Sign of the last highlight movement. The centre tile uses it to pick the
    // side it slides in from on a toggle or a selection change.
    required property int slideDirection
    // Half the visible path length: the furthest tile from the highlight, and
    // therefore the longest stagger delay.
    required property int maxStaggerOrder

    signal clicked

    Accessible.role: Accessible.ListItem
    Accessible.name: root.modelData.relativePath

    // 0 = compact, 1 = full-sized. Selecting a card animates between the
    // compact and full-sized parallelogram forms.
    property real morph: current ? 1 : 0

    // 0 = hidden, 1 = fully presented. Every tile travels together so the
    // strip drops in as one piece each time the switcher opens.
    property real entrance: 0
    property bool ready: false

    // Every tile falls from above its resting position and settles back on its
    // original Y on each open.
    readonly property real dropOffset: Tokens.spacing.extraLarge + Tokens.spacing.large

    // The highlighted tile slides a little sideways into the centre, coming
    // from the side it travelled from, then settles on the exact path slot so
    // the strip gaps stay uniform at rest.
    readonly property real slideDistance: Tokens.spacing.extraLarge + Tokens.spacing.medium

    // Position relative to the highlight, wrapped so cards that wrap around
    // the end of the path still count as its nearest neighbours. This uses
    // discrete indices rather than delegate X: PathView keeps animating those
    // positions after a selection change, so reading them mid-scroll collapsed
    // the wave on every toggle after the first.
    readonly property int slotDelta: {
        const view = PathView.view;
        const count = view?.count ?? 0;
        if (!view || count <= 0 || index < 0 || view.currentIndex < 0)
            return 0;
        let delta = index - view.currentIndex;
        if (delta > count / 2)
            delta -= count;
        if (delta < -count / 2)
            delta += count;
        return delta;
    }
    readonly property int staggerOrder: Math.min(maxStaggerOrder, Math.abs(slotDelta))
    // Neighbours enter from their own edge of the strip; the centre tile
    // follows the last selection movement so the wave still reads as motion.
    readonly property int slideSide: slotDelta < 0 ? -1 : (slotDelta > 0 ? 1 : (slideDirection < 0 ? -1 : 1))
    readonly property real slideFrom: slideSide * slideDistance
    // Opening radiates outwards; closing reverses the wave so the highlight is
    // the last card to leave.
    readonly property int slideInDelay: staggerOrder * Tokens.anim.durations.expressiveFastEffects * 0.35
    readonly property int slideOutDelay: (maxStaggerOrder - staggerOrder) * Tokens.anim.durations.expressiveFastEffects * 0.13

    // Snapshot the cascade when the toggle starts. The highlight can change
    // again while the strip is revealing; without this the running pauses and
    // slide destinations would shift underneath the animations.
    property int activeInDelay: 0
    property int activeOutDelay: 0
    property real activeFrom: 0
    property real slideOffset: 0
    // True while the opening cascade owns slideOffset, so a highlight change
    // in the same frame does not cut the stagger short.
    property bool presenting: false

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

    transform: [
        Translate {
            x: root.morphShift
            y: -(1 - root.entrance) * root.dropOffset

            Behavior on x {
                Anim { type: Anim.FastSpatial }
            }
        },
        Translate {
            x: root.slideOffset
        }
    ]

    // A selection change still glides the incoming tile home on its own, but
    // only when an opening cascade is not already driving every tile.
    onCurrentChanged: {
        if (!current || !presented || presenting)
            return;
        playSelectionSlide();
    }

    function playSelectionSlide(): void {
        slideInAnimation.stop();
        slideOffset = (slideDirection < 0 ? -1 : 1) * slideDistance;
        slideAnimation.restart();
    }

    NumberAnimation {
        id: slideAnimation

        target: root
        property: "slideOffset"
        to: 0
        // A deliberately long, soft settle: the tile keeps gliding towards the
        // centre well after the strip has scrolled it under the highlight.
        duration: Tokens.anim.durations.expressiveSlowSpatial
        easing.type: Easing.OutCubic
    }

    // Opening slides the entire strip in from its own sides, one neighbour
    // after another. Reusing slideOffset keeps the resting geometry untouched:
    // all travel happens inside the tile transform.
    SequentialAnimation {
        id: slideInAnimation

        PauseAnimation { duration: root.activeInDelay }
        NumberAnimation {
            target: root
            property: "slideOffset"
            to: 0
            duration: Tokens.anim.durations.expressiveFastSpatial * 0.68
            easing.type: Easing.OutCubic
        }

        onFinished: root.presenting = false
        onStopped: root.presenting = false
    }

    // Closing runs the same wave backwards while the panel shrinks away.
    SequentialAnimation {
        id: slideOutAnimation

        PauseAnimation { duration: root.activeOutDelay }
        NumberAnimation {
            target: root
            property: "slideOffset"
            to: root.activeFrom
            duration: Tokens.anim.durations.expressiveFastEffects * 0.6
            easing.type: Easing.InCubic
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
            slideOutAnimation.stop();
            playEntrance();
            playToggleSlideIn();
        } else {
            enterAnimation.stop();
            slideAnimation.stop();
            slideInAnimation.stop();
            // The highlight may have moved since the open; rebuild the exit
            // wave from where the strip actually is now.
            activeOutDelay = slideOutDelay;
            activeFrom = slideFrom;
            slideOutAnimation.restart();
        }
    }

    function playToggleSlideIn(): void {
        // Snapshot before starting so a selection change during the reveal
        // cannot rewrite the pauses or destinations of a running cascade.
        activeInDelay = slideInDelay;
        activeOutDelay = slideOutDelay;
        activeFrom = slideFrom;
        // A tile can still hold its exit frame (or a partial slide) when the
        // strip is reopened quickly, so reset before replaying the wave.
        slideAnimation.stop();
        slideOffset = activeFrom;
        slideInAnimation.restart();
        // restart() stops any in-flight run first, which emits stopped() and
        // clears this flag; claim it after the restart so a selection change
        // cannot interrupt the cascade we just started.
        presenting = true;
    }

    function playEntrance(): void {
        // Reset first so a tile that was mid-exit always restarts hidden, and
        // every open replays the wave rather than only the first one.
        activeInDelay = slideInDelay;
        entrance = 0;
        enterAnimation.restart();
    }

    // The fade/scale rides the same wave as the slide. A sideways travel of a
    // few dozen pixels is easy to miss behind the panel's opening clip; the
    // staggered reveal is what makes the cascade read on every toggle.
    SequentialAnimation {
        id: enterAnimation

        PauseAnimation { duration: root.activeInDelay }
        Anim {
            target: root
            property: "entrance"
            from: 0
            to: 1
            type: Anim.FastSpatial
            duration: Tokens.anim.durations.expressiveFastSpatial * 0.62
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: exitAnimation

        PauseAnimation { duration: root.activeOutDelay }
        Anim {
            target: root
            property: "entrance"
            to: 0
            type: Anim.FastEffects
            duration: Tokens.anim.durations.expressiveFastEffects * 0.7
            easing.type: Easing.InCubic
        }
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
