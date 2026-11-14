import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("On-screen display")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            objectName: "osdEnabled"
            first: true
            text: qsTr("Enable on-screen display")
            subtext: qsTr("Show volume, brightness and microphone overlays")
            checked: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        StepperRow {
            objectName: "osdHideDelay"
            last: true
            label: qsTr("Hide delay (ms)")
            subtext: qsTr("How long the overlay stays visible after a change")
            enabled: Config.osd.enabled
            opacity: enabled ? 1 : 0.5
            value: Config.osd.hideDelay
            from: 500
            to: 10000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = Math.round(v)
        }

        SectionHeader {
            text: qsTr("Content")
        }

        ToggleRow {
            objectName: "osdBrightness"
            first: true
            text: qsTr("Brightness")
            subtext: qsTr("Show the brightness slider when brightness changes")
            checked: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            objectName: "osdMicrophone"
            last: true
            text: qsTr("Microphone")
            subtext: qsTr("Show the microphone overlay when the source changes")
            checked: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }
    }
}
