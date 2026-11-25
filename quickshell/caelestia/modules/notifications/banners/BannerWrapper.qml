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
    readonly property bool shadePresent: !!popoutContent && !popoutContent.isDetached && popoutContent.currentName === "notifications"

    // The taskbar shade opens in the same top-right slot as the banner column.
    // Hiding the toast the instant `notifShade` flips made the hand-off a hard
    // cut. Follow the shade's own reveal spring instead and cross-fade the
    // toast out over it, so the two surfaces exchange places smoothly and a
    // reversal mid-flight simply runs the same value backwards.
    readonly property real shadeProgress: shadePresent && popoutContent
        ? Math.max(0, Math.min(1, 1 - popoutContent.offsetScale))
        : 0
    readonly property real toastFade: shadeProgress <= 0.6 ? 1 : Math.max(0, 1 - (shadeProgress - 0.6) / 0.35)
    readonly property real surfaceOpacity: toastFade

    // The shade is a later sibling in the panel layout and owns an opaque
    // surface, so at rest it must draw over the banners. While the two are
    // exchanging places, keep the toast on top so it can be seen fading out
    // instead of being cut off by the incoming menu. Drop back behind the shade
    // once the fade has finished, and never float over a different popout that
    // was opened while the toast returned.
    z: screenState.notifShade || (shadePresent && shadeProgress > 0 && shadeProgress < 1) ? 1 : 0

    // Taskbar popouts (wifi, bluetooth, battery, ...) share the top-right
    // corner with the banner column. Push the whole banner - background
    // included - below the open popout instead of letting the toast hide
    // behind the menu.
    readonly property real popoutInset: {
        // The notification shade is itself a popout; it must not shove the
        // banners down while they are dissolving into it. Keep ignoring it on
        // the way back out, even after `notifShade` clears but before the
        // popout has switched away, so the toast never jumps mid-reversal.
        if (!popoutOpen || screenState.notifShade || shadePresent || !root.parent || popoutPanel.horizontal === false)
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

    visible: height > 0 && surfaceOpacity > 0
    opacity: surfaceOpacity
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
