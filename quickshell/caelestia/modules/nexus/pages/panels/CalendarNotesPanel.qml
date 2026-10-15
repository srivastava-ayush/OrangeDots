pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Calendar & notes")
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
            subtext: qsTr("Show the calendar agenda and notes panel")
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
        }

        ToggleRow {
            text: qsTr("Show on hover")
            subtext: qsTr("Open from the bottom-right screen corner")
            checked: Config.sidebar.showOnHover
            onToggled: GlobalConfig.sidebar.showOnHover = checked
        }

        StepperRow {
            label: qsTr("Corner width")
            subtext: qsTr("Width of the bottom-right activation area")
            value: Config.sidebar.minHoverThreshold
            from: 20
            to: 500
            stepSize: 10
            onMoved: v => GlobalConfig.sidebar.minHoverThreshold = v
        }

        StepperRow {
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels swiped up before the panel opens")
            value: Config.sidebar.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.sidebar.dragThreshold = v
        }

        SectionHeader {
            text: qsTr("Contents")
        }

        ToggleRow {
            first: true
            text: qsTr("Google Calendar agenda")
            checked: Config.sidebar.showAgenda
            onToggled: GlobalConfig.sidebar.showAgenda = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Notes")
            checked: Config.sidebar.showNotes
            onToggled: GlobalConfig.sidebar.showNotes = checked
        }
    }
}
