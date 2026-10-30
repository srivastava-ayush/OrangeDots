pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.images
import qs.services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam
    required property bool animateEntrance
    property bool wakeTracing: false
    readonly property alias unlocking: view.unlocking
    signal wakeSample(var details)

    function recoverRendering(resumed: bool): void {
        if (!root.lock.locked || !root.visible)
            return;
        if (typeof LockRenderRecovery === "undefined") {
            if (resumed)
                console.warn("Lock rendering recovery requires rebuilding the Caelestia native plugin");
            return;
        }
        const before = LockRenderRecovery.state(view);
        const recovered = resumed ? LockRenderRecovery.afterResume(view) : LockRenderRecovery.ifStalled(view);
        if (root.wakeTracing)
            root.wakeSample({ event: "render-recovery", resumed, recovered, before, after: LockRenderRecovery.state(view) });
    }

    function recoverAfterResume(): void { recoverRendering(true); }
    function recoverIfStalled(): void { recoverRendering(false); }

    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""
    // An unavailable capture/wallpaper must never leave an undefined surface.
    color: "black"

    Item {
        id: background
        anchors.fill: parent

        Loader {
            anchors.fill: parent
            sourceComponent: Config.lock.useWallpaper ? wallpaper : capture
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: background
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        blurMultiplier: 3
    }

    Rectangle {
        anchors.fill: parent
        color: "#66000000"
    }

    LockView {
        id: view
        anchors.fill: parent
        visible: Config.lock.enabled
        pam: root.pam
        animateEntrance: root.animateEntrance
        wakeTracing: root.wakeTracing
        onExitFinished: root.lock.locked = false
    }

    WakeTrace {
        lockView: view
        enabled: root.wakeTracing
        screenName: root.screen?.name ?? "unmapped"
        onSample: details => root.wakeSample(details)
    }

    Connections {
        target: root.lock
        function onUnlock(): void {
            if (root.lock.locked)
                view.unlock();
        }
    }

    Connections {
        target: SessionManager
        function onAboutToSleep(): void { view.settle(); }
        function onResumed(): void {
            view.settle();
            Qt.callLater(root.recoverAfterResume);
        }
    }

    Connections {
        target: view.passwordInput.input
        // A replacement callback can also time out while outputs are still
        // waking. On input, recover only a timed-out lock window, after Qt has
        // finished editing its native mask. Healthy frames are untouched.
        function onTextEdited(): void { Qt.callLater(root.recoverIfStalled); }
    }

    onVisibleChanged: {
        if (visible && !animateEntrance)
            view.settle();
    }

    Component {
        id: capture
        ScreencopyView { captureSource: root.screen }
    }

    Component {
        id: wallpaper
        CachingImage { path: Wallpapers.current }
    }
}
