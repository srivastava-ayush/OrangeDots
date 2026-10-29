pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.bar
import qs.modules.bar.popouts as BarPopouts
import qs.modules.nexus
import qs.modules.nexus.pages.panels
import qs.modules.drawers

// Transparent, input-free test surface. taskbar.test.py isolates all settings
// and removes the Hyprland IPC connection, so the desktop is left unchanged.
ShellRoot {
    id: root

    property int step
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
    property point hoverAnchor
    property var nexusStack
    property var tintBaseline
    property real unifiedStatusInset
    readonly property NexusState navigationState: NexusState {
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

    Loader {
        id: fullSceneLoader
        active: ["background", "notifications", "hover", "styles", "attachments", "center"].includes(Quickshell.env("TASKBAR_TEST_MODE"))
        sourceComponent: ContentWindow {
            screen: window.screen
            contentItem.opacity: 0.001
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
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

            BarPopouts.ClipWrapper {
                id: popouts

                screen: window.screen
                screenState: state
                borderThickness: GlobalConfig.border.thickness
                horizontal: Taskbar.horizontal
            }
        }

        BarWrapper {
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
            nState: NexusState {
                screen: window.screen
            }
        }
    }

    Timer {
        interval: ["hover", "attachments"].includes(Quickshell.env("TASKBAR_TEST_MODE")) ? 300 : 700
        running: true
        repeat: true

        onTriggered: {
            try {
                if (!Taskbar.loaded)
                    return;

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
                        scene.screenState.dashboard = true;
                    } else if (phase === 1) {
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
                        root.nexusStack = PageCompRegistry.pageComps[0].createObject(window.contentItem, {
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
                        root.nexusStack = PageCompRegistry.pageComps[PageRegistry.pages.findIndex(page => page.id === "services")].createObject(window.contentItem, {
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
                        root.check(PageRegistry.pages.length === PageCompRegistry.pageComps.length, "Nexus navigation and page components must remain aligned");
                        root.check(!PageRegistry.pages.some(page => [qsTr("Updates"), qsTr("Plugins")].includes(page.label)), "Empty Updates and Plugins pages should be removed");
                        root.check(new Set(PageRegistry.pages.map(page => page.id)).size === PageRegistry.pages.length, "Remaining Nexus pages should have unique stable IDs");
                        const index = PageRegistry.pages.findIndex(page => page.id === "panels");
                        root.check(index >= 0, "Nexus Panels category must remain registered");
                        root.nexusStack = PageCompRegistry.pageComps[index].createObject(window.contentItem, {
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
                        root.find(root.nexusStack.currentItem, "dashboardUtilities").clicked(null);
                        break;
                    case 7:
                        root.check(root.nexusStack.depth === 3 && root.nexusStack.currentItem.title === qsTr("Utilities"), "Utilities must be nested beneath Dashboard");
                        root.navigationState.closeSubPage();
                        break;
                    case 8:
                        root.check(root.nexusStack.currentItem.title === qsTr("Dashboard"), "Back from Utilities should return to Dashboard");
                        root.navigationState.closeSubPage();
                        break;
                    case 9:
                        root.check(root.nexusStack.currentItem.title === qsTr("Panels"), "Back from Dashboard should return to Panels");
                        root.nexusStack.destroy();
                        root.nexusStack = PageCompRegistry.pageComps[PageRegistry.pages.findIndex(page => page.id === "about")].createObject(window.contentItem, {
                            nState: root.navigationState,
                            width: 800,
                            height: 600,
                            visible: false
                        });
                        break;
                    case 10: {
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
                        Taskbar.orientation = entry.orientation;
                        GlobalConfig.notifs.shadeShowOnHover = true;
                        GlobalConfig.bar.persistent = index % 2 === 0;
                        realBar.isHovered = true;
                    } else if (phase === 1) {
                        let icon;
                        if (entry.name === "clock" || entry.name === "notifications") {
                            icon = root.find(scene.contentItem, entry.name === "clock" ? "taskbarClock" : "taskbarNotifications");
                        } else {
                            const status = root.find(scene.contentItem, "taskbarStatusIcons");
                            icon = status.items.children.find(child => child.name === entry.name);
                        }
                        root.check(!!icon, `Missing hover-test icon ${entry.name}`);
                        root.hoverAnchor = icon.mapToItem(interactions, icon.width / 2, icon.height / 2);
                        interactions.updatePopoutHover(root.hoverAnchor.x, root.hoverAnchor.y);
                        root.check(popup.hasCurrent && popup.currentName === entry.name, `${entry.orientation}/${entry.name}: icon should open its popout`);
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
                    root.check(bar.hasEntryAt(point.x, 0), "Top clock's column should take priority over screen-edge hover panels");
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
                    break;
                }
                case 3:
                    root.check(popouts.content.hasCurrent && popouts.content.currentName === "clock", "Top clock hit testing did not open its popout");
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
