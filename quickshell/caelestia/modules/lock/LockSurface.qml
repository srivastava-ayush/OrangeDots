pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.images
import qs.services

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam
    required property bool animateEntrance

    readonly property alias unlocking: unlockAnim.running

    signal revealContent
    signal settleContent

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    color: "transparent"

    Component.onCompleted: {
        if (!animateEntrance)
            Qt.callLater(root.finishEntrance);
    }

    onAnimateEntranceChanged: {
        if (!animateEntrance)
            finishEntrance();
    }

    onScreenChanged: {
        if (!animateEntrance)
            finishEntrance();
    }

    function finishEntrance(): void {
        if (!lock.locked || unlockAnim.running)
            return;

        initAnim.stop();
        dimOverlay.opacity = 1;
        blurredBackground.opacity = 1;
        lockContent.scale = 1;
        lockContent.rotation = 360;
        const screenHeight = screen?.height || 1440;
        lockContent.implicitWidth = screenHeight * lockContent.Tokens.sizes.lock.heightMult * lockContent.Tokens.sizes.lock.ratio;
        lockContent.implicitHeight = screenHeight * lockContent.Tokens.sizes.lock.heightMult;
        lockBg.radius = lockContent.Tokens.rounding.extraLarge * 1.5;
        lockIcon.rotation = 360;
        lockIcon.opacity = 0;
        content.opacity = 1;
        content.scale = 1;
        settleContent();
    }

    Connections {
        function onLockedChanged(): void {
            if (root.lock.locked && !root.animateEntrance)
                root.finishEntrance();
        }

        function onSecureChanged(): void {
            if (root.lock.secure && !root.animateEntrance)
                root.finishEntrance();
        }

        function onUnlock(): void {
            unlockAnim.start();
        }

        target: root.lock
    }

    Connections {
        function onAboutToSleep(): void {
            root.finishEntrance();
        }

        function onResumed(): void {
            // Let the compositor restore the surface before applying its final geometry.
            Qt.callLater(root.finishEntrance);
        }

        target: SessionManager
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            Anim {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: lockContent.size
            }
            Anim {
                target: lockBg
                property: "radius"
                to: lockContent.radius
            }
            Anim {
                target: content
                property: "scale"
                to: 0
            }
            Anim {
                target: content
                property: "opacity"
                to: 0
                type: Anim.StandardSmall
            }
            Anim {
                target: lockIcon
                property: "opacity"
                to: 1
                type: Anim.StandardLarge
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Tokens.anim.durations.small
                }
                Anim {
                    type: Anim.Standard
                    target: lockContent
                    property: "opacity"
                    to: 0
                }
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    ParallelAnimation {
        id: initAnim

        running: root.animateEntrance

        SequentialAnimation {
            Anim {
                target: dimOverlay
                property: "opacity"
                to: 1
                duration: 350 * Tokens.anim.durations.scale
            }
            Anim {
                target: blurredBackground
                property: "opacity"
                to: 1
                duration: 500 * Tokens.anim.durations.scale
            }
        }
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: lockContent
                    property: "scale"
                    to: 1
                    type: Anim.FastSpatial
                }
                Anim {
                    target: lockContent
                    property: "rotation"
                    to: 360
                    duration: Tokens.anim.durations.expressiveFastSpatial
                    easing: Tokens.anim.standardDecel
                }
            }
            ScriptAction {
                script: root.revealContent()
            }
            ParallelAnimation {
                Anim {
                    target: lockIcon
                    property: "rotation"
                    to: 360
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: lockIcon
                    property: "opacity"
                    to: 0
                }
                Anim {
                    type: Anim.DefaultEffects
                    target: content
                    property: "opacity"
                    to: 1
                }
                Anim {
                    target: content
                    property: "scale"
                    to: 1
                }
                Anim {
                    target: lockBg
                    property: "radius"
                    to: lockContent.Tokens.rounding.extraLarge * 1.5
                }
                Anim {
                    target: lockContent
                    property: "implicitWidth"
                    to: (root.screen?.height ?? 0) * lockContent.Tokens.sizes.lock.heightMult * lockContent.Tokens.sizes.lock.ratio
                }
                Anim {
                    target: lockContent
                    property: "implicitHeight"
                    to: (root.screen?.height ?? 0) * lockContent.Tokens.sizes.lock.heightMult
                }
            }
        }
    }

    Item {
        id: background

        anchors.fill: parent

        Loader {
            anchors.fill: parent
            sourceComponent: Config.lock.useWallpaper ? wallpaperBackground : screencopyBackground
        }
    }

    MultiEffect {
        id: blurredBackground

        anchors.fill: parent
        source: background
        opacity: 0
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        blurMultiplier: 3
    }

    Rectangle {
        id: dimOverlay

        anchors.fill: parent
        color: "#66000000"
        opacity: 0
    }

    Component {
        id: screencopyBackground

        ScreencopyView {
            captureSource: root.screen
        }
    }

    Component {
        id: wallpaperBackground

        CachingImage {
            path: Wallpapers.current
        }
    }

    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Tokens.padding.large * 4
        readonly property int radius: size / 4 * Tokens.rounding.scale

        anchors.centerIn: parent
        implicitWidth: size
        implicitHeight: size

        visible: Config.lock.enabled
        rotation: 180
        scale: 0

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: "transparent"
            radius: parent.radius
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(4).weight(Font.Bold).build()
            rotation: 180
        }

        Content {
            id: content

            anchors.centerIn: parent
            width: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio - Tokens.padding.extraLargeIncreased
            height: (root.screen?.height ?? 0) * Tokens.sizes.lock.heightMult - Tokens.padding.extraLargeIncreased

            lock: root
            opacity: 0
            scale: 0
        }
    }
}
