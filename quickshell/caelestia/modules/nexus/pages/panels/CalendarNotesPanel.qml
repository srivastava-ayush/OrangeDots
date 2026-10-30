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
            last: true
            text: qsTr("Enabled")
            subtext: qsTr("Show the Calendar tab in the dashboard")
            checked: Config.sidebar.enabled
            onToggled: GlobalConfig.sidebar.enabled = checked
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
