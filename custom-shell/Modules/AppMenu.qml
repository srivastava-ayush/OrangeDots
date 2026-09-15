import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

RowLayout {
    id: root
    property color fgColor: "white"
    property color hoverColor: "#26ffffff"
    spacing: 2

    // The Apple menu — nerd font Apple logo
    Rectangle {
        Layout.preferredWidth: 28
        Layout.preferredHeight: 22
        radius: 5
        color: mouse.containsMouse ? root.hoverColor : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: "\uf179"
            color: root.fgColor
            font.pixelSize: 16
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    Text {
        id: appName
        text: {
            const c = Hyprland.activeToplevel
            return c ? c.title : ""
        }
        color: root.fgColor
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
        Layout.maximumWidth: 280
        Layout.leftMargin: 4
    }
}