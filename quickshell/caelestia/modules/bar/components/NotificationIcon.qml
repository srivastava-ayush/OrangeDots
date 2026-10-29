import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var bar
    property color colour: Colours.palette.m3secondary

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight
    Accessible.name: qsTr("Notifications")

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        animate: true
        text: Notifs.dnd ? "notifications_off" : "notifications"
        color: root.colour
        fill: root.bar.screenState.notifShade ? 1 : 0
    }

    StyledRect {
        anchors.top: parent.top
        anchors.right: parent.right
        implicitWidth: 7
        implicitHeight: 7
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary
        visible: Notifs.notClosed.length > 0
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: {
            if (Config.notifs.shadeShowOnHover)
                root.bar.openNotifications();
        }
        onClicked: root.bar.screenState.notifShade = !root.bar.screenState.notifShade
    }
}
