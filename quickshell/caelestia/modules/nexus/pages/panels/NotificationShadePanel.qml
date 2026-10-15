pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

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
            subtext: qsTr("Show the notification shade panel")
            checked: Config.notifs.shadeEnabled
            onToggled: GlobalConfig.notifs.shadeEnabled = checked
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Open from the top-right screen corner")
            checked: Config.notifs.shadeShowOnHover
            onToggled: GlobalConfig.notifs.shadeShowOnHover = checked
        }

        StepperRow {
            label: qsTr("Corner width")
            subtext: qsTr("Width of the top-right activation area")
            value: Config.notifs.shadeCornerWidth
            from: 20
            to: 500
            stepSize: 10
            onMoved: v => GlobalConfig.notifs.shadeCornerWidth = v
        }

        StepperRow {
            last: true
            label: qsTr("Swipe threshold")
            subtext: qsTr("Pixels swiped down before the shade opens")
            value: Config.notifs.expandThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.notifs.expandThreshold = v
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
