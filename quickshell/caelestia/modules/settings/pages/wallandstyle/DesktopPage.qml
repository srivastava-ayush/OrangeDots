pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Desktop")
    isSubPage: true

    readonly property var positionValues: ["top-left", "top-center", "top-right", "middle-left", "middle-center", "middle-right", "bottom-left", "bottom-center", "bottom-right"]
    readonly property list<MenuItem> positionItems: [
        MenuItem {
            text: qsTr("Top left")
        },
        MenuItem {
            text: qsTr("Top center")
        },
        MenuItem {
            text: qsTr("Top right")
        },
        MenuItem {
            text: qsTr("Middle left")
        },
        MenuItem {
            text: qsTr("Middle center")
        },
        MenuItem {
            text: qsTr("Middle right")
        },
        MenuItem {
            text: qsTr("Bottom left")
        },
        MenuItem {
            text: qsTr("Bottom center")
        },
        MenuItem {
            text: qsTr("Bottom right")
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Desktop clock")
        }

        ToggleRow {
            objectName: "desktopClockEnabled"
            first: true
            text: qsTr("Show desktop clock")
            subtext: qsTr("Overlay a large clock on the wallpaper")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            objectName: "desktopClockPosition"
            label: qsTr("Position")
            subtext: qsTr("Where the clock sits on the screen")
            menuItems: root.positionItems
            active: root.positionItems[Math.max(0, root.positionValues.indexOf(Config.background.desktopClock.position))]
            onSelected: item => GlobalConfig.background.desktopClock.position = root.positionValues[root.positionItems.indexOf(item)]
        }

        StepperRow {
            objectName: "desktopClockScale"
            label: qsTr("Clock size (%)")
            subtext: qsTr("Scales the clock without changing other desktop elements")
            enabled: Config.background.desktopClock.enabled
            opacity: enabled ? 1 : 0.5
            value: Math.round(Config.background.desktopClock.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.background.desktopClock.scale = v / 100
        }

        ToggleRow {
            objectName: "desktopClockInvert"
            last: true
            text: qsTr("Invert text colours")
            subtext: qsTr("Use dark text on bright wallpapers")
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        SectionHeader {
            text: qsTr("Clock background")
        }

        ToggleRow {
            objectName: "desktopClockBackground"
            first: true
            text: qsTr("Show background")
            subtext: qsTr("Place a translucent card behind the clock")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        SliderRow {
            objectName: "desktopClockBackgroundOpacity"
            icon: "opacity"
            label: qsTr("Background opacity")
            valueLabel: `${Math.round(value * 100)}%`
            value: Config.background.desktopClock.background.opacity
            enabled: Config.background.desktopClock.background.enabled
            onMoved: v => GlobalConfig.background.desktopClock.background.opacity = v
        }

        ToggleRow {
            objectName: "desktopClockBackgroundBlur"
            last: true
            text: qsTr("Blur wallpaper behind clock")
            checked: Config.background.desktopClock.background.blur
            enabled: Config.background.desktopClock.background.enabled
            opacity: enabled ? 1 : 0.5
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
        }

        SectionHeader {
            text: qsTr("Clock shadow")
        }

        ToggleRow {
            objectName: "desktopClockShadow"
            first: true
            text: qsTr("Show shadow")
            subtext: qsTr("Keep the clock readable over busy wallpapers")
            checked: Config.background.desktopClock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        SliderRow {
            objectName: "desktopClockShadowOpacity"
            icon: "opacity"
            label: qsTr("Shadow opacity")
            valueLabel: `${Math.round(value * 100)}%`
            value: Config.background.desktopClock.shadow.opacity
            enabled: Config.background.desktopClock.shadow.enabled
            onMoved: v => GlobalConfig.background.desktopClock.shadow.opacity = v
        }

        SliderRow {
            objectName: "desktopClockShadowBlur"
            last: true
            icon: "blur_on"
            label: qsTr("Shadow blur")
            valueLabel: `${Math.round(value * 100)}%`
            value: Config.background.desktopClock.shadow.blur
            enabled: Config.background.desktopClock.shadow.enabled
            onMoved: v => GlobalConfig.background.desktopClock.shadow.blur = v
        }

        SectionHeader {
            text: qsTr("Audio visualiser")
        }

        ToggleRow {
            objectName: "desktopVisualiserEnabled"
            first: true
            text: qsTr("Show visualiser")
            subtext: qsTr("Draw a music visualiser over the wallpaper")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            objectName: "desktopVisualiserAutoHide"
            text: qsTr("Hide when idle")
            subtext: qsTr("Fade the visualiser out when no audio is playing")
            checked: Config.background.visualiser.autoHide
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.5
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            objectName: "desktopVisualiserBlur"
            text: qsTr("Blur behind visualiser")
            checked: Config.background.visualiser.blur
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.5
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            objectName: "desktopVisualiserRounding"
            label: qsTr("Bar rounding (%)")
            subtext: qsTr("Scales the visualiser bar corners")
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.5
            value: Math.round(Config.background.visualiser.rounding * 100)
            from: 0
            to: 300
            stepSize: 10
            onMoved: v => GlobalConfig.background.visualiser.rounding = v / 100
        }

        StepperRow {
            objectName: "desktopVisualiserSpacing"
            last: true
            label: qsTr("Bar spacing (%)")
            subtext: qsTr("Scales the gap between visualiser bars")
            enabled: Config.background.visualiser.enabled
            opacity: enabled ? 1 : 0.5
            value: Math.round(Config.background.visualiser.spacing * 100)
            from: 0
            to: 300
            stepSize: 10
            onMoved: v => GlobalConfig.background.visualiser.spacing = v / 100
        }
    }
}
