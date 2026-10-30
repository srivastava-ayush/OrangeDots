pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Caelestia
import Caelestia.Services

// Temporary, opt-in diagnostics. Observe only: no focus changes, timers,
// repaint requests, password strings or password lengths.
QtObject {
    id: root

    required property var lockView
    property bool enabled: false
    property string screenName
    readonly property var input: lockView.passwordInput.input
    readonly property var window: input.Window.window
    readonly property string surfaceId: Math.random().toString(36).slice(2, 9)
    property double resumedAt: 0
    property int frames: 0
    property bool clicked: false
    property bool editedBeforeClick: false
    property bool editedAfterClick: false
    property string pendingFrame: ""

    signal sample(var details)

    function capture(event: string): void {
        if (!enabled)
            return;
        sample({
            event, screen: screenName, surfaceId,
            at: new Date().toISOString(),
            sinceResumeMs: resumedAt ? Date.now() - resumedAt : null,
            appState: Qt.application.state,
            windowActive: window?.active ?? null,
            windowVisible: window?.visible ?? null,
            visibility: window?.visibility ?? null,
            focusMatchesInput: window?.activeFocusItem === input,
            inputFocused: input.activeFocus,
            inputVisible: input.visible,
            inputReadOnly: input.readOnly,
            inputSize: [input.width, input.height],
            hasInput: input.length > 0,
            hasMask: input.displayText.length > 0,
            progress: lockView.progress, frames, clicked,
            nativeRender: typeof LockRenderRecovery === "undefined" ? null : LockRenderRecovery.state(input)
        });
    }

    function resumed(): void {
        resumedAt = Date.now();
        frames = 0;
        clicked = false;
        editedBeforeClick = false;
        editedAfterClick = false;
        pendingFrame = "";
        capture("resumed");
    }

    function framePresented(): void {
        frames++;
        if (pendingFrame) {
            const stage = pendingFrame;
            pendingFrame = "";
            capture("frame-for-" + stage);
        }
    }

    readonly property Connections sleepEvents: Connections {
        target: SessionManager
        enabled: root.enabled
        function onAboutToSleep(): void { root.capture("before-sleep"); }
        function onResumed(): void { root.resumed(); }
    }

    readonly property Connections inputEvents: Connections {
        target: root.input
        enabled: root.enabled
        function onTextEdited(): void {
            if (!root.resumedAt || (root.clicked ? root.editedAfterClick : root.editedBeforeClick))
                return;
            if (root.clicked)
                root.editedAfterClick = true;
            else
                root.editedBeforeClick = true;
            root.pendingFrame = root.clicked ? "after-click" : "before-click";
            root.capture("edit-" + root.pendingFrame);
        }
        function onActiveFocusChanged(): void { root.capture("input-focus"); }
    }

    readonly property Connections windowEvents: Connections {
        target: root.window
        enabled: root.enabled
        function onActiveChanged(): void { root.capture("window-active"); }
        function onSceneGraphInvalidated(): void { root.capture("scenegraph-invalidated"); }
        function onSceneGraphInitialized(): void { root.capture("scenegraph-initialized"); }
        function onFrameSwapped(): void { root.framePresented(); }
    }

    readonly property Connections clickEvents: Connections {
        target: root.lockView.passwordInput
        enabled: root.enabled
        function onPointerPressed(): void {
            if (root.clicked || !root.resumedAt)
                return;
            root.clicked = true;
            root.capture("pointer-press");
            Qt.callLater(() => root.capture("after-pointer-press"));
        }
    }
}
