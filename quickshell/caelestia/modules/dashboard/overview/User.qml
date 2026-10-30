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

    implicitHeight: layout.implicitHeight + Tokens.padding.largeIncreased * 2
    anchors.fill: parent
    anchors.margins: Tokens.padding.largeIncreased

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

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            ClippingRectangle {
                objectName: "overviewAvatar"
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 16
                color: Colours.palette.m3secondaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "person"
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
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    text: Quickshell.env("USER") || qsTr("Welcome")
                    font: Tokens.font.title.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Up %1").arg(SysInfo.uptime.split(",").slice(0, 2).join(","))
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.fillHeight: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                objectName: "overviewClock"
                Layout.fillWidth: true
                text: `${Time.hourStr}:${Time.minuteStr}`
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.font.headline.large
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Time.format("ddd, MMM d")
                horizontalAlignment: Text.AlignHCenter
                font: Tokens.font.body.medium
                color: Colours.palette.m3onSurfaceVariant
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillHeight: true }

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

    component PowerButton: IconButton {
        Layout.fillWidth: true
        type: IconButton.Tonal
        font: Tokens.font.icon.medium
        padding: Tokens.padding.extraSmall
    }
}
