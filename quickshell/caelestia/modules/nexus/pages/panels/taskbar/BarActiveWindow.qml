pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property var barEntries: GlobalConfig.bar.entries.values
    readonly property int activeWindowIndex: barEntries.findIndex(e => e.id === "activeWindow")

    title: qsTr("Active window")
    isSubPage: true

    function setEnabled(enabled: bool): void {
        const entries = GlobalConfig.bar.entries;
        if (activeWindowIndex >= 0) {
            entries.at(activeWindowIndex).enabled = enabled;
        } else if (enabled) {
            const statusIcons = barEntries.findIndex(e => e.id === "statusIcons");
            entries.insert({ id: "activeWindow", enabled: true }, statusIcons < 0 ? -1 : statusIcons);
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the active window in the taskbar")
            checked: root.activeWindowIndex >= 0 && root.barEntries[root.activeWindowIndex].enabled
            onToggled: root.setEnabled(checked)
        }

        ToggleRow {
            text: qsTr("Compact")
            checked: Config.bar.activeWindow.compact
            onToggled: GlobalConfig.bar.activeWindow.compact = checked
        }

        ToggleRow {
            text: qsTr("Inverted")
            checked: Config.bar.activeWindow.inverted
            onToggled: GlobalConfig.bar.activeWindow.inverted = checked
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Only show the active window title while hovering")
            checked: Config.bar.activeWindow.showOnHover
            onToggled: GlobalConfig.bar.activeWindow.showOnHover = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show a window details popout when hovering")
            checked: Config.bar.popouts.activeWindow
            onToggled: GlobalConfig.bar.popouts.activeWindow = checked
        }
    }
}
