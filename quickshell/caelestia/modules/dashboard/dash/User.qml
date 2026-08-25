pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

    anchors.fill: parent
    anchors.margins: Tokens.padding.large
    clip: true

    Behavior on pfpFallbackColour {
        CAnim {}
    }

    Item {
        id: pfpContainer

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        height: Math.min(parent.height, 96)
        implicitWidth: height

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
                    fontStyle: Tokens.font.icon.extraLarge
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

    ColumnLayout {
        anchors.left: pfpContainer.right
        anchors.leftMargin: Tokens.spacing.largeIncreased
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.extraSmall

        Row {
            spacing: Tokens.spacing.extraSmall

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.hourStr
                font: Tokens.font.headline.builders.medium.weight(Font.Bold).build()
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: ":"
                color: Colours.palette.m3primary
                font: Tokens.font.headline.builders.medium.weight(Font.Bold).build()
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: Time.minuteStr
                font: Tokens.font.headline.builders.medium.weight(Font.Bold).build()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Time.format("ddd, MMM d")
            color: Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: uptimeChip.implicitSize
            Layout.topMargin: Tokens.spacing.small

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
            Layout.topMargin: Tokens.spacing.small
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
        font: Tokens.font.icon.small
        padding: Tokens.padding.extraSmall
        onClicked: action()
    }
}
