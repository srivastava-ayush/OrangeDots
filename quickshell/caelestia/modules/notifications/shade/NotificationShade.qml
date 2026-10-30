pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.services

// Taskbar notification popout. The list is a grouped dock (swipe to clear
// an app, right click / drag down to expand).
StyledRect {
    id: root

    required property ScreenState screenState

    readonly property ShadeState props: ShadeState {}
    readonly property int notifCount: Notifs.list.reduce((acc, n) => n.closed ? acc : acc + 1, 0)

    // Keep some breathing room while allowing a slightly taller notification list.
    readonly property real maxShadeHeight: ((QsWindow.window as QsWindow)?.screen?.height ?? 1000) * 0.60
    readonly property int listMaxHeight: 480
    readonly property int emptyMinHeight: 180

    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: Math.min(root.maxShadeHeight, layout.implicitHeight)

    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        objectName: "notificationShadeLayout"
        anchors.fill: parent
        // The shared status-popout container already supplies the outer padding.
        spacing: root.Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: root.Tokens.spacing.small

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

            IconButton {
                icon: Notifs.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                type: IconButton.Tonal
                isToggle: true
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Loader {
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

        Item {
            id: listArea

            Layout.fillWidth: true
            Layout.fillHeight: true
            // Preserve the panel's height: give the removed inner inset to the
            // scrollable list instead of padding the header and sides twice.
            implicitHeight: Math.min(root.listMaxHeight, Math.max(view.contentHeight, root.emptyMinHeight)) + root.Tokens.padding.large * 2
            clip: true

            StyledFlickable {
                id: view

                anchors.fill: parent

                flickableDirection: Flickable.VerticalFlick
                contentWidth: width
                contentHeight: notifList.implicitHeight

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: view
                }

                NotificationDock {
                    id: notifList

                    props: root.props
                    screenState: root.screenState
                    container: view
                }
            }

            Loader {
                asynchronous: true
                anchors.centerIn: parent
                active: opacity > 0
                opacity: root.notifCount > 0 ? 0 : 1

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "notifications_paused"
                        color: Colours.palette.m3outlineVariant
                        fontStyle: Tokens.font.icon.large
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("All caught up!")
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
}
