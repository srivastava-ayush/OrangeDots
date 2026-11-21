pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.components

// Clock/date glyphs pick up their own defocus during the hide/return animation.
// The blur is gated per text item so there is no layer while the clock is idle.
StyledText {
    required property real hideProgress

    layer.enabled: hideProgress > 0.001 && hideProgress < 0.999
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: Math.sin(hideProgress * Math.PI)
        blurMax: 32
        blurMultiplier: 1
    }
}
