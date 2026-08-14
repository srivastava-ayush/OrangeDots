pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.utils

Item {
    id: root

    property string source: Wallpapers.current
    property CachingImage current
    property bool completed
    property bool nextSlideLeft: true

    onSourceChanged: {
        if (!source)
            current = null;
        else
            current = imgComp.createObject(this, {
                path: source,
                slideFromLeft: root.nextSlideLeft
            });
        root.nextSlideLeft = !root.nextSlideLeft;
    }

    Component.onCompleted: {
        if (source)
            Qt.callLater(() => {
                current = imgComp.createObject(this, {
                    path: source,
                    slideFromLeft: root.nextSlideLeft
                });
                completed = true;
            });
        root.nextSlideLeft = !root.nextSlideLeft;
    }

    Loader {
        asynchronous: true
        anchors.fill: parent

        active: root.completed && !root.source

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(5).build()
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Bold).build()
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.extraLargeIncreased
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.small

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image files")
                            filters: Images.validImageExtensions
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary
                            onClicked: dialog.open()
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font: Tokens.font.body.large
                        }
                    }
                }
            }
        }
    }

    Component {
        id: imgComp

        CachingImage {
            id: img

            width: parent.width
            height: parent.height

            opacity: 0

            property bool slideFromLeft: true
            readonly property int animDuration: Tokens.anim.durations.expressiveSlowSpatial

            onStatusChanged: {
                if (status === Image.Ready)
                    startAnim();
            }

            function startAnim(): void {
                if (slideFromLeft)
                    slideLeft.start();
                else
                    slideRight.start();
            }

            ParallelAnimation {
                id: slideLeft

                running: false

                Anim {
                    target: img
                    property: "opacity"
                    from: 0
                    to: 1
                    type: Anim.SlowSpatial
                }

                NumberAnimation {
                    target: img
                    property: "x"
                    from: -width
                    to: 0
                    duration: Tokens.anim.durations.expressiveSlowSpatial
                    easing: Tokens.anim.expressiveSlowSpatial
                }

                NumberAnimation {
                    target: img
                    property: "scale"
                    from: 1.3
                    to: 1
                    duration: Tokens.anim.durations.expressiveSlowSpatial
                    easing: Tokens.anim.expressiveSlowSpatial
                }
            }

            ParallelAnimation {
                id: slideRight

                running: false

                Anim {
                    target: img
                    property: "opacity"
                    from: 0
                    to: 1
                    type: Anim.SlowSpatial
                }

                NumberAnimation {
                    target: img
                    property: "x"
                    from: width
                    to: 0
                    duration: Tokens.anim.durations.expressiveSlowSpatial
                    easing: Tokens.anim.expressiveSlowSpatial
                }

                NumberAnimation {
                    target: img
                    property: "scale"
                    from: 1.3
                    to: 1
                    duration: Tokens.anim.durations.expressiveSlowSpatial
                    easing: Tokens.anim.expressiveSlowSpatial
                }
            }

            Timer {
                running: root.current !== img && root.current?.status === Image.Ready
                interval: img.animDuration
                onTriggered: img.destroy()
            }
        }
    }
}
