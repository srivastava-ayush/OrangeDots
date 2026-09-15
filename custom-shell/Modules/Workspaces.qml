import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    property color fgColor: "white"
    property color accent: "#0a84ff"
    spacing: 5
    Layout.alignment: Qt.AlignVCenter

    Repeater {
        model: Hyprland.workspaces
        delegate: Rectangle {
            required property var modelData

            width: modelData.active ? 18 : 7
            height: 3
            radius: 1.5
            color: modelData.active ? root.accent : root.fgColor
            opacity: modelData.active ? 1.0 : 0.35
            Layout.alignment: Qt.AlignVCenter

            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -5
                onClicked: Hyprland.dispatch("workspace " + modelData.id)
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}