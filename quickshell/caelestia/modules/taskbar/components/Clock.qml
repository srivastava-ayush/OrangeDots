pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property color colour: Colours.palette.m3tertiary
    readonly property int padding: Config.bar.clock.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property var font: Tokens.font.body.builders.small.scale(1.1)
    readonly property bool horizontal: Taskbar.horizontal
    readonly property bool showDate: Config.bar.clock.showDate || Taskbar.notched
    // Set by the taskbar layout from the screen's media island state. Only the
    // top bar yields its centre; the vertical left bar must keep the date/time.
    property bool mediaIslandExpanded: false
    // Animated 0..1. Collapsing the entry's implicit width also removes its
    // notch background, so the island is not stacked beneath an empty clock
    // notch. Opacity and an upward slide hide the text while it collapses.
    property real hideProgress: horizontal && mediaIslandExpanded ? 1 : 0
    readonly property real hideOffset: horizontal ? -hideProgress * (implicitHeight + Tokens.padding.large) : 0

    signal clicked

    implicitWidth: horizontal ? Math.max(0, (horizontalLayout.implicitWidth + padding * 2) * (1 - hideProgress)) : Tokens.sizes.bar.innerWidth
    implicitHeight: (horizontal ? horizontalLayout.implicitHeight : layout.implicitHeight) + padding * 2

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, Config.bar.clock.background ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full
    opacity: 1 - hideProgress
    clip: hideProgress > 0

    Behavior on hideProgress {
        Anim {
            type: Anim.FastSpatial
            // Match the media island's slide timing exactly.
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall
        visible: !root.horizontal

        Loader {
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: Config.bar.clock.showIcon
            visible: active

            sourceComponent: MaterialIcon {
                text: "calendar_month"
                color: root.colour
            }
        }

        Loader {
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: root.showDate
            visible: active

            sourceComponent: ColumnLayout {
                spacing: layout.spacing - 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.format("ddd")
                    font: Tokens.font.body.builders.small.scale(0.9).build()
                    color: root.colour
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Time.format("d")
                    font: root.font.scale(1.1).build()
                    color: root.colour
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.leftMargin: -Tokens.padding.extraSmall
                    Layout.rightMargin: -Tokens.padding.extraSmall
                    Layout.topMargin: 4
                    Layout.bottomMargin: Tokens.padding.extraSmall / 2
                    implicitHeight: 1
                    color: Colours.palette.m3outlineVariant
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Time.hourStr
            font: {
                const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / hourMetrics.width);
                return root.font.width(scale * 100).letterSpacing(scale).build();
            }
            color: root.colour

            TextMetrics {
                id: hourMetrics

                font: root.font.build()
                text: Time.hourStr
            }
        }

        StyledText {
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            text: Time.minuteStr
            font: {
                const scale = text === "11" ? 1.15 : Math.min(1.05, Math.max(hourMetrics.width, minMetrics.width) / minMetrics.width);
                return root.font.width(scale * 100).letterSpacing(scale).build();
            }
            color: root.colour

            TextMetrics {
                id: minMetrics

                font: root.font.build()
                text: Time.minuteStr
            }
        }

        Loader {
            Layout.topMargin: -parent.spacing - 4
            Layout.alignment: Qt.AlignHCenter
            asynchronous: true
            active: GlobalConfig.services.useTwelveHourClock
            visible: active

            sourceComponent: StyledText {
                text: Time.amPmStr.toLowerCase()
                font: Tokens.font.body.builders.small.scale(0.9).build()
                color: root.colour
            }
        }

    }

    RowLayout {
        id: horizontalLayout

        anchors.centerIn: parent
        spacing: Tokens.spacing.small
        visible: root.horizontal

        MaterialIcon {
            visible: Config.bar.clock.showIcon
            text: "calendar_month"
            color: root.colour
        }

        StyledText {
            visible: root.showDate
            text: Time.format("ddd, d MMM")
            font: root.font.build()
            color: root.colour
        }

        StyledText {
            text: `${Time.hourStr}:${Time.minuteStr}${GlobalConfig.services.useTwelveHourClock ? ` ${Time.amPmStr.toLowerCase()}` : ""}`
            font: root.font.build()
            color: root.colour
        }

    }

    MouseArea {
        anchors.fill: parent
        enabled: root.horizontal && root.hideProgress < 1
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
