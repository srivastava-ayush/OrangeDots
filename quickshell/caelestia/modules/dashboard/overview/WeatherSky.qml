pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
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
                GradientStop { position: 0; color: Qt.alpha("#2b4d94", Colours.light ? 0.24 : 0.6) }
                GradientStop { position: 1; color: Qt.alpha("#8a72b4", Colours.light ? 0.18 : 0.34) }
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
                color: Qt.alpha("#eef4ff", Colours.light ? 0.5 : 0.65)
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
            color: Qt.alpha("#dbe7ff", Colours.light ? 0.34 : 0.42)
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.daylight

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha("#4aa8ec", Colours.light ? 0.4 : 0.36) }
                GradientStop { position: 1; color: Qt.alpha("#ffffff", Colours.light ? 0.4 : 0.28) }
            }
        }

        // Muted yellow glow pooling at the bottom edge.
        Shape {
            id: sunBlob

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: root.width
            height: root.height * 0.9
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: sunBlob.width / 2
                    centerY: sunBlob.height
                    centerRadius: sunBlob.width / 2
                    focalX: centerX
                    focalY: centerY

                    GradientStop { position: 0; color: Qt.alpha("#dfb45c", Colours.light ? 0.34 : 0.26) }
                    GradientStop { position: 0.55; color: Qt.alpha("#dfb45c", Colours.light ? 0.16 : 0.12) }
                    GradientStop { position: 1; color: Qt.alpha("#dfb45c", 0) }
                }

                PathAngleArc {
                    centerX: sunBlob.width / 2
                    centerY: sunBlob.height
                    radiusX: sunBlob.width / 2
                    radiusY: sunBlob.height
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }
    }

    MaterialIcon {
        x: root.width * 0.62
        y: root.height * 0.28
        text: "cloud"
        fill: 1
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
        color: Qt.alpha(Colours.light ? "#ffffff" : "#e2ecfa", root.cloudy ? 0.2 : 0.1)
    }

    MaterialIcon {
        x: root.width * 0.35
        y: root.height * 0.48
        text: "cloud"
        fill: 1
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
        color: Qt.alpha(Colours.light ? "#ffffff" : "#e2ecfa", root.cloudy ? 0.12 : 0.055)
    }
}
