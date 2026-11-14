pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Material 3 emoji/glyph picker, sharing the shell's surface, typography and
// motion instead of the old fuzzel dmenu. Selecting an emoji copies it and
// pastes it back into the window that had focus.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.emoji
    readonly property int padding: Tokens.padding.large
    readonly property real availableWidth: screenState.modelData?.width ?? 1920
    readonly property real availableHeight: screenState.modelData?.height ?? 1080

    property real revealProgress: shouldBeActive ? 1 : 0

    visible: revealProgress > 0
    implicitWidth: Math.min(460, availableWidth - padding * 2)
    implicitHeight: Math.min(520, availableHeight - padding * 2)
    opacity: revealProgress
    // Fade-through style entrance: a short pop rather than a long travel.
    scale: 0.97 + 0.03 * revealProgress

    // Quick and snappy: ~175ms in, ~120ms out, no spring overshoot. Both are
    // scaled off the fast-spatial token so the shell's animation-speed setting
    // still applies.
    Behavior on revealProgress {
        Anim {
            duration: root.shouldBeActive ? Tokens.anim.durations.expressiveFastSpatial * 0.5 : Tokens.anim.durations.expressiveFastSpatial * 0.35
            easing.type: root.shouldBeActive ? Easing.OutCubic : Easing.InQuad
        }
    }

    StyledClippingRect {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        // Match the shell's own surface so the picker reads as part of it.
        color: Colours.tPalette.m3surface

        Loader {
            anchors.fill: parent
            anchors.margins: root.padding

            active: root.shouldBeActive || root.visible

            sourceComponent: EmojiPickerContent {
                screenState: root.screenState
            }
        }
    }
}
