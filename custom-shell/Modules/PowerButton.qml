import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string icon: ""
    property string label: ""
    property color accent: "#0a84ff"
    signal clicked()

    Layout.fillWidth: true
    spacing: 6

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        width: 42
        height: 42
        radius: 21
        color: mouse.containsMouse ? "#33ffffff" : "#1affffff"

        Behavior on color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: root.icon
            color: root.accent
            font.pixelSize: 17
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.clicked()
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: root.label
        color: "#ccffffff"
        font.pixelSize: 11
    }
}