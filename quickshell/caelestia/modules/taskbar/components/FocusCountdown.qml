import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root
    readonly property color accent: FocusTimer.phase === "focus" ? Colours.palette.m3primary : Colours.palette.m3tertiary

    implicitWidth: Taskbar.horizontal ? content.implicitWidth + 16 : Tokens.sizes.bar.innerWidth
    implicitHeight: content.implicitHeight + 12
    radius: Tokens.rounding.full
    color: Qt.alpha(accent, 0.1)
    opacity: FocusTimer.running ? 1 : 0.6

    GridLayout {
        id: content
        anchors.centerIn: parent
        columns: Taskbar.horizontal ? 2 : 1
        columnSpacing: 6
        rowSpacing: 4

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: FocusTimer.running ? (FocusTimer.phase === "focus" ? "timer" : "coffee") : "pause"
            color: root.accent
            fontStyle: Tokens.font.icon.small
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: FocusTimer.timeText
            font: Tokens.font.label.small
            color: root.accent
        }
    }
}
