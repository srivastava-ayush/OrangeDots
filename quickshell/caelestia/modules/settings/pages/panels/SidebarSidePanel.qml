pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.settings.common
import qs.services

PageBase {
    id: root
    required property string side
    readonly property var settings: SidebarConfig.layoutFor(side)
    readonly property var moduleIds: SidebarConfig.modulesFor(side)
    readonly property list<MenuItem> moduleItems: [
        MenuItem { text: SidebarConfig.moduleName("ai") },
        MenuItem { text: SidebarConfig.moduleName("calendar") },
        MenuItem { text: SidebarConfig.moduleName("clipboard") },
        MenuItem { text: SidebarConfig.moduleName("focus") },
        MenuItem { text: SidebarConfig.moduleName("notes") }
    ]
    title: side === "left" ? qsTr("Left sidebar") : qsTr("Right sidebar")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2
        SectionHeader { first: true; text: qsTr("Panel") }
        ToggleRow {
            first: true
            text: qsTr("Enabled")
            subtext: root.side === "left" ? qsTr("Drag from the left edge toward the right to open") : qsTr("Super+I or drag from the right edge toward the left")
            checked: root.settings.enabled
            onToggled: root.settings.enabled = checked
        }
        StepperRow {
            objectName: "sidebarWidthSetting"
            label: qsTr("Panel width")
            value: root.settings.panelWidth
            from: 360; to: 720; stepSize: 20
            onMoved: value => root.settings.panelWidth = value
        }
        ToggleRow {
            text: qsTr("Full-height sidebar")
            subtext: qsTr("Turn off to choose a custom height")
            checked: root.settings.fullHeight
            onToggled: root.settings.fullHeight = checked
        }
        StepperRow {
            objectName: "sidebarHeightSetting"
            visible: !root.settings.fullHeight
            label: qsTr("Panel height")
            value: root.settings.panelHeight
            from: 480; to: 1600; stepSize: 20
            onMoved: value => root.settings.panelHeight = value
        }
        SelectRow {
            objectName: "sidebarDefaultModule"
            last: true
            label: qsTr("Default module")
            enabled: root.moduleIds.length > 0
            fallbackText: qsTr("Assign modules first")
            menuItems: root.moduleItems.filter((item, index) => root.moduleIds.includes(SidebarConfig.modules[index].id))
            active: root.moduleItems[SidebarConfig.modules.findIndex(module => module.id === SidebarConfig.defaultFor(root.side))] ?? null
            onSelected: item => SidebarConfig.setDefault(root.side, SidebarConfig.modules[root.moduleItems.indexOf(item)].id)
        }
        SectionHeader { text: qsTr("Modules") }
        InfoRow {
            first: true
            label: qsTr("Assigned here")
            value: root.moduleIds.map(id => SidebarConfig.moduleName(id)).join(" · ") || qsTr("No modules assigned")
        }
        NavRow {
            last: true
            icon: "widgets"
            text: qsTr("Configure modules")
            subtext: qsTr("Move modules between sidebars or turn them off")
            onClicked: root.nState.openSubPage(13)
        }
    }
}
