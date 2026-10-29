pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    readonly property int vPadding: Tokens.padding.large
    readonly property bool horizontal: Taskbar.horizontal
    readonly property int spacing: Tokens.spacing.medium

    function centerFor(item: Item): real {
        const center = item.mapToItem(root, item.width / 2, item.height / 2);
        return horizontal ? center.x : center.y;
    }

    function hasEntryAt(x: real, y: real): bool {
        // Include the padding above/below a horizontal entry so edge gestures
        // cannot open another panel while reaching for its clock or status icon.
        const entry = childAt(horizontal ? x : width / 2, horizontal ? height / 2 : y) as EntryWrapper;
        return !!entry?.item;
    }

    function closeTray(): void {
        if (!Config.bar.tray.compact)
            return;

        for (let i = 0; i < repeater.count; i++) {
            const entry = repeater.itemAt(i) as EntryWrapper;
            const tray = entry?.item as Tray;
            if (tray)
                tray.expanded = false;
        }
    }

    function showPopout(name: string, item: Item): void {
        popouts.cancelClose();
        popouts.anchorHovered = true;
        popouts.currentName = name;
        popouts.currentCenter = Qt.binding(() => root.centerFor(item));
        popouts.hasCurrent = true;
    }

    function openNotifications(shortcut = false): void {
        if (!Config.notifs.shadeEnabled) {
            screenState.notifShade = false;
            return;
        }
        for (let i = 0; i < repeater.count; i++) {
            const entry = repeater.itemAt(i) as EntryWrapper;
            const status = entry?.item as StatusIcons;
            const icon = status?.notificationIcon();
            if (icon) {
                if (shortcut)
                    popouts.notificationShortcutActive = true;
                showPopout("notifications", icon);
                return;
            }
        }
        // A configuration can explicitly omit/disable the notification entry.
        screenState.notifShade = false;
    }

    Component.onCompleted: Qt.callLater(() => {
        if (root.screenState.notifShade && !root.popouts.notificationsOpen)
            root.openNotifications(true);
    })

    Connections {
        target: root.screenState

        function onNotifShadeChanged(): void {
            if (root.screenState.notifShade && !root.popouts.notificationsOpen)
                root.openNotifications(true);
        }
    }

    function checkPopout(x: real, y: real): void {
        // Hit-test along the bar's length, not just the painted icon. The
        // cross-axis padding is the path the pointer takes into its popout.
        const px = horizontal ? x : width / 2;
        const py = horizontal ? height / 2 : y;
        const ch = childAt(px, py) as EntryWrapper;
        popouts.anchorHovered = false;

        if (ch?.entryId !== "tray")
            closeTray();

        if (!ch) {
            popouts.scheduleClose();
            return;
        }

        const id = ch.entryId;
        if (id === "statusIcons") {
            const items = (ch.item as StatusIcons).items;
            const pos = items.mapFromItem(root, px, py);
            const icon = items.childAt(pos.x, pos.y);
            if (icon?.name === "notifications") {
                if (Config.notifs.shadeShowOnHover)
                    openNotifications();
                else if (!popouts.notificationsOpen)
                    popouts.scheduleClose();
            } else if (icon && Config.bar.popouts.statusIcons) {
                showPopout(icon.name, icon);
            } else
                popouts.scheduleClose();
        } else if (id === "tray" && Config.bar.popouts.tray) {
            const tray = ch.item as Tray;
            if (!Config.bar.tray.compact || (tray.expanded && !tray.expandIcon.contains(tray.expandIcon.mapFromItem(root, px, py)))) {
                const pos = tray.layout.mapFromItem(root, px, py);
                const trayItem = tray.layout.childAt(pos.x, pos.y) as TrayItem;
                if (trayItem) {
                    showPopout(`traymenu${trayItem.index}`, trayItem);
                } else {
                    popouts.scheduleClose();
                }
            } else {
                popouts.scheduleClose();
                tray.expanded = true;
            }
        } else if (id === "activeWindow" && Config.bar.popouts.activeWindow && Config.bar.activeWindow.showOnHover) {
            showPopout(id.toLowerCase(), ch.item);
        } else if (id === "clock") {
            showPopout(id.toLowerCase(), ch.item);
        } else
            popouts.scheduleClose();
    }

    function handleWheel(x: real, y: real, angleDelta: point): void {
        const ch = childAt(x, y) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            // Workspace scroll
            const mon = (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor);
            const specialWs = mon?.lastIpcObject.specialWorkspace.name;
            if (specialWs?.length > 0)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.workspace.toggle_special("${specialWs.slice(8)}")` : `togglespecialworkspace ${specialWs.slice(8)}`);
            else if (angleDelta.y < 0 || (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? mon.activeWorkspace?.id : Hypr.activeWsId) > 1)
                Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "r${angleDelta.y > 0 ? "-" : "+"}1" })` : `workspace r${angleDelta.y > 0 ? "-" : "+"}1`);
        } else if ((horizontal ? x < width / 2 : y < height / 2) && Config.bar.scrollActions.volume) {
            // Volume scroll on the first half (top or left).
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        } else if (Config.bar.scrollActions.brightness) {
            // Brightness scroll on the second half (bottom or right).
            const monitor = Brightness.getMonitorForScreen(screen);
            if (angleDelta.y > 0)
                monitor.setBrightness(monitor.brightness + GlobalConfig.services.brightnessIncrement);
            else if (angleDelta.y < 0)
                monitor.setBrightness(monitor.brightness - GlobalConfig.services.brightnessIncrement);
        }
    }

    columns: horizontal ? repeater.count : 1
    rows: horizontal ? 1 : repeater.count
    columnSpacing: spacing
    rowSpacing: spacing

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.Config.bar.entries.values.filter(e => e.enabled && e.id !== "notifications")
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillWidth: root.horizontal
                    Layout.fillHeight: !root.horizontal
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        objectName: "taskbarLogo"
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Workspaces {
                        objectName: "taskbarWorkspaces"
                        screen: root.screen
                        fullscreen: root.fullscreen
                    }
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow {
                        objectName: "taskbarActiveWindow"
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {
                        objectName: "taskbarTray"
                    }
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {
                        objectName: "taskbarClock"
                    }
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {
                        objectName: "taskbarStatusIcons"
                        bar: root
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.topMargin: !root.horizontal && index === 0 ? root.vPadding : 0
        Layout.bottomMargin: !root.horizontal && index === repeater.count - 1 ? root.vPadding : 0
        Layout.leftMargin: root.horizontal && index === 0 ? root.vPadding : 0
        Layout.rightMargin: root.horizontal && index === repeater.count - 1 ? root.vPadding : 0
        Layout.alignment: Qt.AlignCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
