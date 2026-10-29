pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components.effects
import qs.services
import qs.utils

MouseArea {
    id: root

    required property SystemTrayItem modelData
    required property int index

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    // Top bars have a fixed cross-axis height. Keep tray images square and
    // inside that height instead of cropping a larger font-derived image.
    readonly property real iconSize: Taskbar.horizontal ? Math.min(Tokens.font.body.small.pointSize * 2, Tokens.sizes.bar.innerWidth) : Tokens.font.body.small.pointSize * 2
    implicitWidth: iconSize
    implicitHeight: iconSize

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}
