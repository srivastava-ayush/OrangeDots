import QtQuick
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    implicitHeight: Math.max(160, cat.implicitHeight + cat.anchors.margins * 2)
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ServiceRef {
        service: Audio.beatTracker
    }

    AnimatedImage {
        id: cat

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        playing: Players.active?.isPlaying ?? false
        speed: Audio.beatTracker.bpm / Config.general.mediaGifSpeedAdjustment
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }
}
