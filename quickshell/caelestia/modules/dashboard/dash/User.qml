pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import M3Shapes
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    property color pfpFallbackColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
    property int availableUpdates: -1
    property int pendingUpdates: 0

    Component.onCompleted: updateCheck.running = true

    Process {
        id: updateCheck

        // checkupdates uses a temporary sync database; never run pacman -Sy to count updates.
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
        onTriggered: {
            if (!updateCheck.running)
                updateCheck.running = true;
        }
    }

    anchors.fill: parent
    anchors.margins: Tokens.padding.large
    clip: true

    Behavior on pfpFallbackColour {
        CAnim {}
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.preferredHeight: (root.width - parent.spacing) / 2

                Item {
                    id: pfpContainer

                    anchors.fill: parent

                    MaterialShape {
                        id: shape

                        anchors.centerIn: parent
                        implicitSize: parent.height
                        shape: MaterialShape.Pill
                        color: Qt.alpha(root.pfpFallbackColour, 1)
                        opacity: root.pfpFallbackColour.a
                        layer.enabled: true

                        MouseArea {
                            id: mouse

                            containmentMask: QtObject {
                                function contains(pt: point): bool {
                                    return shape.contains(pt);
                                }
                            }

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.screenState.dashboard = false;
                                root.facePicker.open();
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: Mask {
                            maskSource: shape
                        }

                        Loader {
                            anchors.centerIn: parent
                            asynchronous: true
                            active: pfp.status !== Image.Ready

                            sourceComponent: MaterialIcon {
                                text: "person_add"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.large
                                fill: 1
                                grade: -2 // Ugh material symbols are such a pain with fill
                            }
                        }

                        CachingImage {
                            id: pfp

                            anchors.fill: parent
                            path: `${Paths.home}/.face`
                        }

                        StyledRect {
                            anchors.fill: parent
                            color: Qt.alpha(Colours.palette.m3scrim, pfp.status === Image.Ready ? 0.4 : 0)
                            opacity: mouse.containsMouse ? 1 : 0
                            layer.enabled: opacity < 1

                            Behavior on opacity {
                                Anim {
                                    type: Anim.DefaultEffects
                                }
                            }

                            MaterialShape {
                                anchors.centerIn: parent
                                implicitSize: parent.height * 0.7
                                shape: MaterialShape.Diamond
                                color: Colours.palette.m3primary
                                scale: mouse.pressed ? 0.9 : mouse.containsMouse ? 1 : 0.7

                                Behavior on color {
                                    CAnim {}
                                }

                                Behavior on scale {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }

                                MaterialIcon {
                                    anchors.centerIn: parent
                                    text: "person_edit"
                                    color: Colours.palette.m3onPrimary
                                    fontStyle: Tokens.font.icon.large
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Time.hourStr
                        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ":"
                        color: Colours.palette.m3primary
                        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Time.minuteStr
                        font: Tokens.font.headline.builders.large.weight(Font.Bold).build()
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Time.format("ddd, MMM d")
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: updateChip.implicitSize
            Layout.topMargin: Tokens.spacing.extraSmall

            Row {
                spacing: Tokens.spacing.small

                Item {
                    width: updateChip.implicitSize
                    height: updateChip.implicitSize

                    MaterialShape {
                        id: updateChip

                        anchors.fill: parent
                        implicitSize: Tokens.sizes.dashboard.uptimeSize + Tokens.padding.small * 2
                        shape: MaterialShape.ClamShell
                        color: Colours.palette.m3secondaryContainer

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "system_update"
                            color: Colours.palette.m3onSecondaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.availableUpdates === -1 ? qsTr("Checking for updates…") : root.availableUpdates === -2 ? qsTr("Updates unavailable") : qsTr("%1 updates available").arg(root.availableUpdates)
                    color: updatesMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurface
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

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: uptimeChip.implicitSize
            Layout.topMargin: -Tokens.spacing.extraSmall

            Row {
                spacing: Tokens.spacing.small

                Item {
                    width: uptimeChip.implicitSize
                    height: uptimeChip.implicitSize

                    MaterialShape {
                        id: uptimeChip

                        anchors.fill: parent
                        implicitSize: Tokens.sizes.dashboard.uptimeSize + Tokens.padding.small * 2
                        shape: MaterialShape.ClamShell
                        color: Colours.palette.m3tertiaryContainer

                        Behavior on color {
                            CAnim {}
                        }

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "clock_arrow_up"
                            color: Colours.palette.m3onTertiaryContainer
                            fontStyle: Tokens.font.icon.medium
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "up " + SysInfo.uptime.split(",").slice(0, 2).join(",") // Max 2 components
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            spacing: Tokens.spacing.extraSmall

            PowerButton {
                iconText: Config.session.icons.logout
                action: () => SessionManager.logout()
            }

            PowerButton {
                iconText: "bedtime"
                action: () => SessionManager.suspend()
            }

            PowerButton {
                iconText: Config.session.icons.hibernate
                action: () => SessionManager.hibernate()
            }

            PowerButton {
                iconText: Config.session.icons.reboot
                action: () => SessionManager.reboot()
            }

            PowerButton {
                iconText: Config.session.icons.shutdown
                action: () => SessionManager.poweroff()
            }
        }
    }

    component PowerButton: IconButton {
        id: btn

        required property string iconText
        required property var action

        icon: btn.iconText
        Layout.fillWidth: true
        type: IconButton.Tonal
        font: Tokens.font.icon.medium
        padding: Tokens.padding.extraSmall
        onClicked: action()
    }
}
