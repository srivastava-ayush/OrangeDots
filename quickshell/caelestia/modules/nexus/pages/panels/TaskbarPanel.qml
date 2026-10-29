pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var barEntries: GlobalConfig.bar.entries.values
    readonly property int activeWindowIndex: barEntries.findIndex(e => e.id === "activeWindow")
    readonly property int clockIndex: barEntries.findIndex(e => e.id === "clock")
    readonly property list<MenuItem> orientationItems: [
        MenuItem {
            text: qsTr("Left")
        },
        MenuItem {
            text: qsTr("Top")
        }
    ]
    readonly property list<MenuItem> centerItems: [
        MenuItem {
            text: qsTr("Active window")
        },
        MenuItem {
            text: qsTr("Time and date")
        }
    ]

    title: qsTr("Taskbar")
    isSubPage: true

    function setCenterClock(showClock: bool): void {
        const entries = GlobalConfig.bar.entries;
        let activeWindow = activeWindowIndex;
        const clock = clockIndex;
        if (clock < 0)
            return;

        if (activeWindow < 0 && !showClock) {
            const statusIcons = barEntries.findIndex(e => e.id === "statusIcons");
            entries.insert({ id: "activeWindow", enabled: true }, statusIcons < 0 ? -1 : statusIcons);
            activeWindow = entries.values.findIndex(e => e.id === "activeWindow");
        }
        if (activeWindow < 0 || (clock < activeWindow) === showClock)
            return;

        // Swap the entries while preserving the order of everything between them.
        const first = Math.min(activeWindow, clock);
        const second = Math.max(activeWindow, clock);
        entries.move(second, first);
        entries.move(first + 1, second);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Behaviour
        SectionHeader {
            first: true
            text: qsTr("Behaviour")
        }

        SelectRow {
            objectName: "taskbarOrientation"
            first: true
            label: qsTr("Orientation")
            subtext: qsTr("Choose which screen edge the taskbar uses")
            menuItems: root.orientationItems
            active: root.orientationItems[Taskbar.horizontal ? 1 : 0]
            onSelected: item => Taskbar.orientation = root.orientationItems.indexOf(item) === 1 ? "top" : "left"
        }

        ToggleRow {
            text: qsTr("Persistent")
            subtext: qsTr("Keep the bar visible at all times")
            checked: Config.bar.persistent
            onToggled: GlobalConfig.bar.persistent = checked
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal the bar when the cursor reaches the screen edge")
            checked: Config.bar.showOnHover && !Config.bar.persistent
            onToggled: {
                GlobalConfig.bar.showOnHover = checked;
                if (checked)
                    GlobalConfig.bar.persistent = false;
            }
        }

        StepperRow {
            label: qsTr("Thickness")
            subtext: qsTr("Thickness of the bar")
            value: Config.border.thickness
            from: 1
            to: 100
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the bar reveals")
            value: Config.bar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.bar.dragThreshold = v
        }

        // Components
        SectionHeader {
            text: qsTr("Components")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Center of taskbar")
            subtext: qsTr("Choose what appears between the two spacers")
            menuItems: root.centerItems
            active: root.centerItems[root.clockIndex !== -1 && root.clockIndex < root.activeWindowIndex ? 1 : 0]
            onSelected: item => {
                const showClock = root.centerItems.indexOf(item) === 1;
                root.setCenterClock(showClock);
                if (showClock)
                    GlobalConfig.bar.clock.showDate = true;
            }
        }

        NavRow {
            first: true
            icon: "workspaces"
            text: qsTr("Workspaces")
            subtext: qsTr("Indicators, window icons")
            onClicked: root.nState.openSubPage(6)
        }

        NavRow {
            icon: "web_asset"
            text: qsTr("Active window")
            subtext: qsTr("Title display, popout")
            onClicked: root.nState.openSubPage(7)
        }

        NavRow {
            icon: "widgets"
            text: qsTr("Tray")
            subtext: qsTr("System tray icons")
            onClicked: root.nState.openSubPage(8)
        }

        NavRow {
            icon: "signal_cellular_alt"
            text: qsTr("Status icons")
            subtext: qsTr("Visible indicators, notification bell")
            onClicked: root.nState.openSubPage(9)
        }

        NavRow {
            objectName: "taskbarNotificationShade"
            icon: "notifications"
            text: qsTr("Notification shade")
            subtext: Config.notifs.shadeEnabled ? qsTr("Status-group bell, hover popout, notification history") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(11)
        }

        NavRow {
            last: true
            icon: "schedule"
            text: qsTr("Clock")
            subtext: qsTr("Date, icon, background")
            onClicked: root.nState.openSubPage(10)
        }

        // Scroll actions
        SectionHeader {
            text: qsTr("Scroll actions")
        }

        ToggleRow {
            first: true
            text: qsTr("Workspaces")
            subtext: qsTr("Scroll over the workspace indicator to switch workspaces")
            checked: Config.bar.scrollActions.workspaces
            onToggled: GlobalConfig.bar.scrollActions.workspaces = checked
        }

        ToggleRow {
            text: qsTr("Volume")
            subtext: Taskbar.horizontal ? qsTr("Scroll on the left half of the bar to adjust volume") : qsTr("Scroll on the top half of the bar to adjust volume")
            checked: Config.bar.scrollActions.volume
            onToggled: GlobalConfig.bar.scrollActions.volume = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Brightness")
            subtext: Taskbar.horizontal ? qsTr("Scroll on the right half of the bar to adjust brightness") : qsTr("Scroll on the bottom half of the bar to adjust brightness")
            checked: Config.bar.scrollActions.brightness
            onToggled: GlobalConfig.bar.scrollActions.brightness = checked
        }
    }
}
