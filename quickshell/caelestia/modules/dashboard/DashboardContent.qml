pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog

Item {
    id: root

    objectName: "dashboardContent"

    required property ScreenState screenState
    required property FileDialog facePicker
    required property FileDialog phoneFilePicker

    readonly property var dashboardTabs: {
        const allTabs = [
           
            {
                component: mediaComponent,
                iconName: "queue_music",
                text: qsTr("Media"),
                enabled: Config.dashboard.showMedia
            },
             {
                component: dashComponent,
                iconName: "dashboard",
                text: qsTr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                component: performanceComponent,
                iconName: "speed",
                text: qsTr("Performance"),
                enabled: Config.dashboard.showPerformance
            },
            {
                component: phoneComponent,
                iconName: "smartphone",
                text: qsTr("Phone"),
                enabled: true
            }
        ];
        return allTabs.filter(tab => tab.enabled);
    }

    function clampSelectedTab(): void {
        if (screenState)
            screenState.dashboardTab = Math.max(0, Math.min(screenState.dashboardTab, dashboardTabs.length - 1));
    }
    onDashboardTabsChanged: clampSelectedTab()
    Component.onCompleted: clampSelectedTab()

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2
    property real performanceHeight: Tokens.sizes.dashboard.mediaTabHeight

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    DashboardTabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: CUtils.clamp(anchors.margins - Config.border.thickness, 0, anchors.margins)
        anchors.margins: Tokens.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        screenState: root.screenState
        tabs: root.dashboardTabs
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.large
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.screenState.dashboardTab
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            // Never drag past the first/last module: there is no content there.
            boundsBehavior: Flickable.StopAtBounds

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            // Remember how far the pointer actually dragged. movementEnded can
            // fire (and reset contentX) before dragEnded, so reading contentX
            // there would always look like a zero-distance drag.
            property real dragStartX: 0
            property real dragDelta: 0
            property bool dragSettling: false

            // Flickable writes contentX itself while dragging, which severs the
            // declarative binding above. Restore it once the gesture is over so
            // tab presses and IPC switches keep sliding to the selected module.
            function syncToCurrent(): void {
                contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            onDragStarted: {
                dragStartX = contentX;
                dragDelta = 0;
                dragSettling = true;
            }

            onContentXChanged: {
                if (dragging)
                    dragDelta = contentX - dragStartX;
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const dx = dragDelta;
                // A short-but-fast fling should also move one module over.
                const threshold = Math.min(currentItem.implicitWidth / 10, 80);
                const flung = Math.abs(horizontalVelocity) > 400;

                if (dx > threshold || (flung && horizontalVelocity > 0))
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (dx < -threshold || (flung && horizontalVelocity < 0))
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);

                // Snap to the selected module instead of continuing Flickable's
                // physics; the Behavior below eases the rest of the distance.
                dragSettling = false;
                cancelFlick();
                syncToCurrent();
            }

            // Recover the binding after wheel scrolling or an uncancelled flick,
            // where no dragEnded is delivered. While a drag is settling, let
            // dragEnded decide first so movementEnded can't reset the offset.
            onMovementEnded: {
                if (!dragSettling)
                    syncToCurrent();
            }

            // One module per gesture: drop any momentum and ease into the chosen
            // module instead of gliding past several of them.
            onFlickStarted: cancelFlick()

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    delegate: Loader {
                        id: paneLoader

                        required property var modelData

                        Layout.alignment: Qt.AlignTop

                        sourceComponent: modelData.component

                        // Keep every module instantiated while the dashboard is
                        // open. Inactive loaders collapse to zero width, which
                        // shifts neighbouring modules mid-slide and makes jumps
                        // between distant tabs look like a teleport.
                        active: true
                    }
                }
            }

            Component {
                id: dashComponent

                Overview {
                    screenState: root.screenState
                    facePicker: root.facePicker
                    preferredHeight: root.performanceHeight
                }
            }

            Component {
                id: mediaComponent

                Media {
                    screenState: root.screenState
                }
            }

            Component {
                id: performanceComponent

                Performance {
                    Component.onCompleted: root.performanceHeight = implicitHeight
                    onImplicitHeightChanged: root.performanceHeight = implicitHeight
                }
            }

            Component {
                id: phoneComponent

                Phone {
                    filePicker: root.phoneFilePicker
                }
            }

            Behavior on contentX {
                // Track the pointer 1:1 while dragging/flicking, then ease the
                // snap to the selected module. No spatial overshoot here: a
                // bounce past the edge would expose the blank strip outside the
                // first/last module.
                enabled: !view.dragging && !view.flicking
                Anim {
                    type: Anim.Emphasized
                }
            }
        }
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.Emphasized
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.Emphasized
        }
    }
}
