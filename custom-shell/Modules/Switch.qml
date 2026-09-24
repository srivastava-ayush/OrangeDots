import QtQuick

Item {
    id: root
    property bool checked: false
    property color accent: "#0a84ff"
    signal toggled(bool state)

    width: 40
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? root.accent : "#33ffffff"
        border.color: root.checked ? "transparent" : "#22ffffff"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        id: knob
        width: 20
        height: 20
        radius: 10
        y: (parent.height - height) / 2
        x: root.checked ? parent.width - width - 2 : 2
        color: "#ffffffff"
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}