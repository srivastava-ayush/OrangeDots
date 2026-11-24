import QtQuick
import Caelestia.Config

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        if (type < AnchorAnim.StandardSmall || type > AnchorAnim.SlowEffects)
            return Tokens.anim.durations.normal;

        if (type === AnchorAnim.FastSpatial)
            return Tokens.anim.durations.expressiveFastSpatial;
        if (type === AnchorAnim.DefaultSpatial)
            return Tokens.anim.durations.expressiveDefaultSpatial;
        if (type === AnchorAnim.SlowSpatial)
            return Tokens.anim.durations.expressiveSlowSpatial;
        if (type === AnchorAnim.FastEffects)
            return Tokens.anim.durations.expressiveFastEffects;
        if (type === AnchorAnim.DefaultEffects)
            return Tokens.anim.durations.expressiveDefaultEffects;
        if (type === AnchorAnim.SlowEffects)
            return Tokens.anim.durations.expressiveSlowEffects;

        const types = ["small", "normal", "large", "extraLarge"];
        // 0-3 are standard, 4-7 are emphasized; both use the graded durations.
        const idx = type % 4;
        return Tokens.anim.durations[types[idx]];
    }
    easing: {
        if (type === AnchorAnim.FastSpatial)
            return Tokens.anim.expressiveFastSpatial;
        if (type === AnchorAnim.DefaultSpatial)
            return Tokens.anim.expressiveDefaultSpatial;
        if (type === AnchorAnim.SlowSpatial)
            return Tokens.anim.expressiveSlowSpatial;
        if (type === AnchorAnim.FastEffects)
            return Tokens.anim.expressiveFastEffects;
        if (type === AnchorAnim.DefaultEffects)
            return Tokens.anim.expressiveDefaultEffects;
        if (type === AnchorAnim.SlowEffects)
            return Tokens.anim.expressiveSlowEffects;

        if (type >= AnchorAnim.StandardSmall && type <= AnchorAnim.StandardExtraLarge)
            return Tokens.anim.standard;
        if (type >= AnchorAnim.EmphasizedSmall && type <= AnchorAnim.EmphasizedExtraLarge)
            return Tokens.anim.emphasized;

        return Tokens.anim.standard;
    }
}
