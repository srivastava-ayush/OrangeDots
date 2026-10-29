pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> qualityItems: [
        MenuItem {
            text: qsTr("Medium")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("High")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("Very high")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("Ultra")
            icon: "bolt"
        }
    ]
    readonly property list<string> qualityValues: RecorderSettings.qualities

    readonly property list<MenuItem> codecItems: [
        MenuItem {
            text: qsTr("H.264 · most compatible")
            icon: "movie"
        },
        MenuItem {
            text: qsTr("HEVC · smaller files")
            icon: "movie"
        },
        MenuItem {
            text: qsTr("AV1 · best compression")
            icon: "movie"
        }
    ]
    readonly property list<string> codecValues: RecorderSettings.codecs

    readonly property list<MenuItem> frameRateItems: [
        MenuItem {
            text: qsTr("Display refresh rate")
            icon: "monitor"
        },
        MenuItem {
            text: qsTr("30 fps")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("60 fps")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("90 fps")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("120 fps")
            icon: "speed"
        },
        MenuItem {
            text: qsTr("144 fps")
            icon: "speed"
        }
    ]
    readonly property list<string> frameRateValues: RecorderSettings.frameRates

    readonly property list<MenuItem> tuneItems: [
        MenuItem {
            text: qsTr("Quality")
            icon: "high_quality"
        },
        MenuItem {
            text: qsTr("Performance")
            icon: "speed"
        }
    ]
    readonly property list<string> tuneValues: RecorderSettings.tunes

    function selectedIndex(values: var, current: var): int {
        return Math.max(0, values.indexOf(current));
    }

    title: qsTr("Screen recorder")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Capture
        SectionHeader {
            first: true
            text: qsTr("Capture")
        }

        InfoRow {
            objectName: "recorderResolution"
            icon: "fullscreen"
            label: qsTr("Resolution")
            value: qsTr("Native (maximum)")
            subtext: qsTr("The display or selected region at full size · never downscaled")
        }

        // Video
        SectionHeader {
            text: qsTr("Video")
        }

        SelectRow {
            objectName: "recorderQuality"
            first: true
            label: qsTr("Quality")
            subtext: qsTr("Ultra keeps the most detail with constant-quality encoding")
            menuItems: root.qualityItems
            active: root.qualityItems[root.selectedIndex(root.qualityValues, RecorderSettings.quality)]
            onSelected: item => RecorderSettings.setQuality(root.qualityValues[root.qualityItems.indexOf(item)])
        }

        SelectRow {
            objectName: "recorderCodec"
            label: qsTr("Codec")
            subtext: qsTr("HEVC and AV1 save space; H.264 plays everywhere")
            menuItems: root.codecItems
            active: root.codecItems[root.selectedIndex(root.codecValues, RecorderSettings.codec)]
            onSelected: item => RecorderSettings.setCodec(root.codecValues[root.codecItems.indexOf(item)])
        }

        SelectRow {
            objectName: "recorderFrameRate"
            label: qsTr("Frame rate")
            subtext: qsTr("Display follows the monitor's current refresh rate")
            menuItems: root.frameRateItems
            active: root.frameRateItems[root.selectedIndex(root.frameRateValues, RecorderSettings.frameRate)]
            onSelected: item => RecorderSettings.setFrameRate(root.frameRateValues[root.frameRateItems.indexOf(item)])
        }

        SelectRow {
            objectName: "recorderTune"
            last: true
            label: qsTr("Encoder tune")
            subtext: qsTr("Quality favours detail; performance favours lower GPU load")
            menuItems: root.tuneItems
            active: root.tuneItems[root.selectedIndex(root.tuneValues, RecorderSettings.tune)]
            onSelected: item => RecorderSettings.setTune(root.tuneValues[root.tuneItems.indexOf(item)])
        }

        // Input
        SectionHeader {
            text: qsTr("Input")
        }

        ToggleRow {
            objectName: "recorderCursor"
            first: true
            last: true
            text: qsTr("Show cursor")
            subtext: qsTr("Include the mouse pointer in recordings")
            checked: RecorderSettings.cursor
            onToggled: RecorderSettings.setCursor(checked)
        }

        // Maintenance
        SectionHeader {
            text: qsTr("Maintenance")
        }

        RowButton {
            objectName: "recorderReset"
            first: true
            last: true
            icon: "restart_alt"
            text: qsTr("Reset to highest quality")
            subtext: qsTr("Native resolution, Ultra, H.264, display frame rate, quality tune")
            disabled: RecorderSettings.isDefault
            onClicked: RecorderSettings.reset()
        }

        StyledText {
            Layout.fillWidth: true
            Layout.margins: Tokens.padding.small
            text: qsTr("Saved to ~/.config/caelestia/cli.json · applies to the next recording")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
