pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset

    readonly property bool isWorkspace: true
    readonly property bool isActive: activeWsId === ws
    readonly property bool isOccupied: occupied[ws] ?? false

    readonly property int ws: groupOffset + index + 1
    readonly property real dotSize: 14
    readonly property real pillHeight: 30
    readonly property real size: isActive ? pillHeight : dotSize

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: dotSize
    Layout.preferredHeight: size

    implicitWidth: dotSize
    implicitHeight: size

    Rectangle {
        id: dot

        anchors.centerIn: parent
        width: root.dotSize
        height: root.size
        radius: width / 2
        color: root.isActive
            ? Colours.palette.m3primary
            : root.isOccupied
                ? Colours.palette.m3onSurface
                : Colours.layer(Colours.palette.m3outlineVariant, 1)

        Behavior on height {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on color {
            CAnim {}
        }
    }

}
