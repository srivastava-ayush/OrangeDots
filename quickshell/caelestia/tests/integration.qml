pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtTest as QtTest
import Quickshell
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.taskbar
import qs.modules.taskbar.popouts as BarPopouts
import qs.modules.settings
import qs.modules.settings.pages.panels
import qs.modules.desktop
import qs.modules.lockscreen as Lock
import qs.modules as Modules

// Transparent, input-free test surface. integration.py isolates all settings
// and removes the Hyprland IPC connection, so the desktop is left unchanged.
ShellRoot {
    id: root

    settings.watchFiles: false

    property int step
    property int mediaWaitTicks
    readonly property QtObject recorderFixture: QtObject {
        property bool running: false
        property bool paused: false
        property real elapsed: 75
        property var startArgs: []
        function start(args = []): void { startArgs = args; running = true; paused = false; }
        function togglePause(): void { paused = !paused; }
        function stop(): void { running = false; paused = false; }
    }
    readonly property QtObject islandPlayer: QtObject {
        property string uniqueId: "island-fixture"
        property string trackTitle: "First track"
        property string trackArtist: "Test artist"
        property string trackArtUrl: ""
        property var metadata: ({})
        property bool isPlaying: true
        property bool canGoPrevious: true
        property bool canGoNext: true
        property bool canTogglePlaying: true
        function previous(): void { trackTitle = "First track"; }
        function next(): void { trackTitle = "Second track"; }
        function togglePlaying(): void { isPlaying = !isPlaying; }
    }
    property point bannerPosition
    property NotifData sampleNotification
    readonly property var hoverCases: [
        { orientation: "top", name: "clock" },
        { orientation: "top", name: "audio" },
        { orientation: "top", name: "network" },
        { orientation: "top", name: "notifications" },
        { orientation: "left", name: "clock" },
        { orientation: "left", name: "audio" },
        { orientation: "left", name: "network" },
        { orientation: "left", name: "notifications" }
    ]
    readonly property var clockCenterCases: {
        const cases = [];
        for (const style of ["unified", "notches", "center"])
            for (const width of [1024, 1281, 1920, 2560])
                cases.push({ style, width });
        return cases;
    }
    property point hoverAnchor
    property var nexusStack
    property var tintBaseline
    property real unifiedStatusInset
    property var calendarIpc
    readonly property string calendarNote: "Calendar integration scratchpad — keep this draft"
    property int calendarWaitTicks
    readonly property SettingsState navigationState: SettingsState {
        screen: window.screen
    }

    Component {
        id: notificationFixture

        NotifData {
            notificationId: "taskbar-shade-test"
            summary: "Notification shade test"
            body: "This notification stays in the isolated test history."
            appName: "Taskbar tests"
            hints: ({})
            expireTimeout: 60000
            popup: true
        }
    }

    function check(condition: bool, message: string): void {
        if (!condition)
            throw new Error(message);
    }

    function find(item: Item, name: string): Item {
        if (item.objectName === name)
            return item;
        for (const child of item.children) {
            const found = find(child, name);
            if (found)
                return found;
        }
        return null;
    }

    function findBackground(item: Item, panel: Item): Item {
        if (item.panel === panel)
            return item;
        for (const child of item.children) {
            const found = findBackground(child, panel);
            if (found)
                return found;
        }
        return null;
    }

    QtTest.TestEvent {
        id: pointerEvents
    }

    Loader {
        id: fullSceneLoader
        active: ["background", "notifications", "hover", "media-island", "media-dashboard", "overview", "launcher-gloss", "recorder-card", "recorder-delete", "styles", "attachments", "center", "calendar"].includes(Quickshell.env("TASKBAR_TEST_MODE"))
        sourceComponent: DesktopWindow {
            readonly property alias testEvents: sceneEvents

            screen: window.screen
            contentItem.opacity: 0.001
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            QtTest.TestEvent {
                id: sceneEvents
            }
        }
    }

    Loader {
        id: calendarShortcuts
        active: Quickshell.env("TASKBAR_TEST_MODE") === "calendar"
        sourceComponent: Modules.Shortcuts {
            // The fixture deliberately has no Hyprland connection/focused
            // monitor. Route the real IPC controller to its isolated screen.
            function activeScreenState(): ScreenState {
                return fullSceneLoader.item.screenState;
            }
        }
    }

    // Real Qt key events, sent only inside this test application's input-free
    // window. This fixture never acquires a session lock or authenticates.
    Loader {
        id: lockInputFixture
        active: ["lock-input", "lock-focus"].includes(Quickshell.env("TASKBAR_TEST_MODE"))
        parent: window.contentItem
        width: 800
        height: 700
        sourceComponent: Item {
            id: passwordFixture
            readonly property WlSessionLock testLock: WlSessionLock {
                signal unlock
            }
            readonly property Lock.Pam testPam: Lock.Pam {
                lock: passwordFixture.testLock
            }
            // UI submission spy only. Never calls a native PAM method or
            // records credentials; the unsecured real backend is tested first.
            readonly property Lock.Pam submissionSpy: Lock.Pam {
                lock: passwordFixture.testLock
                property int submissions
                property int submittedLength
                function submitPassword(password: string): void {
                    submissions++;
                    submittedLength = password.length;
                    clearInput();
                }
            }
            readonly property alias view: view
            readonly property var editor: view.passwordInput
            readonly property var field: view.passwordInput.input
            readonly property alias events: events
            readonly property alias accepted: accepted
            property int exits
            property int earlyExits
            property var extraView
            property var traceSamples: []
            readonly property alias wakeTrace: wakeTrace

            Lock.WakeTrace {
                id: wakeTrace
                lockView: view
                enabled: view.wakeTracing
                screenName: "test"
                onSample: details => passwordFixture.traceSamples = [...passwordFixture.traceSamples, details]
            }
            readonly property alias motionView: motionView

            Component {
                id: motionView
                Lock.LockView {
                    pam: passwordFixture.testPam
                    width: 800
                    height: 700
                    visible: false
                }
            }
            readonly property alias secureAdapter: secureAdapter
            Component {
                id: secureAdapter
                Lock.LockSurface {
                    lock: passwordFixture.testLock
                    pam: passwordFixture.testPam
                    animateEntrance: false
                }
            }

            Lock.LockView {
                id: view
                anchors.fill: parent
                animateEntrance: false
                pam: passwordFixture.testPam
                onExitFinished: passwordFixture.exits++
            }

            QtTest.TestEvent { id: events }
            QtTest.SignalSpy {
                id: accepted
                target: view.passwordInput.input
                signalName: "accepted"
            }
        }
    }

    PanelWindow {
        id: window

        visible: true
        implicitWidth: 1280
        implicitHeight: 720
        color: "transparent"
        // Nonzero to keep Qt polishing layouts; below one 8-bit alpha step.
        contentItem.opacity: 0.001
        mask: Region {}
        anchors.top: true
        anchors.left: true
        WlrLayershell.namespace: "caelestia-taskbar-tests"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        ScreenState {
            id: state

            modelData: window.screen
        }

        Item {
            id: panelArea

            anchors.fill: parent
            anchors.leftMargin: bar.leftInset
            anchors.topMargin: bar.topInset
            anchors.rightMargin: GlobalConfig.border.thickness
            anchors.bottomMargin: GlobalConfig.border.thickness

            BarPopouts.PopoutAnchor {
                id: popouts

                screen: window.screen
                screenState: state
                borderThickness: GlobalConfig.border.thickness
                horizontal: Taskbar.horizontal
            }
        }

        TaskbarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.left: parent.left
            screen: window.screen
            screenState: state
            popouts: popouts.content
            fullscreen: false
        }

        TaskbarPanel {
            id: settings

            visible: false
            width: 800
            height: 600
            nState: SettingsState {
                screen: window.screen
            }
        }
    }

    Timer {
        interval: ["hover", "attachments", "clock-center"].includes(Quickshell.env("TASKBAR_TEST_MODE")) ? 300 : 700
        running: true
        repeat: true

        onTriggered: {
            try {
                if (!Taskbar.loaded)
                    return;

                if (Quickshell.env("TASKBAR_TEST_MODE") === "lock-focus") {
                    const fixture = lockInputFixture.item;
                    const editor = fixture.editor;
                    const field = fixture.field;
                    switch (root.step++) {
                    case 0:
                        const surface = fixture.secureAdapter.createObject(fixture);
                        root.check(!!surface && !surface.visible && !fixture.testLock.locked, "The secure adapter must instantiate without creating a lock or an on-screen surface");
                        surface.destroy();
                        GlobalConfig.appearance.anim.durations.scale = 1;
                        fixture.view.progress = 0;
                        window.contentItem.forceActiveFocus();
                        fixture.view.settle();
                        break;
                    case 1:
                        root.check(fixture.view.progress === 1 && field.activeFocus, "Resume settling must restore the native field's focus without a click");
                        root.check(root.find(fixture, "lockClock").transform[0].y === 0 && root.find(fixture, "lockPasswordRow").transform[0].y === 0, "One progress value must bring the clock and password controls fully on screen");
                        root.check(fixture.events.keyClickChar("a", Qt.NoModifier, 0), "Qt must deliver a key event to the test input");
                        break;
                    case 2:
                        root.check(field.length === 1 && field.displayText === "\u2022" && fixture.testPam.buffer === "", "A real keyboard event must update the visible native mask, not a separate PAM draft");
                        window.contentItem.forceActiveFocus();
                        fixture.view.settle();
                        fixture.events.keyClickChar("a", Qt.NoModifier, 0);
                        break;
                    case 3:
                        root.check(field.length === 2 && field.displayText.length === 2 && field.activeFocus, "Repeated resume must preserve the draft and immediately accept keys without clicking");
                        fixture.testPam.state = Lock.Pam.Failed;
                        fixture.testPam.flashMsg();
                        fixture.view.unlock();
                        window.contentItem.forceActiveFocus();
                        break;
                    case 4:
                        root.check(fixture.view.unlocking && field.readOnly && field.length === 0 && fixture.exits === 1, "The exit must clear drafts, block editing and emit exactly one completion");
                        root.check(!field.activeFocus && !fixture.testLock.locked, "An exit must not steal focus or acquire a real session lock");
                        fixture.view.unlock();
                        break;
                    case 5:
                        root.check(fixture.exits === 1, "A duplicate unlock must not restart the exit or emit another completion");
                        fixture.extraView = fixture.motionView.createObject(fixture);
                        root.check(!!fixture.extraView, "A fresh animated lock view must instantiate independently of a secure surface");
                        fixture.extraView.exitFinished.connect(() => fixture.earlyExits++);
                        fixture.extraView.unlock();
                        break;
                    case 6:
                        root.check(fixture.earlyExits === 1 && fixture.extraView.progress === 0, "A fast unlock during entrance must finish without competing animations");
                        fixture.extraView.destroy();
                        GlobalConfig.appearance.anim.durations.scale = 0;
                        fixture.extraView = fixture.motionView.createObject(fixture);
                        fixture.extraView.exitFinished.connect(() => fixture.earlyExits++);
                        break;
                    case 7:
                        root.check(fixture.extraView.progress === 1, "Disabling animations must leave the new lock view fully revealed");
                        fixture.extraView.unlock();
                        break;
                    case 8:
                        root.check(fixture.earlyExits === 2 && fixture.extraView.progress === 0 && !fixture.testLock.locked, "A zero-duration exit must finish exactly once without acquiring a session lock");
                        fixture.extraView.destroy();
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "lock-input") {
                    const fixture = lockInputFixture.item;
                    const field = fixture.field;
                    switch (root.step++) {
                    case 0:
                        GlobalConfig.appearance.anim.durations.scale = 1;
                        if (Quickshell.env("LOCK_REQUIRE_NATIVE") === "1") {
                            root.check(typeof LockRenderRecovery !== "undefined", "The test must load the rebuilt native rendering helper");
                            const native = LockRenderRecovery.state(field);
                            root.check(native.supported && native.qtBuild === native.qtRuntime, "Native recovery must match the running Qt version");
                            root.check(!native.lockWindow && !LockRenderRecovery.afterResume(field) && !LockRenderRecovery.ifStalled(field), "Recovery must refuse ordinary layer-shell windows");
                            root.check(!LockRenderRecovery.afterResume(null) && !LockRenderRecovery.ifStalled(null), "Recovery must safely reject absent windows");
                        }
                        fixture.view.settle();
                        for (let i = 0; i < 4; i++)
                            root.check(fixture.events.keyClickChar("a", Qt.NoModifier, 0), "Qt must deliver native typing events");
                        break;
                    case 1:
                        root.check(field.length === 4 && field.displayText === "\u2022".repeat(4) && fixture.testPam.buffer === "", "Native password masking must be visible and PAM must not mirror the draft");
                        root.check(field.echoMode === TextInput.Password && (field.inputMethodHints & Qt.ImhSensitiveData) !== 0, "The real text input must mask passwords and disable predictive input");
                        fixture.events.keyClick(Qt.Key_Backspace, Qt.NoModifier, 0);
                        break;
                    case 2:
                        root.check(field.length === 3 && field.displayText.length === 3, "Native Backspace must update both editing and masking");
                        fixture.events.keyClick(Qt.Key_Backspace, Qt.ControlModifier, 0);
                        break;
                    case 3:
                        root.check(field.length === 0, "Ctrl+Backspace must clear the native password field");
                        GlobalConfig.appearance.anim.durations.scale = 0;
                        fixture.events.keyClickChar("x", Qt.NoModifier, 0);
                        field.insert(field.length, "é🎵");
                        break;
                    case 4:
                        root.check(field.length > 1 && field.displayText.length > 1 && field.scale > 0 && field.color.a > 0, "Unicode input and visible masking must work with animations disabled");
                        fixture.events.keyClick(Qt.Key_Return, Qt.NoModifier, 0);
                        break;
                    case 5:
                        root.check(fixture.accepted.count === 1 && !fixture.testPam.passwd.active && fixture.testPam.buffer === "" && !fixture.testLock.locked, "Enter must use the native accepted signal, but never authenticate an unsecured fixture");
                        fixture.testPam.state = Lock.Pam.MaxTries;
                        break;
                    case 6:
                        root.check(field.readOnly && fixture.view.stateMessage.msg.includes("Maximum"), "Maximum-attempt state must block native editing and display feedback");
                        fixture.testPam.state = Lock.Pam.None;
                        fixture.testPam.clearInput();
                        break;
                    case 7:
                        root.check(field.length === 0 && field.displayText.length === 0, "The shared clear signal must erase the native draft");
                        fixture.view.pam = fixture.submissionSpy;
                        fixture.events.keyClickChar("s", Qt.NoModifier, 0);
                        fixture.events.keyClick(Qt.Key_Return, Qt.NoModifier, 0);
                        break;
                    case 8:
                        root.check(fixture.submissionSpy.submissions === 1 && fixture.submissionSpy.submittedLength === 1 && field.length === 0, "Native Enter must hand the draft to the UI spy exactly once and clear the editor");
                        fixture.events.keyClickChar("t", Qt.NoModifier, 0);
                        break;
                    case 9: {
                        const button = root.find(fixture.editor, "lockSubmitButton");
                        root.check(fixture.events.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Qt must deliver a local submit-button mouse event");
                        break;
                    }
                    case 10:
                        root.check(fixture.submissionSpy.submissions === 2 && field.length === 0, "The submit button must use the same handoff as Enter");
                        fixture.submissionSpy.state = Lock.Pam.MaxTries;
                        fixture.events.keyClick(Qt.Key_Return, Qt.NoModifier, 0);
                        break;
                    case 11:
                        root.check(fixture.submissionSpy.submissions === 2 && !fixture.testLock.locked, "A max-attempt or unsecured input must not submit credentials or acquire a lock");
                        fixture.submissionSpy.state = Lock.Pam.None;
                        fixture.view.wakeTracing = true;
                        fixture.wakeTrace.resumed();
                        fixture.editor.activateInput();
                        fixture.events.keyClickChar("a", Qt.NoModifier, 0);
                        break;
                    case 12:
                        root.check(fixture.traceSamples.some(sample => sample.event === "edit-before-click"), "Opt-in tracing must observe the first key before any click");
                        // A background software-rendered test window may be
                        // occluded. Exercise the notification handler directly;
                        // this is not a claim that a GPU frame was presented.
                        fixture.wakeTrace.framePresented();
                        root.check(fixture.traceSamples.some(sample => sample.event === "frame-for-before-click"), "Tracing must correlate edit and frame notifications");
                        fixture.events.mouseClick(field, field.width / 2, field.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
                        fixture.events.keyClickChar("b", Qt.NoModifier, 0);
                        break;
                    case 13:
                        root.check(fixture.traceSamples.some(sample => sample.event === "pointer-press") && fixture.traceSamples.some(sample => sample.event === "edit-after-click"), "Passive tracing must distinguish typing before and after a click");
                        root.check(fixture.traceSamples.every(sample => !("text" in sample) && !("password" in sample) && !("length" in sample)), "Wake traces must not record credentials or password lengths");
                        fixture.view.wakeTracing = false;
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "center") {
                    const scene = fullSceneLoader.item;
                    const selector = root.find(settings, "taskbarStyle");
                    switch (root.step++) {
                    case 0:
                        GlobalConfig.bar.persistent = true;
                        Taskbar.orientation = "left";
                        selector.selected(settings.styleItems[2]);
                        break;
                    case 1:
                    case 2: {
                        root.check(Taskbar.centerOnly && selector.active === settings.styleItems[2], "Nexus must select Center notch");
                        const clockBg = root.find(scene.contentItem, "taskbarNotchClock");
                        root.check(clockBg.width > 0 && clockBg.height > 0, "Center date/time notch must have a background");
                        for (const name of ["taskbarNotchStart", "taskbarNotchStatus"]) {
                            const bg = root.find(scene.contentItem, name);
                            root.check(bg.width === 0 && bg.height === 0, "Side notch backgrounds must be absent");
                        }
                        for (const name of ["taskbarLogo", "taskbarWorkspaces", "taskbarTray", "taskbarStatusIcons"]) {
                            const widget = root.find(scene.contentItem, name);
                            root.check(widget && widget.parent.wallpaperContrast && widget.parent.layer.enabled, `${name} must remain present with wallpaper contrast enabled`);
                            root.check(widget.anchors.centerIn === widget.parent, `${name} must remain centered if its wrapper resizes`);
                            root.check(widget.color.a === 0, `${name} must not have a background pill`);
                            const center = widget.mapToItem(scene.bar, widget.width / 2, widget.height / 2);
                            root.check(Math.abs(Taskbar.horizontal ? center.y - scene.bar.height / 2 : center.x - scene.bar.width / 2) <= 1, `${name} must be centered across the taskbar`);
                        }
                        const status = root.find(scene.contentItem, "taskbarStatusIcons");
                        for (const entry of status.items.children.filter(child => child.item && child.present)) {
                            const icon = entry.item;
                            root.check(icon.anchors.centerIn === entry, `${entry.name} must stay centered within its status wrapper`);
                            const center = icon.mapToItem(scene.bar, icon.width / 2, icon.height / 2);
                            root.check(Math.abs(Taskbar.horizontal ? center.y - scene.bar.height / 2 : center.x - scene.bar.width / 2) <= 1, `${entry.name} icon must be centered across the taskbar: center=${center}, bar=${scene.bar.width}x${scene.bar.height}, item=${icon.width}x${icon.height}, wrapper=${entry.width}x${entry.height}`);
                        }
                        root.check(root.find(scene.contentItem, "taskbarClock").showDate, "Center notch must show date and time");
                        if (root.step === 2)
                            Taskbar.orientation = "top";
                        else
                            selector.selected(settings.styleItems[0]);
                        break;
                    }
                    case 3:
                        root.check(!Taskbar.centerOnly && !root.find(scene.contentItem, "taskbarStatusIcons").parent.layer.enabled, "Unified must restore normal themed rendering");
                        root.check(root.find(scene.contentItem, "taskbarStatusIcons").color.a > 0, "Unified must restore the status background");
                        Taskbar.cycleStyle();
                        root.check(Taskbar.style === "notches", "Cycling Unified must select Three notches");
                        Taskbar.cycleStyle();
                        root.check(Taskbar.style === "center", "Cycling Three notches must select Center notch");
                        Taskbar.cycleStyle();
                        root.check(Taskbar.style === "unified", "Cycling Center notch must return to Unified");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "launcher-gloss") {
                    const scene = fullSceneLoader.item;
                    const launcher = scene.interactionWrapper.panels.launcher;
                    const gloss = root.find(launcher, "launcherGloss");
                    switch (root.step) {
                    case 0:
                        scene.screenState.launcher = true;
                        break;
                    case 1:
                    case 3:
                        if ((!launcher.visible || !gloss.available || gloss.width <= 0 || gloss.height <= 0) && root.mediaWaitTicks++ < 10)
                            return;
                        root.check(launcher.visible && gloss.visible && gloss.available && gloss.width > 0 && gloss.height > 0, `Launcher gloss must be ready and visible when the launcher opens (visible=${launcher.visible}/${gloss.visible}, available=${gloss.available}, size=${gloss.width}x${gloss.height}, open=${scene.screenState.launcher})`);
                        root.check(gloss.z > 0 && gloss.opacity === 0.25 && gloss.rotation === 180, "Launcher gloss must render above content at the shared strength and correct orientation");
                        const pixel = gloss.getContext("2d").getImageData(5, Math.floor(gloss.height / 2), 1, 1).data;
                        root.check(pixel[3] > 0, "Launcher gloss must paint a nontransparent edge after opening/reopening");
                        scene.screenState.launcher = false;
                        break;
                    case 2:
                        scene.screenState.launcher = true;
                        break;
                    case 4:
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "recorder-delete") {
                    const scene = fullSceneLoader.item;
                    const card = root.find(scene.contentItem, "overviewRecorder")?.item;
                    switch (root.step) {
                    case 0:
                        scene.screenState.dashboardTab = 0;
                        scene.screenState.dashboard = true;
                        break;
                    case 1:
                        if (!card && root.mediaWaitTicks++ < 10)
                            return;
                        root.check(!!card, "Recorder card must load for isolated deletion testing");
                        card.recorder = root.recorderFixture;
                        break;
                    case 2:
                        if (!root.find(card, "recordingDelete") && root.mediaWaitTicks++ < 20)
                            return;
                        root.check(!!root.find(card, "recordingDelete"), "Disposable recording must appear in history");
                        root.find(card, "recordingDelete").clicked();
                        break;
                    case 3:
                        root.check(card.props.recordingConfirmDelete.length > 0 && root.find(card, "recordingDeleteCancel").visible, "Delete must request confirmation before removing a file");
                        root.find(card, "recordingDeleteCancel").clicked();
                        break;
                    case 4:
                        root.check(card.props.recordingConfirmDelete === "" && !!root.find(card, "recordingDelete"), "Cancel must leave the disposable recording intact");
                        root.find(card, "recordingDelete").clicked();
                        break;
                    case 5:
                        root.find(card, "recordingDelete").clicked();
                        break;
                    case 6:
                        if (root.find(card, "recordingDelete") && root.mediaWaitTicks++ < 30)
                            return;
                        root.check(card.props.recordingConfirmDelete === "" && !root.find(card, "recordingDelete"), "Confirmed deletion must remove the file and refresh the recording history");
                        const history = root.find(card, "recorderCardHistory").item;
                        const missing = `${Quickshell.env("CAELESTIA_RECORDINGS_DIR")}/missing.mp4`;
                        card.props.recordingConfirmDelete = missing;
                        history.confirmDelete(missing);
                        root.check(history.deleteError.length > 0 && card.props.recordingConfirmDelete === missing, "A deletion failure must show an error and allow retry or cancellation");
                        card.props.recordingConfirmDelete = "";
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "recorder-card") {
                    const scene = fullSceneLoader.item;
                    const card = root.find(scene.contentItem, "overviewRecorder")?.item;
                    switch (root.step) {
                    case 0:
                        scene.screenState.dashboardTab = 0;
                        scene.screenState.dashboard = true;
                        break;
                    case 1:
                        if (!card && root.mediaWaitTicks++ < 10)
                            return;
                        root.check(!!card, "Redesigned recorder card must load in Overview");
                        card.recorder = root.recorderFixture;
                        break;
                    case 2:
                        const capture = root.find(card, "recorderCardCapture");
                        root.check(capture.visible && capture.menuItems.length === 4, "Idle recorder must expose all four capture modes");
                        for (let index = 0; index < 4; index++) {
                            capture.menuItems[index].clicked();
                            root.check(JSON.stringify(root.recorderFixture.startArgs) === JSON.stringify([[], ["-r"], ["-s"], ["-sr"]][index]), "Capture mode must preserve the CLI arguments using only a mock recorder");
                        }
                        capture.menu.itemSelected(capture.menuItems[3]);
                        root.check(card.props.recordingMode === capture.menuItems[3].icon + capture.menuItems[3].text, "Capture mode selection must persist in dashboard state");
                        break;
                    case 3:
                        root.check(root.find(card, "recorderCardStatus").text === qsTr("Recording") && root.find(card, "recorderCardTimer").text === "01:15", "Running recorder must show a clear status and elapsed timer");
                        root.check(!root.find(card, "recorderCardCapture").visible && !root.find(card, "recorderCardHistory").active, "Running recorder must replace capture/history with live controls");
                        root.find(card, "recorderCardPause").clicked();
                        break;
                    case 4:
                        root.check(root.find(card, "recorderCardStatus").text === qsTr("Paused") && root.find(card, "recorderCardPause").icon === "play_arrow", "Paused recorder must offer resume");
                        root.find(card, "recorderCardPause").clicked();
                        root.check(!root.recorderFixture.paused, "Resume control must resume the mock recorder");
                        root.recorderFixture.elapsed = 3661;
                        root.find(card, "recorderCardStop").clicked();
                        break;
                    case 5:
                        root.check(!root.recorderFixture.running && root.find(card, "recorderCardCapture").visible && root.find(card, "recorderCardHistory").active, "Stop must restore capture and recordings history");
                        root.check(card.elapsedText === "1:01:01", "Recorder timer must handle recordings over one hour");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "overview") {
                    const scene = fullSceneLoader.item;
                    switch (root.step) {
                    case 0:
                        scene.screenState.dashboardTab = 0;
                        scene.screenState.dashboard = true;
                        break;
                    case 1:
                        if (!root.find(scene.contentItem, "overviewSessionControls") && root.mediaWaitTicks++ < 10)
                            return;
                        const overview = root.find(scene.contentItem, "dashboardOverview");
                        const gloss = root.find(scene.interactionWrapper.panels.dashboard, "dashboardGloss");
                        root.check(!!gloss && gloss.opacity === 0.25 && gloss.width === scene.interactionWrapper.panels.dashboard.width && gloss.height === scene.interactionWrapper.panels.dashboard.height, "Dashboard must share the island's edge-to-edge gloss and strength");
                        const profile = root.find(overview, "overviewProfileCard");
                        root.check(overview.width === Tokens.sizes.dashboard.mediaTabWidth && profile.width <= 260, "Overview must use a compact profile panel within the Media tab footprint");
                        for (const name of ["overviewAvatar", "overviewClock", "overviewUpdates", "overviewSessionControls"]) {
                            const item = root.find(profile, name);
                            root.check(!!item, `Compact profile must retain ${name}`);
                            const pos = item.mapToItem(profile, 0, 0);
                            root.check(pos.x >= 0 && pos.y >= 0 && pos.x + item.width <= profile.width + 0.01 && pos.y + item.height <= profile.height + 0.01, `${name} must fit inside the compact profile card`);
                        }
                        root.check(root.find(overview, "overviewSessionControls").children.filter(child => child.icon !== undefined).length === 5, "The minimal profile must retain all five session actions");
                        root.check(!!root.find(overview, "overviewQuickControls") && !!root.find(overview, "overviewRecorder") && !!root.find(overview, "overviewWeather"), "Overview must retain utilities, recorder and weather");
                        Weather.dataQuery = Weather.locationQuery;
                        Weather.weather = {
                            temperature: 22, feelsLike: 23, humidity: 55, windSpeed: 12,
                            code: 1, isDay: true,
                            days: [
                                { date: "2026-10-30", code: 1, high: 24, low: 16, rainChance: 10 },
                                { date: "2026-10-31", code: 2, high: 23, low: 15, rainChance: 25 },
                                { date: "2026-11-01", code: 3, high: 21, low: 14, rainChance: 30 }
                            ]
                        };
                        break;
                    case 2:
                        const weatherCard = root.find(scene.contentItem, "overviewWeather").item;
                        const forecast = root.find(weatherCard, "overviewWeatherForecast");
                        root.check(root.find(weatherCard, "overviewWeatherConditions").visible && !root.find(weatherCard, "overviewWeatherStatus").visible, "Weather must show current conditions when data is available");
                        root.check(root.find(weatherCard, "overviewWeatherTemperature").text === Weather.temperature(22), "Weather hero must show the current temperature");
                        root.check(forecast.children.filter(child => child.objectName === "overviewWeatherForecastDay").length === 3, "Weather must retain the compact three-day forecast");
                        const forecastPosition = forecast.mapToItem(weatherCard, 0, 0);
                        root.check(forecastPosition.y >= 0 && forecastPosition.y + forecast.height <= weatherCard.height, "Weather forecast must fit inside the redesigned card");
                        Weather.weather = null;
                        break;
                    case 3:
                        root.check(root.find(scene.contentItem, "overviewWeatherStatus").visible, "Weather must retain its setup and unavailable-data state");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "media-dashboard") {
                    const scene = fullSceneLoader.item;
                    switch (root.step) {
                    case 0:
                        GlobalConfig.dashboard.showMedia = true;
                        scene.screenState.dashboardTab = 0;
                        scene.screenState.dashboard = true;
                        break;
                    case 1:
                        root.check(!!root.find(scene.contentItem, "dashboardMediaEmpty"), "The redesigned Media tab must retain its empty state");
                        // Exercise layout regardless of playback availability;
                        // never click controls or change a real player's state.
                        root.find(scene.contentItem, "dashboardMediaContent").opacity = 1;
                        break;
                    case 2:
                        if (!root.find(scene.contentItem, "dashboardMediaRepeat") && root.mediaWaitTicks++ < 10)
                            return;
                        root.check(!!root.find(scene.contentItem, "dashboardMediaArtwork"), "Media tab must show rounded artwork instead of a click wheel");
                        const visualizer = root.find(scene.contentItem, "dashboardMediaVisualizer");
                        root.check(!!visualizer && visualizer.width > 0 && visualizer.height === 28 && visualizer.barCount > 2, "Media tab must show a compact spectrum beneath the artwork");
                        root.check(visualizer.playing === (Players.active?.isPlaying ?? false), "Visualizer must follow playback state");
                        const capabilities = { Shuffle: "shuffleSupported", Previous: "canGoPrevious", PlayPause: "canTogglePlaying", Next: "canGoNext", Repeat: "loopSupported" };
                        for (const name of Object.keys(capabilities)) {
                            const control = root.find(scene.contentItem, `dashboardMedia${name}`);
                            root.check(!!control && control.disabled === !Players.active?.[capabilities[name]], `${name} must respect the player's capabilities`);
                            const position = control.mapToItem(scene.interactionWrapper.panels.dashboard, 0, 0);
                            root.check(position.y >= 0 && position.y + control.height <= scene.interactionWrapper.panels.dashboard.height, `${name} must fit within the dashboard height (y=${position.y}, height=${control.height}, dashboard=${scene.interactionWrapper.panels.dashboard.height})`);
                        }
                        const artwork = root.find(scene.contentItem, "dashboardMediaArtwork");
                        root.check(scene.testEvents.mouseClick(artwork, artwork.width / 2, artwork.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Artwork click must reach the media card's Spotify scratchpad action");
                        break;
                    case 3:
                        root.check(!scene.screenState.dashboard, "Opening Spotify's scratchpad must dismiss the dashboard");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "media-island") {
                    const scene = fullSceneLoader.item;
                    const island = scene.mediaIsland;
                    switch (root.step) {
                    case 0:
                        root.check(island.displayDuration === 5000, "Media island must default to a five-second timeout");
                        Taskbar.style = "unified";
                        Taskbar.orientation = "top";
                        island.displayDuration = 850;
                        island.activeScreen = true;
                        island.fullscreen = false;
                        island.player = root.islandPlayer;
                        scene.screenState.dashboard = false;
                        break;
                    case 1:
                        root.check(island.expanded && island.visible && !scene.screenState.dashboard, "Playback must reveal only the separate island");
                        root.check(root.find(island, "mediaIslandGloss").opacity === 0.25, "Island must retain the subtle shared gloss strength");
                        const islandVisualizer = root.find(island, "mediaIslandVisualizer");
                        root.check(!!islandVisualizer && islandVisualizer.height === 12 && islandVisualizer.width > 0 && islandVisualizer.playing, "Island must show a compact live spectrum while playing");
                        const background = root.findBackground(scene.contentItem, island);
                        const dashboardBackground = root.findBackground(scene.contentItem, scene.interactionWrapper.panels.dashboard);
                        root.check(background.group === dashboardBackground.group && background.group.color === scene.surfaceColour, "Island and dashboard must share the actual shell background renderer, not separate transparent windows");
                        root.check(island.parent === scene.interactionWrapper.panels && Math.abs(island.y) < 0.01, "The island must live directly inside the shell at the dashboard entry edge");
                        root.find(island, "islandNext").clicked(null);
                        break;
                    case 2:
                        root.check(island.expanded && root.islandPlayer.trackTitle === "Second track" && !scene.screenState.dashboard, "Next track must renew the island without opening the dashboard");
                        root.find(island, "islandPlayPause").clicked(null);
                        Taskbar.style = "notches";
                        break;
                    case 3:
                        root.check(island.expanded && !root.islandPlayer.isPlaying, "Pausing must reveal the island with working playback controls");
                        root.check(!root.find(island, "mediaIslandVisualizer").playing, "Island spectrum must settle when playback pauses");
                        const islandBackground = root.findBackground(scene.contentItem, island);
                        root.check(islandBackground.y < 0 && island.hideInset === scene.interactionWrapper.panels.y, "Notched shells must bridge the island surface all the way to the screen edge");
                        break;
                    case 4:
                        root.check(!island.expanded, "The island must automatically dismiss after its timeout");
                        root.check(!root.find(island, "mediaIslandVisualizer"), "Hidden island must unload its visualizer and release its audio service reference");
                        root.islandPlayer.trackArtist = "Late artist metadata";
                        scene.screenState.dashboardTab = 1;
                        scene.screenState.dashboard = true;
                        break;
                    case 5:
                        root.check(!island.expanded, "Late artist metadata must not retrigger the island");
                        root.islandPlayer.togglePlaying();
                        break;
                    case 6:
                        root.check(!island.expanded && scene.screenState.dashboard && scene.screenState.dashboardTab === 1, "Playback events must not reveal the island or change tabs while the dashboard is open");
                        root.islandPlayer.previous();
                        break;
                    case 7:
                        root.check(!island.expanded, "Track changes must also stay suppressed while the dashboard is open");
                        scene.screenState.dashboard = false;
                        island.fullscreen = true;
                        root.check(!island.expanded, "Fullscreen must immediately dismiss the island");
                        island.fullscreen = false;
                        island.activeScreen = false;
                        root.islandPlayer.next();
                        break;
                    case 8:
                        root.check(!island.expanded, "An unfocused screen must not reveal an island");
                        island.activeScreen = true;
                        root.islandPlayer.previous();
                        break;
                    case 9:
                        root.check(island.expanded, "A fresh track event on the focused screen must reveal the island");
                        island.player = null;
                        break;
                    case 10:
                        root.check(!island.expanded && !island.visible, "Player removal must dismiss the island");
                        island.offsetScale = 0.5;
                        break;
                    case 11:
                        const playerContent = root.find(island, "mediaIslandContent");
                        root.check(Math.abs(island.width - island.fullWidth * 0.74) < 0.01 && island.opacity === 0.5, "Island must match the dashboard's centered curtain and fade halfway through the animation");
                        root.check(island.y === (-island.height - island.hideInset - 5) * 0.5, "Island must use the dashboard's slide distance with its top inset");
                        root.check(playerContent.width === island.fullWidth - 32, "Island content must remain full-sized during the reveal animation");
                        island.offsetScale = 1;
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        break;
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "attachments") {
                    const scene = fullSceneLoader.item;
                    const panels = scene.interactionWrapper.panels;
                    const popup = panels.popouts;
                    const index = Math.floor(root.step / 5);
                    const phase = root.step % 5;
                    if (index >= root.hoverCases.length) {
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }
                    const entry = root.hoverCases[index];
                    const dashBg = root.findBackground(scene.contentItem, panels.dashboard);
                    const popupBg = root.findBackground(scene.contentItem, panels.popoutsWrapper);
                    if (phase === 0) {
                        Taskbar.style = "notches";
                        Taskbar.orientation = entry.orientation;
                        GlobalConfig.bar.persistent = true;
                        GlobalConfig.dashboard.scale = index % 2 === 0 ? 60 : 140;
                        scene.screenState.dashboard = true;
                    } else if (phase === 1) {
                        const dashboard = panels.dashboard;
                        const requestedScale = index % 2 === 0 ? 0.6 : 1.4;
                        root.check(dashboard.dashboardScale > 0 && dashboard.dashboardScale <= requestedScale + 0.001, `Dashboard scale must respect the requested size and screen bounds (case=${index}, actual=${dashboard.dashboardScale}, requested=${requestedScale}, config=${GlobalConfig.dashboard.scale}, screenConfig=${GlobalConfig.forScreen(scene.screen.name).dashboard.scale})`);
                        root.check(Math.abs(dashboard.fullWidth - dashboard.naturalWidth * dashboard.dashboardScale) < 0.01, "Dashboard background and input width must follow the scaled content");
                        root.check(dashboard.fullWidth <= panels.width + 0.01 && dashboard.height <= panels.height + 0.01, "Scaled dashboard must fit inside the screen");
                        root.check(panels.dashboard.visible && dashBg.width === panels.dashboard.width, "Dashboard background must span its full width");
                        root.check(dashBg.y < 0 && dashBg.y + dashBg.height >= panels.y + panels.dashboard.y + panels.dashboard.height - 1, "Dashboard must connect directly to the shell's top edge");
                        scene.screenState.dashboard = false;
                        popup.currentName = entry.name;
                        popup.hasCurrent = true;
                    } else if (phase === 2) {
                        root.check(dashBg.width === 0 && dashBg.height === 0, "Closed dashboard must leave no ghost background");
                        root.check(panels.y + panels.dashboard.y + panels.dashboard.height <= 0, "Dashboard must slide completely past the screen edge");
                        root.check(popupBg.width > 0 && popupBg.height > 0, "Popout must have a background");
                        if (Taskbar.horizontal)
                            root.check(popupBg.y < 0 && popupBg.width === popup.width, `${entry.name}: top popout must attach to the shell across its full width`);
                        else
                            root.check(popupBg.x < 0 && popupBg.height === popup.height, `${entry.name}: left popout must attach to the shell across its full height`);
                        popup.close();
                    } else if (phase === 4) {
                        root.check(popupBg.width === 0 && popupBg.height === 0, `${entry.name}: closed popout must leave no ghost background`);
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "styles") {
                    const scene = fullSceneLoader.item;
                    const selector = root.find(settings, "taskbarStyle");
                    switch (root.step++) {
                    case 0:
                        root.check(Taskbar.style === "unified", "Unified must remain the default");
                        const unifiedStatus = root.find(scene.contentItem, "taskbarStatusIcons");
                        const unifiedEnd = unifiedStatus.mapToItem(scene.bar, unifiedStatus.width, unifiedStatus.height);
                        root.unifiedStatusInset = Taskbar.horizontal ? scene.bar.width - unifiedEnd.x : scene.bar.height - unifiedEnd.y;
                        root.check(Math.abs(root.unifiedStatusInset - Tokens.padding.large) <= 1, "Unified status icons must have an outer inset despite the legacy trailing power entry");
                        GlobalConfig.bar.clock.showDate = false;
                        selector.selected(settings.styleItems[1]);
                        root.find(settings, "taskbarCenterNotchSize").moved(320);
                        break;
                    case 1:
                    case 3: {
                        root.check(Taskbar.notched, "Nexus must switch to Three notches");
                        root.check(Taskbar.centerNotchSize === 320, "Nexus must update center notch size");
                        const realBar = scene.bar;
                        const status = root.find(scene.contentItem, "taskbarStatusIcons");
                        const statusEnd = status.mapToItem(realBar, status.width, status.height);
                        root.check(Math.abs((Taskbar.horizontal ? realBar.width - statusEnd.x : realBar.height - statusEnd.y) - root.unifiedStatusInset) <= 1, "Unified and Three notches must have identical status-group edge insets");
                        const clock = root.find(scene.contentItem, "taskbarClock");
                        root.check(clock && clock.showDate, "The center notch must show date and time");
                        root.check(!root.find(scene.contentItem, "taskbarActiveWindow"), "Notches must hide the active-window entry");
                        const center = clock.mapToItem(realBar, clock.width / 2, clock.height / 2);
                        root.check(Math.abs((Taskbar.horizontal ? center.x - realBar.width / 2 : center.y - realBar.height / 2)) < 2, "Clock notch must be centered on the screen axis");
                        const names = ["taskbarNotchStart", "taskbarNotchClock", "taskbarNotchStatus"];
                        let end = 0;
                        for (const name of names) {
                            const shape = root.find(scene.contentItem, name);
                            root.check(shape && shape.width > 0 && shape.height > 0, `${name} must have a background`);
                            const start = Taskbar.horizontal ? shape.x : shape.y;
                            root.check(start >= end, "Notch backgrounds must not overlap");
                            end = start + (Taskbar.horizontal ? shape.width : shape.height);
                            root.check(Taskbar.horizontal ? shape.y < 0 : shape.x < 0, "Each notch must extend behind the shell edge");
                            if (name === "taskbarNotchClock")
                                root.check((Taskbar.horizontal ? shape.width : shape.height) >= 319, "Center notch must honor its requested minimum length");
                        }
                        if (root.step === 2)
                            Taskbar.orientation = "top";
                        else {
                            GlobalConfig.bar.persistent = false;
                            scene.bar.isHovered = false;
                        }
                        break;
                    }
                    case 2:
                        // Allow the orientation-dependent layouts to polish.
                        break;
                    case 4:
                        root.check(!scene.bar.visible && scene.bar.notchRects.length === 0, "Auto-hide must hide the notch backgrounds too");
                        GlobalConfig.bar.persistent = true;
                        break;
                    case 5:
                        root.check(scene.bar.notchRects.length === 3, "Showing the taskbar must restore all notches");
                        root.find(settings, "taskbarCenterNotchSize").moved(1200);
                        bar.fullscreen = true;
                        break;
                    case 6: {
                        root.check(!bar.visible && bar.notchRects.length === 0, "Fullscreen must hide notches");
                        const rects = scene.bar.notchRects;
                        root.check(Taskbar.horizontal ? rects[0].x + rects[0].width < rects[1].x && rects[1].x + rects[1].width < rects[2].x : rects[0].y + rects[0].height < rects[1].y && rects[1].y + rects[1].height < rects[2].y, "An oversized center notch must leave gaps before adjacent notches");
                        root.find(settings, "taskbarCenterNotchSize").moved(320);
                        bar.fullscreen = false;
                        selector.selected(settings.styleItems[0]);
                        Taskbar.orientation = "left";
                        break;
                    }
                    case 7:
                        root.check(!Taskbar.notched && scene.bar.notchRects.length === 0, "Unified must remove the notch shapes");
                        root.check(!!root.find(scene.contentItem, "taskbarActiveWindow"), "Unified must restore the original entries");
                        root.check(!GlobalConfig.bar.clock.showDate && !root.find(scene.contentItem, "taskbarClock").showDate, "Switching styles must preserve the original date preference");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (["tint", "tint-load"].includes(Quickshell.env("TASKBAR_TEST_MODE"))) {
                    if (!ShellTint.loaded)
                        return;
                    if (Quickshell.env("TASKBAR_TEST_MODE") === "tint-load") {
                        const expected = JSON.parse(Quickshell.env("TINT_EXPECT") || '{"enabled":true,"colour":"#173f3b","strength":0.72}');
                        root.check(ShellTint.enabled === expected.enabled && ShellTint.colour === expected.colour && Math.abs(ShellTint.strength - expected.strength) < 0.0001, "Saved tint settings must restore safely");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }
                    switch (root.step++) {
                    case 0:
                        root.check(!ShellTint.enabled, "Custom tint should be off by default");
                        GlobalConfig.bar.persistent = true;
                        for (const key of Object.keys(Colours.current).filter(key => /^(m3|term[0-9])/.test(key) && !key.endsWith("Changed")))
                            root.check(Qt.colorEqual(Colours.palette[key], Colours.sourcePalette[key]), `Untinted palette must preserve ${key}`);
                        root.tintBaseline = {
                            surface: Colours.current.m3surface,
                            primary: Colours.current.m3primary,
                            secondary: Colours.current.m3secondary,
                            shadow: Colours.current.m3shadow
                        };
                        root.nexusStack = PageComponents.pageComps[0].createObject(window.contentItem, {
                            nState: root.navigationState,
                            width: 800,
                            height: 600,
                            visible: false
                        });
                        break;
                    case 1:
                        root.find(root.nexusStack.currentItem, "shellTintSettings").clicked();
                        break;
                    case 2:
                        root.check(root.nexusStack.currentItem.title === qsTr("Shell tint"), "Nexus should expose the Shell tint page");
                        root.find(root.nexusStack.currentItem, "shellTintColour").editingFinished("#173f3b");
                        root.find(root.nexusStack.currentItem, "shellTintStrength").moved(0.72);
                        break;
                    case 3: {
                        root.check(ShellTint.enabled && ShellTint.colour === "#173f3b" && ShellTint.strength === 0.72, "Nexus colour and strength edits must update the tint");
                        root.check(!Qt.colorEqual(Colours.palette.m3surface, root.tintBaseline.surface), "Tint must change the shell surface live");
                        root.check(Qt.colorEqual(Colours.current.m3surface, root.tintBaseline.surface), "Tint must not overwrite the source wallpaper palette");
                        root.check(Qt.colorEqual(Colours.palette.m3primary, root.tintBaseline.primary) && Qt.colorEqual(Colours.palette.m3secondary, root.tintBaseline.secondary), "Tint must preserve accent colours");
                        root.check(Qt.colorEqual(Colours.palette.m3shadow, root.tintBaseline.shadow), "Tint must not recolour shadows");
                        const status = root.find(window.contentItem, "taskbarStatusIcons");
                        root.check(Qt.colorEqual(status.color, Colours.tPalette.m3surfaceContainer), "Existing shell widgets should pick up the tinted palette automatically");
                        Colours.load(JSON.stringify({
                            name: "Tint test theme",
                            flavour: "test",
                            mode: "dark",
                            colours: { surface: "101820", primary: "ffb86b" }
                        }), false);
                        Colours.preview.m3surface = "#222222";
                        Colours.showPreview = true;
                        ShellTint.strength = 0;
                        break;
                    }
                    case 4:
                        root.check(Qt.colorEqual(Colours.palette.m3surface, Colours.preview.m3surface), "Zero strength should preserve wallpaper previews exactly");
                        Colours.showPreview = false;
                        ShellTint.setColour("#fff");
                        ShellTint.strength = 1;
                        break;
                    case 5:
                        root.check(ShellTint.colour === "#ffffff" && Qt.colorEqual(Colours.palette.m3surface, "#ffffff"), "Full strength should apply the selected background colour");
                        root.check(Qt.colorEqual(Colours.palette.m3primary, Colours.current.m3primary) && Colours.scheme === "Tint test theme", "Wallpaper scheme reloads should still update accents beneath the tint");
                        root.check(ShellTint.contrast(Colours.palette.m3onSurface, Colours.palette.m3surface) >= 4.5, "A light tint must retain readable foreground text");
                        root.nexusStack.currentItem.applyPreset(root.nexusStack.currentItem.presets.find(preset => preset.name === qsTr("VOID")));
                        root.check(ShellTint.colour === "#000000" && ShellTint.strength === 1, "The VOID preset should apply pure black at full strength");
                        GlobalConfig.appearance.transparency.enabled = true;
                        break;
                    case 6:
                        root.check(Number.isFinite(Colours.tPalette.m3surface.r) && Number.isFinite(Colours.tPalette.m3surfaceContainer.r), "Pure-black tint must be safe with transparency enabled");
                        root.check(Math.abs(Colours.tPalette.m3surface.a - Colours.transparency.base) < 0.01, "Tint must preserve the existing transparency setting");
                        root.find(root.nexusStack.currentItem, "shellTintRed").moved(0.5);
                        root.check(ShellTint.colour === "#800000", "RGB sliders should update the colour");
                        root.check(!ShellTint.setColour("invalid") && ShellTint.colour === "#800000", "Invalid hex input must leave the colour unchanged");
                        ShellTint.strength = 2;
                        root.check(ShellTint.strength === 1, "Strength should clamp above one");
                        ShellTint.strength = -1;
                        root.check(ShellTint.strength === 0, "Strength should clamp below zero");
                        root.find(root.nexusStack.currentItem, "shellTintReset").clicked(null);
                        break;
                    case 7:
                        root.check(!ShellTint.enabled && Qt.colorEqual(Colours.palette.m3surface, Colours.current.m3surface), "Reset must restore the wallpaper-derived palette");
                        GlobalConfig.appearance.transparency.enabled = false;
                        ShellTint.setColour("#173f3b");
                        ShellTint.strength = 0.72;
                        break;
                    case 8:
                        root.nexusStack.destroy();
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (["recorder", "recorder-load"].includes(Quickshell.env("TASKBAR_TEST_MODE"))) {
                    if (!RecorderSettings.loaded)
                        return;

                    if (Quickshell.env("TASKBAR_TEST_MODE") === "recorder-load") {
                        root.check(RecorderSettings.quality === "ultra" && RecorderSettings.codec === "h264" && RecorderSettings.frameRate === "display" && RecorderSettings.tune === "quality" && RecorderSettings.cursor, "Missing or invalid recorder settings must fall back to maximum-quality defaults");
                        root.check(RecorderSettings.unknownArgs.length === 0, "Invalid recorder args must not leak into rewritten settings");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }

                    switch (root.step++) {
                    case 0:
                        root.check(RecorderSettings.quality === "medium" && RecorderSettings.codec === "hevc", "Saved quality and codec must load");
                        root.check(RecorderSettings.frameRate === "60" && RecorderSettings.tune === "performance", "Saved frame rate and tune must load");
                        root.check(!RecorderSettings.cursor, "Saved cursor preference must load");
                        root.check(RecorderSettings.resolution === "native", "Recorder resolution must always stay native");
                        root.check(RecorderSettings.unknownArgs.join(" ") === "-bm vbr", "Unrelated recorder arguments must be preserved");
                        root.check(!RecorderSettings.isDefault, "Saved settings should differ from the maximum-quality defaults");
                        root.nexusStack = PageComponents.pageComps[PageRegistry.pages.findIndex(page => page.id === "services")].createObject(window.contentItem, {
                            nState: root.navigationState,
                            width: 800,
                            height: 600,
                            visible: false
                        });
                        break;
                    case 1:
                        root.find(root.nexusStack.currentItem, "servicesRecorder").clicked(null);
                        break;
                    case 2: {
                        const page = root.nexusStack.currentItem;
                        root.check(page.title === qsTr("Screen recorder"), "Services should open the Screen recorder page");
                        root.check(root.find(page, "recorderResolution").value === qsTr("Native (maximum)"), "The recorder page must advertise native resolution");
                        root.check(!root.find(page, "recorderReset").disabled, "Reset should be available for non-default settings");
                        root.find(page, "recorderReset").clicked(null);
                        break;
                    }
                    case 3: {
                        const page = root.nexusStack.currentItem;
                        root.check(RecorderSettings.isDefault, "Reset must restore maximum-quality defaults");
                        root.check(root.find(page, "recorderQuality").active.text === qsTr("Ultra"), "The quality selector must follow the reset");
                        root.find(page, "recorderQuality").selected(page.qualityItems[1]);
                        root.find(page, "recorderCodec").selected(page.codecItems[2]);
                        root.find(page, "recorderFrameRate").selected(page.frameRateItems[1]);
                        root.find(page, "recorderTune").selected(page.tuneItems[1]);
                        RecorderSettings.setCursor(false);
                        break;
                    }
                    case 4: {
                        const page = root.nexusStack.currentItem;
                        root.check(RecorderSettings.quality === "high" && RecorderSettings.codec === "av1" && RecorderSettings.frameRate === "30" && RecorderSettings.tune === "performance" && !RecorderSettings.cursor, "Recorder selectors and cursor toggle must update the service");
                        root.check(!root.find(page, "recorderReset").disabled, "Changed settings should enable reset");
                        root.find(page, "recorderReset").clicked(null);
                        break;
                    }
                    case 5:
                        root.check(RecorderSettings.isDefault && root.find(root.nexusStack.currentItem, "recorderCursor").checked, "Reset must restore the cursor and all defaults");
                        root.nexusStack.destroy();
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "nexus") {
                    switch (root.step++) {
                    case 0: {
                        root.check(PageRegistry.pages.length === PageComponents.pageComps.length, "Nexus navigation and page components must remain aligned");
                        root.check(!PageRegistry.pages.some(page => [qsTr("Updates"), qsTr("Plugins")].includes(page.label)), "Empty Updates and Plugins pages should be removed");
                        root.check(new Set(PageRegistry.pages.map(page => page.id)).size === PageRegistry.pages.length, "Remaining Nexus pages should have unique stable IDs");
                        const index = PageRegistry.pages.findIndex(page => page.id === "panels");
                        root.check(index >= 0, "Nexus Panels category must remain registered");
                        root.nexusStack = PageComponents.pageComps[index].createObject(window.contentItem, {
                            nState: root.navigationState,
                            width: 800,
                            height: 600,
                            visible: false
                        });
                        root.check(!!root.nexusStack, "Nexus Panels navigation stack must load");
                        break;
                    }
                    case 1: {
                        const page = root.nexusStack.currentItem;
                        root.check(page.title === qsTr("Panels"), "Panels should remain the root page");
                        const labels = page.contentChild.children.filter(child => typeof child.text === "string").map(child => child.text);
                        root.check(!labels.includes(qsTr("Notification shade")) && !labels.includes(qsTr("Utilities")), "Moved settings must not remain separate Panels entries");
                        root.find(page, "panelsTaskbar").clicked(null);
                        break;
                    }
                    case 2:
                        root.check(root.nexusStack.currentItem.title === qsTr("Taskbar"), "Taskbar navigation should open the taskbar page");
                        root.find(root.nexusStack.currentItem, "taskbarNotificationShade").clicked(null);
                        break;
                    case 3:
                        root.check(root.nexusStack.depth === 3 && root.nexusStack.currentItem.title === qsTr("Notification shade"), "Notification shade must be nested beneath Taskbar");
                        root.navigationState.closeSubPage();
                        break;
                    case 4:
                        root.check(root.nexusStack.currentItem.title === qsTr("Taskbar"), "Back from the shade should return to Taskbar");
                        root.navigationState.closeSubPage();
                        break;
                    case 5:
                        root.check(root.nexusStack.currentItem.title === qsTr("Panels"), "Back from Taskbar should return to Panels");
                        root.find(root.nexusStack.currentItem, "panelsDashboard").clicked(null);
                        break;
                    case 6:
                        root.check(root.nexusStack.currentItem.title === qsTr("Dashboard"), "Dashboard navigation should remain intact");
                        root.check(!!root.find(root.nexusStack.currentItem, "weatherDataLicense"), "Weather provider and license must remain accessible in Nexus rather than cluttering the card");
                        root.check(root.find(root.nexusStack.currentItem, "dashboardScale").value === 100, "Dashboard scale must default to 100 percent");
                        root.find(root.nexusStack.currentItem, "dashboardScale").moved(90);
                        root.check(GlobalConfig.dashboard.scale === 90, "Nexus scale control must update dashboard preferences");
                        root.find(root.nexusStack.currentItem, "dashboardUtilities").clicked(null);
                        break;
                    case 7:
                        root.check(root.nexusStack.depth === 3 && root.nexusStack.currentItem.title === qsTr("Utilities"), "Utilities must be nested beneath Dashboard");
                        root.navigationState.closeSubPage();
                        break;
                    case 8:
                        root.check(root.nexusStack.currentItem.title === qsTr("Dashboard"), "Back from Utilities should return to Dashboard");
                        root.check(root.find(root.nexusStack.currentItem, "dashboardScale").value === 90, "Dashboard scale must survive settings page navigation");
                        root.find(root.nexusStack.currentItem, "dashboardScaleReset").clicked(null);
                        root.check(GlobalConfig.dashboard.scale === 100, "Dashboard size reset must restore 100 percent");
                        root.find(root.nexusStack.currentItem, "dashboardCalendarSettings").clicked(null);
                        break;
                    case 9:
                        root.check(root.nexusStack.depth === 3 && root.nexusStack.currentItem.title === qsTr("Calendar & notes"), "Calendar settings must be nested beneath Dashboard");
                        root.check(!root.nexusStack.currentItem.contentChild.children.some(child => child.text === qsTr("Show on hover") || child.label === qsTr("Corner width")), "Calendar settings must not advertise the removed corner interactions");
                        root.navigationState.closeSubPage();
                        break;
                    case 10:
                        root.check(root.nexusStack.currentItem.title === qsTr("Dashboard"), "Back from Calendar settings should return to Dashboard");
                        root.navigationState.closeSubPage();
                        break;
                    case 11:
                        root.check(root.nexusStack.currentItem.title === qsTr("Panels"), "Back from Dashboard should return to Panels");
                        root.nexusStack.destroy();
                        root.nexusStack = PageComponents.pageComps[PageRegistry.pages.findIndex(page => page.id === "about")].createObject(window.contentItem, {
                            nState: root.navigationState,
                            width: 800,
                            height: 600,
                            visible: false
                        });
                        break;
                    case 12: {
                        const about = root.nexusStack.currentItem;
                        root.check(root.find(about, "aboutShellName").text === "Orange OS", "About should show the Orange OS name");
                        root.check(root.find(about, "aboutShellVersion").text === "AYUSH_GOAT_V4", "About should show the custom release version");
                        root.check(root.find(about, "aboutShellSoftware").value === "AYUSH_GOAT_V4", "The software version should match the About heading");
                        root.check(typeof about.pluginCount === "undefined", "The unused fake plugin counter should be removed");
                        root.nexusStack.destroy();
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "calendar") {
                    const scene = fullSceneLoader.item;
                    const interactions = scene.interactionWrapper;
                    const dashboard = interactions.panels.dashboard;
                    const calendar = root.find(scene.contentItem, "dashboardCalendar");
                    const notes = calendar ? root.find(calendar, "calendarNotes") : null;
                    if ((root.step === 1 || root.step === 14) && (!calendar || root.find(calendar, "calendarAgenda").count !== 2)) {
                        root.check(++root.calendarWaitTicks < 10, "The local iCal fixture and agenda model must finish loading");
                        return;
                    }
                    root.calendarWaitTicks = 0;
                    switch (root.step++) {
                    case 0:
                        Taskbar.orientation = "top";
                        GlobalConfig.sidebar.enabled = true;
                        GlobalConfig.sidebar.showAgenda = true;
                        GlobalConfig.sidebar.showNotes = true;
                        root.calendarIpc = calendarShortcuts.item.drawers;
                        root.check(!!root.calendarIpc, "The real drawer IPC handler must be available");
                        root.calendarIpc.setTab("calendar");
                        break;
                    case 1: {
                        root.check(!!calendar && scene.screenState.dashboard, "Named calendar IPC must open the new dashboard tab");
                        const agenda = root.find(calendar, "calendarAgenda");
                        root.check(agenda.count === 2 && GoogleCalendar.events.length === 2, "The dashboard must display all-day and timed events from the isolated local iCal fixture, excluding cancelled events");
                        root.check(root.find(calendar, "calendarRefresh").visible, "A configured calendar must retain its refresh control");
                        const timed = GoogleCalendar.events.find(event => !event.allDay);
                        calendar.now = new Date((timed.start.getTime() + timed.end.getTime()) / 2);
                        root.check(scene.testEvents.mouseClick(notes, notes.width / 2, notes.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Qt must deliver a local click into the calendar scratchpad");
                        notes.insert(0, root.calendarNote);
                        break;
                    }
                    case 2: {
                        root.check(CalendarNotes.text === root.calendarNote && dashboard.notesActive, `The dashboard must retain keyboard focus while editing the shared scratchpad (saved=${CalendarNotes.text === root.calendarNote}, open=${scene.screenState.dashboard}, selected=${calendar?.selected}, fieldFocus=${notes?.activeFocus}, fieldVisible=${notes?.visible})`);
                        const agenda = root.find(calendar, "calendarAgenda");
                        root.check(agenda.contentItem.children.some(child => child.objectName === "calendarAgendaEvent" && child.ongoing), "Current-event highlighting must survive the move into the dashboard");
                        scene.testEvents.mouseMove(interactions, interactions.width - 1, interactions.height - 1, 0, Qt.NoButton, Qt.NoModifier);
                        root.check(scene.screenState.dashboard, "Pointer departure must not close a focused notes editor");
                        root.calendarIpc.setTab("dashboard");
                        break;
                    }
                    case 3:
                        root.check(!dashboard.notesActive && CalendarNotes.text === root.calendarNote, "Switching tabs must release the notes focus without losing the draft");
                        root.calendarIpc.setTab("calendar");
                        break;
                    case 4:
                        root.check(notes.text === root.calendarNote, "The scratchpad must survive lazy tab unloading and reloading");
                        scene.screenState.dashboard = false;
                        break;
                    case 5:
                        root.check(!dashboard.visible && !calendar && CalendarNotes.text === root.calendarNote, "Closing the dashboard must unload its UI but preserve the scratchpad");
                        root.calendarIpc.toggle("utilitySidebar");
                        break;
                    case 6:
                        root.check(!!calendar && notes.text === root.calendarNote && root.calendarIpc.isOpen("utilitySidebar") === "1", "The legacy sidebar IPC name must open the Calendar tab rather than a corner panel");
                        root.calendarIpc.toggle("utilitySidebar");
                        break;
                    case 7:
                        root.check(!scene.screenState.dashboard && root.calendarIpc.isOpen("utilitySidebar") === "0", "The legacy sidebar command must toggle the Calendar tab closed");
                        root.check(typeof interactions.inUtilitySidebarCorner === "undefined" && typeof interactions.panels.utilitySidebar === "undefined", "The obsolete bottom-right trigger and separate sidebar must be removed");
                        scene.testEvents.mouseMove(interactions, interactions.width - 1, interactions.height - 1, 0, Qt.NoButton, Qt.NoModifier);
                        root.check(!scene.screenState.dashboard, "Hovering the former bottom-right corner must not reopen the calendar");
                        root.calendarIpc.setTab("calendar");
                        GlobalConfig.sidebar.showAgenda = false;
                        break;
                    case 8:
                        root.check(!root.find(calendar, "calendarAgenda").visible && notes.visible, "The existing agenda visibility preference must work in the dashboard");
                        GlobalConfig.sidebar.showAgenda = true;
                        GlobalConfig.sidebar.showNotes = false;
                        break;
                    case 9:
                        root.check(root.find(calendar, "calendarAgenda").visible && !notes.visible, "The existing notes visibility preference must remain independent of the agenda");
                        GlobalConfig.sidebar.enabled = false;
                        break;
                    case 10: {
                        const content = root.find(scene.contentItem, "dashboardContent");
                        root.check(!content.dashboardTabs.some(tab => tab.text === qsTr("Calendar")) && calendarShortcuts.item.dashboardTabIndex("calendar") === -1, "Disabling Calendar must remove it from both the tab row and named IPC mapping");
                        scene.screenState.dashboard = false;
                        root.calendarIpc.setTab("calendar");
                        root.check(!scene.screenState.dashboard, "IPC must not open a disabled Calendar tab");
                        GlobalConfig.sidebar.enabled = true;
                        GlobalConfig.sidebar.showNotes = true;
                        GlobalConfig.dashboard.showDashboard = false;
                        GlobalConfig.dashboard.showPerformance = false;
                        break;
                    }
                    case 11:
                        // Let the native per-screen configuration mirror the
                        // preference changes before invoking a named shortcut.
                        root.calendarIpc.setTab("calendar");
                        break;
                    case 12:
                        root.check(scene.screenState.dashboardTab === 1 && !!calendar && notes.text === root.calendarNote, "Calendar selection must follow the filtered tab order when other tabs are disabled");
                        GoogleCalendar._url = "";
                        GoogleCalendar._rawIcs = "";
                        break;
                    case 13:
                        root.check(root.find(calendar, "calendarAgenda").count === 0 && !root.find(calendar, "calendarRefresh").visible, "An unconfigured calendar must not display stale events or a refresh button");
                        root.check(root.find(calendar, "calendarEmptyMessage").text.includes("calendar-url"), "The unconfigured state must explain the unchanged private URL setup");
                        GoogleCalendar.refresh();
                        break;
                    case 14:
                        root.check(root.find(calendar, "calendarAgenda").count === 2, "Manual refresh must reload the original iCal source inside the dashboard");
                        scene.testEvents.mouseClick(notes, notes.width / 2, notes.height / 2, Qt.LeftButton, Qt.NoModifier, 0);
                        root.check(scene.testEvents.keyClick(Qt.Key_Escape, Qt.NoModifier, 0), "Qt must deliver Escape locally to the notes editor");
                        break;
                    case 15:
                        root.check(!scene.screenState.dashboard && CalendarNotes.text === root.calendarNote, "Escape must close the focused Calendar tab without erasing notes");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "clock-center") {
                    const index = Math.floor(root.step / 3);
                    const phase = root.step % 3;
                    if (index >= root.clockCenterCases.length) {
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }
                    const entry = root.clockCenterCases[index];
                    if (phase === 0) {
                        Taskbar.orientation = "top";
                        Taskbar.style = entry.style;
                        // Exercise synthetic monitor widths without changing
                        // the desktop's real screen geometry or input region.
                        bar.width = entry.width;
                        GlobalConfig.bar.clock.showDate = true;
                        GlobalConfig.bar.workspaces.shown = 3;
                        GlobalConfig.services.useTwelveHourClock = false;
                    } else {
                        const clock = root.find(bar, "taskbarClock");
                        const center = clock.mapToItem(bar, clock.width / 2, clock.height / 2);
                        root.check(Math.abs(center.x - entry.width / 2) < 0.001, `${entry.style}/${entry.width}: clock/date must be at the exact screen midpoint, not between unequal side groups (${center.x})`);
                        if (Taskbar.notched) {
                            const range = clock.parent.parent.notchRanges[1];
                            root.check(Math.abs(range.start + range.length / 2 - entry.width / 2) < 0.001, `${entry.style}/${entry.width}: the clock's notch background must share the exact screen midpoint`);
                        }
                        const clockLeft = center.x - clock.width / 2;
                        const clockRight = center.x + clock.width / 2;
                        for (const name of ["taskbarLogo", "taskbarWorkspaces", "taskbarActiveWindow", "taskbarTray", "taskbarStatusIcons"]) {
                            const item = root.find(bar, name);
                            if (!item)
                                continue;
                            const left = item.mapToItem(bar, 0, 0).x;
                            const right = item.mapToItem(bar, item.width, 0).x;
                            root.check(right <= clockLeft || left >= clockRight, `${entry.style}/${entry.width}: ${name} must not overlap the centered clock/date`);
                        }
                        if (phase === 1) {
                            GlobalConfig.bar.workspaces.shown = 7;
                            GlobalConfig.services.useTwelveHourClock = true;
                        } else if (index === root.clockCenterCases.length - 1) {
                            // Leave the shared isolated state in its default
                            // style before the next integration test starts.
                            Taskbar.style = "unified";
                        }
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "hover") {
                    const scene = fullSceneLoader.item;
                    const interactions = scene.interactionWrapper;
                    const panel = interactions.panels.popoutsWrapper;
                    const popup = panel.content;
                    const realBar = scene.bar;
                    const index = Math.floor(root.step / 5);
                    const phase = root.step % 5;
                    if (index >= root.hoverCases.length) {
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }
                    const entry = root.hoverCases[index];
                    if (phase === 0) {
                        popup.close();
                        if (index === 0) {
                            scene.screenState.dashboard = false;
                            GlobalConfig.dashboard.showMedia = true;
                            GlobalConfig.dashboard.showDashboard = true;
                        }
                        Taskbar.orientation = entry.orientation;
                        GlobalConfig.notifs.shadeShowOnHover = true;
                        GlobalConfig.bar.persistent = index % 2 === 0;
                        realBar.isHovered = true;
                    } else if (phase === 1) {
                        if (index === 0) {
                            // Screen-scoped Config follows GlobalConfig asynchronously.
                            const dashboard = interactions.panels.dashboard;
                            dashboard.selectDefaultTab(true);
                            root.check(scene.screenState.dashboardTab === 0, "Playing media must default to the Media tab");
                            dashboard.selectDefaultTab(false);
                            root.check(scene.screenState.dashboardTab === 1, "Paused or absent media must default to Overview");
                            GlobalConfig.dashboard.showMedia = false;
                        }
                        let icon;
                        if (entry.name === "clock" || entry.name === "notifications") {
                            icon = root.find(scene.contentItem, entry.name === "clock" ? "taskbarClock" : "taskbarNotifications");
                        } else {
                            const status = root.find(scene.contentItem, "taskbarStatusIcons");
                            icon = status.items.children.find(child => child.name === entry.name);
                        }
                        root.check(!!icon, `Missing hover-test icon ${entry.name}`);
                        if (entry.name === "clock" && realBar.horizontal) {
                            const center = icon.mapToItem(scene.contentItem, icon.width / 2, icon.height / 2);
                            root.check(Math.abs(center.x - scene.width / 2) <= 0.5, `Top clock/date must be centered on the screen in ${Taskbar.style} style: ${center.x} vs ${scene.width / 2}`);
                            for (const fraction of [0.01, 0.24, 0.26, 0.5, 0.74, 0.76, 0.99]) {
                                popup.close();
                                const point = icon.mapToItem(interactions, icon.width * fraction, icon.height / 2);
                                interactions.updatePopoutHover(point.x, point.y);
                                root.check(!popup.hasCurrent && !popup.anchorHovered, `Top clock: hovering must never open the calendar (${fraction})`);
                                root.check(!realBar.blocksDashboardHover(point.x, point.y), "The click-only top clock must not block dashboard hover");
                            }
                            GlobalConfig.dashboard.showOnHover = true;
                            const point = icon.mapToItem(interactions, icon.width / 2, icon.height / 2);
                            root.check(pointerEvents.mouseMove(icon, icon.width / 2, icon.height / 2, 0, Qt.NoButton, Qt.NoModifier), "Qt must deliver a local clock hover event");
                            if (interactions.inTopPanel(interactions.panels.dashboard, point.x, point.y))
                                root.check(scene.screenState.dashboard, "Hovering the clock inside the dashboard trigger must open the dashboard instead of the calendar");
                            for (const shouldOpen of [true, false, true]) {
                                root.check(pointerEvents.mouseClick(icon, icon.width / 2, icon.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Qt must deliver a local clock click");
                                root.check(popup.hasCurrent === shouldOpen, "Clicking the top clock must toggle the calendar");
                                if (shouldOpen)
                                    root.check(!scene.screenState.dashboard, "Opening the calendar by click must hide the dashboard");
                                else {
                                    interactions.updatePopoutHover(point.x, point.y);
                                    root.check(!popup.hasCurrent, "Hover must not reopen a calendar dismissed by click");
                                }
                            }
                            root.check(pointerEvents.mouseMove(icon, icon.width / 2 + 1, icon.height / 2, 0, Qt.NoButton, Qt.NoModifier), "Qt must deliver hover over the clicked-open calendar anchor");
                            root.check(!scene.screenState.dashboard, "Dashboard hover must not cover a calendar explicitly opened by click");
                        }
                        root.hoverAnchor = icon.mapToItem(interactions, icon.width / 2, icon.height / 2);
                        interactions.updatePopoutHover(root.hoverAnchor.x, root.hoverAnchor.y);
                        root.check(popup.hasCurrent && popup.currentName === entry.name, `${entry.orientation}/${entry.name}: popout must be open after activation`);
                        // Walk every pixel from the icon through the bar padding.
                        // The old exact-icon hit test closed the popout here.
                        const start = realBar.horizontal ? root.hoverAnchor.y : root.hoverAnchor.x;
                        for (let distance = Math.ceil(start); distance < realBar.thickness; distance++) {
                            interactions.updatePopoutHover(realBar.horizontal ? root.hoverAnchor.x : distance, realBar.horizontal ? distance : root.hoverAnchor.y);
                            root.check(popup.hasCurrent && popup.anchorHovered, `${entry.orientation}/${entry.name}: padding must retain the icon's hover`);
                        }
                    } else if (phase === 2) {
                        const point = panel.mapToItem(interactions, panel.hoverWidth / 2, panel.hoverHeight / 2);
                        interactions.updatePopoutHover(point.x, point.y);
                        root.check(popup.hasCurrent && !popup.anchorHovered && popup.pointerInHoverRegion, `${entry.orientation}/${entry.name}: hover should transfer into the panel`);
                    } else if (phase === 3) {
                        root.check(popup.hasCurrent && realBar.visible, `${entry.orientation}/${entry.name}: popout and bar must remain open over the panel`);
                        const point = panel.mapToItem(interactions, panel.hoverWidth + 80, panel.hoverHeight + 80);
                        interactions.updatePopoutHover(point.x, point.y);
                        root.check(popup.hasCurrent, `${entry.orientation}/${entry.name}: leaving should allow a short handoff grace period`);
                    } else {
                        root.check(!popup.hasCurrent, `${entry.orientation}/${entry.name}: popout should close after leaving both icon and panel`);
                        if (!GlobalConfig.bar.persistent)
                            root.check(!realBar.visible, "An auto-hidden bar should collapse after its popout closes");
                    }
                    root.step++;
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "notifications") {
                    const scene = fullSceneLoader.item;
                    const panels = scene.interactionWrapper.panels;
                    const popup = panels.popouts;
                    const realBar = scene.bar;
                    const realState = scene.screenState;
                    switch (root.step++) {
                    case 0:
                        Taskbar.orientation = "top";
                        GlobalConfig.bar.persistent = true;
                        root.sampleNotification = notificationFixture.createObject(root);
                        Notifs.list = [root.sampleNotification];
                        break;
                    case 1: {
                        root.check(panels.notifications.visible, "New-notification banner should still appear independently");
                        root.bannerPosition = panels.notifications.mapToItem(scene.contentItem, 0, 0);
                        const bell = root.find(scene.contentItem, "taskbarNotifications");
                        root.check(!!bell, "Existing bar configurations should gain a notification bell");
                        const status = root.find(scene.contentItem, "taskbarStatusIcons");
                        root.check(status.notificationIcon() === bell, "The notification bell must live inside the shared status-icon group");
                        const point = bell.mapToItem(realBar, bell.width / 2, bell.height / 2);
                        realBar.checkPopout(point.x, point.y);
                        break;
                    }
                    case 2: {
                        root.check(popup.notificationsOpen && realState.notifShade, "Hover should open the taskbar shade and synchronize drawer state");
                        root.check(!popup.notificationShortcutActive, "Hover must not grab keyboard focus");
                        root.check(!!root.find(scene.contentItem, "taskbarNotificationShade"), "The shade should render inside the shared taskbar popout");
                        const shade = root.find(scene.contentItem, "taskbarNotificationShade");
                        const shadeLayout = root.find(shade, "notificationShadeLayout");
                        root.check(shadeLayout.x === 0 && shadeLayout.y === 0 && shadeLayout.width === shade.width, "The notification shade must use shared popout padding without a second inner inset");
                        root.check(root.findBackground(scene.contentItem, panels.notifications).width === 0, "Hidden banners must not leave a ghost background in their old corner");
                        root.check(panels.popoutsWrapper.y === 0, "Top shade should attach below the taskbar");
                        const bg = root.findBackground(scene.contentItem, panels.popoutsWrapper);
                        root.check(bg.width >= popup.implicitWidth && bg.height >= popup.implicitHeight, "Shade background should cover the full content");
                        popup.close();
                        break;
                    }
                    case 3:
                        root.check(!realState.notifShade && panels.notifications.visible, "Closing the shade should restore the separate banner");
                        root.check(Notifs.notClosed.length === 1, "Opening the shade must not dismiss notification history");
                        Taskbar.orientation = "left";
                        break;
                    case 4: {
                        const bell = root.find(scene.contentItem, "taskbarNotifications");
                        const point = bell.mapToItem(realBar, bell.width / 2, bell.height / 2);
                        realBar.checkPopout(point.x, point.y);
                        break;
                    }
                    case 5:
                        root.check(popup.notificationsOpen && panels.popoutsWrapper.x === 0, "Left shade should attach to the taskbar and open rightwards");
                        root.check(Math.abs(panels.popoutsWrapper.y + panels.popoutsWrapper.height - panels.height) < 1, "Left notification shade must sit flush with the shell's inner bottom edge");
                        Notifs.list = [...Notifs.list, notificationFixture.createObject(root, {
                            notificationId: "taskbar-shade-test-2",
                            appName: "More taskbar tests",
                            popup: false
                        })];
                        break;
                    case 6:
                        root.check(Math.abs(panels.popoutsWrapper.y + panels.popoutsWrapper.height - panels.height) < 1, "Changing notification-list height must preserve the bottom attachment");
                        popup.currentName = "clock";
                        root.check(!realState.notifShade, "Switching to another popout must clear notification-shade state");
                        GlobalConfig.notifs.shadeEnabled = false;
                        break;
                    case 7:
                        root.check(!root.find(scene.contentItem, "taskbarNotifications"), "Disabling the shade should hide its taskbar bell");
                        GlobalConfig.notifs.shadeEnabled = true;
                        GlobalConfig.notifs.shadeShowOnHover = false;
                        popup.close();
                        break;
                    case 8: {
                        const bell = root.find(scene.contentItem, "taskbarNotifications");
                        const point = bell.mapToItem(realBar, bell.width / 2, bell.height / 2);
                        realBar.checkPopout(point.x, point.y);
                        root.check(!popup.notificationsOpen, "Disabling hover should leave the shade closed on hover");
                        realState.notifShade = true;
                        break;
                    }
                    case 9:
                        root.check(popup.notificationsOpen && popup.notificationShortcutActive, `Drawer IPC should open and pin the taskbar shade: open=${popup.notificationsOpen}, pin=${popup.notificationShortcutActive}, current=${popup.currentName}, hasCurrent=${popup.hasCurrent}, state=${realState.notifShade}`);
                        realState.notifShade = false;
                        GlobalConfig.bar.persistent = false;
                        realBar.isHovered = false;
                        break;
                    case 10:
                        root.check(!popup.notificationsOpen && !realBar.visible, "Closing a pinned shade should allow auto-hide again");
                        realState.notifShade = true;
                        break;
                    case 11:
                        root.check(popup.notificationsOpen && realBar.visible, "Opening via drawer IPC should reveal an auto-hidden taskbar");
                        realState.notifShade = false;
                        Taskbar.orientation = "top";
                        GlobalConfig.bar.persistent = true;
                        break;
                    case 12:
                        root.check(typeof scene.interactionWrapper.inNotifShadeCorner === "undefined", "The obsolete screen-corner trigger must be removed");
                        root.check(panels.notifications.visible, "New-notification banners should remain available after using the taskbar shade");
                        const position = panels.notifications.mapToItem(scene.contentItem, 0, 0);
                        root.check(position.x === root.bannerPosition.x && position.y === root.bannerPosition.y, "Banner placement must not move to the taskbar");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                    }
                    return;
                }

                if (Quickshell.env("TASKBAR_TEST_MODE") === "background") {
                    const scene = fullSceneLoader.item;
                    const panels = scene.interactionWrapper.panels;
                    const popup = panels.popouts;
                    if (root.step === 0) {
                        Taskbar.orientation = "top";
                    } else if (root.step === 1) {
                        popup.currentName = "clock";
                        popup.hasCurrent = true;
                    } else if (root.step === 5) {
                        popup.currentName = "clock";
                        popup.hasCurrent = true;
                    } else {
                        const bg = root.findBackground(scene.contentItem, panels.popoutsWrapper);
                        console.log(`BACKGROUND ${popup.currentName}: ${bg.width}x${bg.height}; content ${popup.width}x${popup.height}; implicit ${popup.implicitWidth}x${popup.implicitHeight}; current ${popup.current?.width}x${popup.current?.height}`);
                        root.check(popup.width >= popup.implicitWidth, "Popout wrapper is stuck narrower than its intrinsic content width");
                        root.check(popup.height >= popup.implicitHeight, "Popout wrapper is stuck shorter than its intrinsic content height");
                        root.check(bg.width >= popup.implicitWidth, "Popout background is narrower than its intrinsic content width");
                        root.check(bg.height >= popup.implicitHeight, "Popout background is shorter than its intrinsic content height");
                        if (root.step === 2 || root.step === 6) {
                            popup.currentName = "audio";
                        } else if (root.step === 3 || root.step === 7) {
                            popup.currentName = "network";
                        } else if (root.step === 4) {
                            Taskbar.orientation = "left";
                        } else {
                            console.log("TASKBAR TEST PASS");
                            Qt.quit();
                        }
                    }
                    root.step++;
                    return;
                }

                switch (root.step++) {
                case 0:
                    root.check(Taskbar.orientation === Quickshell.env("TASKBAR_EXPECT_INITIAL"), "Initial orientation/default is incorrect");
                    if (Quickshell.env("TASKBAR_TEST_MODE") === "load") {
                        root.check(Taskbar.style === (Quickshell.env("TASKBAR_EXPECT_STYLE") || "unified"), "Initial style/default is incorrect");
                        root.check(Taskbar.centerNotchSize === Number(Quickshell.env("TASKBAR_EXPECT_NOTCH_SIZE") || "0"), "Center notch size must restore safely");
                        console.log("TASKBAR TEST PASS");
                        Qt.quit();
                        return;
                    }
                    root.find(settings, "taskbarOrientation").selected(settings.orientationItems[0]);
                    break;
                case 1:
                    root.check(!bar.horizontal && bar.width === bar.contentWidth && bar.height === window.height, "Left bar geometry is incorrect");
                    root.check(panelArea.x === bar.thickness && panelArea.y === GlobalConfig.border.thickness, "Left panel insets are incorrect");
                    root.check(root.find(window.contentItem, "taskbarClock").implicitHeight > root.find(window.contentItem, "taskbarClock").implicitWidth, "Left clock should be vertical");
                    root.find(settings, "taskbarOrientation").selected(settings.orientationItems[1]);
                    break;
                case 2: {
                    root.check(bar.horizontal && bar.width === window.width && bar.height === bar.contentWidth, `Top bar geometry is incorrect: ${bar.width}x${bar.height}, window ${window.width}x${window.height}, thickness ${bar.thickness}, expected ${bar.contentWidth}`);
                    root.check(panelArea.y === bar.thickness && panelArea.x === GlobalConfig.border.thickness, "Top panel insets are incorrect");
                    for (const name of ["taskbarClock", "taskbarWorkspaces", "taskbarActiveWindow", "taskbarStatusIcons"]) {
                        const widget = root.find(window.contentItem, name);
                        root.check(!!widget && widget.implicitWidth > widget.implicitHeight, `${name} should be horizontal: ${widget?.implicitWidth}x${widget?.implicitHeight}, horizontal ${widget?.horizontal}`);
                        root.check(widget.width >= widget.implicitWidth, `${name}'s background must cover its intrinsic width`);
                    }
                    const clock = root.find(window.contentItem, "taskbarClock");
                    const point = clock.mapToItem(bar, clock.width / 2, clock.height / 2);
                    root.check(Math.abs(point.x - bar.width / 2) <= 0.5, `Top clock/date must be exactly screen-centered: ${point.x} vs ${bar.width / 2}`);
                    root.check(!bar.blocksDashboardHover(point.x, 0), "The click-only top clock must leave screen-edge dashboard hover available");
                    root.check(root.find(settings, "taskbarOrientation").active === settings.orientationItems[1], "Nexus should show Top as selected");
                    const status = root.find(window.contentItem, "taskbarStatusIcons");
                    const bluetooth = status.items.children.find(child => child.name === "bluetooth")?.item;
                    root.check(bluetooth && bluetooth.layout.rows === 1, "Top Bluetooth devices must form one row in Unified style, not stack vertically");
                    root.check(bluetooth.height <= status.height, "Top status pill must fit the Bluetooth row");
                    const tray = root.find(window.contentItem, "taskbarTray");
                    root.check(tray.nonAnimHeight >= tray.layout.implicitHeight, "Top tray must reserve enough height for its icons");
                    if (tray.layout.implicitHeight > 0)
                        root.check(tray.layout.y >= 0 && tray.layout.y + tray.layout.height <= tray.height + 1, "Top tray icons must stay inside their clip after rotating");
                    root.check(status.parent.Layout.rightMargin === Tokens.padding.large, "Unified status icons must have trailing padding even with an unsupported power entry");
                    root.check(Math.abs(bar.width - status.mapToItem(bar, status.width, 0).x - Tokens.padding.large) <= 1, "Unified status icons must not stick to the screen's right edge");
                    bar.checkPopout(point.x, point.y);
                    root.check(!popouts.content.hasCurrent, "Hovering the top clock must leave the calendar closed");
                    root.check(pointerEvents.mouseClick(clock, clock.width / 2, clock.height / 2, Qt.LeftButton, Qt.NoModifier, 0), "Qt must deliver a local clock click");
                    break;
                }
                case 3:
                    root.check(popouts.content.hasCurrent && popouts.content.currentName === "clock", "Clicking the top clock did not open its popout");
                    root.check(popouts.y === 0 && popouts.height > 0, "Top popout should expand downwards");
                    root.check(popouts.x >= 0 && popouts.x + popouts.width <= panelArea.width, "Top popout should stay within the screen");
                    popouts.content.close();
                    GlobalConfig.bar.persistent = false;
                    break;
                case 4:
                    root.check(bar.height === GlobalConfig.border.thickness && !bar.visible, "Hidden top bar should collapse to the border");
                    bar.isHovered = true;
                    break;
                case 5:
                    root.check(bar.visible && bar.height === bar.contentWidth, "Hover should reveal the top bar");
                    bar.fullscreen = true;
                    break;
                case 6:
                    root.check(bar.thickness === 0 && !bar.visible, "Fullscreen should hide the bar");
                    bar.fullscreen = false;
                    GlobalConfig.bar.persistent = true;
                    Taskbar.orientation = "left";
                    break;
                case 7: {
                    root.check(!popouts.content.hasCurrent, "Changing orientation should dismiss stale popouts");
                    const battery = root.find(window.contentItem, "taskbarBatteryStatus");
                    const glyph = root.find(battery, "taskbarBatteryGlyph");
                    const percentage = root.find(battery, "taskbarBatteryPercentage");
                    root.check(Math.abs(glyph.x + glyph.width / 2 - battery.width / 2) < 1 && glyph.y === 0, "Battery glyph must recenter after Top → Left without restarting");
                    if (percentage.visible) {
                        root.check(Math.abs(percentage.x + percentage.width / 2 - battery.width / 2) < 1 && percentage.y === glyph.height, "Battery percentage must move below its glyph after Top → Left");
                        root.check(battery.width >= percentage.width, "Vertical battery must fit the percentage width");
                    }
                    const clock = root.find(window.contentItem, "taskbarClock");
                    const point = clock.mapToItem(bar, clock.width / 2, clock.height / 2);
                    bar.checkPopout(point.x, point.y);
                    break;
                }
                case 8:
                    root.check(popouts.content.hasCurrent && popouts.width > 0 && popouts.x === 0, "Left popout should expand rightwards");
                    root.check(popouts.y >= 0 && popouts.y + popouts.height <= panelArea.height, "Left popout should stay within the screen");
                    Taskbar.orientation = "invalid";
                    root.check(Taskbar.orientation === "left", "Invalid orientation should fall back to Left");
                    Taskbar.orientation = "top";
                    break;
                default:
                    console.log("TASKBAR TEST PASS");
                    Qt.quit();
                }
            } catch (error) {
                console.error(`TASKBAR TEST FAIL: ${error.message}`);
                Qt.quit();
            }
        }
    }
}
