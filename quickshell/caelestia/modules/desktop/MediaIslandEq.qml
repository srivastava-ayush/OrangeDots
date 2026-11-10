pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Fixed three-band equaliser for the media island. Unlike the dashboard's
// cava-driven spectrum this reads no audio data: each bar loops through its
// own hardcoded keyframes and only needs to know whether playback is active.
Item {
    id: root

    property bool playing: false
    property color colour: Colours.palette.m3primary
    property int barWidth: 3
    property int barSpacing: 2
    readonly property int barCount: 3

    implicitWidth: barCount * barWidth + (barCount - 1) * barSpacing
    implicitHeight: 12

    opacity: playing ? 1 : 0.45

    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    Repeater {
        model: root.barCount

        StyledRect {
            id: bar

            required property int index

            // One hardcoded pattern per band, so the three bars never move
            // as a single block.
            readonly property var keyframes: [
                [0.95, 0.35, 0.7, 0.45],
                [0.55, 1, 0.4, 0.75],
                [0.7, 0.45, 0.95, 0.5]
            ][index]

            property real level: 0.3

            x: index * (root.barWidth + root.barSpacing)
            y: root.height - height
            width: root.barWidth
            height: Tokens.padding.extraSmall + level * (root.height - Tokens.padding.extraSmall)
            radius: Tokens.rounding.full
            color: root.colour

            // Deterministic keyframes, intentionally independent per bar.
            SequentialAnimation {
                id: wave

                running: root.playing
                loops: Animation.Infinite

                NumberAnimation {
                    target: bar
                    property: "level"
                    to: bar.keyframes[0]
                    duration: 330 + bar.index * 90
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: bar
                    property: "level"
                    to: bar.keyframes[1]
                    duration: 260 + bar.index * 70
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: bar
                    property: "level"
                    to: bar.keyframes[2]
                    duration: 310 + bar.index * 50
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: bar
                    property: "level"
                    to: bar.keyframes[3]
                    duration: 420 - bar.index * 40
                    easing.type: Easing.InOutSine
                }

                // Pausing stops the loop wherever it is and settles the bar.
                onStopped: bar.level = 0.3
            }

            // Only smooth the settle when the keyframe loop is not driving
            // the level itself.
            Behavior on level {
                enabled: !wave.running

                Anim {
                    type: Anim.FastEffects
                }
            }
        }
    }
}
