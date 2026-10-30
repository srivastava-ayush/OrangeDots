pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.dashboard.media as DashboardMedia
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

    readonly property real fullWidth: Math.min(440, parent ? parent.width : 440)
    implicitWidth: fullWidth * (0.48 + 0.52 * reveal)
    implicitHeight: 92
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
        onTriggered: root.expanded = false
    }

    Item {
        id: pill
        objectName: "mediaIslandCurtain"
        anchors.fill: parent

        RowLayout {
            objectName: "mediaIslandContent"
            // Reveal a full-size player through the curtain, like the dashboard.
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
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

                StyledText {
                    Layout.fillWidth: true
                    text: [root.player?.isPlaying ? qsTr("Playing") : qsTr("Paused"), root.player?.trackArtist].filter(Boolean).join(" · ")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    active: root.visible
                    sourceComponent: DashboardMedia.EqBars {
                        objectName: "mediaIslandVisualizer"
                        barWidth: 3
                        barSpacing: 2
                        playing: root.player?.isPlaying ?? false
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
    }
}
