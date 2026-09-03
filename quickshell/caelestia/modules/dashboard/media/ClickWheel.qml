pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services

// Old school iPod click wheel with a Material 3 coat of paint:
//   - tap the compass points: shuffle (top), next (right), play/pause (bottom), previous (left)
//   - tap the middle ("screen") to toggle playback
//   - drag around the ring like a real click wheel to scrub through the track
//   - scroll over it to change volume, complete with a little iPod-style volume HUD
Item {
    id: root

    // Compass zones: 0 = top, 1 = right, 2 = bottom, 3 = left
    readonly property real size: Math.min(width, height)
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2

    readonly property int progressWidth: 5
    readonly property real bodySize: size - (progressWidth + Tokens.spacing.small) * 2
    readonly property real bandWidth: Math.max(30, Math.round(bodySize * 0.16))
    readonly property real platterSize: bodySize - bandWidth * 2 - Tokens.spacing.small - 4
    readonly property real platterRadius: platterSize / 2
    readonly property real coverSize: platterSize - Tokens.spacing.small
    readonly property real arcRadius: (bodySize / 2 + platterRadius + Tokens.spacing.small) / 2 + 2
    readonly property real highlightWidth: bandWidth - Tokens.padding.small * 2

    property int hoverZone: -1
    property int pressZone: -1

    property bool _centerPress: false
    property bool _dragged: false
    property real _lastAngle: 0
    property real _accum: 0

    function angleAt(x: real, y: real): real {
        return Math.atan2(y - centerY, x - centerX) * 180 / Math.PI;
    }

    function zoneAt(x: real, y: real): int {
        const deg = angleAt(x, y);
        if (deg >= -135 && deg < -45)
            return 0;
        if (deg >= -45 && deg < 45)
            return 1;
        if (deg >= 45 && deg <= 135)
            return 2;
        return 3;
    }

    function inCenter(x: real, y: real): bool {
        const dx = x - centerX;
        const dy = y - centerY;
        return dx * dx + dy * dy <= platterRadius * platterRadius;
    }

    // Keep the position (and thus the progress ring) fresh
    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    // Progress ring around the rim of the wheel
    CircularProgress {
        anchors.fill: parent
        value: Players.active ? Players.active.position / (Players.active.length || 1) : 0
        strokeWidth: root.progressWidth
        padding: 2
        hasEndIndicator: false
        fgColour: Colours.palette.m3primary
        bgColour: Qt.alpha(Colours.palette.m3outlineVariant, 0.6)

        Behavior on fgColour {
            CAnim {}
        }
        Behavior on bgColour {
            CAnim {}
        }
    }

    // Machined "aluminium" body, themed through the M3 palette
    StyledRect {
        id: body

        anchors.centerIn: parent
        width: root.bodySize
        height: root.bodySize
        radius: Tokens.rounding.full
        color: Colours.palette.m3surfaceContainerHigh
        border.width: 1
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.8)

        scale: root.pressZone >= 0 || root._centerPress ? 0.98 : 1

        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }

        // Hover / press highlights for the four click-wheel quadrants
        Shape {
            anchors.fill: parent
            asynchronous: true
            preferredRendererType: Shape.CurveRenderer
            data: highlights.instances
        }

        Variants {
            id: highlights

            model: Array.from({
                length: 4
            }, (_, i) => i)

            ShapePath {
                id: hl

                required property int modelData

                fillColor: "transparent"
                // ShapePath has no opacity, so fade via stroke alpha instead
                strokeColor: {
                    if (root.pressZone === modelData)
                        return Qt.alpha(Colours.palette.m3primary, 0.18);
                    if (root.hoverZone === modelData)
                        return Qt.alpha(Colours.palette.m3onSurface, 0.08);
                    return "transparent";
                }
                strokeWidth: root.highlightWidth
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.bodySize / 2
                    centerY: root.bodySize / 2
                    radiusX: root.arcRadius
                    radiusY: root.arcRadius
                    startAngle: [-132, -42, 48, 138][hl.modelData]
                    sweepAngle: 84
                }

                Behavior on strokeColor {
                    CAnim {}
                }
            }
        }

        // Bezel around the "screen"
        StyledRect {
            anchors.centerIn: parent
            width: root.platterSize
            height: root.platterSize
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainerHighest
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.5)
        }

        // Spinning album art, iPod-vinyl style
        CoverArt {
            id: coverArt

            anchors.centerIn: parent
            shape.shape: MaterialShape.Cookie9Sided
            implicitWidth: root.coverSize
            implicitHeight: root.coverSize

            RotationAnimation on rotation {
                from: coverArt.rotation
                to: coverArt.rotation + 360
                duration: 5000 // 33⅓ RPM — real turntable speed (60s / 120.33 rpm ≈ 1.8s per revolution)
                loops: Animation.Infinite
                running: Players.active?.isPlaying ?? false
            }
        }

        component WheelIcon: MaterialIcon {
            property int zone
            property bool activeState: false

            color: activeState ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            opacity: Players.active ? 1 : 0.4
            scale: root.pressZone === zone ? 1.25 : 1

            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on color {
                CAnim {}
            }
        }

        WheelIcon {
            zone: 0
            text: "shuffle"
            activeState: Players.active?.shuffle ?? false
            fontStyle: Tokens.font.icon.builders.small.weight(Font.Medium).build()
            x: body.width / 2 - width / 2
            y: body.height / 2 - root.arcRadius - height / 2
        }

        WheelIcon {
            zone: 1
            text: "skip_next"
            fontStyle: Tokens.font.icon.medium
            x: body.width / 2 + root.arcRadius - width / 2
            y: body.height / 2 - height / 2
        }

        WheelIcon {
            zone: 2
            text: Players.active?.isPlaying ? "pause" : "play_arrow"
            fontStyle: Tokens.font.icon.medium
            x: body.width / 2 - width / 2
            y: body.height / 2 + root.arcRadius - height / 2
        }

        WheelIcon {
            zone: 3
            text: "skip_previous"
            fontStyle: Tokens.font.icon.medium
            x: body.width / 2 - root.arcRadius - width / 2
            y: body.height / 2 - height / 2
        }

        // iPod-style volume HUD, snackbar colours straight out of Android
        StyledRect {
            id: hud

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 + root.platterRadius - Tokens.padding.large - height / 2
            implicitWidth: hudRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: hudRow.implicitHeight + Tokens.padding.extraSmall
            radius: Tokens.rounding.full
            color: Colours.palette.m3inverseSurface
            opacity: hudTimer.running ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            RowLayout {
                id: hudRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: Audio.muted ? "volume_off" : "volume_up"
                    color: Colours.palette.m3inverseOnSurface
                    fontStyle: Tokens.font.icon.builders.small.scale(0.85).build()
                }

                StyledText {
                    text: `${Math.round(Audio.volume * 100)}%`
                    color: Colours.palette.m3inverseOnSurface
                    font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
                }
            }

            Timer {
                id: hudTimer

                interval: 1200
            }
        }
    }

    CustomMouseArea {
        id: input

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onWheel: event => {
            if (event.angleDelta.y > 0)
                Audio.incrementVolume();
            else if (event.angleDelta.y < 0)
                Audio.decrementVolume();
            hudTimer.restart();
        }

        onPressed: e => {
            if (!Players.active)
                return;
            root._dragged = false;
            if (root.inCenter(e.x, e.y)) {
                root._centerPress = true;
                return;
            }
            root.pressZone = root.zoneAt(e.x, e.y);
            root._lastAngle = root.angleAt(e.x, e.y);
            root._accum = 0;
        }

        onPositionChanged: e => {
            root.hoverZone = root.zoneAt(e.x, e.y);
            if (!pressed || !Players.active || root._centerPress)
                return;

            const p = Players.active;
            if (!(p.canSeek && p.positionSupported))
                return;

            // Unwrap the angle delta so dragging across ±180° keeps working
            const deg = root.angleAt(e.x, e.y);
            let delta = deg - root._lastAngle;
            if (delta > 180)
                delta -= 360;
            else if (delta < -180)
                delta += 360;
            root._lastAngle = deg;
            root._accum += delta;
            // Ignore tiny jitters so they don't swallow the click on release
            if (Math.abs(root._accum) >= 4)
                root._dragged = true;

            // One detent every 15°, scrub distance scales with track length
            const stepDeg = 15;
            const stepSecs = Math.max(5, Math.round((p.length || 0) / 40));
            while (Math.abs(root._accum) >= stepDeg) {
                const dir = root._accum > 0 ? 1 : -1;
                root._accum -= dir * stepDeg;
                p.position = Math.max(0, Math.min(p.length || Number.MAX_VALUE, p.position + dir * stepSecs));
            }
        }

        onReleased: {
            const zone = root.pressZone;
            const wasCenter = root._centerPress;
            root.pressZone = -1;
            root._centerPress = false;
            if (!Players.active || root._dragged)
                return;

            const p = Players.active;
            if (wasCenter || zone === 2) {
                if (p.canTogglePlaying)
                    p.togglePlaying();
            } else if (zone === 0 && p.shuffleSupported) {
                p.shuffle = !p.shuffle;
            } else if (zone === 1 && p.canGoNext) {
                p.next();
            } else if (zone === 3 && p.canGoPrevious) {
                p.previous();
            }
        }

        onCanceled: {
            root.pressZone = -1;
            root._centerPress = false;
        }

        onContainsMouseChanged: {
            if (!containsMouse)
                root.hoverZone = -1;
        }
    }
}
