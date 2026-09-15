import QtQuick
import Quickshell

Item {
    id: root
    property color fgColor: "white"
    property color hoverColor: "#26ffffff"

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: label
        anchors.margins: -8
        radius: 5
        color: mouse.containsMouse ? root.hoverColor : "transparent"

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: root.fgColor
        font.pixelSize: 13
        text: {
            const d = clock.date
            if (!d) return ""
            // macOS format: "Tue Sep 15  9:41 AM"
            return Qt.formatDateTime(d, "ddd MMM d  h:mm AP")
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -8
        hoverEnabled: true
    }
}