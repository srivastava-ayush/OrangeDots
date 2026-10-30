pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.lock

FocusScope {
    id: root
    objectName: "lockPasswordInput"

    required property real centerScale
    required property int centerWidth
    required property var lock
    readonly property alias input: field
    readonly property bool windowActive: Window.active
    readonly property bool editable: !lock.unlocking && !lock.pam.passwd.active && lock.pam.state !== Pam.MaxTries
    readonly property real controlSize: Math.ceil(arrow.implicitHeight + Tokens.padding.extraSmall * 2)
    signal pointerPressed


    focus: true
    implicitWidth: field.length > 0 ? centerWidth * 0.8 : Math.min(centerWidth * 0.8, field.placeholderWidth + leading.implicitWidth + submit.implicitWidth + row.spacing * 2 + Tokens.padding.medium * 2)
    implicitHeight: controlSize + Tokens.padding.extraSmall * 2

    function activateInput(): void {
        if (visible && !lock.unlocking)
            field.forceActiveFocus(Qt.OtherFocusReason);
    }

    function submitPassword(): void {
        if (!lock.unlocking && (editable || (field.length === 0 && lock.pam.howdy.canAttempt)))
            lock.pam.submitPassword(field.text);
    }

    Component.onCompleted: Qt.callLater(root.activateInput)
    onWindowActiveChanged: {
        if (windowActive)
            activateInput();
    }
    onVisibleChanged: {
        if (visible)
            Qt.callLater(root.activateInput);
    }

    Connections {
        target: root.lock
        function onInputRequested(): void { root.activateInput(); }
    }

    Connections {
        target: root.lock.pam
        function onClearInput(): void { field.clear(); }
    }

    Behavior on implicitWidth {
        Anim { type: Anim.FastSpatial }
    }

    StyledRect {
        anchors.fill: parent
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer

        StateLayer {
            hoverEnabled: false
            cursorShape: Qt.IBeamCursor
            onClicked: root.activateInput()
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall
        spacing: Tokens.spacing.medium

        Item {
            id: leading

            Layout.fillHeight: true
            implicitWidth: root.controlSize

            AnimLoader {
                anchors.centerIn: parent
                sourceComp: root.lock.pam.passwd.active || root.lock.pam.howdy.active ? spinner : lockIcon
            }

            Component {
                id: spinner
                LoadingIndicator {
                    implicitSize: leading.height - Tokens.padding.small * 2
                }
            }

            Component {
                id: lockIcon
                MaterialIcon {
                    animate: true
                    text: root.lock.pam.fprint.active ? "fingerprint" : root.lock.pam.howdy.canAttempt ? "face" : "lock"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale).build()
                    fill: 1
                }
            }
        }

        InputField {
            id: field
            objectName: "lockPasswordField"

            Layout.fillWidth: true
            Layout.fillHeight: true
            centerScale: root.centerScale
            wakeTracing: root.lock.wakeTracing
            onPointerPressed: root.pointerPressed()
            readOnly: !root.editable
            placeholderText: root.lock.pam.passwd.active ? qsTr("Loading…") : root.lock.pam.howdy.active ? qsTr("Scanning face…") : root.lock.pam.state === Pam.MaxTries ? qsTr("Max tries reached") : qsTr("Enter your password")
            onAccepted: root.submitPassword()
            onTextEdited: {
                if (root.lock.pam.howdy.active)
                    root.lock.pam.howdy.abort();
            }
        }

        Item {
            id: submit

            implicitWidth: root.controlSize
            implicitHeight: root.controlSize

            MaterialShape {
                anchors.fill: parent
                color: field.length > 0 ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                shape: field.length > 0 ? MaterialShape.Arrow : MaterialShape.Circle
                rotation: 90
                scale: field.length === 0 ? 1 : mouse.pressed ? 0.6 : mouse.containsMouse ? 0.8 : 0.7

                Behavior on scale { Anim { type: Anim.FastSpatial } }
                Behavior on color { CAnim {} }
            }

            MaterialIcon {
                id: arrow

                anchors.centerIn: parent
                text: "arrow_forward"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.medium.scale(root.centerScale * 1.2).build()
                opacity: field.length > 0 ? 0 : 1
                Behavior on opacity { Anim { type: Anim.FastEffects } }
            }

            MouseArea {
                id: mouse
                objectName: "lockSubmitButton"

                anchors.fill: parent
                enabled: root.editable && field.length > 0
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.submitPassword()
            }
        }
    }
}
