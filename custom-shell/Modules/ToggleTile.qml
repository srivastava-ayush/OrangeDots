import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property string iconActive: ""
    property color accent: "#0a84ff"
    property bool active: false
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 52
    radius: 14
    color: active ? root.accent : "#1affffff"

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Text {
            text: root.active && root.iconActive !== "" ? root.iconActive : root.icon
            color: "white"
            font.pixelSize: 17
        }

        Text {
            text: root.label
            color: "white"
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { root.active = !root.active; root.clicked() }
    }
}