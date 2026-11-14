import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Lock screen")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Behaviour")
        }

        ToggleRow {
            objectName: "lockEnabled"
            first: true
            text: qsTr("Enable lock screen")
            subtext: qsTr("Show the Caelestia lock screen when the session is locked")
            checked: Config.lock.enabled
            onToggled: GlobalConfig.lock.enabled = checked
        }

        ToggleRow {
            objectName: "lockWallpaper"
            last: true
            text: qsTr("Use wallpaper as background")
            subtext: qsTr("Otherwise the screen is captured when locking")
            checked: Config.lock.useWallpaper
            onToggled: GlobalConfig.lock.useWallpaper = checked
        }

        SectionHeader {
            text: qsTr("Fingerprint")
        }

        ToggleRow {
            objectName: "lockFingerprint"
            first: true
            text: qsTr("Unlock with fingerprint")
            subtext: qsTr("Requires a fingerprint enrolled with fprintd")
            checked: Config.lock.enableFprint
            onToggled: GlobalConfig.lock.enableFprint = checked
        }

        StepperRow {
            objectName: "lockFingerprintTries"
            last: true
            label: qsTr("Maximum fingerprint attempts")
            subtext: qsTr("Fall back to the password after this many failures")
            enabled: Config.lock.enableFprint
            opacity: enabled ? 1 : 0.5
            value: Config.lock.maxFprintTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxFprintTries = Math.round(v)
        }

        SectionHeader {
            text: qsTr("Face unlock")
        }

        ToggleRow {
            objectName: "lockFace"
            first: true
            text: qsTr("Unlock with face recognition")
            subtext: qsTr("Requires Howdy to be installed and configured")
            checked: Config.lock.enableHowdy
            onToggled: GlobalConfig.lock.enableHowdy = checked
        }

        StepperRow {
            objectName: "lockFaceTries"
            label: qsTr("Maximum face attempts")
            subtext: qsTr("Fall back to the password after this many failures")
            enabled: Config.lock.enableHowdy
            opacity: enabled ? 1 : 0.5
            value: Config.lock.maxHowdyTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxHowdyTries = Math.round(v)
        }

        ToggleRow {
            objectName: "lockFaceOnWake"
            last: true
            text: qsTr("Try face unlock on wake")
            subtext: qsTr("Start a Howdy attempt automatically when the lock screen appears")
            checked: Config.lock.triggerHowdyOnWake
            enabled: Config.lock.enableHowdy
            opacity: enabled ? 1 : 0.5
            onToggled: GlobalConfig.lock.triggerHowdyOnWake = checked
        }

        SectionHeader {
            text: qsTr("Shortcut")
        }

        InfoRow {
            first: true
            last: true
            icon: "lock"
            label: qsTr("Lock the session")
            value: "SUPER + L"
            subtext: qsTr("The lockscreen can also be triggered from the session menu")
        }
    }
}
