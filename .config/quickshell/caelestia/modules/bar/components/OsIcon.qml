import QtQuick
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: Math.round(Tokens.font.body.large.pointSize * 1.2)
    implicitHeight: Math.round(Tokens.font.body.large.pointSize * 1.2)

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
        color: Colours.palette.m3tertiary
    }
}
