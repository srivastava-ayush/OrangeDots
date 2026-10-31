pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

// Pure UI: no Wayland lock requests and no authentication decisions. One
// progress value owns the entrance/curtain/exit instead of imperative resets
// across several independent animations. The secure surface owns its lifetime.
FocusScope {
    id: root

    required property Pam pam
    property bool animateEntrance: true
    property bool wakeTracing: false
    property real progress: 1
    property bool unlocking: false
    readonly property real contentProgress: Math.max(0, Math.min(1, (progress - 0.25) / 0.75))
    readonly property real screenHeight: height > 0 ? height : 1440
    readonly property alias passwordInput: center.passwordInput
    readonly property alias stateMessage: center.stateMessage

    signal inputRequested
    signal exitFinished

    focus: true
    clip: true

    function settle(): void {
        if (unlocking)
            return;
        transition.stop();
        progress = 1;
        inputRequested();
    }

    function unlock(): void {
        if (unlocking)
            return;
        transition.stop();
        unlocking = true;
        // Clear this view even when it is exercised without a secure surface.
        // PAM also broadcasts draft clearing to every output on real unlock.
        passwordInput.input.clear();
        transition.to = 0;
        transition.start();
    }

    Component.onCompleted: {
        if (animateEntrance) {
            progress = 0;
            transition.to = 1;
            transition.start();
        } else {
            settle();
        }
    }

    onAnimateEntranceChanged: {
        if (!animateEntrance)
            settle();
    }

    Anim {
        id: transition

        target: root
        property: "progress"
        type: root.unlocking ? Anim.FastSpatial : Anim.SlowSpatial
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.unlocking)
                root.exitFinished();
            else
                root.inputRequested();
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        text: "lock"
        fontStyle: Tokens.font.icon.builders.extraLarge.scale(4).weight(Font.Bold).build()
        rotation: 180 + 180 * root.progress
        scale: 0.7 + 0.3 * root.progress
        opacity: (1 - root.contentProgress) * (root.unlocking ? Math.min(1, root.progress * 4) : 1)
    }

    Center {
        id: center

        anchors.centerIn: parent
        width: centerWidth
        // Keep clock/input together instead of distributing spare screen height
        // between the rows of the center column.
        height: implicitHeight
        lock: root
        opacity: root.contentProgress
        scale: 0.9 + 0.1 * root.contentProgress
    }
}
