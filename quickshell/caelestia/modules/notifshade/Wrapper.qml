pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Slides in from above, or grows from a visible notification popup.
// PanelBg follows the animated bounds through offsetScale.
Item {
    id: root

    required property ScreenState screenState
    required property var popupPanel

    readonly property bool shouldBeActive: Config.notifs.shadeEnabled && screenState.notifShade
    property bool morphFromPopup
    property real popupTop
    property real popupRightMargin
    property real popupWidth
    property real popupHeight
    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (!shouldBeActive) {
            morphFromPopup = false;
            return;
        }

        const popups = Notifs.popups.filter(n => !n.closed);
        morphFromPopup = popups.length > 0 && popupPanel.popupHeight > 0;
        if (morphFromPopup) {
            popupTop = popupPanel.popupTop;
            popupRightMargin = popupPanel.popupRightMargin;
            popupWidth = popupPanel.popupWidth;
            popupHeight = popupPanel.popupHeight;
            for (const notif of popups)
                notif.popup = false;
        }
    }

    visible: shouldBeActive || offsetScale < 1
    clip: morphFromPopup
    anchors.topMargin: morphFromPopup ? popupTop * offsetScale : (-implicitHeight - 5) * offsetScale
    anchors.rightMargin: morphFromPopup ? popupRightMargin * offsetScale : 0
    implicitWidth: morphFromPopup ? popupWidth * offsetScale + content.implicitWidth * (1 - offsetScale) : content.implicitWidth
    implicitHeight: morphFromPopup ? popupHeight * offsetScale + content.implicitHeight * (1 - offsetScale) : content.implicitHeight
    opacity: morphFromPopup ? 1 : 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.fill: parent

        active: root.shouldBeActive || root.visible

        sourceComponent: Shade {
            screenState: root.screenState
        }
    }
}
