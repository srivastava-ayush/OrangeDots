import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen?.height ?? 1440) / 1440)
    readonly property int centerWidth: Tokens.sizes.lock.centerWidth * centerScale

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true

    spacing: Tokens.spacing.largeIncreased

    Clock {
        Layout.alignment: Qt.AlignHCenter
        centerScale: root.centerScale
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        ProfilePic {
            centerWidth: root.centerWidth
            size: passwordInput.implicitHeight
        }

        PasswordInput {
            id: passwordInput
            Layout.alignment: Qt.AlignVCenter
            centerWidth: root.centerWidth
            centerScale: Math.max(0.8, root.centerScale)
            lock: root.lock
        }
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
