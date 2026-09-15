import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    property color fgColor: "white"
    property color hoverColor: "#26ffffff"
    spacing: 8
    Layout.alignment: Qt.AlignVCenter

    // WiFi — monochrome, dimmed when the radio is off
    Rectangle {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        radius: 5
        color: mouse.containsMouse ? root.hoverColor : "transparent"
        Text {
            anchors.centerIn: parent
            text: "\uf1eb"
            color: root.fgColor
            font.pixelSize: 13
        }
        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true }
    }

    // Bluetooth
    Rectangle {
        Layout.preferredWidth: 22
        Layout.preferredHeight: 22
        radius: 5
        color: bluetooth.containsMouse ? root.hoverColor : "transparent"
        Text {
            anchors.centerIn: parent
            text: "\uf293"
            color: root.fgColor
            font.pixelSize: 13
        }
        MouseArea { id: bluetooth; anchors.fill: parent; hoverEnabled: true }
    }

    // StatusNotifierItems from the tray
    Repeater {
        model: SystemTray.items

        Rectangle {
            required property var modelData
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 5
            color: mouse.containsMouse ? root.hoverColor : "transparent"

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: modelData.icon
                sourceSize: Qt.size(16, 16)
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton)
                        modelData.activate()
                    else
                        modelData.display()
                }
            }
        }
    }
}