pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

RowLayout {
    id: root

    spacing: Tokens.spacing.extraSmall

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: Time.hourStr
        color: Colours.palette.m3onSurface
        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: ":"
        color: Colours.palette.m3primary
        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: Time.minuteStr
        color: Colours.palette.m3onSurface
        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
    }

    Loader {
        asynchronous: true
        Layout.alignment: Qt.AlignVCenter

        active: GlobalConfig.services.useTwelveHourClock
        visible: active

        sourceComponent: StyledText {
            text: Time.amPmStr.toLowerCase()
            color: Colours.palette.m3primary
            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Tokens.spacing.small
        text: Time.format("ddd, MMM d")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.builders.small.build()
    }
}
