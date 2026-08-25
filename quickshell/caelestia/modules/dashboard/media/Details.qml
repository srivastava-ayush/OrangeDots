pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Track info + controls; the shared card background comes from Media.qml
StyledRect {
    id: root

    readonly property bool hasUnknownLength: (Players.active?.length ?? 0) > 2147483647
    readonly property string loopLabel: {
        const state = Players.active?.loopState;
        if (state === MprisLoopState.Track)
            return qsTr("Repeat · one");
        if (state === MprisLoopState.Playlist)
            return qsTr("Repeat · all");
        return qsTr("Repeat · off");
    }

    function lengthStr(length: int): string {
        if (length < 0)
            return "-1:-1";

        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
        return `${mins}:${secs}`;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall

        Timer {
            running: Players.active?.isPlaying ?? false
            interval: GlobalConfig.dashboard.mediaUpdateInterval
            triggeredOnStart: true
            repeat: true
            onTriggered: Players.active?.positionChanged()
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            text: Players.active?.trackTitle ?? ""
            font: Tokens.font.title.large
            elide: Text.ElideRight
            animate: true
        }

    StyledText {
        Layout.fillWidth: true
        text: `${Players.active?.trackArtist || qsTr("Unknown artist")} • ${Players.active?.trackAlbum || qsTr("Unknown album")}`
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.large
        elide: Text.ElideRight
        animate: true
    }

        // Push the controls to the bottom of the card
        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.topMargin: Tokens.spacing.extraLargeIncreased
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            TextMetrics {
                id: timeMetrics

                text: Players.active ? root.lengthStr(Math.max(Players.active.position, root.hasUnknownLength ? 0 : Players.active.length)).replace(/[1-9]/g, "0") : "00:00"
                font: Tokens.font.mono.builders.small.weight(Font.Medium).build()
            }

            StyledText {
                id: positionLabel

                Layout.preferredWidth: timeMetrics.width
                text: root.lengthStr(Players.active?.position ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font: timeMetrics.font
                horizontalAlignment: Text.AlignHCenter
            }

            StyledSlider {
                id: positionSlider

                Layout.fillWidth: true
                value: Players.active ? Players.active.position / (Players.active.length || 1) : 0
                enabled: (Players.active?.canSeek ?? false) && !root.hasUnknownLength
                wavy: true
                animateWave: Players.active?.isPlaying ?? false
                waveFrequency: 5
                waveDuration: 2000
                interactionOnMove: false
                onInteraction: value => {
                    const active = Players.active;
                    if (active?.canSeek && active?.positionSupported)
                        active.position = value * active.length;
                }

                Binding {
                    target: positionLabel
                    property: "text"
                    value: root.lengthStr(positionSlider.pos * (Players.active?.length ?? 0))
                    when: positionSlider.dragging
                }
            }

            StyledText {
                Layout.preferredWidth: timeMetrics.width
                text: root.hasUnknownLength ? "--:--" : root.lengthStr(Players.active?.length ?? -1)
                color: Colours.palette.m3onSurfaceVariant
                font: timeMetrics.font
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RowLayout {
            Layout.topMargin: Tokens.spacing.medium
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconButton {
                type: IconButton.Tonal
                icon: Players.active?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                isRound: true
                shapeMorph: true
                checked: Players.active?.loopState === MprisLoopState.Track || Players.active?.loopState === MprisLoopState.Playlist
                font: Tokens.font.icon.builders.medium.weight(Font.Medium).build()
                disabled: !Players.active?.loopSupported
                onClicked: {
                    const state = Players.active.loopState;
                    if (state === MprisLoopState.None)
                        Players.active.loopState = MprisLoopState.Track;
                    else if (state === MprisLoopState.Track)
                        Players.active.loopState = MprisLoopState.Playlist;
                    else
                        Players.active.loopState = MprisLoopState.None;
                }
                implicitWidth: Math.round(implicitHeight * 0.9)
            }

            StyledText {
                text: root.loopLabel
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.builders.medium.weight(Font.Medium).build()
            }

            Item {
                Layout.fillWidth: true
            }

            // Engraved branding, iPod style
            StyledText {
                text: qsTr("ORANGEPOD")
                color: Colours.palette.m3outline
                font: Tokens.font.mono.builders.small.weight(Font.Medium).capitalisation(Font.AllUppercase).letterSpacing(1.5).build()
            }
        }
    }
}
