pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// Independent player content, drawn on the shell's shared dashboard surface.
Item {
    id: root

    required property bool fullscreen
    required property bool activeScreen
    property bool dashboardOpen: false
    property real hideInset: 0
    // Notched top bars keep the island's surface attached to the screen edge,
    // but this item is anchored below the bar. Lift it by the bar thickness as
    // it reveals so the player fills that band instead of leaving a gap.
    property real topInset: 0
    property var player: Players.active
    property int displayDuration: 5000
    property bool expanded: false
    property string lastEventKey: ""
    readonly property bool hasDuration: Number.isFinite(player?.length) && player.length > 0 && player.length <= 2147483647
    readonly property real duration: hasDuration ? player.length : 0
    readonly property real position: Math.max(0, Math.min(player?.position ?? 0, duration))
    readonly property string eventKey: player
        ? `${player.uniqueId}\n${player.trackTitle || player.metadata["xesam:url"] || ""}\n${player.isPlaying}` : ""

    // One reversible spring is the only animated timeline. The target is kept
    // separate so direction-specific tuning can be applied before the spring
    // is retargeted; changing a SpringAnimation's tuning in the same update as
    // its target makes the first close frame snap.
    property bool revealTarget: false
    property real revealProgress: revealTarget ? 1 : 0
    readonly property real sizeProgress: Math.max(0, revealProgress)
    readonly property real visualProgress: Math.min(1, sizeProgress)
    readonly property real reveal: visualProgress

    Behavior on revealProgress {
        SpringAnim {
            id: surfaceSpring

            role: SpringAnim.Island
            epsilon: 0.002
        }
    }

    // Content is not animated separately. Its stage is a directional remap of
    // the same progress value: 0.69 is ~100ms into the open spring, 0.25 is
    // ~120ms into the close spring. A reversal keeps the current remap so the
    // content never jumps while the surface keeps its velocity.
    property real contentStart: 0.25
    readonly property real contentStage: Math.min(
        1,
        Math.max(0, (revealProgress - contentStart) / Math.max(0.001, 1 - contentStart)))
    // Nested content rides the same reversible timeline. Each child takes a
    // delayed slice of contentStage, so a fixed order reads forwards while
    // opening and in reverse while closing without ever retargeting an
    // animation: reversing mid-flight keeps every child exactly where it was.
    readonly property real staggerSpan: 0.45
    function nestedStage(order: int, steps: int): real {
        const last = Math.max(1, steps);
        const delay = Math.min(Math.max(order, 0), last) / last * staggerSpan;
        return Math.min(1, Math.max(0, (root.contentStage - delay) / (1 - staggerSpan)));
    }

    // Closing lifts the whole surface by its own pill height plus a small
    // margin, so the vacated notch leaves the viewport instead of hanging
    // around. It is derived from the same spring, never animated on its own,
    // and the anchor keeps it continuous when the spring reverses. At the
    // settled closed endpoint the island is hidden, so the offset returns to
    // zero before the next reveal.
    readonly property real closeLiftAmount: pillHeight + 4
    property real liftAnchorProgress: visualProgress
    property real liftAnchorValue: 0
    readonly property real pullHint: {
        const p = visualProgress;
        if (!revealTarget && p <= 0.001)
            return 0;
        const anchor = liftAnchorProgress;
        if (revealTarget) {
            const span = Math.max(0.001, 1 - anchor);
            const u = Math.min(1, Math.max(0, (p - anchor) / span));
            return liftAnchorValue * (1 - u);
        }
        const span = Math.max(0.001, anchor);
        const u = Math.min(1, Math.max(0, (anchor - p) / span));
        const eased = u * u * u * (u * (u * 6 - 15) + 10);
        const hint = liftAnchorValue * (1 - u) - closeLiftAmount * eased;
        return Math.max(-closeLiftAmount, Math.min(0, hint));
    }

    onExpandedChanged: {
        const stage = root.contentStage;
        const hint = root.pullHint;
        const hintProgress = root.visualProgress;
        // A progress value that is merely close to an endpoint is not enough:
        // with the current start it can still produce a visible stage below
        // saturation, and resetting the start there would make content jump.
        const nearClosed = hintProgress <= 0.001 && stage <= 0.001;
        const nearOpen = hintProgress >= 0.999 && stage >= 0.999;
        const settled = nearClosed || nearOpen;

        // Open: ~4.6% overshoot, settled by ~450ms. Close: a stiffer, gentler
        // spring with no visible bounce; the surface is down by ~300ms while
        // content has already finished leaving at ~120ms.
        surfaceSpring.role = expanded ? SpringAnim.Island : SpringAnim.Dismiss;

        // Only re-anchor at a settled endpoint. Retargeting mid-flight keeps the
        // existing content stage and lift at this instant, so reversing cannot
        // make either pop or snap. A saturated stage needs no inversion: keeping
        // its current start already keeps content fully shown or hidden.
        if (settled) {
            root.contentStart = expanded ? 0.69 : 0.25;
            root.liftAnchorValue = 0;
        } else {
            if (stage > 0.02 && stage < 0.98)
                root.contentStart = (root.revealProgress - stage) / (1 - stage);
            root.liftAnchorValue = hint;
        }
        root.liftAnchorProgress = hintProgress;

        root.revealTarget = expanded;
    }

    Component.onCompleted: {
        surfaceSpring.role = expanded ? SpringAnim.Island : SpringAnim.Dismiss;
        root.contentStart = expanded ? 0.69 : 0.25;
        root.revealTarget = expanded;
        root.liftAnchorProgress = root.visualProgress;
        root.liftAnchorValue = 0;
    }

    onEventKeyChanged: {
        if (dashboardOpen) {
            lastEventKey = eventKey;
            eventDelay.stop();
        } else {
            eventDelay.restart();
        }
    }
    onFullscreenChanged: if (fullscreen) dismiss()
    onActiveScreenChanged: if (!activeScreen) dismiss()
    onDashboardOpenChanged: {
        if (dashboardOpen) {
            dismiss();
            eventDelay.stop();
            lastEventKey = eventKey;
        }
    }

    function dismiss(): void {
        expanded = false;
        hideTimer.stop();
    }

    function formatTime(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(total / 60);
        return `${minutes}:${(total % 60).toString().padStart(2, "0")}`;
    }

    // ---- Dynamic Island geometry ----------------------------------------
    readonly property real fullWidth: Math.min(440, parent ? parent.width : 440)
    readonly property real pillWidth: fullWidth * 0.48
    readonly property real expandedHeight: 120
    // A unified bar paints a full-width surface over this panel, so height grown
    // inside the bar band stays hidden until the island clears the bar and then
    // pops into view. Start flush with the bar's bottom edge so every frame of
    // the reveal is visible below it. Notched bars have no surface across the
    // centre notch, so they keep growing from zero and stay unchanged.
    readonly property real collapsedHeight: Math.min(expandedHeight, Taskbar.notched ? 0 : topInset)
    readonly property real pillHeight: collapsedHeight
    readonly property real maxSurfaceRadius: 44
    readonly property real surfaceRadius: Math.min(implicitHeight / 2, maxSurfaceRadius)
    readonly property real targetWidth: fullWidth
    readonly property real targetHeight: expandedHeight

    // Grows in place while open. On close the whole surface is pulled up far
    // enough to carry the vacated notch out of the viewport.
    anchors.topMargin: -topInset + pullHint
    implicitWidth: pillWidth + (targetWidth - pillWidth) * sizeProgress
    implicitHeight: pillHeight + (targetHeight - pillHeight) * sizeProgress
    visible: expanded || revealProgress > 0.001 || contentStage > 0.001
    clip: true

    InsetGloss {
        objectName: "mediaIslandGloss"
        anchors.fill: parent
    }

    Item {
        id: curtain

        objectName: "mediaIslandCurtain"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Full-sized content is clipped by the morphing parent, never resized
        // by the layout. Only the staging transform scales it during the reveal.
        width: root.fullWidth
        height: root.expandedHeight
        transformOrigin: Item.Top

        opacity: root.contentStage
        scale: 0.85 + 0.15 * root.contentStage

        RowLayout {
            objectName: "mediaIslandContent"
            // Reveal a full-size player through the curtain, like the dashboard.
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 44
            anchors.topMargin: 16
            width: root.fullWidth - 32
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 18
                color: Colours.palette.m3secondaryContainer

                // Artwork leads the cascade on open and leaves last on close.
                opacity: root.nestedStage(0, 5)
                transform: Translate {
                    y: (1 - root.nestedStage(0, 5)) * 8
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "music_note"
                }

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 112
                    sourceSize.height: 112
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                opacity: root.nestedStage(1, 5)
                transform: Translate {
                    y: (1 - root.nestedStage(1, 5)) * 8
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || qsTr("Media")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Loader {
                        objectName: "mediaIslandEqLoader"
                        active: root.visible
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: MediaIslandEq {
                            objectName: "mediaIslandEq"
                            playing: root.player?.isPlaying ?? false
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: [root.player?.isPlaying ? qsTr("Playing") : qsTr("Paused"), root.player?.trackArtist].filter(Boolean).join(" · ")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            IconButton {
                objectName: "islandPrevious"
                icon: "skip_previous"
                type: IconButton.Text
                enabled: root.player?.canGoPrevious ?? false
                opacity: root.nestedStage(2, 5)
                transform: Translate {
                    y: (1 - root.nestedStage(2, 5)) * 8
                }
                onClicked: root.player?.previous()
            }

            IconButton {
                objectName: "islandPlayPause"
                icon: root.player?.isPlaying ? "pause" : "play_arrow"
                type: IconButton.Filled
                enabled: root.player?.canTogglePlaying ?? false
                opacity: root.nestedStage(3, 5)
                transform: Translate {
                    y: (1 - root.nestedStage(3, 5)) * 8
                }
                onClicked: root.player?.togglePlaying()
            }

            IconButton {
                objectName: "islandNext"
                icon: "skip_next"
                type: IconButton.Text
                enabled: root.player?.canGoNext ?? false
                opacity: root.nestedStage(4, 5)
                transform: Translate {
                    y: (1 - root.nestedStage(4, 5)) * 8
                }
                onClicked: root.player?.next()
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: root.fullWidth - 32
            spacing: 10

            // The scrubber closes the cascade and is the first thing to leave.
            opacity: root.nestedStage(5, 5)
            transform: Translate {
                y: (1 - root.nestedStage(5, 5)) * 8
            }

            StyledText {
                objectName: "islandElapsed"
                text: root.formatTime(progress.dragging ? progress.pos * root.duration : root.position)
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledSlider {
                id: progress
                objectName: "islandProgress"
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                value: root.duration > 0 ? root.position / root.duration : 0
                enabled: root.hasDuration && (root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false)
                wavy: false
                interactionOnMove: false
                onDraggingChanged: if (root.expanded) hideTimer.restart()
                onInteraction: value => {
                    if (enabled)
                        root.player.position = Math.max(0, Math.min(1, value)) * root.duration;
                }
            }

            StyledText {
                objectName: "islandDuration"
                text: root.hasDuration ? root.formatTime(root.duration) : "--:--"
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    Timer {
        id: eventDelay
        interval: 250
        onTriggered: {
            if (!root.player) {
                root.lastEventKey = "";
                root.dismiss();
                return;
            }
            if (root.eventKey === root.lastEventKey)
                return;
            root.lastEventKey = root.eventKey;
            if (root.fullscreen || !root.activeScreen || root.dashboardOpen)
                return;
            root.expanded = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: root.displayDuration
        onTriggered: {
            if (hover.hovered || progress.dragging)
                restart();
            else
                root.expanded = false;
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered && root.expanded) hideTimer.restart()
    }

    Timer {
        running: root.visible && (root.player?.isPlaying ?? false) && (root.player?.positionSupported ?? false)
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: root.player?.positionChanged()
    }
}
