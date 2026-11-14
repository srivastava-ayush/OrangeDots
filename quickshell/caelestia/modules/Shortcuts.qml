import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.settings

Scope {
    id: root

    property bool launcherInterrupted
    readonly property alias drawers: drawers
    readonly property bool hasFullscreen: Hypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false

    function activeScreenState(): ScreenState {
        return ShellState.forActive();
    }

    function dashboardTabIndex(tab: string): int {
        // Mirrors the enabled-filtered tab order in dashboard/DashboardContent.qml.
        const screenState = root.activeScreenState();
        const conf = screenState ? GlobalConfig.forScreen(screenState.modelData.name) : GlobalConfig;
        const tabs = [
            ["media", conf.dashboard.showMedia],
            ["dashboard", conf.dashboard.showDashboard],
            ["performance", conf.dashboard.showPerformance],
            ["phone", true]
        ];
        return tabs.filter(t => t[1]).findIndex(t => t[0] === tab);
    }

    function openLauncherAt(query: string, attempts: int): void {
        const screenState = root.activeScreenState();
        screenState.launcher = true;

        const search = ShellState.componentsForActive()?.find("launcherSearch");
        if (search)
            search.text = query;
        else if (attempts > 0)
            Qt.callLater(() => root.openLauncherAt(query, attempts - 1));
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "nexus"
        description: "Open nexus"
        onPressed: SettingsWindows.create()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "showall"
        description: "Toggle launcher, dashboard and osd"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const v = root.activeScreenState();
            v.launcher = v.dashboard = v.osd = !(v.launcher || v.dashboard || v.osd);
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = root.activeScreenState();
            screenState.dashboard = !screenState.dashboard;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "session"
        description: "Toggle session menu"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const screenState = root.activeScreenState();
            screenState.session = !screenState.session;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted && !root.hasFullscreen) {
                const screenState = root.activeScreenState();
                screenState.launcher = !screenState.launcher;
            }
            root.launcherInterrupted = false;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "launcherInterrupt"
        description: "Interrupt launcher keybind"
        onPressed: root.launcherInterrupted = true
    }

    IpcHandler {
        id: drawers

        function cycleBarStyle(): void {
            Taskbar.cycleStyle();
        }

        function toggleBarOrientation(): void {
            Taskbar.orientation = Taskbar.horizontal ? "left" : "top";
        }

        function toggleBarPersistent(): void {
            GlobalConfig.bar.persistent = !GlobalConfig.bar.persistent;
            if (!GlobalConfig.bar.persistent)
                root.activeScreenState().bar = false;
        }

        function toggle(drawer: string): void {
            if (drawer === "rightSidebar") drawer = "ai";
            if (list().split("\n").includes(drawer)) {
                if (root.hasFullscreen && ["launcher", "session", "dashboard", "ai", "leftSidebar", "notifShade", "utilitySidebar"].includes(drawer))
                    return;
                const screenState = root.activeScreenState();
                if (drawer === "ai" && !SidebarConfig.layout.enabled)
                    return;
                if (drawer === "leftSidebar" && !SidebarConfig.leftLayout.enabled) return;
                if (drawer === "utilitySidebar") {
                    // Preserve the old IPC name without retaining a Calendar
                    // dashboard tab: open its assigned sidebar module instead.
                    const side = SidebarConfig.placement("calendar");
                    if (side === "off" || !SidebarConfig.layoutFor(side).enabled) return;
                    const panel = ShellState.componentsFor(screenState.modelData)?.panels?.[side === "left" ? "leftSidebar" : "rightSidebar"];
                    if (!panel) return;
                    const key = side === "left" ? "leftSidebar" : "ai";
                    const wasOpen = screenState[key] && panel.selectedModule === "calendar";
                    panel.selectedModule = "calendar";
                    screenState[key] = !wasOpen;
                } else {
                    screenState[drawer] = !screenState[drawer];
                }
            } else {
                console.warn(lc, `Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const screenState = root.activeScreenState();
            return [...Object.keys(screenState).filter(k => typeof screenState[k] === "boolean"), "rightSidebar", "utilitySidebar"].join("\n");
        }

        function isOpen(drawer: string): string {
            if (drawer === "rightSidebar") drawer = "ai";
            const screenState = root.activeScreenState();
            if (drawer === "utilitySidebar") {
                const side = SidebarConfig.placement("calendar");
                if (side === "off") return "0";
                const panel = ShellState.componentsFor(screenState.modelData)?.panels?.[side === "left" ? "leftSidebar" : "rightSidebar"];
                return screenState[side === "left" ? "leftSidebar" : "ai"] && panel?.selectedModule === "calendar" ? "1" : "0";
            }
            if (typeof screenState[drawer] !== "boolean")
                return "unknown";
            return screenState[drawer] ? "1" : "0";
        }

        function setTab(tab: string): void {
            const index = root.dashboardTabIndex(tab);
            if (index === -1) {
                console.warn(lc, `Dashboard tab "${tab}" does not exist`);
                return;
            }
            if (root.hasFullscreen)
                return;
            const screenState = root.activeScreenState();
            screenState.dashboard = true;
            screenState.dashboardTab = index;
        }

        target: "drawers"
    }

    IpcHandler {
        function open(): void {
            SettingsWindows.create();
        }

        function toggle(): void {
            const fallbackScreen = Quickshell.screens[0];
            const comps = ShellState.componentsForActive()
                ?? (fallbackScreen ? ShellState.componentsFor(fallbackScreen) : null);
            const popouts = comps?.panels?.popouts;
            // Nexus lives in the detached popout overlay, which never sets
            // hasCurrent; detachedMode is the reliable open indicator.
            if (popouts?.detachedMode === "any") {
                popouts.close();
                return;
            }
            // The overlay may be open on another monitor; close that instance
            // instead of opening a second one.
            const openElsewhere = Quickshell.screens
                .map(screen => ShellState.componentsFor(screen)?.panels?.popouts)
                .find(p => p?.detachedMode === "any");
            if (openElsewhere) {
                openElsewhere.close();
                return;
            }
            SettingsWindows.create();
        }

        target: "nexus"
    }

    IpcHandler {
        function pick(): void {
            if (root.hasFullscreen)
                return;
            root.openLauncherAt(`${GlobalConfig.launcher.actionPrefix}wallpaper `, 10);
        }

        target: "wallpapers"
    }

    IpcHandler {
        function info(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Info);
        }

        function success(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Success);
        }

        function warn(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Warning);
        }

        function error(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Error);
        }

        target: "toaster"
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.shortcuts"
        defaultLogLevel: LoggingCategory.Info
    }
}
