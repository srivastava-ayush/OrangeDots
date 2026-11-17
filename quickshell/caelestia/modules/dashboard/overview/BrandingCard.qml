pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

StyledRect {
    id: root

    objectName: "overviewBranding"

    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer
    border.width: 1
    border.color: Qt.alpha(Colours.palette.m3primary, 0.16)

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: 0

        StyledText {
            objectName: "overviewBrandName"
            Layout.alignment: Qt.AlignHCenter
            text: Branding.name
            font: Tokens.font.title.medium
            color: Colours.palette.m3onSurface
        }

        StyledText {
            objectName: "overviewBrandVersion"
            Layout.alignment: Qt.AlignHCenter
            text: Branding.version
            font: Tokens.font.label.small
            color: Colours.palette.m3primary
        }
    }
}
