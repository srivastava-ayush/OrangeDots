pragma ComponentBehavior: Bound

import "center"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config

ColumnLayout {
    id: root

    required property var lock
    readonly property alias passwordInput: passwordInput
    readonly property alias stateMessage: stateMessage
    readonly property real centerScale: Math.min(1, lock.screenHeight / 1440)
    readonly property int centerWidth: Math.max(0, Math.min(Tokens.sizes.lock.centerWidth * centerScale, lock.width - Tokens.padding.extraLargeIncreased))

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true
    spacing: Tokens.spacing.largeIncreased

    Clock {
        objectName: "lockClock"
        Layout.alignment: Qt.AlignHCenter
        centerScale: root.centerScale
        transform: Translate {
            y: -root.lock.screenHeight * 0.75 * (1 - root.lock.contentProgress)
        }
    }

    RowLayout {
        objectName: "lockPasswordRow"
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium
        transform: Translate {
            y: root.lock.screenHeight * 0.75 * (1 - root.lock.contentProgress)
        }

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
        id: stateMessage
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
