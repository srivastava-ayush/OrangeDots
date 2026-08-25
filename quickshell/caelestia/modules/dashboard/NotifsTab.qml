pragma ComponentBehavior: Bound

import "notifications"
import "utilities/cards"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property Props props: Props {}
    readonly property int notifCount: Notifs.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

    readonly property int notifHeight: 250

    // Keep in sync with Dash.extraWidth so tab switches don't resize the popup.
    readonly property int extraWidth: 220

    implicitWidth: Tokens.sizes.dashboard.userWidth + Tokens.sizes.dashboard.weatherWidth + Tokens.spacing.medium * 3 + root.extraWidth
    implicitHeight: layout.implicitHeight

    Component.onCompleted: Notifs.list.forEach(n => n.popup = false)

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        Toggles {
            Layout.fillWidth: true

            screenState: root.screenState
            popouts: root.popouts
        }

        Rect {
            Layout.fillWidth: true
            Layout.preferredHeight: root.notifHeight

            radius: Tokens.rounding.extraLarge

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: root.notifCount > 0 ? qsTr("notification%1").arg(root.notifCount === 1 ? "" : "s") : qsTr("Notifications")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.large
                    }

                    StyledText {
                        visible: root.notifCount > 0
                        text: root.notifCount
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.large
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    clip: true

                    Loader {
                        asynchronous: true
                        anchors.centerIn: parent
                        active: opacity > 0
                        opacity: root.notifCount > 0 ? 0 : 1

                        sourceComponent: ColumnLayout {
                            spacing: Tokens.spacing.extraLarge

                            Image {
                                asynchronous: true
                                source: Paths.absolutePath(Config.paths.noNotifsPic)
                                fillMode: Image.PreserveAspectFit
                                sourceSize.width: parent.width * 0.8 * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

                                layer.enabled: true
                                layer.effect: Colouriser {
                                    colorizationColor: Colours.palette.m3outlineVariant
                                    brightness: 1
                                }
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: qsTr("All up to date!")
                                color: Colours.palette.m3outlineVariant
                                font: Tokens.font.headline.builders.small.width(90).build()
                            }
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.StandardExtraLarge
                            }
                        }
                    }

                    StyledFlickable {
                        id: view

                        anchors.fill: parent

                        flickableDirection: Flickable.VerticalFlick
                        contentWidth: width
                        contentHeight: notifList.implicitHeight

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: view
                        }

                        NotifDockList {
                            id: notifList

                            props: root.props
                            screenState: root.screenState
                            container: view
                        }
                    }
                }

                Loader {
                    Layout.alignment: Qt.AlignRight
                    asynchronous: true

                    scale: root.notifCount > 0 ? 1 : 0.5
                    opacity: root.notifCount > 0 ? 1 : 0
                    active: opacity > 0

                    sourceComponent: IconButton {
                        id: clearBtn

                        icon: "clear_all"
                        font: Tokens.font.icon.large
                        onClicked: clearTimer.start()

                        Elevation {
                            anchors.fill: parent
                            radius: parent.radius
                            z: -1
                            level: clearBtn.stateLayer.containsMouse ? 4 : 3
                        }
                    }

                    Behavior on scale {
                        Anim {
                            type: Anim.FastSpatial
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: clearTimer

        repeat: true
        triggeredOnStart: true
        interval: Math.max(15, Math.min(80, 69.8 - 12.3 * Math.log(Notifs.notClosed.length)))
        onTriggered: {
            const first = Notifs.notClosed[0];
            if (!first) {
                stop();
                return;
            }

            const appName = first.appName;
            let cleared = 0;
            for (const n of Notifs.notClosed.filter(n => n.appName === appName)) {
                n.close();
                cleared++;
                if (cleared > 30) {
                    interval = 5;
                    return;
                }
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
