pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    function selectDefaultTab(preferMedia: bool): void {
        // Match DashboardContent's enabled-filtered order, not fixed indices.
        if (preferMedia && Config.dashboard.showMedia)
            screenState.dashboardTab = 0;
        else if (Config.dashboard.showDashboard)
            screenState.dashboardTab = Config.dashboard.showMedia ? 1 : 0;
        else
            screenState.dashboardTab = 0;
    }

    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }
    readonly property FileDialog phoneFilePicker: FileDialog {
        title: qsTr("Send a file to your phone")
        onAccepted: path => KdeConnect.action(["--share", path])
    }

    readonly property real nonAnimHeight: ((content.item as DashboardContent)?.nonAnimHeight ?? 0) * dashboardScale
    // Dashboard no longer contains an editable Calendar scratchpad.
    readonly property bool notesActive: false
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    // Notched bars bridge the closed pill to the screen edge, so the pill itself
    // must be at least as tall as the band it covers. Kept separate from the
    // bar's vacated band (topInset), which lifts the content into the top bar.
    property real hideInset: 0
    property real topInset: 0

    // One reversible spring is the only animated timeline. The target is kept
    // separate so direction-specific tuning can be applied before the spring
    // is retargeted; changing a SpringAnimation's tuning in the same binding
    // update as its target makes the first close frame snap.
    property bool revealTarget: shouldBeActive
    property real revealProgress: revealTarget ? 1 : 0
    readonly property real sizeProgress: Math.max(0, revealProgress)
    readonly property real visualProgress: Math.min(1, sizeProgress)
    readonly property real reveal: visualProgress

    Behavior on revealProgress {
        SpringAnimation {
            id: surfaceSpring

            spring: 3.4
            damping: 0.30
            mass: 1
            epsilon: 0.002
        }
    }

    // Content is not animated separately. Its stage is a directional remap of
    // the same progress value: 0.69 is ~100ms into the open spring, 0.25 is
    // ~120ms into the close spring. A reversal keeps the current remap so the
    // content never jumps while the surface keeps its velocity.
    property real contentStart: shouldBeActive ? 0.69 : 0.25
    readonly property real contentStage: Math.min(
        1,
        Math.max(0, (revealProgress - contentStart) / Math.max(0.001, 1 - contentStart)))
    // Closing lifts the whole surface by its own pill height plus a small
    // margin, so the empty notch leaves the viewport instead of hanging around.
    // It is derived from the same spring, never animated on its own, and the
    // anchor keeps it continuous when the spring reverses. At the settled
    // closed endpoint the panel is hidden, so the offset returns to zero before
    // the next open.
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

    onShouldBeActiveChanged: {
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
        surfaceSpring.spring = shouldBeActive ? 3.4 : 4.0;
        surfaceSpring.damping = shouldBeActive ? 0.30 : 0.40;

        // Only re-anchor at a settled endpoint. Retargeting mid-flight keeps the
        // existing content stage and lift at this instant, so reversing cannot
        // make either pop or snap. A saturated stage needs no inversion: keeping
        // its current start already keeps the content fully shown or fully
        // hidden, while recomputing from a value that close to 0/1 is both
        // unnecessary and numerically unstable.
        if (settled) {
            root.contentStart = shouldBeActive ? 0.69 : 0.25;
            root.liftAnchorValue = 0;
        } else {
            if (stage > 0.02 && stage < 0.98)
                root.contentStart = (root.revealProgress - stage) / (1 - stage);
            root.liftAnchorValue = hint;
        }
        root.liftAnchorProgress = hintProgress;

        root.revealTarget = shouldBeActive;
    }

    Component.onCompleted: {
        surfaceSpring.spring = shouldBeActive ? 3.4 : 4.0;
        surfaceSpring.damping = shouldBeActive ? 0.30 : 0.40;
        root.contentStart = shouldBeActive ? 0.69 : 0.25;
        root.liftAnchorProgress = root.visualProgress;
        root.liftAnchorValue = 0;
    }

    // ---- Dynamic Island geometry ----------------------------------------
    readonly property real pillWidth: 190
    readonly property real pillHeight: Math.max(34, hideInset)
    readonly property real maxSurfaceRadius: 44
    readonly property real surfaceRadius: Math.min(implicitHeight / 2, maxSurfaceRadius)

    // ---------------------------------------------------------------------

    readonly property real naturalWidth: content.implicitWidth || 854
    readonly property real naturalHeight: content.implicitHeight
    readonly property real dashboardScale: Math.min(
        Math.max(0.6, Math.min(1.4, (Config.dashboard.scale ?? 100) / 100)),
        parent && parent.width > 0 ? parent.width / naturalWidth : 1.4,
        parent && parent.height > 0 && naturalHeight > 0 ? parent.height / naturalHeight : 1.4)
    readonly property real fullWidth: naturalWidth * dashboardScale
    readonly property real fullHeight: naturalHeight * dashboardScale
    readonly property real targetWidth: Math.max(pillWidth, fullWidth)
    readonly property real targetHeight: Math.max(pillHeight, fullHeight)
    // Keep the edge target generous even while the pill is collapsed.
    // A configured width overrides the automatic dashboard-sized target.
    readonly property real hoverWidth: {
        const autoWidth = Math.min(parent ? parent.width : fullWidth + 200, fullWidth + 200);
        return DashboardHover.width > 0 ? Math.min(parent ? parent.width : DashboardHover.width, DashboardHover.width) : autoWidth;
    }
    readonly property real hoverHeight: Math.max(Config.border.minThickness, DashboardHover.height)

    // Grows in place while open. On close the whole surface is pulled up far
    // enough to carry the vacated notch out of the viewport.
    anchors.topMargin: -topInset + pullHint
    implicitWidth: pillWidth + (targetWidth - pillWidth) * sizeProgress
    implicitHeight: pillHeight + (targetHeight - pillHeight) * sizeProgress
    visible: shouldBeActive || revealProgress > 0.001 || contentStage > 0.001
    clip: true

    InsetGloss {
        objectName: "dashboardGloss"
        anchors.fill: parent
    }

    Item {
        id: curtain

        objectName: "dashboardCurtain"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Full-sized content is clipped by the morphing parent, never resized
        // by the layout. Only the staging transform scales it during the reveal.
        width: root.fullWidth
        height: root.fullHeight
        transformOrigin: Item.Top

        opacity: root.contentStage
        scale: 0.85 + 0.15 * root.contentStage

        Loader {
            id: content

            objectName: "dashboardContentLoader"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            transformOrigin: Item.Top
            scale: root.dashboardScale

            active: root.shouldBeActive || root.visible

            sourceComponent: DashboardContent {
                screenState: root.screenState
                facePicker: root.facePicker
                phoneFilePicker: root.phoneFilePicker
                // Nested elements derive their own staggered stage from the
                // wrapper's single spring, so they cannot drift out of sync.
                revealStage: root.contentStage
            }
        }
    }
}
