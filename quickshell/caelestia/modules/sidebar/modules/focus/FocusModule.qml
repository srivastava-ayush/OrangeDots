pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.modules.settings.common
import qs.services
import qs.modules.sidebar as Sidebar

FocusScope {
    id: root
    required property ScreenState screenState
    required property bool selected
    focus: selected
    signal closeRequested
    readonly property color accent: FocusTimer.phase === "focus" ? Colours.palette.m3primary : Colours.palette.m3tertiary
    Keys.onEscapePressed: root.closeRequested()

    StyledFlickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight + SidebarStyle.padding * 2
        clip: true

        ColumnLayout {
            id: body
            x: SidebarStyle.padding
            y: SidebarStyle.padding
            width: parent.width - SidebarStyle.padding * 2
            spacing: SidebarStyle.gap

            Sidebar.SidebarHeader {
                moduleId: "focus"
                IconButton { icon: "close"; type: IconButton.Text; onClicked: root.closeRequested() }
            }
            StyledTextField {
                Layout.fillWidth: true
                placeholderText: qsTr("What are you working on?")
                text: FocusTimer.task
                verticalPadding: SidebarStyle.cardPadding
                onTextEdited: FocusTimer.task = text
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: SidebarStyle.smallGap
                TextButton {
                    text: qsTr("Focus")
                    type: FocusTimer.phase === "focus" ? TextButton.Tonal : TextButton.Text
                    onClicked: FocusTimer.setPhase("focus")
                }
                TextButton {
                    text: qsTr("Break")
                    type: FocusTimer.phase === "break" ? TextButton.Tonal : TextButton.Text
                    onClicked: FocusTimer.setPhase("break")
                }
                TextButton {
                    text: qsTr("Long break")
                    type: FocusTimer.phase === "longBreak" ? TextButton.Tonal : TextButton.Text
                    onClicked: FocusTimer.setPhase("longBreak")
                }
            }
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: SidebarStyle.smallGap
                Layout.bottomMargin: SidebarStyle.smallGap
                implicitWidth: Math.min(body.width, 220)
                implicitHeight: implicitWidth
                radius: width / 2
                color: Qt.alpha(root.accent, 0.08)
                border.width: 1
                border.color: Qt.alpha(root.accent, 0.25)
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: SidebarStyle.smallGap
                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: FocusTimer.phase === "focus" ? "timer" : "coffee"
                        color: root.accent
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: FocusTimer.timeText
                        font: Tokens.font.headline.builders.large.scale(1.3).build()
                        color: root.accent
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: FocusTimer.running ? FocusTimer.phaseName : FocusTimer.engaged ? qsTr("Paused") : qsTr("Ready when you are")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.medium
                    }
                }
            }
            StyledProgressBar {
                Layout.fillWidth: true
                implicitHeight: 6
                value: FocusTimer.progress
                fgColour: root.accent
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                IconButton { icon: "restart_alt"; type: IconButton.Text; onClicked: FocusTimer.reset() }
                TextButton {
                    text: FocusTimer.running ? qsTr("Pause") : FocusTimer.engaged ? qsTr("Resume") : qsTr("Start")
                    type: TextButton.Filled
                    onClicked: FocusTimer.running ? FocusTimer.pause() : FocusTimer.start()
                }
                IconButton { icon: "skip_next"; type: IconButton.Text; onClicked: FocusTimer.advance(false) }
            }
            StyledText {
                Layout.fillWidth: true
                text: qsTr("%1 completed · Long break every 4 focus sessions").arg(FocusTimer.completed)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
            SectionHeader { text: qsTr("Your rhythm") }
            StepperRow {
                first: true
                enabled: !FocusTimer.running
                label: qsTr("Focus minutes")
                value: FocusTimer.workMinutes
                from: 1; to: 120; stepSize: 1
                onMoved: value => FocusTimer.workMinutes = value
            }
            StepperRow {
                label: qsTr("Break minutes")
                enabled: !FocusTimer.running
                value: FocusTimer.breakMinutes
                from: 1; to: 60; stepSize: 1
                onMoved: value => FocusTimer.breakMinutes = value
            }
            StepperRow {
                last: true
                enabled: !FocusTimer.running
                label: qsTr("Long break minutes")
                value: FocusTimer.longBreakMinutes
                from: 1; to: 90; stepSize: 1
                onMoved: value => FocusTimer.longBreakMinutes = value
            }
            ToggleRow {
                first: true
                text: qsTr("Focus DND")
                subtext: qsTr("Quiet notifications while focusing · restores DND when paused or finished")
                checked: FocusTimer.useDnd
                onToggled: FocusTimer.useDnd = checked
            }
            ToggleRow {
                text: qsTr("Auto-start next interval")
                subtext: qsTr("Otherwise the next work/break interval waits for you")
                checked: FocusTimer.autoStart
                onToggled: FocusTimer.autoStart = checked
            }
            ToggleRow {
                last: true
                text: qsTr("Taskbar countdown")
                subtext: qsTr("Show remaining time before the system tray while a session is active")
                checked: FocusTimer.showTaskbar
                onToggled: FocusTimer.showTaskbar = checked
            }
        }
    }
}
