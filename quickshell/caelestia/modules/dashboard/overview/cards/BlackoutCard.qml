import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: icon.implicitHeight + Tokens.padding.large
            radius: Tokens.rounding.full
            color: Blackout.enabled ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

            MaterialIcon {
                id: icon

                anchors.centerIn: parent
                text: "visibility_off"
                color: Blackout.enabled ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.large
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Blackout")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Blackout.enabled ? qsTr("Display off; lid sleep paused") : qsTr("Keep music and connections active")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        StyledSwitch {
            checked: Blackout.enabled
            onToggled: Blackout.enabled = checked
        }
    }
}
