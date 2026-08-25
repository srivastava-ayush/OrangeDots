import QtQuick
import qs.components

Item {
    id: root

    required property ScreenState screenState
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel

    visible: height > 0
    anchors.topMargin: -5
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
    }
}
