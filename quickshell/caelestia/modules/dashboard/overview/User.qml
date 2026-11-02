pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker
    property int availableUpdates: -1
    property int pendingUpdates: 0

    implicitHeight: header.implicitHeight + footer.implicitHeight + Tokens.spacing.medium + Tokens.padding.large * 2
    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    Component.onCompleted: updateCheck.running = true

    Process {
        id: updateCheck
        // checkupdates uses a temporary database, never pacman -Sy.
        command: ["checkupdates"]
        onStarted: root.pendingUpdates = 0
        stdout: StdioCollector {
            onStreamFinished: root.pendingUpdates = text.trim() ? text.trim().split("\n").length : 0
        }
        onExited: code => root.availableUpdates = code === 2 ? 0 : code === 0 ? root.pendingUpdates : -2
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: if (!updateCheck.running) updateCheck.running = true
    }

    Item {
        id: layout
        anchors.fill: parent

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: avatar.height + identity.implicitHeight + Tokens.spacing.medium
            height: implicitHeight

            ClippingRectangle {
                id: avatar
                objectName: "overviewAvatar"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: Math.min(root.width, 180)
                height: width
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "person"
                    fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                    color: Colours.palette.m3onSecondaryContainer
                }

                CachingImage {
                    anchors.fill: parent
                    path: `${Paths.home}/.face`
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.screenState.dashboard = false;
                        root.facePicker.open();
                    }
                }
            }

            ColumnLayout {
                id: identity
                anchors.top: avatar.bottom
                anchors.topMargin: Tokens.spacing.medium
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: Quickshell.env("USER") || qsTr("Welcome")
                    font: Tokens.font.title.medium
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Up %1").arg(SysInfo.uptime.split(",").slice(0, 2).join(","))
                    horizontalAlignment: Text.AlignHCenter
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        ColumnLayout {
            id: footer
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Tokens.spacing.small

            Item {
                objectName: "overviewUpdates"
                Layout.fillWidth: true
                implicitHeight: updateRow.implicitHeight

                RowLayout {
                    id: updateRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "system_update"
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.availableUpdates === -1 ? qsTr("Checking updates…") : root.availableUpdates === -2 ? qsTr("Updates unavailable") : root.availableUpdates === 0 ? qsTr("System up to date") : qsTr("%1 updates available").arg(root.availableUpdates)
                        font: Tokens.font.label.medium
                        color: updatesMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: updatesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.screenState.dashboard = false;
                        Quickshell.execDetached(["kitty", "-e", "sudo", "pacman", "-Syu"]);
                    }
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            RowLayout {
                objectName: "overviewSessionControls"
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                PowerButton {
                    icon: "lock"
                    onClicked: {
                        root.screenState.dashboard = false;
                        Quickshell.execDetached(["caelestia", "shell", "lock", "lock"]);
                    }
                }
                PowerButton {
                    icon: "bedtime"
                    onClicked: SessionManager.suspend()
                }
                PowerButton {
                    icon: Config.session.icons.hibernate
                    onClicked: SessionManager.hibernate()
                }
                PowerButton {
                    icon: Config.session.icons.reboot
                    onClicked: SessionManager.reboot()
                }
                PowerButton {
                    icon: Config.session.icons.shutdown
                    onClicked: SessionManager.poweroff()
                }
            }
        }
    }

    component PowerButton: IconButton {
        Layout.fillWidth: true
        type: IconButton.Tonal
        font: Tokens.font.icon.medium
        padding: Tokens.padding.extraSmall
    }
}
