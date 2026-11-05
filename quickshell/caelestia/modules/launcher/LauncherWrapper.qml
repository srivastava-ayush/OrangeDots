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

    // Mirror the dashboard curtain from the bottom edge, with one reversible
    // timeline for the slide, centered width reveal and fade.
    property real revealProgress: shouldBeActive ? 1 : 0
    property real offsetScale: Math.pow(1 - revealProgress, 3)
    readonly property real curtainProgress: Math.max(0, Math.min(1, revealProgress))
    readonly property real curtainEase: curtainProgress * curtainProgress * curtainProgress
        * (curtainProgress * (curtainProgress * 6 - 15) + 10)
    readonly property real fullWidth: content.implicitWidth || 630
    readonly property real curtainWidthScale: 0.9 + 0.1 * curtainEase

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            implicitHeight = Qt.binding(() => content.implicitHeight);
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: revealProgress > 0
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: fullWidth * curtainWidthScale
    opacity: 1 - offsetScale
    clip: true

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on revealProgress {
        Anim {
            type: root.shouldBeActive ? Anim.SlowSpatial : Anim.DefaultSpatial
            duration: root.shouldBeActive ? Tokens.anim.durations.expressiveSlowSpatial * 0.85 : Tokens.anim.durations.expressiveDefaultSpatial * 0.85
            easing.type: Easing.InOutCubic
        }
    }

    InsetGloss {
        objectName: "launcherGloss"
        anchors.fill: parent
        z: 1 // Keep the sheen above app rows/search backgrounds, without taking input.
        // The launcher joins the bottom shell edge, opposite to the dashboard.
        rotation: 180
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        // Clip full-size rows/search through the curtain instead of squeezing
        // their layout as the outer surface expands and contracts.
        width: root.fullWidth

        active: root.shouldBeActive || root.visible

        sourceComponent: LauncherContent {
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
