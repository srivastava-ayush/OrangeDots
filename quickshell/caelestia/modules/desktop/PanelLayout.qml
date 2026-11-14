import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.taskbar as Bar
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.sidebar as Sidebar
import qs.modules.notifications.banners as Notifications
import qs.modules.onscreendisplay as Osd
import qs.modules.sessionmenu as Session
import qs.modules.emoji as Emoji
import qs.modules.taskbar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property Bar.TaskbarWrapper bar
    required property real borderThickness
    property bool fullscreen

    readonly property alias osd: osd
    readonly property alias osdWrapper: osdWrapper
    readonly property alias notifications: notifications
    readonly property alias session: session
    readonly property alias sessionWrapper: sessionWrapper
    readonly property alias emojiPicker: emojiPicker
    readonly property alias launcher: launcher
    readonly property alias ai: ai
    readonly property alias sidebar: ai
    readonly property alias leftSidebar: leftSidebar
    readonly property alias rightSidebar: ai
    readonly property alias dashboard: dashboard
    readonly property alias mediaIsland: mediaIsland
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    // Long-axis position of this screen's status icons; the detached Nexus
    // overlay grows out of it and collapses back into it.
    readonly property real statusIconCenter: bar.centerForStatusIcons()

    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.leftMargin: bar.horizontal ? borderThickness : bar.thickness
    anchors.topMargin: bar.horizontal ? bar.thickness : borderThickness

    Item {
        id: osdWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 0
        clip: false

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.OsdWrapper {
            id: osd

            screen: root.screen
            screenState: root.screenState
            sidebarOrSessionVisible: false

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Notifications.BannerWrapper {
        id: notifications

        screenState: root.screenState
        osdPanel: osdWrapper
        sessionPanel: sessionWrapper
        popoutPanel: popoutsWrapper

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Item {
        id: sessionWrapper

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        clip: false
        visible: session.offsetScale < 1

        implicitWidth: session.implicitWidth
        implicitHeight: session.implicitHeight

        Session.SessionMenuWrapper {
            id: session

            screenState: root.screenState
            availableWidth: root.width
            sidebarVisible: false

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Launcher.LauncherWrapper {
        id: launcher

        screen: root.screen
        screenState: root.screenState
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Sidebar.SidebarWrapper {
        id: leftSidebar
        side: "left"
        screenState: root.screenState
        hideInset: root.x
        topClearance: {
            const popout = popoutsWrapper.content;
            if (!popout.hasCurrent || popout.isDetached) return 0;
            const left = popoutsWrapper.x;
            const width = Math.max(popout.width, popout.nonAnimWidth);
            if (left + width <= 0 || left >= leftSidebar.implicitWidth) return 0;
            return popoutsWrapper.y + Math.max(popout.height, popout.nonAnimHeight) + root.Tokens.spacing.small;
        }
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: topClearance
    }

    Sidebar.SidebarWrapper {
        id: ai
        screenState: root.screenState
        // Reserve the attached popout's destination rectangle, not its sliding
        // position, to keep the chat stable while crossing from icon to menu.
        topClearance: {
            // Banner height already animates. Follow its live bottom edge so
            // the sidebar yields and recovers space in the same motion.
            const toastBottom = notifications.visible
                ? Math.max(0, notifications.y + notifications.height + root.Tokens.spacing.small)
                : 0;
            const popout = popoutsWrapper.content;
            if (!popout.hasCurrent || popout.isDetached)
                return toastBottom;
            const popoutWidth = Math.max(popout.width, popout.nonAnimWidth);
            const popoutHeight = Math.max(popout.height, popout.nonAnimHeight);
            const left = popoutsWrapper.x;
            const top = popoutsWrapper.y;
            const naturalTop = 0;
            if (left + popoutWidth <= root.width - ai.implicitWidth || left >= root.width || top + popoutHeight <= naturalTop)
                return toastBottom;
            return Math.max(toastBottom, top + popoutHeight + root.Tokens.spacing.small);
        }
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: topClearance
    }

    Dashboard.DashboardWrapper {
        id: dashboard

        screenState: root.screenState
        hideInset: root.bar.notched ? root.y : 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
    }

    MediaIsland {
        id: mediaIsland
        fullscreen: root.fullscreen
        dashboardOpen: root.screenState.dashboard
        activeScreen: ShellState.forActive() === root.screenState
        hideInset: root.bar.notched ? root.y : 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        // Share the island state with the taskbar so a top bar can animate its
        // clock out of the way. ScreenState is per-screen, so another monitor's
        // island never hides this screen's clock.
        onExpandedChanged: root.screenState.mediaIslandExpanded = expanded
        Component.onCompleted: root.screenState.mediaIslandExpanded = expanded
        Component.onDestruction: root.screenState.mediaIslandExpanded = false
    }

    // Sits above the drawers but below the detached popout overlay.
    Emoji.EmojiPicker {
        id: emojiPicker

        screenState: root.screenState
        anchors.centerIn: parent
    }

    BarPopouts.PopoutAnchor {
        id: popoutsWrapper

        screen: root.screen
        screenState: root.screenState
        borderThickness: root.borderThickness
        horizontal: root.bar.horizontal
        hideInset: root.bar.notched ? (horizontal ? root.y : root.x) : 0
    }
}
