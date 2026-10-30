pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Notification shade")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the notification bell and shade in the taskbar")
            checked: Config.notifs.shadeEnabled
            onToggled: GlobalConfig.notifs.shadeEnabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Show on hover")
            subtext: qsTr("Open from the taskbar bell; click to toggle when disabled")
            checked: Config.notifs.shadeShowOnHover
            onToggled: GlobalConfig.notifs.shadeShowOnHover = checked
        }

        SectionHeader {
            text: qsTr("Notifications")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Group preview count")
            subtext: qsTr("Notifications shown per group before collapsing")
            value: Config.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = v
        }
    }
}
