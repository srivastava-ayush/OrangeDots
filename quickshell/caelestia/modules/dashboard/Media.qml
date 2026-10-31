import "media"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ScreenState screenState

    function toggleSpotifyScratchpad(): void {
        const configHome = Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`;
        screenState.dashboard = false;
        Quickshell.execDetached(["bash", `${configHome}/hypr/scripts/toggle-spotify.sh`]);
    }

    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: Tokens.sizes.dashboard.mediaTabHeight

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.extraLarge

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            state: Players.active ? "" : "noMedia"

            states: State {
                name: "noMedia"

                PropertyChanges {
                    noMedia.opacity: 1
                    content.opacity: 0
                }
            }

            transitions: [
                Transition {
                    from: ""

                    SequentialAnimation {
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                },
                Transition {
                    to: ""

                    SequentialAnimation {
                        Anim {
                            target: noMedia
                            property: "opacity"
                            type: Anim.DefaultEffects
                        }
                        Anim {
                            target: content
                            property: "opacity"
                            type: Anim.SlowEffects
                        }
                    }
                }
            ]

            Loader {
                id: noMedia
                objectName: "dashboardMediaEmpty"

                anchors.centerIn: parent
                asynchronous: true
                active: opacity > 0
                opacity: 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.small

                    StyledRect {
                        Layout.bottomMargin: Tokens.spacing.small
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.palette.m3secondaryContainer
                        implicitWidth: 96
                        implicitHeight: 96
                        radius: Tokens.rounding.extraLarge

                        MaterialIcon {
                            id: icon

                            anchors.centerIn: parent
                            text: "queue_music"
                            fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                            color: Colours.palette.m3onSecondaryContainer
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Nothing playing")
                        font: Tokens.font.headline.medium
                    }

                    StyledText {
                        text: qsTr("Play something for it to show up here!")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }
            }

            Loader {
                id: content
                objectName: "dashboardMediaContent"

                anchors.fill: parent
                asynchronous: true
                active: opacity > 0

                sourceComponent: RowLayout {
                    spacing: Tokens.spacing.extraLarge

                    // An expanded island: artwork, metadata and direct controls.
                    StyledRect {
                        id: mediaCard

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        color: Colours.tPalette.m3surfaceContainer
                        radius: Tokens.rounding.extraLarge
                        clip: true

                        // Behind the content: buttons/seek consume their own clicks,
                        // while artwork, metadata and free space toggle Super+S.
                        MouseArea {
                            objectName: "dashboardMediaSpotifyToggle"
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleSpotifyScratchpad()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            anchors.topMargin: Tokens.padding.largeIncreased
                            anchors.bottomMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.extraLarge

                            ColumnLayout {
                                id: artworkColumn
                                readonly property real artworkSize: Math.max(64, Math.min(mediaCard.height - Tokens.padding.largeIncreased * 2 - 40, 220))
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: artworkSize
                                Layout.maximumWidth: artworkSize
                                Layout.minimumWidth: 0
                                spacing: Tokens.spacing.small

                                ClippingRectangle {
                                    objectName: "dashboardMediaArtwork"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: artworkColumn.artworkSize
                                    Layout.minimumHeight: 0
                                    Layout.maximumHeight: artworkColumn.artworkSize
                                    radius: Tokens.rounding.extraLarge
                                    color: Colours.palette.m3secondaryContainer

                                    MaterialIcon {
                                        anchors.centerIn: parent
                                        text: "music_note"
                                        fontStyle: Tokens.font.icon.builders.large.scale(2).build()
                                        color: Colours.palette.m3onSecondaryContainer
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: Players.getArtUrl(Players.active)
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        sourceSize.width: 440
                                        sourceSize.height: 440
                                    }
                                }

                                EqBars {
                                    objectName: "dashboardMediaVisualizer"
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                }
                            }

                            Details {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }

                    }

                    LyricsAndSelector {
                        Layout.fillHeight: true
                        implicitWidth: Tokens.sizes.dashboard.mediaSectionWidth
                    }
                }
            }
        }
    }
}
