import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property Item popoutPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel

    readonly property Item popoutContent: popoutPanel ? popoutPanel.content : null
    readonly property bool popoutOpen: !!popoutContent && popoutContent.hasCurrent && !popoutContent.isDetached

    // Taskbar popouts (wifi, bluetooth, battery, ...) share the top-right
    // corner with the banner column. Push the whole banner - background
    // included - below the open popout instead of letting the toast hide
    // behind the menu.
    readonly property real popoutInset: {
        if (!popoutOpen || !root.parent || popoutPanel.horizontal === false)
            return 0;

        // Both items are siblings in the panel layout, so their local geometry
        // can be compared directly. Reading each property also keeps the
        // binding live while the popout slides or switches between icons.
        const popoutLeft = popoutPanel.x + popoutContent.x;
        const popoutRight = popoutLeft + popoutContent.width;
        const popoutBottom = popoutPanel.y + popoutContent.y + popoutContent.height;

        if (popoutRight <= root.x || popoutLeft >= root.x + root.width)
            return 0;

        return Math.max(0, popoutBottom + Tokens.spacing.medium);
    }

    // Keep the usual 5px tuck under the bar, but never tuck behind a popout.
    property real topMargin: popoutInset > 0 ? popoutInset : -5

    visible: height > 0 && !screenState.notifShade
    anchors.topMargin: topMargin
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    BannerList {
        id: content

        // Keep toast content below the popout; DesktopWindow bridges only the
        // shared shell background upward, without moving the toast's controls.
        anchors.topMargin: root.popoutInset > 0 ? 0 : -root.anchors.topMargin
        screenState: root.screenState
        topInset: root.popoutInset
    }
}
