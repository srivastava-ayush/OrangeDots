pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

// Subtle audio-reactive equaliser strip; spans whatever width it's given
Item {
    id: root

    property int barWidth: 5
    property int barSpacing: 3

    readonly property bool playing: Players.active?.isPlaying ?? false
    readonly property int barCount: Math.max(2, Math.floor((width + barSpacing) / (barWidth + barSpacing)))

    // Hold a ref so the cava service actually starts its capture thread
    ServiceRef {
        service: Audio.cava
    }

    implicitHeight: Tokens.padding.extraLarge
    opacity: playing ? 1 : 0.35

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    Repeater {
        model: root.barCount

        StyledRect {
            id: bar

            required property int index

                readonly property real level: {
                    const vals = Audio.cava.values;
                    if (!vals.length || !root.playing)
                        return 0;
                    // Sample across the spectrum so neighbours move smoothly together,
                    // then lift quiet bins with a gamma curve so bars visibly dance
                    const idx = Math.floor((index + 0.5) * vals.length / root.barCount);
                    const raw = Math.max(0, Math.min(1, vals[idx]));
                    return Math.pow(raw, 0.4);
                }

            // Distribute the bars evenly across the full width
            x: Math.round(index * (root.width - root.barWidth) / (root.barCount - 1))
            y: root.height - height
            width: root.barWidth
            height: Tokens.padding.extraSmall + level * (root.height - Tokens.padding.extraSmall)
            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            Behavior on height {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
