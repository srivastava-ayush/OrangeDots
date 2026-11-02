pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

// Decorative only: translucent sky washes preserve the shell's surface and text.
ClippingRectangle {
    id: root

    required property bool isDay
    property bool cloudy: false
    property real daylight: isDay ? 1 : 0
    radius: Tokens.rounding.extraLarge
    color: "transparent"

    Behavior on daylight {
        Anim { type: Anim.SlowEffects }
    }

    Item {
        anchors.fill: parent
        opacity: 1 - root.daylight

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("#243e73", Colours.light ? 0.18 : 0.42) }
                GradientStop { position: 1; color: Qt.alpha("#726290", Colours.light ? 0.12 : 0.2) }
            }
        }

        Repeater {
            model: [Qt.point(0.53, 0.12), Qt.point(0.68, 0.23), Qt.point(0.9, 0.15), Qt.point(0.6, 0.4), Qt.point(0.93, 0.48), Qt.point(0.8, 0.6)]

            Rectangle {
                required property point modelData
                x: root.width * modelData.x
                y: root.height * modelData.y
                width: 2
                height: 2
                radius: 1
                color: Qt.alpha("#e4edff", Colours.light ? 0.3 : 0.38)
            }
        }

        MaterialIcon {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 42
            anchors.topMargin: 44
            text: "bedtime"
            fill: 1
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.8).build()
            color: Qt.alpha("#d5e3ff", Colours.light ? 0.2 : 0.23)
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.daylight

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("#59a7dc", Colours.light ? 0.32 : 0.22) }
                GradientStop { position: 0.6; color: Qt.alpha("#b2c8d0", Colours.light ? 0.16 : 0.06) }
                GradientStop { position: 1; color: Qt.alpha("#f1bf7a", Colours.light ? 0.24 : 0.12) }
            }
        }

        Rectangle {
            id: sun
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 52
            anchors.topMargin: 48
            width: 40
            height: 40
            radius: 20
            color: Qt.alpha("#ffe0a3", Colours.light ? 0.55 : 0.25)

            Rectangle {
                anchors.centerIn: parent
                width: 76
                height: 76
                radius: 38
                color: Qt.alpha("#ffe0a3", 0.035)
            }
        }
    }

    MaterialIcon {
        x: root.width * 0.62
        y: root.height * 0.28
        text: "cloud"
        fill: 1
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
        color: Qt.alpha(Colours.light ? "#ffffff" : "#dce8f7", root.cloudy ? 0.11 : 0.055)
    }

    MaterialIcon {
        x: root.width * 0.35
        y: root.height * 0.48
        text: "cloud"
        fill: 1
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
        color: Qt.alpha(Colours.light ? "#ffffff" : "#dce8f7", root.cloudy ? 0.065 : 0.03)
    }
}
