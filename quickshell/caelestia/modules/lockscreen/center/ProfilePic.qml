pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property int centerWidth
    property int size: Math.round(centerWidth * 0.5)
    readonly property color bgColour: Colours.tPalette.m3surfaceContainerHighest

    implicitWidth: size
    implicitHeight: size

    MaterialShape {
        id: shape

        anchors.centerIn: parent
        implicitSize: size

        shape: MaterialShape.ClamShell
        color: Qt.alpha(root.bgColour, 1)
        opacity: root.bgColour.a
        layer.enabled: true
    }

    MaterialIcon {
        anchors.centerIn: parent

        text: "person"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.size(Math.max(4, size / 2)).build()
        visible: pfp.status !== Image.Ready
    }

    CachingImage {
        id: pfp

        anchors.fill: shape
        path: `/vol1/.face`

        layer.enabled: true
        layer.effect: Mask {
            maskSource: shape
        }
    }
}
