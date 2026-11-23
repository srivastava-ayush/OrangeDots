pragma ComponentBehavior: Bound

import "./kblayout"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.notifications.shade as NotifShade

Item {
    id: root

    required property PopoutState popouts
    required property ScreenState screenState
    readonly property Popout currentPopout: content.children.find(c => c.shouldBeActive) ?? null
    readonly property Item current: currentPopout?.item ?? null

    implicitWidth: (currentPopout?.implicitWidth ?? 0) + Tokens.padding.extraLargeIncreased
    implicitHeight: (currentPopout?.implicitHeight ?? 0) + Tokens.padding.extraLargeIncreased

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        Popout {
            name: "activewindow"
            sourceComponent: ActiveWindow {
                popouts: root.popouts
            }
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                popouts: root.popouts
                view: Nmcli.activeEthernet ? "ethernet" : "wireless"
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                id: passwordComponent

                popouts: root.popouts
                network: (networkPopout.item as Network)?.passwordNetwork ?? null
            }

            Connections {
                function onCurrentNameChanged() {
                    // Update network immediately when password popout becomes active
                    if (root.popouts.currentName === "wirelesspassword") {
                        // Set network immediately if available
                        if ((networkPopout.item as Network)?.passwordNetwork) {
                            if (passwordPopout.item) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }
                        // Also try after a short delay in case networkPopout.item wasn't ready
                        Qt.callLater(() => {
                            if (passwordPopout.item && (networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        }, 100);
                    }
                }

                target: root.popouts
            }

            Connections {
                function onItemChanged() {
                    // When network popout loads, update password popout if it's active
                    if (root.popouts.currentName === "wirelesspassword" && passwordPopout.item) {
                        Qt.callLater(() => {
                            if ((networkPopout.item as Network)?.passwordNetwork) {
                                (passwordPopout.item as WirelessPassword).network = (networkPopout.item as Network).passwordNetwork;
                            }
                        });
                    }
                }

                target: networkPopout
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                popouts: root.popouts
            }
        }

        Popout {
            name: "battery"
            sourceComponent: Battery {}
        }

        Popout {
            name: "audio"
            sourceComponent: AudioPopout {
                popouts: root.popouts
            }
        }

        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "clock"
            sourceComponent: CalendarPopout {
                popouts: root.popouts
            }
        }

        Popout {
            name: "notifications"
            sourceComponent: NotifShade.NotificationShade {
                objectName: "taskbarNotificationShade"
                screenState: root.screenState
                // The shared popout already supplies the outer background.
                color: "transparent"
            }
        }

        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
        }

        Repeater {
            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    function onHasCurrentChanged(): void {
                        if (root.popouts.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }

                    target: root.popouts
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.popouts
                        trayItem: trayMenu.modelData.menu // qmllint disable unresolved-type
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: root.popouts.currentName === name
        // Every status menu is built from scratch the first time it is shown.
        // Building the whole tree (network list, sliders, toggles) inside the
        // frame a switch lands is the main source of the hitch while sweeping
        // across icons. Keep stateless menus instantiated once revealed so a
        // second visit only runs the crossfade. Dialog-backed popouts are
        // rebuilt, and tray menus already reload their own source.
        readonly property bool warmable: name !== "wirelesspassword" && !name.startsWith("traymenu")
        property bool warmed: false

        // The menu hangs from the bar edge. Pinning content to the top/left of
        // the morphing container means a size change reveals the menu instead
        // of sliding an already final-sized menu towards the centre every frame.
        // At rest the content exactly fills this box, so this matches the old
        // centred placement (only the bar-bottom shade grows upwards).
        readonly property bool hangsFromBottom: !Taskbar.horizontal && root.popouts.currentName === "notifications"

        anchors.top: popout.hangsFromBottom ? undefined : parent.top
        anchors.bottom: popout.hangsFromBottom ? parent.bottom : undefined
        anchors.left: parent.left

        // The menu's inner content is staged from one reversible spring: the
        // card fades, lifts into place and settles while the shell morphs around
        // it. The outgoing card uses a stiffer tuning so it clears before the
        // incoming one arrives, and a fast sweep just retargets the same spring
        // instead of restarting separate timelines.
        property real revealStage: 0
        property int slideDirection: 1

        Behavior on revealStage {
            SpringAnimation {
                id: stageSpring
                spring: 4.5
                damping: 0.55
                mass: 1
                epsilon: 0.005
            }
        }

        onShouldBeActiveChanged: {
            // Set the tuning before retargeting so the first frame keeps its
            // velocity instead of snapping (same pattern as the other panels).
            stageSpring.spring = popout.shouldBeActive ? 4.5 : 7;
            stageSpring.damping = popout.shouldBeActive ? 0.55 : 0.7;
            popout.slideDirection = popout.shouldBeActive ? 1 : -1;
            if (popout.shouldBeActive && popout.warmable)
                popout.warmed = true;
            popout.revealStage = popout.shouldBeActive ? 1 : 0;
        }

        // A loader can also be born active (e.g. the popout is reopened with
        // the previous name still current). Start such a card already shown.
        Component.onCompleted: {
            if (popout.shouldBeActive) {
                if (popout.warmable)
                    popout.warmed = true;
                popout.revealStage = 1;
            }
        }

        active: popout.warmed || popout.shouldBeActive || popout.opacity > 0
        visible: popout.shouldBeActive || popout.opacity > 0
        opacity: popout.revealStage
        transform: Translate {
            y: (1 - popout.revealStage) * popout.slideDirection * (popout.hangsFromBottom ? -12 : 12)
        }
        transformOrigin: popout.hangsFromBottom ? Item.BottomLeft : Item.TopLeft
        scale: 0.97 + 0.03 * popout.revealStage
    }
}
