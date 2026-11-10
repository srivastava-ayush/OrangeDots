pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

// Independent player content, drawn on the shell's shared dashboard surface.
Item {
    id: root

    required property bool fullscreen
    required property bool activeScreen
    property bool dashboardOpen: false
    property real hideInset: 0
    property var player: Players.active
    property int displayDuration: 5000
    property bool expanded: false
    property string lastEventKey: ""
    readonly property bool hasDuration: Number.isFinite(player?.length) && player.length > 0 && player.length <= 2147483647
    readonly property real duration: hasDuration ? player.length : 0
    readonly property real position: Math.max(0, Math.min(player?.position ?? 0, duration))
    readonly property string eventKey: player
        ? `${player.uniqueId}\n${player.trackTitle || player.metadata["xesam:url"] || ""}\n${player.isPlaying}` : ""
    // Keep the same slide, centered curtain and fade as DashboardWrapper.
    property real offsetScale: expanded ? 0 : 1
    readonly property real reveal: Math.max(0, Math.min(1, 1 - offsetScale))

    onEventKeyChanged: {
        if (dashboardOpen) {
            lastEventKey = eventKey;
            eventDelay.stop();
        } else {
            eventDelay.restart();
        }
    }
    onFullscreenChanged: if (fullscreen) dismiss()
    onActiveScreenChanged: if (!activeScreen) dismiss()
    onDashboardOpenChanged: {
        if (dashboardOpen) {
            dismiss();
            eventDelay.stop();
            lastEventKey = eventKey;
        }
    }

    function dismiss(): void {
        expanded = false;
        hideTimer.stop();
    }

    function formatTime(seconds: real): string {
        const total = Math.max(0, Math.floor(seconds));
        const minutes = Math.floor(total / 60);
        return `${minutes}:${(total % 60).toString().padStart(2, "0")}`;
    }

    readonly property real fullWidth: Math.min(440, parent ? parent.width : 440)
    implicitWidth: fullWidth * (0.48 + 0.52 * reveal)
    implicitHeight: 120
    anchors.topMargin: (-implicitHeight - hideInset - 5) * offsetScale
    visible: reveal > 0
    opacity: reveal
    clip: true

    Behavior on offsetScale {
        Anim {
            type: Anim.FastSpatial
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: eventDelay
        interval: 250
        onTriggered: {
            if (!root.player) {
                root.lastEventKey = "";
                root.dismiss();
                return;
            }
            if (root.eventKey === root.lastEventKey)
                return;
            root.lastEventKey = root.eventKey;
            if (root.fullscreen || !root.activeScreen || root.dashboardOpen)
                return;
            root.expanded = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: root.displayDuration
        onTriggered: {
            if (hover.hovered || progress.dragging)
                restart();
            else
                root.expanded = false;
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered && root.expanded) hideTimer.restart()
    }

    Timer {
        running: root.visible && (root.player?.isPlaying ?? false) && (root.player?.positionSupported ?? false)
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Item {
        id: pill
        objectName: "mediaIslandCurtain"
        anchors.fill: parent

        InsetGloss {
            objectName: "mediaIslandGloss"
            anchors.fill: parent
        }

        RowLayout {
            objectName: "mediaIslandContent"
            // Reveal a full-size player through the curtain, like the dashboard.
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 44
            anchors.topMargin: 16
            width: root.fullWidth - 32
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 56
                radius: 18
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "music_note"
                }

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 112
                    sourceSize.height: 112
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.player?.trackTitle || qsTr("Media")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Loader {
                        objectName: "mediaIslandEqLoader"
                        active: root.visible
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: MediaIslandEq {
                            objectName: "mediaIslandEq"
                            playing: root.player?.isPlaying ?? false
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: [root.player?.isPlaying ? qsTr("Playing") : qsTr("Paused"), root.player?.trackArtist].filter(Boolean).join(" · ")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }
            }

            IconButton {
                objectName: "islandPrevious"
                icon: "skip_previous"
                type: IconButton.Text
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
            }

            IconButton {
                objectName: "islandPlayPause"
                icon: root.player?.isPlaying ? "pause" : "play_arrow"
                type: IconButton.Filled
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player?.togglePlaying()
            }

            IconButton {
                objectName: "islandNext"
                icon: "skip_next"
                type: IconButton.Text
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
            }
        }

        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            width: root.fullWidth - 32
            spacing: 10

            StyledText {
                objectName: "islandElapsed"
                text: root.formatTime(progress.dragging ? progress.pos * root.duration : root.position)
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledSlider {
                id: progress
                objectName: "islandProgress"
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                value: root.duration > 0 ? root.position / root.duration : 0
                enabled: root.hasDuration && (root.player?.canSeek ?? false) && (root.player?.positionSupported ?? false)
                wavy: false
                interactionOnMove: false
                onDraggingChanged: if (root.expanded) hideTimer.restart()
                onInteraction: value => {
                    if (enabled)
                        root.player.position = Math.max(0, Math.min(1, value)) * root.duration;
                }
            }

            StyledText {
                objectName: "islandDuration"
                text: root.hasDuration ? root.formatTime(root.duration) : "--:--"
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
