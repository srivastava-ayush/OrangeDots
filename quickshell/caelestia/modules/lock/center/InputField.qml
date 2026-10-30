pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Qt owns editing, masking, cursor movement and rendering. No duplicate
// password buffer, character delegates, hidden text, or model recovery timers.
TextInput {
    id: root

    required property real centerScale
    property string placeholderText: qsTr("Enter your password")
    property bool wakeTracing: false
    signal pointerPressed
    readonly property real placeholderWidth: placeholder.implicitWidth

    focus: true
    echoMode: TextInput.Password
    passwordCharacter: "\u2022"
    passwordMaskDelay: 0
    inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
    selectByMouse: false
    persistentSelection: false
    clip: true
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter
    color: Colours.palette.m3onSurface
    font: Tokens.font.body.builders.medium.scale(centerScale).width(110).build()
    cursorVisible: activeFocus && !readOnly && length > 0

    TapHandler {
        enabled: root.wakeTracing
        gesturePolicy: TapHandler.DragThreshold
        onPressedChanged: {
            if (pressed)
                root.pointerPressed();
        }
    }

    // Keep the existing Ctrl+Backspace-to-clear shortcut. All ordinary editing
    // (including Backspace, Unicode and key repeats) stays with TextInput.
    Keys.onPressed: event => {
        if (!readOnly && event.key === Qt.Key_Backspace && (event.modifiers & Qt.ControlModifier)) {
            clear();
            event.accepted = true;
        }
    }

    Connections {
        target: root
        function onTextEdited(): void { feedback.restart(); }
    }

    StyledText {
        id: placeholder

        anchors.centerIn: parent
        visible: root.length === 0
        text: root.placeholderText
        font: root.font
        color: Colours.palette.m3outline
    }

    // Decorative only: the native masked text is always visible, including
    // when animations are disabled or interrupted by display power changes.
    SequentialAnimation {
        id: feedback

        Anim {
            target: root
            property: "scale"
            from: 1
            to: 1.035
            type: Anim.FastEffects
        }
        Anim {
            target: root
            property: "scale"
            to: 1
            type: Anim.FastEffects
        }
    }
}
