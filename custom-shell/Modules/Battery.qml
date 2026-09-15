import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

Item {
    id: root
    property color fgColor: "white"
    property color hoverColor: "#26ffffff"
    property color accent: "#0a84ff"

    readonly property var device: UPower.displayDevice
    readonly property int pct: device ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: device ? device.state === UPowerDeviceState.Charging : false

    visible: device !== null && device.isLaptopBattery

    implicitWidth: 78
    implicitHeight: 22

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: 5
        color: mouse.containsMouse ? root.hoverColor : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        // --- drawn macOS battery shell ---
        Item {
            width: 26
            height: 13
            Rectangle {                       // body
                anchors.fill: parent
                anchors.rightMargin: 2
                radius: 3.5
                border.color: root.fgColor
                border.width: 1
                color: "transparent"

                Rectangle {                   // fill level
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 1.5
                    }
                    width: parent.width * (root.pct / 100) - 3
                    height: parent.height - 4
                    radius: 2
                    color: {
                        if (root.charging) return "#30d158"      // green while charging
                        if (root.pct <= 15 && !root.charging) return "#ff453a" // red low
                        return root.fgColor
                    }
                }

                Text {                        // charging bolt
                    anchors.centerIn: parent
                    visible: root.charging
                    text: "\uf0e7"
                    color: "white"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
            Rectangle {                       // nub on the right edge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 5
                radius: 1
                color: root.fgColor
                opacity: 0.7
            }
        }

        Text {
            text: root.pct + "%"
            color: root.pct <= 15 && !root.charging ? "#ff453a" : root.fgColor
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
    }
}