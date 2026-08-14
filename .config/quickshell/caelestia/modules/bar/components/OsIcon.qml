import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.2) + Tokens.padding.medium
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.2) + Tokens.padding.medium

    color: "transparent"
    radius: Tokens.rounding.full
    border.color: Qt.hsla(Colours.palette.m3primary.hslHue, 0.05, Colours.palette.m3primary.hslLightness * 0.6, 1)
    border.width: 2

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const screenState = ShellState.forActive();
            screenState.launcher = !screenState.launcher;
        }
    }

    Text {
        anchors.centerIn: parent
        text: "y"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Tokens.font.body.large.pointSize
        font.bold: true
        color: Colours.palette.m3primary
    }
}
