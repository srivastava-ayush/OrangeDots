pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState

    function selectDefaultTab(preferMedia: bool): void {
        // Match DashboardContent's enabled-filtered order, not fixed indices.
        if (preferMedia && Config.dashboard.showMedia)
            screenState.dashboardTab = 0;
        else if (Config.dashboard.showDashboard)
            screenState.dashboardTab = Config.dashboard.showMedia ? 1 : 0;
        else
            screenState.dashboardTab = 0;
    }

    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }
    readonly property FileDialog phoneFilePicker: FileDialog {
        title: qsTr("Send a file to your phone")
        onAccepted: path => KdeConnect.action(["--share", path])
    }

    readonly property real nonAnimHeight: ((content.item as DashboardContent)?.nonAnimHeight ?? 0) * dashboardScale
    readonly property bool notesActive: (content.item as DashboardContent)?.notesActive ?? false
    readonly property bool shouldBeActive: screenState.dashboard && Config.dashboard.enabled
    // A top taskbar can inset the dashboard below the screen edge. Include that
    // gap in the slide-out distance so no background remains inside the screen.
    property real hideInset: 0
    property real offsetScale: shouldBeActive ? 0 : 1
    // Reveal a full-sized dashboard through a centered curtain instead of
    // squeezing its cards/text as the hover surface expands from the top.
    readonly property real naturalWidth: content.implicitWidth || 854
    readonly property real naturalHeight: content.implicitHeight
    readonly property real dashboardScale: Math.min(
        Math.max(0.6, Math.min(1.4, (Config.dashboard.scale ?? 100) / 100)),
        parent && parent.width > 0 ? parent.width / naturalWidth : 1.4,
        parent && parent.height > 0 && naturalHeight > 0 ? parent.height / naturalHeight : 1.4)
    readonly property real fullWidth: naturalWidth * dashboardScale
    // Keep the edge target generous even while the curtain is collapsed.
    readonly property real hoverWidth: Math.min(parent ? parent.width : fullWidth + 200, fullWidth + 200)
    readonly property real curtainProgress: Math.max(0, Math.min(1, 1 - offsetScale))
    readonly property real curtainWidthScale: Config.dashboard.showOnHover ? 0.48 + 0.52 * curtainProgress : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - hideInset - 5) * offsetScale
    implicitHeight: naturalHeight * dashboardScale
    implicitWidth: fullWidth * curtainWidthScale
    opacity: 1 - offsetScale
    clip: Config.dashboard.showOnHover

    Behavior on offsetScale {
        Anim {
            // A monotonic curve keeps the reveal from overshooting its clip.
            type: Anim.FastSpatial
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        transformOrigin: Item.Top
        scale: root.dashboardScale

        active: root.shouldBeActive || root.visible

        sourceComponent: DashboardContent {
            screenState: root.screenState
            facePicker: root.facePicker
            phoneFilePicker: root.phoneFilePicker
        }
    }
}
