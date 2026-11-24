pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property bool sidebarVisible
    // Bottom-centre point (in the parent's space) the card grows out of.
    required property real anchorX
    required property real anchorY
    property real availableWidth: 912

    readonly property real finalWidth: Math.min(880, Math.max(0, availableWidth - 32))
    readonly property real finalHeight: 244
    readonly property real nonAnimWidth: finalWidth

    readonly property bool shouldBeActive: screenState.session && Config.session.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    // 0 = a point at the bottom centre, 1 = the fully open card.
    readonly property real reveal: 1 - offsetScale
    property var pendingCommand: []

    function runAfterExit(command: var): void {
        if (!shouldBeActive || pendingCommand.length)
            return;
        pendingCommand = command;
        screenState.session = false;
        if (offsetScale >= 1)
            finishAction();
    }

    function finishAction(): void {
        const command = pendingCommand;
        pendingCommand = [];
        if (command.length && !SessionManager.exec(command))
            Quickshell.execDetached(command);
    }

    onOffsetScaleChanged: if (offsetScale >= 1) finishAction()
    // Reopening cancels a deferred action instead of leaving it armed for later.
    onShouldBeActiveChanged: if (shouldBeActive) pendingCommand = []

    // Mirror the taskbar popouts, but sourced from the bottom centre of the
    // screen: the clip grows around a point that travels up to the middle, so
    // the menu rises out of the bottom edge instead of fading in.
    readonly property real targetX: parent ? parent.width / 2 : anchorX
    readonly property real targetY: parent ? parent.height / 2 : anchorY
    readonly property real currentX: anchorX + (targetX - anchorX) * reveal
    readonly property real currentY: anchorY + (targetY - anchorY) * reveal

    visible: offsetScale < 1
    clip: true

    x: currentX - width / 2
    y: currentY - height / 2
    width: finalWidth * reveal
    height: finalHeight * reveal
    opacity: reveal

    Behavior on offsetScale {
        Anim {
            // Aim for roughly a 300 ms summon while keeping the expressive
            // curve; the exit stays slightly shorter so dismissal feels crisp.
            duration: root.shouldBeActive ? Tokens.anim.durations.expressiveSlowSpatial * 0.46 : Tokens.anim.durations.expressiveDefaultSpatial * 0.55
            easing.type: root.shouldBeActive ? Easing.OutQuint : Easing.InCubic
        }
    }

    Loader {
        id: content

        // Keep the card at its final size and centred inside the growing clip,
        // so the reveal shows its middle rather than squashing the layout.
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        width: root.finalWidth
        height: root.finalHeight

        active: root.shouldBeActive || root.visible

        sourceComponent: SessionMenuContent {
            screenState: root.screenState
            reveal: root.reveal
            onActionRequested: command => root.runAfterExit(command)
        }
    }
}
