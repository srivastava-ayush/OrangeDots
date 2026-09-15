import QtQuick

Rectangle {
    id: root
    property color fgColor: "white"
    property color hoverColor: "#26ffffff"
    signal toggled()

    width: 26
    height: 22
    radius: 6
    color: mouse.containsMouse ? root.hoverColor : "transparent"
    Behavior on color { ColorAnimation { duration: 100 } }

    // macOS "Control Center" glyph: two slider lines with knobs
    Column {
        anchors.centerIn: parent
        spacing: 4

        Row {
            spacing: 2
            Rectangle {
                width: 9; height: 2.5; radius: 1.25
                anchors.verticalCenter: parent.verticalCenter
                color: root.fgColor
            }
            Rectangle {
                width: 5; height: 5; radius: 2.5
                color: root.fgColor
            }
            Rectangle {
                width: 3; height: 2.5; radius: 1.25
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
            }
        }

        Row {
            spacing: 2
            Rectangle {
                width: 3; height: 2.5; radius: 1.25
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
            }
            Rectangle {
                width: 5; height: 5; radius: 2.5
                color: root.fgColor
            }
            Rectangle {
                width: 9; height: 2.5; radius: 1.25
                anchors.verticalCenter: parent.verticalCenter
                color: root.fgColor
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.toggled()
    }
}