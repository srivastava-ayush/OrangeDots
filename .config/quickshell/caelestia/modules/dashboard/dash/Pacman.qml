pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    property int packageCount: 0
    property int updateCount: 0
    readonly property bool hasUpdates: root.updateCount > 0

    readonly property string cacheFile: "/tmp/caelestia-pacman-updates"

    anchors.fill: parent

    // Package count is instant (no network), so read it directly.
    Process {
        id: pkgProc

        running: true
        command: ["sh", "-c", "pacman -Q | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.packageCount = parseInt(text.trim()) || 0
        }
    }

    // Update count needs a fresh db; checkupdates syncs into a temp dir (no root).
    // Run it in the background hourly and cache the result so the widget never blocks.
    Timer {
        interval: 60 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updProc.exec(updProc.command)
    }

    Process {
        id: updProc

        command: ["sh", "-c", `echo "$(checkupdates 2>/dev/null | wc -l)" > ${root.cacheFile}`]
    }

    FileView {
        id: updFile

        path: root.cacheFile
        onLoaded: root.updateCount = parseInt(text().trim()) || 0
    }

    Timer {
        interval: 10 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updFile.reload()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["kitty", "-e", "sudo", "pacman", "-Syu"])
    }

    Row {
        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        MaterialIcon {
            anchors.verticalCenter: parent.verticalCenter

            animate: true
            text: root.hasUpdates ? "system_update" : "package_2"
            color: root.hasUpdates ? Colours.palette.m3tertiary : Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.4).build()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.extraSmall

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                animate: true
                text: root.hasUpdates ? root.updateCount : root.packageCount
                color: root.hasUpdates ? Colours.palette.m3tertiary : Colours.palette.m3primary
                font: Tokens.font.headline.builders.medium.width(110).weight(Font.DemiBold).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                animate: true
                text: root.hasUpdates ? qsTr("%1 pkgs").arg(root.packageCount) : qsTr("up to date")
                font: Tokens.font.body.small

                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.width - Tokens.padding.extraLargeIncreased)
            }
        }
    }
}
