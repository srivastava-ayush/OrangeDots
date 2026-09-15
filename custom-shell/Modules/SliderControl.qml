import QtQuick

Item {
    id: root
    property real from: 0
    property real to: 100
    property real value: 50
    property color accent: "#0a84ff"
    signal moved()

    height: 26
    readonly property real trackWidth: width

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: "#40ffffff"

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * ((root.value - root.from) / (root.to - root.from))
            height: 6
            radius: 3
            color: "#ffffffff"
        }
    }

    // macOS round slider knob
    Rectangle {
        x: {
            const p = (root.value - root.from) / (root.to - root.from)
            return p * (root.width - knob.width)
        }
        id: knob
        width: 16
        height: 16
        y: parent.height / 2 - height / 2
        radius: 8
        color: "#ffffffff"

        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "transparent"
            border.color: "#2a000000"
            border.width: 1
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: (mouse) => {
            if (pressed) {
                root.value = Math.max(root.from, Math.min(root.to, (mouse.x / width) * (root.to - root.from) + root.from))
                root.moved()
            }
        }
        onPressed: (mouse) => {
            root.value = Math.max(root.from, Math.min(root.to, (mouse.x / width) * (root.to - root.from) + root.from))
            root.moved()
        }
    }
}