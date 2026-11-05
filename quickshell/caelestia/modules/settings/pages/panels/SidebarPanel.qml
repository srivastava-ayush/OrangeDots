import QtQuick.Layouts
import Caelestia.Config
import qs.modules.settings.common
import qs.services

PageBase {
    id: root
    title: qsTr("Sidebar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2
        NavRow {
            objectName: "sidebarLeftSettings"
            first: true
            icon: "left_panel_open"
            text: qsTr("Left sidebar")
            subtext: SidebarConfig.leftLayout.enabled ? qsTr("%1 modules · drag inward from the left edge").arg(SidebarConfig.leftModules.length) : qsTr("Disabled")
            onClicked: root.nState.openSubPage(11)
        }
        NavRow {
            objectName: "sidebarRightSettings"
            icon: "right_panel_open"
            text: qsTr("Right sidebar")
            subtext: SidebarConfig.layout.enabled ? qsTr("%1 modules · Super+I or right-edge drag").arg(SidebarConfig.enabledModules.length) : qsTr("Disabled")
            onClicked: root.nState.openSubPage(12)
        }
        NavRow {
            objectName: "sidebarModulesSettings"
            last: true
            icon: "widgets"
            text: qsTr("Modules")
            subtext: qsTr("Assign modules to Left / Right / Off, rename labels and configure AI")
            onClicked: root.nState.openSubPage(13)
        }
    }
}
