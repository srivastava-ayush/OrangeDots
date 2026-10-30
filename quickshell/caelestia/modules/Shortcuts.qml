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
            ["phone", true],
            ["calendar", conf.sidebar.enabled]
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
            if (list().split("\n").includes(drawer)) {
                if (root.hasFullscreen && ["launcher", "session", "dashboard", "notifShade", "utilitySidebar"].includes(drawer))
                    return;
                const screenState = root.activeScreenState();
                if (drawer === "utilitySidebar") {
                    // Compatibility for scripts using the former corner drawer.
                    const index = root.dashboardTabIndex("calendar");
                    if (index < 0 || !GlobalConfig.forScreen(screenState.modelData.name).dashboard.enabled)
                        return;
                    if (screenState.dashboard && screenState.dashboardTab === index)
                        screenState.dashboard = false;
                    else {
                        screenState.dashboardTab = index;
                        screenState.dashboard = true;
                    }
                } else {
                    screenState[drawer] = !screenState[drawer];
                }
            } else {
                console.warn(lc, `Drawer "${drawer}" does not exist`);
            }
        }

        function list(): string {
            const screenState = root.activeScreenState();
            return [...Object.keys(screenState).filter(k => typeof screenState[k] === "boolean"), "utilitySidebar"].join("\n");
        }

        function isOpen(drawer: string): string {
            const screenState = root.activeScreenState();
            if (drawer === "utilitySidebar")
                return screenState.dashboard && screenState.dashboardTab === root.dashboardTabIndex("calendar") ? "1" : "0";
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
