pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Caelestia.Config
import qs.components
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
    readonly property real pfpSize: Math.min(root.height - Tokens.padding.medium * 2, 96)

    anchors.fill: parent
    anchors.margins: Tokens.padding.large

    Behavior on pfpFallbackColour {
        CAnim {}
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.large

        Item {
            id: pfpContainer

            implicitWidth: root.pfpSize
            implicitHeight: root.pfpSize

            MaterialShape {
                id: shape

                anchors.fill: parent
                shape: MaterialShape.Circle
                color: Qt.alpha(root.pfpFallbackColour, 1)
                opacity: root.pfpFallbackColour.a
                layer.enabled: true

                MouseArea {
                    id: mouse

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
                        text: "person"
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
                        shape: MaterialShape.Circle
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

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.extraSmall

            StyledText {
                text: "yush's rch"
                color: Colours.palette.m3primary
                font: Tokens.font.headline.builders.small.width(60).weight(Font.DemiBold).build()
            }

            Row {
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "clock_arrow_up"
                    color: Colours.palette.m3secondary
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: Math.round(fontInfo.pointSize * 0.1)
                    text: "up " + SysInfo.uptime.split(",").slice(0, 2).join(",") // Max 2 components
                    color: Colours.palette.m3secondary
                    font: Tokens.font.body.small

                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, root.width - pfpContainer.implicitWidth - root.anchors.margins * 2 - row.spacing)
                }
            }
        }
    }
}
