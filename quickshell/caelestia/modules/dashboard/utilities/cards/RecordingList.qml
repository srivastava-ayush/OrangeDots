pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property var props
    required property ScreenState screenState
    property string deleteError

    function confirmDelete(path: string): void {
        if (root.props.recordingConfirmDelete !== path)
            return;
        if (CUtils.deleteFile(Qt.resolvedUrl(path))) {
            root.props.recordingConfirmDelete = "";
            root.deleteError = "";
        } else {
            root.deleteError = qsTr("Couldn't delete the recording. Check file permissions and try again.");
        }
    }

    spacing: 0

    WrapperMouseArea {
        Layout.fillWidth: true

        cursorShape: Qt.PointingHandCursor
        onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded

        RowLayout {
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                text: "history"
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: qsTr("Recent recordings")
                font: Tokens.font.label.medium
                color: Colours.palette.m3onSurfaceVariant
            }

            IconButton {
                icon: root.props.recordingListExpanded ? "expand_less" : "expand_more"
                type: IconButton.Text
                label.animate: true
                onClicked: root.props.recordingListExpanded = !root.props.recordingListExpanded
            }
        }
    }

    StyledListView {
        id: list

        model: FileSystemModel {
            path: Paths.recsdir
            nameFilters: ["recording_*.mp4"]
            sortReverse: true
        }

        Layout.fillWidth: true
        Layout.rightMargin: -Tokens.spacing.small
        implicitHeight: count === 0 ? 32 : 36 * Math.min(count, root.props.recordingListExpanded ? 8 : 2)
        clip: true

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: list
        }

        delegate: RowLayout {
            id: recording

            required property FileSystemEntry modelData
            property string baseName
            readonly property bool confirmingDelete: modelData !== null && root.props.recordingConfirmDelete === modelData.path

            anchors.left: list.contentItem.left
            anchors.right: list.contentItem.right
            anchors.rightMargin: Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall

            Component.onCompleted: baseName = modelData.baseName

            StyledText {
                Layout.fillWidth: true
                Layout.rightMargin: Tokens.spacing.extraSmall
                text: {
                    if (recording.confirmingDelete)
                        return qsTr("Delete this recording?");
                    const time = recording.baseName;
                    const matches = time.match(/^recording_(\d{4})(\d{2})(\d{2})_(\d{2})-(\d{2})-(\d{2})/);
                    if (!matches)
                        return time;
                    const date = new Date(...matches.slice(1));
                    date.setMonth(date.getMonth() - 1); // Woe (months start from 0)
                    return Qt.formatDateTime(date, "MMM d · HH:mm");
                }
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            IconButton {
                visible: !recording.confirmingDelete
                icon: "play_arrow"
                type: IconButton.Text
                onClicked: {
                    Quickshell.execDetached([...GlobalConfig.general.apps.playback, recording.modelData.path]);
                }
            }

            IconButton {
                visible: !recording.confirmingDelete
                icon: "folder"
                type: IconButton.Text
                onClicked: {
                    Quickshell.execDetached([...GlobalConfig.general.apps.explorer, recording.modelData.path]);
                }
            }

            IconButton {
                objectName: "recordingDelete"
                icon: recording.confirmingDelete ? "check" : "delete_forever"
                type: IconButton.Text
                label.color: Colours.palette.m3error
                stateLayer.color: Colours.palette.m3error
                onClicked: {
                    if (recording.confirmingDelete)
                        root.confirmDelete(recording.modelData.path);
                    else {
                        root.deleteError = "";
                        root.props.recordingConfirmDelete = recording.modelData.path;
                    }
                }
            }

            IconButton {
                objectName: "recordingDeleteCancel"
                visible: recording.confirmingDelete
                icon: "close"
                type: IconButton.Text
                onClicked: {
                    root.props.recordingConfirmDelete = "";
                    root.deleteError = "";
                }
            }
        }

        add: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 0
            }
        }

        displaced: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 1
            }
            Anim {
                property: "y"
            }
        }

        Loader {
            asynchronous: true
            anchors.centerIn: parent

            opacity: list.count === 0 ? 1 : 0
            active: opacity > 0

            sourceComponent: ColumnLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "scan_delete"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge

                    opacity: root.props.recordingListExpanded ? 1 : 0
                    scale: root.props.recordingListExpanded ? 1 : 0
                    Layout.preferredHeight: root.props.recordingListExpanded ? implicitHeight : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }

                    Behavior on scale {
                        Anim {}
                    }

                    Behavior on Layout.preferredHeight {
                        Anim {}
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "scan_delete"
                        color: Colours.palette.m3outline

                        opacity: !root.props.recordingListExpanded ? 1 : 0
                        scale: !root.props.recordingListExpanded ? 1 : 0
                        Layout.preferredWidth: !root.props.recordingListExpanded ? implicitWidth : 0

                        Behavior on opacity {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }

                        Behavior on scale {
                            Anim {}
                        }

                        Behavior on Layout.preferredWidth {
                            Anim {}
                        }
                    }

                    StyledText {
                        text: qsTr("No recordings found")
                        color: Colours.palette.m3outline
                    }
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }

    StyledText {
        objectName: "recordingDeleteError"
        Layout.fillWidth: true
        visible: root.deleteError.length > 0
        text: root.deleteError
        color: Colours.palette.m3error
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
    }
}
