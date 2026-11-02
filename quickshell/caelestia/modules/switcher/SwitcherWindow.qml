pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services

PanelWindow {
    id: root

    required property SwitcherState state
    property real progress: state.opened ? 1 : 0
    readonly property int cardWidth: 144
    readonly property int cardSpacing: 8

    visible: progress > 0 || state.opened
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "caelestia-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: state.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // The closing animation must not intercept clicks or keyboard input.
    mask: Region { item: root.state.opened ? surface : null }

    Behavior on progress {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: surface
        anchors.fill: parent
        focus: root.state.opened
        onVisibleChanged: {
            if (visible && root.state.opened)
                forceActiveFocus();
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.state.cancel();
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                root.state.cycle(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
            } else if (event.key === Qt.Key_Left) {
                root.state.cycle(-1);
            } else if (event.key === Qt.Key_Right) {
                root.state.cycle(1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.state.accept();
            }
            // Do not forward typing to the previously focused application.
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.key === Qt.Key_Alt && !event.isAutoRepeat)
                root.state.accept();
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.state.opened
            onClicked: root.state.cancel()
        }

        StyledRect {
            id: panel
            objectName: "windowSwitcherPanel"
            Accessible.role: Accessible.Dialog
            Accessible.name: qsTr("Window switcher")

            anchors.centerIn: parent
            width: Math.min(parent.width - 32, Math.max(320, Math.min(root.state.entries.length, 6) * (root.cardWidth + root.cardSpacing) + 40))
            height: 246
            radius: Tokens.rounding.extraLarge
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3outlineVariant, 0.65)
            opacity: root.progress
            scale: 0.96 + 0.04 * root.progress

            // Consume empty panel-space clicks rather than cancelling behind it.
            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Switch windows")
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: (root.state.selectedIndex + 1) + " / " + root.state.entries.length
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                    }
                }

                ListView {
                    id: list
                    objectName: "windowSwitcherList"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: root.cardSpacing
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.state.entries
                    currentIndex: root.state.selectedIndex
                    highlightMoveDuration: 120
                    highlightRangeMode: ListView.ApplyRange
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: width
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                    onCountChanged: Qt.callLater(() => list.positionViewAtIndex(list.currentIndex, ListView.Contain))

                    delegate: StyledRect {
                        id: entry
                        required property var modelData
                        required property int index
                        readonly property bool selected: root.state.selectedIndex === index
                        readonly property string appName: DesktopEntries.heuristicLookup(modelData.appId)?.name || modelData.appId || qsTr("Window")
                        Accessible.role: Accessible.ListItem
                        Accessible.name: appName + ": " + modelData.title

                        width: root.cardWidth
                        height: list.height
                        radius: Tokens.rounding.large
                        color: selected ? Colours.palette.m3secondaryContainer : "transparent"
                        border.width: selected ? 2 : 0
                        border.color: Colours.palette.m3primary

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            CachingIconImage {
                                Layout.alignment: Qt.AlignHCenter
                                implicitSize: 48
                                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(entry.modelData.appId)?.icon || "application-x-executable", "application-x-executable")
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: entry.appName
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                font: Tokens.font.body.small
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: entry.modelData.title
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.body.small
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.state.opened
                            onClicked: {
                                root.state.selectedIndex = entry.index;
                                root.state.accept();
                            }
                        }
                    }
                }

        
            }
        }
    }
}
