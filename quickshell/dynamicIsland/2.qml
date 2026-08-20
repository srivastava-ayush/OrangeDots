// Dynamic Island — Vercel × iOS Edition
// =========================================================
//   COMPACT  →  pill: time, status dot, battery
//   HOVER    →  full media player + power actions
//   LEAVE    →  collapses back to pill
//
// Uses Nerd Font icons. Set font.family to your Nerd Font.
// Install:
//   mkdir -p ~/.config/quickshell/dynamic-island
//   cp shell.qml ~/.config/quickshell/dynamic-island/shell.qml
//   quickshell -c dynamic-island

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: -1
            color: "transparent"

            anchors { top: true; left: true; right: true }
            margins.top: 8
            implicitHeight: container.implicitHeight + 16

            readonly property string font: "Symbols Nerd Font, SF Pro Display, Inter, system-ui"
            readonly property string fontMono: "SF Mono, JetBrains Mono, Fira Code, monospace"

            readonly property color black:     "#000000"
            readonly property color surface:   "#0a0a0a"
            readonly property color raised:    "#111111"
            readonly property color border:    Qt.rgba(1, 1, 1, 0.06)
            readonly property color borderHov: Qt.rgba(1, 1, 1, 0.12)
            readonly property color textPri:   "#fafafa"
            readonly property color textSec:   Qt.rgba(1, 1, 1, 0.50)
            readonly property color textTert:  Qt.rgba(1, 1, 1, 0.25)
            readonly property color accent:    "#666666"
            readonly property color accentPri: "#ffffff"
            readonly property color green:     "#22c55e"
            readonly property color red:       "#ef4444"

            property bool expanded: mainMouse.containsMouse

            property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
            property bool hasPlayer: player !== null
            property real batteryLevel: UPower.displayDevice.percentage
            property bool batteryCharging: UPower.displayDevice.state === 1

            property string timeText: Qt.formatTime(new Date(), "hh:mm")
            property string dateText: Qt.formatDate(new Date(), "ddd, MMM d")
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    root.timeText = Qt.formatTime(new Date(), "hh:mm")
                    root.dateText = Qt.formatDate(new Date(), "ddd, MMM d")
                }
            }

            Timer {
                interval: 500
                running: root.expanded && root.hasPlayer && root.player.isPlaying
                repeat: true
                onTriggered: root.player.positionChanged()
            }

            Process { id: lockProc;    command: ["loginctl", "lock-session"] }
            Process { id: sleepProc;   command: ["systemctl", "suspend"] }
            Process { id: restartProc; command: ["systemctl", "reboot"] }
            Process { id: shutdownProc;command: ["systemctl", "poweroff"] }
            Process { id: logoutProc;  command: ["loginctl", "terminate-user", ""] }

            function fmt(s) {
                if (isNaN(s) || s < 0) return "0:00"
                var m = Math.floor(s / 60)
                var sec = Math.floor(s % 60)
                return m + ":" + (sec < 10 ? "0" : "") + sec
            }

            Item {
                id: container
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Math.min(parent.width - 32, 520)
                implicitHeight: mainCol.implicitHeight

                Column {
                    id: mainCol
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    spacing: 10

                    // ══════════════════════════════════════════════
                    //  ISLAND
                    // ══════════════════════════════════════════════
                    Rectangle {
                        id: island
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: root.expanded ? parent.width : pillRow.implicitWidth + 36
                        height: root.expanded ? 300 : 34
                        radius: root.expanded ? 28 : 17
                        color: root.black
                        border.color: root.expanded ? root.borderHov : root.border
                        border.width: 1
                        clip: true

                        Behavior on width  { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }

                        // very subtle top edge highlight
                        Rectangle {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            height: 1
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.08) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                            }
                        }

                        MouseArea {
                            id: mainMouse
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            preventStealing: true
                        }

                        // ════════════ COMPACT PILL ════════════
                        Row {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 8
                            opacity: root.expanded ? 0 : 1
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            // status dot
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.hasPlayer && root.player.isPlaying ? root.green : root.textTert
                            }

                            Text {
                                text: root.timeText
                                color: root.textPri
                                font.family: root.fontMono
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.letterSpacing: -0.5
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: Math.round(root.batteryLevel * 100) + "%"
                                color: root.textTert
                                font.family: root.fontMono
                                font.pixelSize: 10
                                font.weight: Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // ════════════ EXPANDED ════════════
                        Column {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 0
                            opacity: root.expanded ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            // ── top: art + track info + controls ──
                            Row {
                                width: parent.width
                                spacing: 20

                                // album art
                                Rectangle {
                                    width: 96; height: 96; radius: 16
                                    color: root.surface; clip: true
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        anchors.fill: parent
                                        source: root.hasPlayer ? (root.player.trackArtUrl || "") : ""
                                        fillMode: Image.PreserveAspectCrop; asynchronous: true
                                    }

                                    // no-image placeholder icon
                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u266B" // music note fallback
                                        color: root.textTert; font.family: root.font; font.pixelSize: 24
                                        visible: !root.hasPlayer || !root.player.trackArtUrl
                                    }
                                }

                                // info + progress
                                Column {
                                    width: parent.width - 96 - 20 - 60
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 0

                                    Text {
                                        width: parent.width
                                        text: root.hasPlayer ? (root.player.trackTitle || "Not Playing") : "No Media"
                                        color: root.textPri; font.family: root.font
                                        font.pixelSize: 15; font.weight: Font.DemiBold
                                        font.letterSpacing: -0.3; elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                    Text {
                                        width: parent.width; topPadding: 2
                                        text: root.hasPlayer ? (root.player.trackArtist || "") : ""
                                        color: root.textSec; font.family: root.font
                                        font.pixelSize: 12; elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Item { width: 1; height: 16 }

                                    // progress bar
                                    Rectangle {
                                        width: parent.width; height: 2; radius: 1
                                        color: Qt.rgba(1, 1, 1, 0.08)

                                        Rectangle {
                                            height: parent.height; radius: 1; color: root.textPri
                                            width: {
                                                if (!root.hasPlayer || !root.player.length) return 0
                                                return parent.width * Math.max(0, Math.min(1, root.player.position / root.player.length))
                                            }
                                            Behavior on width { NumberAnimation { duration: 300 } }
                                        }
                                    }

                                    Item { width: 1; height: 6 }

                                    // time labels
                                    Row {
                                        width: parent.width
                                        Text { text: root.hasPlayer ? root.fmt(root.player.position) : "0:00"
                                            color: root.textTert; font.family: root.fontMono; font.pixelSize: 10 }
                                        Item { width: parent.width - 2 * 30; height: 1 }
                                        Text { text: root.hasPlayer ? root.fmt(root.player.length) : "0:00"
                                            color: root.textTert; font.family: root.fontMono; font.pixelSize: 10 }
                                    }
                                }

                                // transport controls — right side
                                Column {
                                    width: 60
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 16

                                        // prev
                                        Rectangle { width: 32; height: 32; radius: 16; color: "transparent"
                                            Text { anchors.centerIn: parent; text: "\uEB19"; color: root.hasPlayer && root.player.canGoPrevious ? root.textPri : root.textTert; font.family: root.font; font.pixelSize: 14 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.hasPlayer && root.player.previous() }
                                        }

                                        // next
                                        Rectangle { width: 32; height: 32; radius: 16; color: "transparent"
                                            Text { anchors.centerIn: parent; text: "\uEB1C"; color: root.hasPlayer && root.player.canGoNext ? root.textPri : root.textTert; font.family: root.font; font.pixelSize: 14 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.hasPlayer && root.player.next() }
                                        }
                                    }

                                    // play/pause — large
                                    Rectangle { width: 40; height: 40; radius: 20; color: root.accentPri; anchors.horizontalCenter: parent.horizontalCenter
                                        Text { anchors.centerIn: parent
                                            text: root.hasPlayer && root.player.isPlaying ? "\uEB08" : "\uEB1B"
                                            font.family: root.font; font.pixelSize: 16; color: root.black }
                                        MouseArea { anchors.fill: parent; onClicked: root.hasPlayer && root.player.togglePlaying() }
                                    }
                                }
                            }

                            Item { width: 1; height: 28 }

                            // ── divider ──
                            Rectangle { width: parent.width; height: 1; color: root.border }

                            Item { width: 1; height: 20 }

                            // ── power row ──
                            Row {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: [
                                        { icon: "\uF023B", label: "Lock",    tint: root.textSec, fn: function() { lockProc.running = true } },
                                        { icon: "\uF0598", label: "Sleep",   tint: root.textSec, fn: function() { sleepProc.running = true } },
                                        { icon: "\uF0450", label: "Restart", tint: root.textSec, fn: function() { restartProc.running = true } },
                                        { icon: "\uF0425", label: "Shutdown",tint: root.red,     fn: function() { shutdownProc.running = true } },
                                        { icon: "\uF0347", label: "Logout",  tint: root.textSec, fn: function() {
                                            logoutProc.command = ["loginctl", "terminate-user", Quickshell.env("USER") || ""]
                                            logoutProc.running = true
                                        }}
                                    ]

                                    Rectangle {
                                        width: (parent.width - 32) / 5
                                        height: 52; radius: 12
                                        color: modelData.tint === root.red ? Qt.rgba(0.94, 0.27, 0.27, 0.08) : root.surface
                                        border.color: modelData.tint === root.red ? Qt.rgba(0.94, 0.27, 0.27, 0.2) : root.border
                                        border.width: 1

                                        Column {
                                            anchors.centerIn: parent; spacing: 4

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: modelData.icon; font.family: root.font
                                                font.pixelSize: 16; color: modelData.tint
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: modelData.label; font.family: root.font
                                                font.pixelSize: 9; color: modelData.tint
                                                font.weight: Font.Medium
                                            }
                                        }

                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.fn() }
                                    }
                                }
                            }

                            Item { width: 1; height: 8 }

                            // ── status row ──
                            RowLayout {
                                width: parent.width; spacing: 12

                                Row { spacing: 6
                                    Text { text: "\uF0279"; font.family: root.font; font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: Math.round(root.batteryLevel * 100) + "%"
                                        font.family: root.fontMono; font.pixelSize: 10
                                        color: root.batteryLevel < 0.2 ? root.red : root.textSec
                                        anchors.verticalCenter: parent.verticalCenter }
                                }

                                Row { spacing: 6
                                    Text { text: "\uF028"; font.family: root.font; font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "100"; font.family: root.fontMono; font.pixelSize: 10; color: root.textSec
                                        anchors.verticalCenter: parent.verticalCenter }
                                }

                                Row { spacing: 6
                                    Text { text: "\uF05A9"; font.family: root.font; font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "On"; font.family: root.fontMono; font.pixelSize: 10; color: root.green
                                        anchors.verticalCenter: parent.verticalCenter }
                                }

                                Item { Layout.fillWidth: true }

                                Text { text: root.dateText; font.family: root.fontMono; font.pixelSize: 10; color: root.textTert
                                    anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }

                    // drag hint
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 20; height: 2; radius: 1
                        color: Qt.rgba(1, 1, 1, 0.10)
                        opacity: root.expanded ? 0.4 : 0.2
                        z: 10
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }
    }
}
