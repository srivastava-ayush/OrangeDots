pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState
    required property real reveal
    signal actionRequested(command: var)

    implicitWidth: 880
    implicitHeight: 244
    scale: 0.94 + reveal * 0.06
    transformOrigin: Item.Center
    Keys.onEscapePressed: root.screenState.session = false

    // Clicks in the card's padding/gaps dismiss it; action buttons above this
    // area still consume their own clicks normally.
    MouseArea {
        anchors.fill: parent
        onClicked: root.screenState.session = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            SessionButton {
                id: lock
                objectName: "sessionLock"
                order: 0
                icon: "lock"
                title: qsTr("Lock")
                subtitle: qsTr("Stay private")
                // Talk to the running shell directly; the caelestia CLI adds
                // Python startup latency before the lock animation begins.
                command: ["qs", "-c", "caelestia", "ipc", "call", "lock", "lock"]
                KeyNavigation.right: logout
                KeyNavigation.down: logout
                Component.onCompleted: forceActiveFocus()
            }
            SessionButton {
                id: logout
                order: 1
                icon: Config.session.icons.logout
                title: qsTr("Sign out")
                subtitle: qsTr("Step away")
                accent: Colours.palette.m3tertiary
                command: Config.session.commands.logout
                KeyNavigation.left: lock
                KeyNavigation.right: hibernate
                KeyNavigation.up: lock
                KeyNavigation.down: hibernate
            }
            SessionButton {
                id: hibernate
                order: 2
                icon: Config.session.icons.hibernate
                title: qsTr("Hibernate")
                subtitle: qsTr("Save this moment")
                accent: Colours.palette.m3secondary
                command: Config.session.commands.hibernate
                KeyNavigation.left: logout
                KeyNavigation.right: reboot
                KeyNavigation.up: logout
                KeyNavigation.down: reboot
            }
            SessionButton {
                id: reboot
                order: 3
                icon: Config.session.icons.reboot
                title: qsTr("Restart")
                subtitle: qsTr("Start fresh")
                command: Config.session.commands.reboot
                KeyNavigation.left: hibernate
                KeyNavigation.right: shutdown
                KeyNavigation.up: hibernate
                KeyNavigation.down: shutdown
            }
            SessionButton {
                id: shutdown
                order: 4
                icon: Config.session.icons.shutdown
                title: qsTr("Power off")
                subtitle: qsTr("Call it a day")
                accent: Colours.palette.m3error
                command: Config.session.commands.shutdown
                KeyNavigation.left: reboot
                KeyNavigation.up: reboot
            }
        }

    }

    component SessionButton: ButtonBase {
        id: button

        required property list<string> command
        required property string icon
        required property string title
        required property string subtitle
        required property int order
        property color accent: Colours.palette.m3primary
        property real entrance: 0
        readonly property bool presented: root.screenState.session
        readonly property bool highlighted: activeFocus || hovered
        property real lift: highlighted ? 1 : 0

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: 0
        implicitWidth: 152
        implicitHeight: 188
        color: "transparent"
        inactiveOnColour: accent
        activeOnColour: accent
        radius: pressed ? 20 : 26
        opacity: entrance
        scale: (0.82 + entrance * 0.18) * (1 + lift * 0.025)
        transformOrigin: Item.Bottom
        transform: [
            Translate { y: (1 - button.entrance) * 52 - button.lift * 7 },
            Rotation {
                origin.x: button.width / 2
                origin.y: button.height
                axis { x: 1; y: 0; z: 0 }
                angle: (1 - button.entrance) * 18
            }
        ]

        Behavior on lift { Anim { type: Anim.FastSpatial } }

        Rectangle {
            anchors.fill: parent
            z: -1
            radius: button.radius
            border.width: 1
            border.color: Qt.alpha(button.accent, 0.18 + button.lift * 0.5)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(button.accent, 0.08 + button.lift * 0.2) }
                GradientStop { position: 1; color: Qt.alpha(button.accent, 0.025 + button.lift * 0.035) }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 68
                implicitHeight: 68
                radius: 22 + button.lift * 12
                color: Qt.alpha(button.accent, 0.12 + button.lift * 0.12)
                border.width: 1
                border.color: Qt.alpha(button.accent, 0.15 + button.lift * 0.25)

                MaterialIcon {
                    anchors.centerIn: parent
                    text: button.icon
                    color: button.accent
                    fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
                }
            }
            StyledText {
                Layout.fillWidth: true
                text: button.title
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: button.subtitle
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
            Item { Layout.fillHeight: true }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 16 + button.lift * 20
                implicitHeight: 3
                radius: 2
                color: button.accent
                opacity: 0.25 + button.lift * 0.75
            }
        }

        onPresentedChanged: {
            if (presented) {
                exitAnimation.stop();
                enterAnimation.restart();
            } else {
                enterAnimation.stop();
                exitAnimation.restart();
            }
        }
        Component.onCompleted: if (presented) enterAnimation.start()

        SequentialAnimation {
            id: enterAnimation
            PauseAnimation { duration: button.order * Tokens.anim.durations.expressiveFastEffects * 0.55 }
            Anim {
                target: button
                property: "entrance"
                from: 0
                to: 1
                type: Anim.SlowSpatial
                easing.type: Easing.OutBack
                easing.overshoot: 0.65
            }
        }
        Anim {
            id: exitAnimation
            target: button
            property: "entrance"
            to: 0
            type: Anim.FastEffects
            easing.type: Easing.InCubic
        }

        function exec(): void {
            if (root.screenState.session)
                root.actionRequested(command);
        }
        onClicked: exec()
        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (Config.session.vimKeybinds && (event.modifiers & Qt.ControlModifier)) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.right) {
                    KeyNavigation.right.forceActiveFocus();
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.left) {
                    KeyNavigation.left.forceActiveFocus();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.left) {
                    KeyNavigation.left.forceActiveFocus();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.right) {
                KeyNavigation.right.forceActiveFocus();
                event.accepted = true;
            }
        }
    }
}
