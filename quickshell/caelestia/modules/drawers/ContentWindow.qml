pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property ScreenState screenState: ShellState.forScreen(screen)

    readonly property HyprlandMonitor monitor: Hypr.monitorFor(screen)
    readonly property bool hasSpecialWorkspace: (monitor?.lastIpcObject.specialWorkspace?.name.length ?? 0) > 0
    readonly property bool hasFullscreenOnNormalWs: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
    readonly property bool hasFullscreen: {
        if (hasSpecialWorkspace) {
            const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
            if (!specialName)
                return false;
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return hasFullscreenOnNormalWs;
    }

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg // SDFs joins are not exact, so offset by 2px to ensure nothing shows
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: {
        if (focusGrab.active || panels.popouts.isDetached)
            return 0;

        if (monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace?.lastIpcObject.windows > 0)
            return 0;

        const thresholds = [];
        for (const panel of ["dashboard", "launcher", "session"])
            if (contentItem.Config[panel].enabled)
                thresholds.push(contentItem.Config[panel].dragThreshold);
        return Math.max(...thresholds);
    }

    onHasFullscreenChanged: {
        screenState.launcher = false;
        screenState.session = false;
        screenState.dashboard = false;
        screenState.notifShade = false;
        screenState.utilitySidebar = false;
        panels.popouts.close();
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: (fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen) || (hasSpecialWorkspace && hasFullscreenOnNormalWs) ? WlrLayer.Overlay : WlrLayer.Top
    // OnDemand lets the notes field take keyboard focus on click without
    // stealing it when the sidebar is merely hovered open
    WlrLayershell.keyboardFocus: screenState.launcher || screenState.session || screenState.dashboard || screenState.utilitySidebar ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : regions

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + panels.x
        y: panels.notifications.y + panels.y
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + panels.y
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
            height: panels.osd.height
        }
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: {
            const s = root.screenState;
            const conf = root.contentItem.Config;
            if ((s.launcher && conf.launcher.enabled) || (s.session && conf.session.enabled))
                return true;
            if (!conf.dashboard.showOnHover && s.dashboard && conf.dashboard.enabled)
                return true;
            // Same for the sidebar, which hosts the notes text field
            if (s.utilitySidebar && conf.sidebar.enabled && interactionWrapper.utilityShortcutActive)
                return true;
            if (panels.popouts.currentName.startsWith("traymenu") && (panels.popouts.current as StackView)?.depth > 1)
                return true;
            return false;
        }
        windows: [root]
        onCleared: {
            root.screenState.launcher = false;
            root.screenState.session = false;
            root.screenState.dashboard = false;
            root.screenState.notifShade = false;
            root.screenState.utilitySidebar = false;
            panels.popouts.hasCurrent = false;
            bar.closeTray();
        }
    }

    StyledRect {
        anchors.fill: parent
        // Hover popouts stay undimmed; only session and detached panels need a scrim.
        opacity: (root.screenState.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            objectName: "taskbarShellBorder"
            anchors.fill: parent
            anchors.margins: -50 // Make border thicker to smooth out bulge from closed drawers
            group: blobGroup
            radius: root.borderRounding
            borderLeft: (bar.notched ? root.borderThickness : panels.x) - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: (bar.notched ? root.borderThickness : panels.y) - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        Repeater {
            model: 3

            BlobRect {
                required property int index
                readonly property rect bounds: bar.notchRects[index] ?? Qt.rect(0, 0, 0, 0)

                objectName: ["taskbarNotchStart", "taskbarNotchClock", "taskbarNotchStatus"][index]
                group: blobGroup
                // Extend behind the outer border to keep the notch attached and
                // its outer edge flat, with rounded corners facing the desktop.
                x: bar.horizontal ? bounds.x : -root.borderRounding
                y: bar.horizontal ? -root.borderRounding : bounds.y
                width: bounds.width > 0 ? bounds.width + (bar.horizontal ? 0 : root.borderRounding) : 0
                height: bounds.height > 0 ? bounds.height + (bar.horizontal ? root.borderRounding : 0) : 0
                radius: root.borderRounding
            }
        }

        PanelBg {
            id: dashBg

            panel: panels.dashboard
            deformAmount: 0.1
            // In notch mode the full-width bar no longer bridges this gap.
            // Continue the dashboard's own surface behind the shell's top edge,
            // across its whole width, rather than hanging it from the clock.
            y: bar.notched ? -root.borderRounding : panel.y + panels.y
            implicitWidth: panel.visible ? panel.width : 0
            implicitHeight: {
                if (!panel.visible)
                    return 0;
                if (!bar.notched)
                    return panel.height;
                const bottom = panel.y + panels.y + panel.height;
                return bottom > 0 ? bottom - y : 0;
            }
        }

        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.session.x + panels.x
            implicitWidth: panels.session.width
        }

        PanelBg {
            id: osdBg

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + panels.x
            implicitWidth: panels.osd.width
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
            // The taskbar shade hides banners without deleting their popup state.
            // Hide their separate surface too, rather than leaving a ghost panel.
            implicitWidth: panels.notifications.visible ? panels.notifications.width : 0
            implicitHeight: panels.notifications.visible ? panels.notifications.height : 0
        }

        PanelBg {
            id: utilitySidebarBg

            panel: panels.utilitySidebar
        }

        PanelBg {
            id: popoutBg

            readonly property bool shellAttached: bar.notched && !panels.popouts.isDetached
            readonly property real contentX: panels.x + panels.popoutsWrapper.x + panels.popouts.x
            readonly property real contentY: panels.y + panels.popoutsWrapper.y + panels.popouts.y
            // Overlap the bar edge so movement deformation cannot detach the popout.
            property real extraSize: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: shellAttached && !bar.horizontal ? -root.borderRounding : contentX - (bar.horizontal ? 0 : panels.popouts.width * extraSize)
            y: shellAttached && bar.horizontal ? -root.borderRounding : contentY - (bar.horizontal ? panels.popouts.height * extraSize : 0)
            implicitWidth: {
                if (!panel.visible)
                    return 0;
                if (!shellAttached)
                    return panels.popouts.width * (1 + (bar.horizontal ? 0 : extraSize));
                const right = contentX + panels.popouts.width;
                return bar.horizontal ? panels.popouts.width : right > 0 ? right - x : 0;
            }
            implicitHeight: {
                if (!panel.visible)
                    return 0;
                if (!shellAttached)
                    return panels.popouts.height * (1 + (bar.horizontal ? extraSize : 0));
                const bottom = contentY + panels.popouts.height;
                return bar.horizontal ? (bottom > 0 ? bottom - y : 0) : panels.popouts.height;
            }

            Behavior on extraSize {
                Anim {}
            }
        }
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        screenState: root.screenState
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            screenState: root.screenState
            bar: bar
            borderThickness: root.borderThickness

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilitySidebar.transform: Matrix4x4 {
                matrix: utilitySidebarBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.left: parent.left

            screen: root.screen
            screenState: root.screenState
            popouts: panels.popouts

            fullscreen: root.hasFullscreen
        }

        // Hover-only target above the bar, so it still works when the bar handles pointer input.
        Item {
            id: overviewCorner

            anchors.top: parent.top
            anchors.left: parent.left
            width: HotCorner.width
            height: HotCorner.width
            visible: HotCorner.enabled && !root.hasFullscreen

            HoverHandler {
                id: overviewHover

                onHoveredChanged: {
                    if (hovered)
                        overviewTimer.start();
                    else
                        overviewTimer.stop();
                }
            }

            Timer {
                id: overviewTimer

                interval: HotCorner.interval
                onTriggered: {
                    if (HotCorner.enabled && !root.hasFullscreen && overviewHover.hovered)
                        Hypr.dispatch('hl.plugin.scrolloverview.overview("toggle all")');
                }
            }
        }
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "rootWindow"
        component: root
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "interactionWrapper"
        component: interactions
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "bar"
        component: bar
    }

    ShellState.ComponentRef {
        screen: root.screen
        slot: "panels"
        component: panels
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: panel.x + panels.x
        y: panel.y + panels.y
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
