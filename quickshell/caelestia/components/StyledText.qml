pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

Text {
    id: root

    property bool animate: false

    // A value change is one reversible settle rather than a fade-out / cut /
    // fade-in. The spring retargets when values arrive quickly (wifi strength,
    // volume, track title), so the glyph never jumps between two timelines.
    property real swapStage: 1

    Behavior on swapStage {
        SpringAnim {
            role: SpringAnim.Content
            epsilon: 0.002
        }
    }

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Colours.palette.m3onSurface
    font: Tokens.font.body.small

    // The glyph dips a few percent while the value changes, then springs back
    // as it fades in, so the swap reads as a settle instead of a blink.
    transform: Scale {
        xScale: 0.94 + 0.06 * root.swapStage
        yScale: 0.94 + 0.06 * root.swapStage
    }

    // Kept: the universal colour shift that tracks the Material 3 palette.
    Behavior on color {
        CAnim {}
    }

    Behavior on text {
        enabled: root.animate

        SequentialAnimation {
            ScriptAction {
                script: root.swapStage = 0
            }
            Anim {
                target: root
                property: "opacity"
                to: 0
                type: Anim.DefaultEffects
            }
            PropertyAction {}
            ScriptAction {
                script: root.swapStage = 1
            }
            Anim {
                target: root
                property: "opacity"
                to: 1
                type: Anim.DefaultEffects
            }
        }
    }
}
