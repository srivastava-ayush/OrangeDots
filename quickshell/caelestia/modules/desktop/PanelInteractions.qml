import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.taskbar as Bar
import qs.modules.taskbar.popouts as BarPopouts

CustomMouseArea {
    id: root

    required property ShellScreen screen
    required property BarPopouts.PopoutWrapper popouts
    required property ScreenState screenState
    required property PanelLayout panels
    required property Bar.TaskbarWrapper bar
    required property real borderThickness
    required property bool fullscreen

    property point dragStart
    property bool dashboardShortcutActive
    property bool osdShortcutActive
    property bool launcherShortcutActive
    readonly property bool mediaPlaying: Players.active?.isPlaying ?? false

    function inBarPopout(x: real, y: real): bool {
        if (!popouts.hasCurrent || popouts.isDetached)
            return false;
        const panel = panels.popoutsWrapper;
        const pos = panel.mapFromItem(root, x, y);
        return pos.x >= 0 && pos.y >= panel.hoverY && pos.x <= panel.hoverWidth && pos.y <= panel.hoverY + panel.hoverHeight;
    }

    function updatePopoutHover(x: real, y: real): void {
        if (popouts.isDetached || popouts.notificationShortcutActive) {
            popouts.cancelHoverIntent();
            return;
        }
        const inBar = bar.horizontal ? y < bar.thickness : x < bar.thickness;
        const inPopup = inBarPopout(x, y);
        popouts.pointerInHoverRegion = inPopup;
        if (inBar) {
            bar.checkPopout(x, y);
        } else {
            popouts.cancelHoverIntent();
            popouts.anchorHovered = false;
            if (inPopup)
                popouts.cancelClose();
            else
                popouts.scheduleClose();
        }
        bar.isHovered = Config.bar.showOnHover && !Config.bar.persistent && !screenState.bar && (inBar || inPopup);
    }

    Connections {
        target: root.popouts

        function onHoverClosed(): void {
            root.bar.closeTray();
        }
    }

    function withinPanelHeight(panel: Item, x: real, y: real): bool {
        const panelY = panels.y + panel.y;
        return y >= panelY - Config.border.rounding && y <= panelY + panel.height + Config.border.rounding;
    }

    function withinPanelWidth(panel: Item, x: real, y: real): bool {
        const panelX = panels.x + panel.x;
        // The dashboard's closed-state edge strip can extend below the bar inset,
        // so include its configured height in the widened top target.
        if (panel === panels.dashboard && y <= Math.max(Config.border.minThickness, panels.y, panels.dashboard.hoverHeight)) {
            const center = panelX + panel.width / 2;
            return Math.abs(x - center) <= panels.dashboard.hoverWidth / 2 + Config.border.rounding;
        }
        return x >= panelX - Config.border.rounding && x <= panelX + panel.width + Config.border.rounding;
    }

    function inLeftPanel(panel: Item, x: real, y: real): bool {
        return x < panels.x + panel.x + panel.width && withinPanelHeight(panel, x, y);
    }

    function inRightPanel(panel: Item, x: real, y: real): bool {
        return x > Math.min(width - Config.border.minThickness, panels.x + panel.x) && withinPanelHeight(panel, x, y);
    }

    function inTopPanel(panel: Item, x: real, y: real): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        // When the dashboard is closed, only the configured top strip triggers it.
        // Once it starts opening, the revealed panel keeps the hover target alive.
        const bottom = panel === panels.dashboard ? (panelHeight > 0 ? Math.max(panels.dashboard.hoverHeight, panels.y + panelHeight) : panels.dashboard.hoverHeight) : panels.y + panelHeight;
        return y < Math.max(Config.border.minThickness, bottom) && withinPanelWidth(panel, x, y);
    }

    function inBottomPanel(panel: Item, x: real, y: real, isCorner = false): bool {
        const panelHeight = panel.height * (1 - (panel.offsetScale ?? 0)); // qmllint disable missing-property
        return y > height - Math.max(Config.border.minThickness, Config.border.thickness + panelHeight) - (isCorner ? Config.border.rounding : 0) && withinPanelWidth(panel, x, y);
    }

    function onWheel(event: WheelEvent): void {
        if (fullscreen)
            return;
        if (bar.horizontal ? event.y < bar.thickness : event.x < bar.thickness) {
            bar.handleWheel(event.x, event.y, event.angleDelta);
        }
    }

    anchors.fill: parent
    acceptedButtons: fullscreen ? Qt.NoButton : Qt.AllButtons
    hoverEnabled: true

    onPressed: event => {
        dragStart = Qt.point(event.x, event.y);
        if (screenState.session) {
            const panel = panels.session;
            const point = panel.mapFromItem(root, event.x, event.y);
            if (point.x < 0 || point.y < 0 || point.x > panel.width || point.y > panel.height) {
                screenState.session = false;
                return;
            }
        }
    }
    onContainsMouseChanged: {
        if (!containsMouse) {
            // Only hide if not activated by shortcut
            if (!osdShortcutActive) {
                screenState.osd = false;
                root.panels.osd.hovered = false;
            }

            if (!dashboardShortcutActive && !root.panels.dashboard.notesActive)
                screenState.dashboard = false;

            // Only hide the launcher if not opened by keyboard/drag/IPC
            if (!launcherShortcutActive)
                screenState.launcher = false;

            popouts.anchorHovered = false;
            popouts.pointerInHoverRegion = false;
            popouts.scheduleClose();

            bar.isHovered = false;
        }
    }

    onPositionChanged: event => {
        if (popouts.isDetached || popouts.notificationShortcutActive) {
            bar.isHovered = false;
            return;
        }

        const x = event.x;
        const y = event.y;
        const dragX = x - dragStart.x;
        const dragY = y - dragStart.y;

        if (fullscreen) {
            root.panels.osd.hovered = inRightPanel(panels.osdWrapper, x, y);
            return;
        }

        // Track both entering and leaving the bar while the pointer stays in this window.
        const inBar = bar.horizontal ? y < bar.clampedHeight : x < bar.clampedWidth;
        const inPopup = inBarPopout(x, y);
        bar.isHovered = Config.bar.showOnHover && !Config.bar.persistent && !screenState.bar && (inBar || inPopup);

        // Show/hide bar on drag
        const dragFromBar = bar.horizontal ? dragStart.y < bar.clampedHeight : dragStart.x < bar.clampedWidth;
        const barDrag = bar.horizontal ? dragY : dragX;
        if (pressed && dragFromBar) {
            if (barDrag > Config.bar.dragThreshold)
                screenState.bar = true;
            else if (barDrag < -Config.bar.dragThreshold)
                screenState.bar = false;
        }

        // Show osd on hover
        const showOsd = !screenState.ai && inRightPanel(panels.osdWrapper, x, y);

        // Always update visibility based on hover if not in shortcut mode
        if (!osdShortcutActive) {
            screenState.osd = showOsd;
            root.panels.osd.hovered = showOsd;
        } else if (showOsd) {
            // If hovering over OSD area while in shortcut mode, transition to hover control
            osdShortcutActive = false;
            root.panels.osd.hovered = true;
        }

        // The right edge opens the modular sidebar, not the session menu.
        if (SidebarConfig.layout.enabled && pressed && inRightPanel(panels.sidebar, dragStart.x, dragStart.y) && withinPanelHeight(panels.sidebar, x, y)) {
            if (dragX < -20)
                screenState.ai = true;
            else if (dragX > 20)
                screenState.ai = false;
        }
        // Mirror the same inward/outward gesture at the left screen edge,
        // including the taskbar inset when the bar itself is on the left.
        const leftPanel = panels.leftSidebar;
        const leftReach = Math.max(Config.border.minThickness, panels.x + (leftPanel.visible ? leftPanel.width : 0));
        if (SidebarConfig.leftLayout.enabled && pressed && dragStart.x <= leftReach && withinPanelHeight(leftPanel, x, y)) {
            if (dragX > 20) screenState.leftSidebar = true;
            else if (dragX < -20) screenState.leftSidebar = false;
        }
        // Show/hide launcher on hover, or show/hide on drag if hover is disabled
        const showLauncher = inBottomPanel(panels.launcher, x, y);

        if (Config.launcher.showOnHover) {
            // Always update visibility based on hover if not in shortcut mode
            if (!launcherShortcutActive) {
                screenState.launcher = showLauncher;
            } else if (showLauncher) {
                // If hovering over the launcher zone while in shortcut mode, transition to hover control
                launcherShortcutActive = false;
            }
        } else if (pressed && inBottomPanel(panels.launcher, dragStart.x, dragStart.y) && withinPanelWidth(panels.launcher, x, y)) {
            if (dragY < -Config.launcher.dragThreshold)
                screenState.launcher = true;
            else if (dragY > Config.launcher.dragThreshold)
                screenState.launcher = false;
        }

        // Show dashboard on hover
        const overBarEntry = bar.horizontal && y < bar.thickness && bar.blocksDashboardHover(x, y);
        const calendarOpen = bar.horizontal && popouts.hasCurrent && popouts.currentName === "clock";
        const showDashboard = Config.dashboard.showOnHover && !overBarEntry && !calendarOpen && inTopPanel(panels.dashboard, x, y);
        if (showDashboard && !screenState.dashboard)
            panels.dashboard.selectDefaultTab(mediaPlaying);

        // Always update visibility based on hover if not in shortcut mode
        if (!dashboardShortcutActive) {
            // A focused scratchpad stays open even if the pointer leaves the
            // dashboard. Click-away focus handling dismisses it explicitly.
            screenState.dashboard = showDashboard || panels.dashboard.notesActive;
        } else if (showDashboard) {
            // If hovering over dashboard area while in shortcut mode, transition to hover control
            dashboardShortcutActive = false;
        }

        // Show/hide dashboard on drag (for touchscreen devices)
        if (pressed && inTopPanel(panels.dashboard, dragStart.x, dragStart.y) && withinPanelWidth(panels.dashboard, x, y)) {
            if (dragY > Config.dashboard.dragThreshold)
                screenState.dashboard = true;
            else if (dragY < -Config.dashboard.dragThreshold)
                screenState.dashboard = false;
        }

        updatePopoutHover(x, y);
    }

    Connections {
        target: Config.bar

        function onPersistentChanged() {
            root.bar.isHovered = false;
            if (!Config.bar.persistent)
                root.screenState.bar = false;
        }

        function onShowOnHoverChanged() {
            if (Config.bar.showOnHover)
                root.screenState.bar = false;
            else
                root.bar.isHovered = false;
        }
    }

    Connections {
        target: Config.notifs

        function onShadeEnabledChanged() {
            if (!Config.notifs.shadeEnabled)
                root.screenState.notifShade = false;
        }
    }

    // Monitor individual visibility changes
    Connections {
        function onLauncherChanged() {
            if (root.screenState.launcher) {
                // Launcher became visible without the pointer in its zone
                // (keybind, drag or IPC), so keep it open until hovered,
                // dismissed with a click elsewhere or escape
                const inLauncherZone = root.inBottomPanel(root.panels.launcher, root.mouseX, root.mouseY);
                if (!inLauncherZone) {
                    root.launcherShortcutActive = true;
                }
            } else {
                // Launcher hidden, clear shortcut flag
                root.launcherShortcutActive = false;
            }

            // If launcher is hidden, clear shortcut flags for dashboard and OSD
            if (!root.screenState.launcher) {
                root.dashboardShortcutActive = false;
                root.osdShortcutActive = false;

                // Also hide dashboard and OSD if they're not being hovered
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);

                if (!inDashboardArea && !root.panels.dashboard.notesActive) {
                    root.screenState.dashboard = false;
                }
                if (!inOsdArea) {
                    root.screenState.osd = false;
                    root.panels.osd.hovered = false;
                }
            }
        }

        function onAiChanged() {
            if (root.screenState.ai) {
                root.screenState.session = false;
                root.screenState.osd = false;
                root.panels.osd.hovered = false;
                root.osdShortcutActive = false;
            }
        }

        function onLeftSidebarChanged() {
            if (root.screenState.leftSidebar) root.screenState.session = false;
        }

        function onDashboardChanged() {
            if (root.screenState.dashboard) {
                // Dashboard became visible, immediately check if this should be shortcut mode
                const inDashboardArea = root.inTopPanel(root.panels.dashboard, root.mouseX, root.mouseY);
                if (!inDashboardArea) {
                    root.dashboardShortcutActive = true;
                }
            } else {
                // Dashboard hidden, clear shortcut flag
                root.dashboardShortcutActive = false;
            }
        }

        function onOsdChanged() {
            if (root.screenState.osd) {
                // OSD became visible, immediately check if this should be shortcut mode
                const inOsdArea = root.inRightPanel(root.panels.osdWrapper, root.mouseX, root.mouseY);
                if (!inOsdArea) {
                    root.osdShortcutActive = true;
                }
            } else {
                // OSD hidden, clear shortcut flag
                root.osdShortcutActive = false;
            }
        }

        target: root.screenState
    }
}
