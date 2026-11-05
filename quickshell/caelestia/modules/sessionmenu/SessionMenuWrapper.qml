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
    property real availableWidth: 912
    readonly property real nonAnimWidth: implicitWidth

    readonly property bool shouldBeActive: screenState.session && Config.session.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarVisible ? 14 : 0
    readonly property real entranceOffset: offsetScale * 48
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

    visible: offsetScale < 1
    anchors.verticalCenterOffset: entranceOffset
    // Stable geometry prevents the liquid background snapping as the loader exits.
    implicitWidth: Math.min(880, Math.max(0, availableWidth - 32))
    implicitHeight: 244
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: root.shouldBeActive ? Anim.SlowSpatial : Anim.DefaultSpatial
            duration: root.shouldBeActive ? Tokens.anim.durations.expressiveSlowSpatial * 1.35 : Tokens.anim.durations.expressiveDefaultSpatial
            easing.type: root.shouldBeActive ? Easing.OutQuint : Easing.InCubic
        }
    }

    Loader {
        id: content

        anchors.fill: parent

        active: root.shouldBeActive || root.visible

        sourceComponent: SessionMenuContent {
            screenState: root.screenState
            reveal: 1 - root.offsetScale
            onActionRequested: command => root.runAfterExit(command)
        }
    }
}
