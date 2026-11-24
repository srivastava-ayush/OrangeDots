pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Config
import qs.components
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

    // 0 = hidden, 1 = fully presented. Drives only opacity and scale; the
    // directional travel lives in the entry offsets below.
    property real entrance: 0
    property bool ready: false

    // Toggle entry distances, scaled to the card size so the travel reads from
    // well outside the panel. The highlight drops in from far above while the
    // neighbours sweep in from far beyond their own edge of the strip.
    readonly property real dropOffset: fullHeight * 3
    readonly property real slideDistance: fullTileWidth * 4

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
    // 0 = highlighted tile, negative = left neighbours, positive = right.
    readonly property bool centreTile: slotDelta === 0
    readonly property int slideSide: slotDelta < 0 ? -1 : (slotDelta > 0 ? 1 : (slideDirection < 0 ? -1 : 1))

    // The highlighted tile falls from above; the three tiles on each side
    // sweep in from their own edge of the strip.
    readonly property real entryFromX: centreTile ? 0 : slideSide * slideDistance
    readonly property real entryFromY: centreTile ? -dropOffset : 0
    // Every tile enters and leaves together — no staggered cascade.
    readonly property int slideInDelay: 0
    readonly property int slideOutDelay: 0

    // Snapshot the cascade when the toggle starts. The highlight can change
    // again while the strip is revealing; without this the running pauses and
    // slide destinations would shift underneath the animations.
    property int activeInDelay: 0
    property int activeOutDelay: 0
    property real activeFromX: 0
    property real activeFromY: 0
    // entryOffsetX/Y carry the toggle wave.
    property real entryOffsetX: 0
    property real entryOffsetY: 0
    // True while the opening cascade owns the entry offsets, so a highlight
    // change in the same frame does not cut the stagger short.
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

            // The gap compensation follows the same critically damped spring as
            // the card morph. FastSpatial's overshoot made the row wobble every
            // time the highlight moved; a spring also retargets cleanly when a
            // wallpaper is cycled again before the previous move has settled.
            Behavior on x {
                SpringAnim {
                    role: SpringAnim.Card
                    // Sub-pixel rest: the equal-gap check measures to 1px.
                    epsilon: 0.25
                }
            }
        },
        Translate {
            x: root.entryOffsetX
            y: root.entryOffsetY
        }
    ]

    // Toggle open: the highlight falls from above while its neighbours sweep
    // in from the left and right edges. All tiles move together and all travel
    // lives in the transform, so resting geometry is never touched.
    ParallelAnimation {
        id: slideInAnimation

        NumberAnimation {
            target: root
            property: "entryOffsetX"
            to: 0
            duration: Tokens.anim.durations.expressiveSlowSpatial * 0.55
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "entryOffsetY"
            to: 0
            duration: Tokens.anim.durations.expressiveSlowSpatial * 0.55
            easing.type: Easing.OutCubic
        }

        onFinished: root.presenting = false
        onStopped: root.presenting = false
    }

    // Closing runs the same motion backwards: neighbours return to their edges
    // and the highlight lifts back to the top.
    ParallelAnimation {
        id: slideOutAnimation

        NumberAnimation {
            target: root
            property: "entryOffsetX"
            to: root.activeFromX
            duration: Tokens.anim.durations.expressiveSlowSpatial * 0.45
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "entryOffsetY"
            to: root.activeFromY
            duration: Tokens.anim.durations.expressiveSlowSpatial * 0.45
            easing.type: Easing.InCubic
        }
    }

    // A smooth, non-bouncy morph: the selected card expands and its neighbours
    // contract together, with no overshoot and no restart hitch on rapid cycles.
    // Stiffer than the panel surfaces so the card change reads as an immediate
    // response to the selection, without overshooting the resting width.
    Behavior on morph {
        SpringAnim {
            role: SpringAnim.Card
            // Snappy but visible: the card reaches full width in ~335ms
            // while still retargeting cleanly when the selection changes fast.
            epsilon: 0.001
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
            slideInAnimation.stop();
            // The highlight may have moved since the open; rebuild the exit
            // wave from where the strip actually is now.
            activeOutDelay = slideOutDelay;
            activeFromX = entryFromX;
            activeFromY = entryFromY;
            slideOutAnimation.restart();
        }
    }

    function playToggleSlideIn(): void {
        // Snapshot before starting so a selection change during the reveal
        // cannot rewrite the pauses or destinations of a running cascade.
        activeInDelay = slideInDelay;
        activeOutDelay = slideOutDelay;
        activeFromX = entryFromX;
        activeFromY = entryFromY;
        // A tile can still hold its exit frame (or a partial slide) when the
        // strip is reopened quickly, so reset before replaying the wave.
        entryOffsetX = activeFromX;
        entryOffsetY = activeFromY;
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

    // Fade/scale runs together with the slide on every toggle.
    Anim {
        id: enterAnimation

        target: root
        property: "entrance"
        from: 0
        to: 1
        duration: Tokens.anim.durations.expressiveSlowSpatial * 0.55
        easing.type: Easing.OutCubic
    }

    Anim {
        id: exitAnimation

        target: root
        property: "entrance"
        to: 0
        duration: Tokens.anim.durations.expressiveSlowSpatial * 0.45
        easing.type: Easing.InCubic
    }

    Item {
        id: tile

        objectName: "wallpaperSwitcherCard"

        readonly property real w: width
        readonly property real h: height
        // Horizontal shear that turns the card into a parallelogram.
        readonly property real s: Math.min(h * 0.22, w * 0.28)

        // Non-selected cards stay compact; only the highlight expands to the
        // full card width. The strip compensates with a matching nudge so the
        // gaps between all cards remain equal. Every card keeps the same height
        // so the strip stays one aligned row.
        width: root.compactTileWidth + (root.fullTileWidth - root.compactTileWidth) * root.morph
        height: root.fullHeight
        anchors.horizontalCenter: parent.horizontalCenter
    }

    // The thumbnail is clipped by a plain rectangle that is then sheared into
    // a parallelogram. No offscreen alpha mask is involved, so there is no
    // stale texture to blank tiles and no white fill to spill over neighbours.
    Item {
        id: imageLayer

        anchors.fill: tile

        Rectangle {
            id: clipper

            // A plain rect of width (w - s) and height h. Shearing x by
            // -(s/h)*y + s maps its corners exactly onto the tile outline:
            // (0,0)->(s,0), (w-s,0)->(w,0), (0,h)->(0,h), (w-s,h)->(w-s,h).
            readonly property real w: Math.max(0, tile.w - tile.s)
            readonly property real h: tile.h

            width: w
            height: h
            color: "transparent"
            clip: true

            transformOrigin: Item.TopLeft
            transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                    1, tile.s > 0 ? -tile.s / tile.h : 0, 0, tile.s,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1
                )
            }

            StyledRect {
                anchors.fill: parent
                color: Colours.palette.m3surfaceContainerHigh
            }

            CachingImage {
                objectName: "wallpaperSwitcherImage"
                anchors.fill: parent
                path: root.modelData.path
                // Keep filtering on while the strip moves. Toggling it off at
                // the start of a PathView scroll makes the thumbnails shimmer
                // and reads as a stutter between otherwise smooth frames.
                smooth: true
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
    }

    // Selection outline, matching the clipped image's parallelogram exactly so
    // no thumbnail pixels ever stick out past the border.
    Shape {
        anchors.fill: tile
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeWidth: root.current ? 2 : 0
            strokeColor: Colours.palette.m3primary
            joinStyle: ShapePath.MiterJoin
            capStyle: ShapePath.FlatCap

            startX: tile.s
            startY: 0
            PathLine { x: tile.w; y: 0 }
            PathLine { x: tile.w - tile.s; y: tile.h }
            PathLine { x: 0; y: tile.h }
            PathLine { x: tile.s; y: 0 }
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
