import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    readonly property real popupTop: y + content.anchors.topMargin + content.clampedPadding
    readonly property real popupRightMargin: content.clampedPadding
    readonly property real popupWidth: Math.max(1, content.implicitWidth - content.padding - content.clampedPadding)
    readonly property real popupHeight: Math.max(0, content.implicitHeight - content.padding - content.clampedPadding)

    visible: height > 0 && !screenState.notifShade
    anchors.topMargin: -5
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
    }
}
