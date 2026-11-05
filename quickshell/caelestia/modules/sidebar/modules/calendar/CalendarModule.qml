pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.settings
import qs.services
import qs.modules.sidebar as Sidebar

FocusScope {
    id: root
    required property ScreenState screenState
    required property bool selected
    signal closeRequested
    focus: selected
    Keys.onEscapePressed: root.closeRequested()

    // Reuse the existing Google Calendar feed and notes persistence, rather than
    // introducing another account integration or a second copy of the draft.
    MouseArea { anchors.fill: parent }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SidebarStyle.padding
        spacing: SidebarStyle.gap
        Sidebar.SidebarHeader {
            moduleId: "calendar"
            IconButton {
                icon: "settings"
                type: IconButton.Text
                onClicked: { root.closeRequested(); SettingsWindows.openCalendarSettings(); }
            }
            IconButton {
                objectName: "sidebarCalendarClose"
                icon: "close"
                type: IconButton.Text
                onClicked: root.closeRequested()
            }
        }
        CalendarContent {
            objectName: "sidebarCalendar"
            Layout.fillWidth: true
            Layout.fillHeight: true
            selected: root.selected
            onCloseRequested: root.closeRequested()
            contentPadding: 0
            color: "transparent"
            radius: 0
        }
    }
}
