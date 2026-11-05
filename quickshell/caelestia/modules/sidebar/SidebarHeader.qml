pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root
    required property string moduleId
    objectName: "sidebarHeader_" + moduleId
    property string subtitle: ""
    default property alias actions: actionRow.data
    Layout.fillWidth: true
    Layout.minimumHeight: SidebarStyle.headerHeight
    spacing: SidebarStyle.smallGap

    children: [
        MaterialIcon {
            text: SidebarConfig.modules.find(module => module.id === root.moduleId)?.icon ?? "widgets"
            color: Colours.palette.m3primary
        },
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            StyledText {
                Layout.fillWidth: true
                text: SidebarConfig.moduleName(root.moduleId)
                font: Tokens.font.title.medium
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
        },
        RowLayout {
            id: actionRow
            spacing: SidebarStyle.smallGap
        }
    ]
}
