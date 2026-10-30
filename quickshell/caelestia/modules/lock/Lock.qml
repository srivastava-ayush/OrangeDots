pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Caelestia
import Caelestia.Services
import qs.components.misc

Scope {
    id: root

    property alias lock: lock
    property bool animateEntrance
    property bool wakeTracing: false
    property var wakeSamples: []

    function recordWake(details: var): void {
        if (wakeTracing) {
            wakeSamples = [...wakeSamples, details].slice(-64);
            console.info("LOCK_WAKE_TRACE " + JSON.stringify(details));
        }
    }

    function requestLock(animate: bool): void {
        if (!lock.locked)
            animateEntrance = animate;
        lock.locked = true;
    }

    WlSessionLock {
        id: lock

        signal unlock

        onLockedChanged: {
            if (!locked) {
                root.animateEntrance = false;
                root.wakeTracing = false;
            }
        }

        LockSurface {
            lock: lock
            pam: pam
            animateEntrance: root.animateEntrance
            wakeTracing: root.wakeTracing
            onWakeSample: details => root.recordWake(details)
        }
    }

    Connections {
        function onAboutToSleep(): void {
            root.animateEntrance = false;
        }

        function onResumed(): void {
            root.animateEntrance = false;
        }

        target: SessionManager
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: root.requestLock(true)
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            root.requestLock(true);
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        function traceWake(): string {
            root.wakeSamples = [];
            root.wakeTracing = true;
            return "Wake tracing armed; no password text or lengths are recorded.";
        }

        function wakeTrace(): string {
            return JSON.stringify(root.wakeSamples, null, 2);
        }

        function stopWakeTrace(): void {
            root.wakeTracing = false;
        }

        function renderRecoveryStatus(): string {
            return JSON.stringify(typeof LockRenderRecovery === "undefined" ? { supported: false, reason: "native plugin not rebuilt" } : LockRenderRecovery.state(null));
        }

        target: "lock"
    }
}
