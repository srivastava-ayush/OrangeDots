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

    Connections {
        function onRevealContent(): void {
            curtainAnim.start();
        }

        function onSettleContent(): void {
            curtainAnim.stop();
            clockSlide.y = 0;
            passwordSlide.y = 0;
        }

        target: root.lock
    }

    ParallelAnimation {
        id: curtainAnim

        Anim {
            target: clockSlide
            property: "y"
            to: 0
            type: Anim.SlowSpatial
        }
        Anim {
            target: passwordSlide
            property: "y"
            to: 0
            type: Anim.SlowSpatial
        }
    }

    Clock {
        Layout.alignment: Qt.AlignHCenter
        centerScale: root.centerScale

        transform: Translate {
            id: clockSlide

            y: -(root.lock.screen?.height ?? 1440) * 0.75
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.medium

        transform: Translate {
            id: passwordSlide

            y: (root.lock.screen?.height ?? 1440) * 0.75
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
        Layout.fillWidth: true
        pam: root.lock.pam
    }
}
