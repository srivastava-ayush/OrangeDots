// Dynamic Island widget for QuickShell
// -------------------------------------------------
// Collapsed  -> minimal rounded pill showing the current time
// On hover   -> expands smoothly into an MPRIS music player
//               (album art, title/artist, seek progress, prev/play/next)
//
// Install:
//   mkdir -p ~/.config/quickshell/dynamic-island
//   cp shell.qml ~/.config/quickshell/dynamic-island/shell.qml
//   quickshell -c dynamic-island
//
// Requires: quickshell (https://quickshell.org), a compositor that
// supports the wlr-layer-shell protocol (Hyprland, Sway, etc.), and
// an MPRIS-capable media player (Spotify, mpv, browsers, etc.) for
// the expanded view to show live data.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            property var modelData
            screen: modelData

            // Float over everything, don't reserve bar space
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: 2
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 90
            margins.top: 6

            // ----- state -----
            property bool hovered: hoverArea.containsMouse
            property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
            property bool hasPlayer: player !== null
            property bool expanded: hovered && hasPlayer

            // clock
            property string timeText: Qt.formatTime(new Date(), "hh:mm")
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: root.timeText = Qt.formatTime(new Date(), "hh:mm")
            }

            // live-ish playback position (mpris only pushes updates occasionally)
            Timer {
                interval: 500
                running: root.expanded && root.hasPlayer && root.player.isPlaying
                repeat: true
                onTriggered: root.player.positionChanged()
            }

            // ----- layout host, centers the island in the full-width strip -----
            Item {
                anchors.fill: parent

                Rectangle {
                    id: island
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top

                    radius: height / 2
                    color: "#e6141414"
                    border.color: "#33ffffff"
                    border.width: 1

                    width: root.expanded ? 360 : pillRow.implicitWidth + 32
                    height: root.expanded ? 84 : 34

                    Behavior on width {
                        NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
                    }
                    Behavior on height {
                        NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
                    }
                    Behavior on radius {
                        NumberAnimation { duration: 320; easing.type: Easing.OutExpo }
                    }

                    // widen the actual mouse-catching area a little so hovering
                    // near the pill still triggers expansion
                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                    }

                    // ===================== COLLAPSED VIEW =====================
                    Row {
                        id: pillRow
                        anchors.centerIn: parent
                        spacing: 8
                        opacity: root.expanded ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        visible: opacity > 0.01

                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.hasPlayer && root.player.isPlaying ? "#4ade80" : "#666666"
                        }

                        Text {
                            text: root.timeText
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // ===================== EXPANDED VIEW =====================
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        opacity: root.expanded ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        // album art
                        Rectangle {
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 60
                            radius: 12
                            color: "#222222"
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.hasPlayer ? (root.player.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }

                        // title / artist / progress
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: root.hasPlayer ? (root.player.trackTitle || "Unknown Title") : ""
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : ""
                                color: "#aaaaaa"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                height: 3
                                radius: 1.5
                                color: "#3a3a3a"

                                Rectangle {
                                    height: parent.height
                                    radius: 1.5
                                    color: "#ffffff"
                                    width: {
                                        if (!root.hasPlayer || !root.player.length) return 0
                                        var frac = root.player.position / root.player.length
                                        return parent.width * Math.max(0, Math.min(1, frac))
                                    }
                                    Behavior on width { NumberAnimation { duration: 400 } }
                                }
                            }
                        }

                        // transport controls
                        RowLayout {
                            spacing: 6

                            Text {
                                text: "⏮"
                                color: root.hasPlayer && root.player.canGoPrevious ? "white" : "#555555"
                                font.pixelSize: 16
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    enabled: root.hasPlayer && root.player.canGoPrevious
                                    onClicked: root.player.previous()
                                }
                            }

                            Text {
                                text: root.hasPlayer && root.player.isPlaying ? "⏸" : "▶"
                                color: "white"
                                font.pixelSize: 18
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    enabled: root.hasPlayer
                                    onClicked: root.player.togglePlaying()
                                }
                            }

                            Text {
                                text: "⏭"
                                color: root.hasPlayer && root.player.canGoNext ? "white" : "#555555"
                                font.pixelSize: 16
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    enabled: root.hasPlayer && root.player.canGoNext
                                    onClicked: root.player.next()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
