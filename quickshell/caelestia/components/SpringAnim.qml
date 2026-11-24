import QtQuick
import Caelestia.Config

// Central spring presets so surface motion is named instead of hand-tuned at
// each call site. The per-role values preserve the tuning each surface had
// before this component existed; `epsilon` stays at the call site because it is
// measured in the animated property's own units (pixels vs. a 0..1 stage).
SpringAnimation {
    enum Role {
        Surface,       // Popout shell size and anchor travel: springy, slightly underdamped
        Anchor,        // Popout anchor offset: same family, a hair softer
        Panel,         // Popout content reveal
        PanelClose,    // Popout content leaving: stiffer, clears before the next card arrives
        Snap,          // Compact pills and sidebar tabs: snappy, settles quickly
        Launcher,      // Launcher surface opening: soft and floaty
        LauncherClose, // Launcher surface closing: stiff, gets out of the way
        Island,        // Media island opening
        Dismiss,       // Stiff, no visible bounce: island and dashboard closing
        Reveal,        // Dashboard surface opening
        Card,          // Wallpaper strip card morph: stiff, deliberately no overshoot
        Content        // Inner glyphs/labels settling inside an already-moving surface
    }

    property int role: SpringAnim.Surface

    // Tween durations already scale with `anim.durations.scale` inside the
    // native token object. Springs have no duration to scale, so scale the
    // oscillator: Qt integrates `v += spring * error - damping * v` per 16 ms
    // tick, so stiffness / t² and damping / t keep the damping ratio (the
    // shape, including overshoot) and multiply the period by t. Identity at
    // 100%. The floor is a stability limit, not taste: Qt clamps damping at
    // 1.0 and the explicit integrator diverges once `spring * 0.016` passes
    // ~1, which going much below 0.5x would do to the stiffest role.
    readonly property real timeScale: Math.max(0.5, Tokens.anim.durations.scale)

    readonly property var tuning: {
        switch (role) {
        case SpringAnim.Anchor:
            return { spring: 3.2, damping: 0.50 };
        case SpringAnim.Panel:
            return { spring: 4.5, damping: 0.55 };
        case SpringAnim.PanelClose:
            return { spring: 7.0, damping: 0.70 };
        case SpringAnim.Snap:
            return { spring: 6.0, damping: 0.50 };
        case SpringAnim.Launcher:
            return { spring: 2.2, damping: 0.22 };
        case SpringAnim.LauncherClose:
            return { spring: 5.4, damping: 0.50 };
        case SpringAnim.Island:
            return { spring: 3.4, damping: 0.30 };
        case SpringAnim.Dismiss:
            return { spring: 4.0, damping: 0.40 };
        case SpringAnim.Reveal:
            return { spring: 3.8, damping: 0.30 };
        case SpringAnim.Card:
            // Qt clamps damping above 1.0; 1.0 is the stiffest setting that
            // still settles without overshoot, which is the point of this role.
            return { spring: 14.0, damping: 1.00 };
        case SpringAnim.Content:
            // A glyph or label settling inside a panel that is already moving.
            // Nearly critical, so it eases with the surface instead of adding
            // a second bounce on top of the pill/panel spring.
            return { spring: 4.5, damping: 0.80 };
        default:
            return { spring: 3.2, damping: 0.48 };
        }
    }

    spring: tuning.spring / (timeScale * timeScale)
    damping: tuning.damping / timeScale
    mass: 1
}
