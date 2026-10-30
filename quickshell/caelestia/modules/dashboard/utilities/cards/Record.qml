pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property var props
    required property ScreenState screenState
    property var recorder: Recorder
    readonly property real nonAnimHeight: layout.implicitHeight + Tokens.padding.large * 2
    readonly property string elapsedText: {
        const elapsed = Math.max(0, Math.floor(recorder.elapsed));
        const hours = Math.floor(elapsed / 3600);
        const minutes = Math.floor((elapsed % 3600) / 60);
        const seconds = (elapsed % 60).toString().padStart(2, "0");
        return hours > 0 ? `${hours}:${minutes.toString().padStart(2, "0")}:${seconds}` : `${minutes.toString().padStart(2, "0")}:${seconds}`;
    }

    implicitHeight: Math.max(232, nonAnimHeight)
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Screen recorder")
                font: Tokens.font.title.small
                elide: Text.ElideRight
            }

            StyledRect {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: root.recorder.paused ? Colours.palette.m3tertiary : root.recorder.running ? Colours.palette.m3error : Colours.palette.m3outline
            }

            StyledText {
                objectName: "recorderCardStatus"
                text: root.recorder.paused ? qsTr("Paused") : root.recorder.running ? qsTr("Recording") : qsTr("Ready")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }

        SplitButton {
            id: capture
            objectName: "recorderCardCapture"
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            visible: !root.recorder.running
            minLeftWidth: Math.max(0, layout.width - expandBtn.implicitWidth - spacing)
            label.Layout.maximumWidth: Math.max(0, minLeftWidth - iconLabel.implicitWidth - textRow.spacing - horizontalPadding * 2)
            label.elide: Text.ElideRight
            menuOnTop: true
            active: menuItems.find(m => root.props.recordingMode === m.icon + m.text) ?? menuItems[0]
            menu.onItemSelected: item => root.props.recordingMode = item.icon + item.text

            menuItems: [
                MenuItem {
                    icon: "fullscreen"
                    text: qsTr("Record fullscreen")
                    activeText: qsTr("Record screen")
                    onClicked: root.recorder.start()
                },
                MenuItem {
                    icon: "screenshot_region"
                    text: qsTr("Record region")
                    activeText: qsTr("Record region")
                    onClicked: root.recorder.start(["-r"])
                },
                MenuItem {
                    icon: "select_to_speak"
                    text: qsTr("Record fullscreen with sound")
                    activeText: qsTr("Screen + audio")
                    onClicked: root.recorder.start(["-s"])
                },
                MenuItem {
                    icon: "volume_up"
                    text: qsTr("Record region with sound")
                    activeText: qsTr("Region + audio")
                    onClicked: root.recorder.start(["-sr"])
                }
            ]
        }

        RowLayout {
            objectName: "recorderCardLiveControls"
            Layout.fillWidth: true
            visible: root.recorder.running
            spacing: Tokens.spacing.small

            StyledText {
                objectName: "recorderCardTimer"
                Layout.fillWidth: true
                text: root.elapsedText
                font: Tokens.font.headline.medium
                elide: Text.ElideRight
            }

            IconButton {
                objectName: "recorderCardPause"
                icon: root.recorder.paused ? "play_arrow" : "pause"
                type: IconButton.Tonal
                onClicked: root.recorder.togglePause()
            }

            IconButton {
                objectName: "recorderCardStop"
                icon: "stop"
                type: IconButton.Filled
                inactiveColour: Colours.palette.m3error
                inactiveOnColour: Colours.palette.m3onError
                onClicked: root.recorder.stop()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
        }

        Loader {
            objectName: "recorderCardHistory"
            Layout.fillWidth: true
            asynchronous: true
            active: !root.recorder.running
            visible: active
            sourceComponent: RecordingList {
                props: root.props
                screenState: root.screenState
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.recorder.running
            text: root.recorder.paused ? qsTr("Resume when you're ready") : qsTr("Recording in progress")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }
    }
}
