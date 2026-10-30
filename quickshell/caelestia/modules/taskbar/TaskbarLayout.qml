pragma ComponentBehavior: Bound

import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.PopoutWrapper popouts
    required property bool fullscreen
    readonly property int vPadding: Tokens.padding.large
    readonly property bool horizontal: Taskbar.horizontal
    readonly property bool centeredClock: horizontal || Taskbar.notched
    readonly property int spacing: Tokens.spacing.medium
    readonly property int notchPadding: Tokens.padding.medium
    readonly property var entryItems: children.filter(child => child.entryId && child.item)

    function entryGroup(id: string): int {
        if (id === "logo" || id === "workspaces" || (id === "activeWindow" && !Taskbar.notched))
            return 0;
        if (id === "clock")
            return 1;
        if (id === "tray" || id === "statusIcons")
            return 2;
        return -1;
    }

    readonly property var groupMetrics: {
        const lengths = [0, 0, 0];
        const counts = [0, 0, 0];
        if (centeredClock) {
            for (const entry of entryItems) {
                const group = entryGroup(entry.entryId);
                if (group < 0)
                    continue;
                lengths[group] += horizontal ? entry.item.implicitWidth : entry.item.implicitHeight;
                counts[group]++;
            }
            for (let i = 0; i < lengths.length; i++)
                lengths[i] += Math.max(0, counts[i] - 1) * spacing;
        }
        return { lengths, counts };
    }

    function spacerLength(side: string): real {
        const half = (horizontal ? width : height) / 2;
        const centerHalf = groupMetrics.lengths[1] / 2;
        const group = side === "start" ? 0 : 2;
        const gaps = groupMetrics.counts[group] > 0 ? 2 : 1;
        // Balance each half independently, not with two equal expanding gaps:
        // asymmetric workspace/title/tray widths must never shift the clock.
        return Math.max(0, half - centerHalf - groupMetrics.lengths[group] - vPadding - spacing * gaps);
    }

    // Main-axis ranges shared by the shell's SDF backgrounds. The notch itself
    // is drawn at the screen edge, not as a floating rectangle around the icon.
    readonly property var notchRanges: {
        const ranges = [{ start: 0, length: 0 }, { start: 0, length: 0 }, { start: 0, length: 0 }];
        if (!Taskbar.notched)
            return ranges;
        const starts = [Infinity, Infinity, Infinity];
        const ends = [-Infinity, -Infinity, -Infinity];
        for (const entry of entryItems) {
            const group = entryGroup(entry.entryId);
            if (group < 0)
                continue;
            const start = horizontal ? (group === 1 ? (width - entry.width) / 2 : entry.x) : entry.y;
            const length = horizontal ? entry.width : entry.height;
            starts[group] = Math.min(starts[group], start);
            ends[group] = Math.max(ends[group], start + length);
        }
        const limit = horizontal ? width : height;
        for (let i = 0; i < ranges.length; i++) {
            if (!Number.isFinite(starts[i]))
                continue;
            const start = Math.max(0, starts[i] - notchPadding);
            ranges[i] = { start, length: Math.max(0, Math.min(limit, ends[i] + notchPadding) - start) };
        }
        if (ranges[1].length > 0 && Taskbar.centerNotchSize > ranges[1].length) {
            const center = (starts[1] + ends[1]) / 2;
            const left = ranges[0].length > 0 ? ranges[0].start + ranges[0].length + spacing : 0;
            const right = ranges[2].length > 0 ? ranges[2].start - spacing : limit;
            // Keep the clock centered and prevent a large preference from
            // merging its notch into the workspace/status groups.
            const available = Math.max(0, 2 * Math.min(center - left, right - center));
            const length = Math.max(ranges[1].length, Math.min(Taskbar.centerNotchSize, available));
            ranges[1] = { start: center - length / 2, length };
        }
        return ranges;
    }

    function centerFor(item: Item): real {
        const center = item.mapToItem(root, item.width / 2, item.height / 2);
        return horizontal ? center.x : center.y;
    }

    function blocksDashboardHover(x: real, y: real): bool {
        // Include the padding above/below a horizontal entry so edge gestures
        // cannot open another panel while reaching for a status icon. The top
        // clock is click-only, so its column remains a dashboard hover target.
        const entry = entryAt(horizontal ? x : width / 2, horizontal ? height / 2 : y);
        return !!entry?.item && (!horizontal || entry.entryId !== "clock");
    }

    function entryAt(x: real, y: real): Item {
        // Layer effects insert rendering items alongside their source. childAt
        // can hit that proxy instead of EntryWrapper in Center notch mode.
        // Test real entries in their own coordinates, independent of painting.
        return entryItems.find(entry => entry.visible && entry.contains(entry.mapFromItem(root, x, y))) ?? null;
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
        const ch = entryAt(px, py) as EntryWrapper;
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
        } else if (id === "clock" && (!horizontal || (popouts.hasCurrent && popouts.currentName === "clock"))) {
            // Top calendars open only by click. Hover can retain an already
            // opened calendar while crossing the bar padding into its popout.
            showPopout(id.toLowerCase(), ch.item);
        } else
            popouts.scheduleClose();
    }

    function handleWheel(x: real, y: real, angleDelta: point): void {
        const ch = entryAt(x, y) as EntryWrapper;
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
            values: {
                const configured = root.Config.bar.entries.values;
                // Count only entries with a delegate. Legacy presets can end in
                // an unsupported `power` entry; counting it prevents the last
                // real widget from receiving its screen-edge padding.
                const supported = ["logo", "workspaces", "spacer", "activeWindow", "tray", "clock", "statusIcons"];
                const enabled = configured.filter(e => e.enabled && supported.includes(e.id));
                if (!root.centeredClock)
                    return enabled;
                const start = enabled.filter(e => root.entryGroup(e.id) === 0);
                const end = enabled.filter(e => root.entryGroup(e.id) === 2);
                // Top bars and notches center the clock on the screen itself.
                // Unified Top keeps the active title in the start group; Left
                // Unified restores the user's original entry ordering/choice.
                const clock = configured.find(e => e.id === "clock" && e.enabled) ?? { id: "clock", enabled: true };
                return [...start, { id: "spacer", side: "start" }, clock, { id: "spacer", side: "end" }, ...end];
            }
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    readonly property real mainLength: root.centeredClock ? root.spacerLength(modelData.side) : 0

                    Layout.fillWidth: root.horizontal && !root.centeredClock
                    Layout.fillHeight: !root.horizontal && !root.centeredClock
                    Layout.preferredWidth: root.horizontal ? mainLength : 0
                    Layout.preferredHeight: root.horizontal ? 0 : mainLength
                    Layout.minimumWidth: root.horizontal && root.centeredClock ? mainLength : 0
                    Layout.maximumWidth: root.horizontal && root.centeredClock ? mainLength : Infinity
                    Layout.minimumHeight: !root.horizontal && root.centeredClock ? mainLength : 0
                    Layout.maximumHeight: !root.horizontal && root.centeredClock ? mainLength : Infinity
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
                        id: clock

                        objectName: "taskbarClock"
                        // GridLayout rounds cells to logical pixels. Correct
                        // that rounding so the date/time stays at the exact
                        // screen midpoint, including odd widths and scaling.
                        transform: Translate {
                            x: root.horizontal ? root.width / 2 - clock.parent.x - clock.x - clock.width / 2 : 0
                        }

                        onClicked: {
                            if (root.popouts.hasCurrent && root.popouts.currentName === "clock") {
                                root.popouts.close();
                            } else {
                                root.screenState.dashboard = false;
                                root.showPopout("clock", clock);
                            }
                        }
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
        id: entryWrapper

        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id
        readonly property bool wallpaperContrast: Taskbar.centerOnly && (root.entryGroup(entryId) === 0 || root.entryGroup(entryId) === 2)

        // White silhouettes with a dark halo remain legible over light, dark,
        // and busy wallpaper without introducing another pill/notch background.
        // Apply to this entry only: the clock and all popouts keep theme colours.
        layer.enabled: wallpaperContrast
        layer.effect: MultiEffect {
            brightness: 1
            shadowEnabled: true
            shadowColor: "#f0000000"
            shadowOpacity: 1
            shadowBlur: 0.3
            blurMax: 8
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Layout.topMargin: !root.horizontal && index === 0 ? root.vPadding : 0
        Layout.bottomMargin: !root.horizontal && index === repeater.count - 1 ? root.vPadding : 0
        Layout.leftMargin: root.horizontal && index === 0 ? root.vPadding : 0
        Layout.rightMargin: root.horizontal && index === repeater.count - 1 ? root.vPadding : 0
        Layout.alignment: Qt.AlignCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Binding {
            target: entryWrapper.item
            property: "anchors.centerIn"
            value: entryWrapper
            when: Taskbar.centerOnly && entryWrapper.item !== null
        }
    }
}
