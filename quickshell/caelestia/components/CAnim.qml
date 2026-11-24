import QtQuick
import Caelestia.Config

ColorAnimation {
    enum Type {
        FastEffects = 0,
        DefaultEffects,
        SlowEffects
    }

    property int type: CAnim.SlowEffects

    duration: {
        if (type === CAnim.FastEffects)
            return Tokens.anim.durations.expressiveFastEffects;
        if (type === CAnim.DefaultEffects)
            return Tokens.anim.durations.expressiveDefaultEffects;
        return Tokens.anim.durations.expressiveSlowEffects;
    }
    easing: {
        if (type === CAnim.FastEffects)
            return Tokens.anim.expressiveFastEffects;
        if (type === CAnim.DefaultEffects)
            return Tokens.anim.expressiveDefaultEffects;
        return Tokens.anim.expressiveSlowEffects;
    }
}
