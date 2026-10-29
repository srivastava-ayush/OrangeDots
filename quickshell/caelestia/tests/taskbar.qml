pragma ComponentBehavior: Bound

import QtQuick
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
        active: ["background", "notifications", "hover"].includes(Quickshell.env("TASKBAR_TEST_MODE"))
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
        interval: Quickshell.env("TASKBAR_TEST_MODE") === "hover" ? 300 : 700
        running: true
        repeat: true

        onTriggered: {
            try {
                if (!Taskbar.loaded)
                    return;

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
