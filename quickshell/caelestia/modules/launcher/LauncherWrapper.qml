pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    // One reversible spring is the only animated timeline. The target is kept
    // separate so direction-specific tuning can be applied before the spring
    // is retargeted; changing a SpringAnimation's tuning in the same update as
    // its target makes the first close frame snap. Open is slower and looser so
    // the reveal has time to breathe, close stays stiff and gets out of the way.
    property bool revealTarget: shouldBeActive
    property real revealProgress: revealTarget ? 1 : 0
    readonly property real visualProgress: Math.min(1, Math.max(0, revealProgress))
    readonly property real curtainProgress: visualProgress
    readonly property real fullWidth: content.implicitWidth || 630

    // Quadratic instead of cubic: the slide stays continuous through the
    // spring's overshoot, turning it into a short lift at the end of the open
    // instead of either a dead-stop or a big bounce.
    readonly property real offsetScale: Math.pow(1 - revealProgress, 2)
    readonly property real curtainEase: {
        const p = curtainProgress;
        return p * p * p * (p * (p * 6 - 15) + 10);
    }
    readonly property real curtainWidthScale: 0.9 + 0.1 * curtainEase

    // Content is staged from the same spring, never animated on its own. Open
    // starts content almost immediately so the launcher feels instant, while
    // close clears it early enough for the surface to collapse underneath. A
    // reversal keeps the current remap, so content never jumps while the sheet
    // keeps the spring's velocity.
    property real contentStart: shouldBeActive ? 0.22 : 0.45
    readonly property real contentStage: Math.min(
        1,
        Math.max(0, (revealProgress - contentStart) / Math.max(0.001, 1 - contentStart)))

    // Shared by the background blob and the content transform so the liquid
    // edge bulge peaks with the reveal instead of drifting out of phase.
    readonly property real liquidDeform: 0.1 + Math.sin(curtainProgress * Math.PI) * 0.17

    onShouldBeActiveChanged: {
        surfaceSpring.role = shouldBeActive ? SpringAnim.Launcher : SpringAnim.LauncherClose;

        const stage = root.contentStage;
        const progress = root.revealProgress;
        const settled = shouldBeActive
            ? progress >= 0.999 && stage >= 0.999
            : progress <= 0.001 && stage <= 0.001;
        if (settled) {
            root.contentStart = shouldBeActive ? 0.22 : 0.45;
        } else if (stage > 0.02 && stage < 0.98) {
            // Invert the current stage into a new start so a mid-flight
            // reversal preserves exactly what is on screen.
            root.contentStart = (progress - stage) / (1 - stage);
        }
        root.revealTarget = shouldBeActive;

        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    Component.onCompleted: {
        surfaceSpring.role = shouldBeActive ? SpringAnim.Launcher : SpringAnim.LauncherClose;
        root.contentStart = shouldBeActive ? 0.22 : 0.45;
        root.revealTarget = shouldBeActive;
        Qt.callLater(() => Apps) // Load apps on init
    }

    visible: revealProgress > 0
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: fullWidth * curtainWidthScale
    opacity: Math.min(1, 1 - offsetScale)
    clip: true

    Behavior on revealProgress {
        // Respect the global "animation duration" setting: at 0 the sheet
        // should open and close instantly instead of springing.
        enabled: GlobalConfig.appearance.anim.durations.scale > 0

        SpringAnim {
            id: surfaceSpring

            role: SpringAnim.Launcher
            epsilon: 0.002
        }
    }

    InsetGloss {
        objectName: "launcherGloss"
        anchors.fill: parent
        z: 1 // Keep the sheen above app rows/search backgrounds, without taking input.
        // The launcher joins the bottom shell edge, opposite to the dashboard.
        rotation: 180
    }

    Item {
        id: curtain

        objectName: "launcherCurtain"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // Full-sized content is clipped by the morphing sheet instead of being
        // squeezed; only the staged transform scales it during the reveal.
        width: root.fullWidth
        height: root.implicitHeight
        transformOrigin: Item.Bottom

        opacity: root.contentStage
        scale: 0.94 + 0.06 * root.contentStage

        Loader {
            id: content

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: root.fullWidth

            active: root.shouldBeActive || root.visible

            sourceComponent: LauncherContent {
                screenState: root.screenState
                panels: root.panels
                maxHeight: root.maxHeight
            }
        }
    }
}
