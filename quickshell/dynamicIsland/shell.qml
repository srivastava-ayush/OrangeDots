// Dynamic Island — Vercel × iOS Edition
// =========================================================
//   COMPACT  →  pill: time, status dot, battery
//   HOVER    →  full media player + power actions
//   LEAVE    →  collapses back to pill

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

            // Nerd Font icons (v3 MD codepoints, all above BMP so use String.fromCodePoint)
            readonly property string ico_lock:    String.fromCodePoint(0xF033E)
            readonly property string ico_sleep:   String.fromCodePoint(0xF0492)
            readonly property string ico_restart: String.fromCodePoint(0xF0450)
            readonly property string ico_power:   String.fromCodePoint(0xF0425)
            readonly property string ico_logout:  String.fromCodePoint(0xF0347)
            readonly property string ico_prev:    String.fromCodePoint(0xF04A9)
            readonly property string ico_next:    String.fromCodePoint(0xF04AD)
            readonly property string ico_play:    String.fromCodePoint(0xF040A)
            readonly property string ico_pause:   String.fromCodePoint(0xF03EB)
            readonly property string ico_ff:      String.fromCodePoint(0xF01F3)
            readonly property string ico_rw:      String.fromCodePoint(0xF04A3)
            readonly property string ico_battery: String.fromCodePoint(0xF037C)
            readonly property string ico_volume:  String.fromCodePoint(0xF057E)
            readonly property string ico_wifi:    String.fromCodePoint(0xF05A9)
            readonly property string ico_music:   String.fromCodePoint(0xF0758)

            readonly property string fontFamily: "Symbols Nerd Font, SF Pro Display, Inter, system-ui"
            readonly property string fontMono:   "SF Mono, JetBrains Mono, Fira Code, monospace"

            readonly property color black:     "#000000"
            readonly property color surface:   "#0a0a0a"
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
            property real batteryLevel: UPower.displayDevice ? UPower.displayDevice.percentage : 0
            property bool batteryCharging: UPower.displayDevice ? UPower.displayDevice.state === 1 : false
            property bool hasBattery: UPower.displayDevice !== null && UPower.displayDevice.isPresent !== false

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

            // seek helper
            function seek(offset) {
                if (!root.hasPlayer || !root.player) return
                var pos = root.player.position + offset
                pos = Math.max(0, Math.min(pos, root.player.length || 0))
                root.player.setPosition(pos)
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

                            Rectangle {
                                width: 6; height: 6; radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.hasPlayer && root.player.isPlaying ? root.green : root.textTert
                            }
                            Text {
                                text: root.timeText
                                color: root.textPri; font.family: root.fontMono
                                font.pixelSize: 13; font.weight: Font.DemiBold
                                font.letterSpacing: -0.5
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: Math.round(root.batteryLevel * 100) + "%"
                                color: root.textTert; font.family: root.fontMono
                                font.pixelSize: 10; font.weight: Font.Normal
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.hasBattery
                            }
                        }

                        // ════════════ EXPANDED MEDIA PLAYER ════════════
                        Column {
                            anchors.fill: parent
                            anchors.margins: 24
                            spacing: 0
                            opacity: root.expanded ? 1 : 0
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            // ── art + info + controls ──
                            Row {
                                width: parent.width; spacing: 20

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
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.ico_music
                                        color: root.textTert; font.family: root.fontFamily; font.pixelSize: 28
                                        visible: !root.hasPlayer || !root.player.trackArtUrl
                                    }
                                    Rectangle {
                                        anchors.fill: parent; radius: parent.radius; color: "transparent"
                                        border.color: Qt.rgba(1, 1, 1, 0.06); border.width: 1
                                    }
                                }

                                // track info
                                Column {
                                    width: parent.width - 96 - 60 - 40
                                    anchors.verticalCenter: parent.verticalCenter; spacing: 0

                                    Text {
                                        width: parent.width
                                        text: root.hasPlayer ? (root.player.trackTitle || "Not Playing") : "No Media"
                                        color: root.textPri; font.family: root.fontFamily
                                        font.pixelSize: 15; font.weight: Font.DemiBold
                                        font.letterSpacing: -0.3; elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width; topPadding: 2
                                        text: root.hasPlayer ? (root.player.trackArtist || "") : ""
                                        color: root.textSec; font.family: root.fontFamily
                                        font.pixelSize: 12; elide: Text.ElideRight
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

                                    Row {
                                        width: parent.width
                                        Text { text: root.hasPlayer ? root.fmt(root.player.position) : "0:00"
                                            color: root.textTert; font.family: root.fontMono; font.pixelSize: 10 }
                                        Item { width: parent.width - 60; height: 1 }
                                        Text { text: root.hasPlayer ? root.fmt(root.player.length) : "0:00"
                                            color: root.textTert; font.family: root.fontMono; font.pixelSize: 10 }
                                    }
                                }

                                // transport controls — right column
                                Column {
                                    width: 60
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    // top row: rw + ff
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 20
                                        // seek backward 10s
                                        Rectangle { width: 28; height: 28; radius: 14; color: "transparent"
                                            Text { anchors.centerIn: parent; text: root.ico_rw
                                                color: root.hasPlayer ? root.textSec : root.textTert
                                                font.family: root.fontFamily; font.pixelSize: 13 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4
                                                onClicked: root.seek(-10000) }
                                        }
                                        // seek forward 10s
                                        Rectangle { width: 28; height: 28; radius: 14; color: "transparent"
                                            Text { anchors.centerIn: parent; text: root.ico_ff
                                                color: root.hasPlayer ? root.textSec : root.textTert
                                                font.family: root.fontFamily; font.pixelSize: 13 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4
                                                onClicked: root.seek(10000) }
                                        }
                                    }

                                    // middle row: prev + play + next
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 8
                                        // previous
                                        Rectangle { width: 30; height: 30; radius: 15; color: "transparent"
                                            Text { anchors.centerIn: parent; text: root.ico_prev
                                                color: root.hasPlayer && root.player.canGoPrevious ? root.textPri : root.textTert
                                                font.family: root.fontFamily; font.pixelSize: 12 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4
                                                onClicked: root.hasPlayer && root.player.previous() }
                                        }
                                        // play/pause — white circle
                                        Rectangle { width: 38; height: 38; radius: 19; color: root.accentPri
                                            Text { anchors.centerIn: parent
                                                text: root.hasPlayer && root.player.isPlaying ? root.ico_pause : root.ico_play
                                                font.family: root.fontFamily; font.pixelSize: 15; color: root.black }
                                            MouseArea { anchors.fill: parent
                                                onClicked: root.hasPlayer && root.player.togglePlaying() }
                                        }
                                        // next
                                        Rectangle { width: 30; height: 30; radius: 15; color: "transparent"
                                            Text { anchors.centerIn: parent; text: root.ico_next
                                                color: root.hasPlayer && root.player.canGoNext ? root.textPri : root.textTert
                                                font.family: root.fontFamily; font.pixelSize: 12 }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4
                                                onClicked: root.hasPlayer && root.player.next() }
                                        }
                                    }
                                }
                            }

                            Item { width: 1; height: 28 }
                            Rectangle { width: parent.width; height: 1; color: root.border }
                            Item { width: 1; height: 20 }

                            // ── power row ──
                            Row {
                                width: parent.width; spacing: 8

                                Repeater {
                                    model: ListModel {
                                        ListElement { iconId: "lock";    label: "Lock";    isRed: false }
                                        ListElement { iconId: "sleep";   label: "Sleep";   isRed: false }
                                        ListElement { iconId: "restart"; label: "Restart"; isRed: false }
                                        ListElement { iconId: "power";   label: "Shutdown";isRed: true }
                                        ListElement { iconId: "logout";  label: "Logout";  isRed: false }
                                    }

                                    Rectangle {
                                        width: (parent.width - 32) / 5; height: 52; radius: 12
                                        color: model.isRed ? Qt.rgba(0.94, 0.27, 0.27, 0.08) : root.surface
                                        border.color: model.isRed ? Qt.rgba(0.94, 0.27, 0.27, 0.2) : root.border
                                        border.width: 1

                                        property string icon: {
                                            if (model.iconId === "lock") return root.ico_lock
                                            if (model.iconId === "sleep") return root.ico_sleep
                                            if (model.iconId === "restart") return root.ico_restart
                                            if (model.iconId === "power") return root.ico_power
                                            return root.ico_logout
                                        }
                                        property color tint: model.isRed ? root.red : root.textSec

                                        Column {
                                            anchors.centerIn: parent; spacing: 4
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: parent.parent.icon; font.family: root.fontFamily
                                                font.pixelSize: 16; color: parent.parent.tint
                                            }
                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: model.label; font.family: root.fontFamily
                                                font.pixelSize: 9; color: parent.parent.tint; font.weight: Font.Medium
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (model.iconId === "lock") lockProc.running = true
                                                else if (model.iconId === "sleep") sleepProc.running = true
                                                else if (model.iconId === "restart") restartProc.running = true
                                                else if (model.iconId === "power") shutdownProc.running = true
                                                else if (model.iconId === "logout") {
                                                    logoutProc.command = ["loginctl", "terminate-user", Quickshell.env("USER") || ""]
                                                    logoutProc.running = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Item { width: 1; height: 8 }

                            // ── status row ──
                            RowLayout {
                                width: parent.width; spacing: 12

                                Row { spacing: 6; visible: root.hasBattery
                                    Text { text: root.ico_battery; font.family: root.fontFamily
                                        font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: Math.round(root.batteryLevel * 100) + "%"
                                        font.family: root.fontMono; font.pixelSize: 10
                                        color: root.batteryLevel < 0.2 ? root.red : root.textSec
                                        anchors.verticalCenter: parent.verticalCenter }
                                }
                                Row { spacing: 6
                                    Text { text: root.ico_volume; font.family: root.fontFamily
                                        font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "---"; font.family: root.fontMono; font.pixelSize: 10; color: root.textSec
                                        anchors.verticalCenter: parent.verticalCenter }
                                }
                                Row { spacing: 6
                                    Text { text: root.ico_wifi; font.family: root.fontFamily
                                        font.pixelSize: 11; color: root.textTert
                                        anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: "On"; font.family: root.fontMono; font.pixelSize: 10; color: root.green
                                        anchors.verticalCenter: parent.verticalCenter }
                                }

                                Item { Layout.fillWidth: true }

                                Text { text: root.dateText; font.family: root.fontMono; font.pixelSize: 10
                                    color: root.textTert; anchors.verticalCenter: parent.verticalCenter }
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
