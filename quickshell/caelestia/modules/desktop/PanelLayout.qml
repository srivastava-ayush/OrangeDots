import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.taskbar as Bar
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.ai as Ai
import qs.modules.notifications.banners as Notifications
import qs.modules.onscreendisplay as Osd
import qs.modules.sessionmenu as Session
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
    readonly property alias launcher: launcher
    readonly property alias ai: ai
    readonly property alias dashboard: dashboard
    readonly property alias mediaIsland: mediaIsland
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper

    anchors.fill: parent
    anchors.margins: borderThickness
    anchors.leftMargin: bar.horizontal ? borderThickness : bar.thickness
    anchors.topMargin: bar.horizontal ? bar.thickness : borderThickness

    Item {
        id: osdWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sessionWrapper.anchors.rightMargin + session.width * (1 - session.offsetScale)
        clip: session.visible

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.OsdWrapper {
            id: osd

            screen: root.screen
            screenState: root.screenState
            sidebarOrSessionVisible: session.visible

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

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        clip: false

        implicitWidth: session.implicitWidth * (1 - session.offsetScale)
        implicitHeight: session.implicitHeight

        Session.SessionMenuWrapper {
            id: session

            screenState: root.screenState
            sidebarVisible: false

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
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

    Ai.AiSidebarWrapper {
        id: ai
        screenState: root.screenState
        // Reserve the attached popout's destination rectangle, not its sliding
        // position, to keep the chat stable while crossing from icon to menu.
        topClearance: {
            const popout = popoutsWrapper.content;
            if (!popout.hasCurrent || popout.isDetached)
                return 0;
            const popoutWidth = Math.max(popout.width, popout.nonAnimWidth);
            const popoutHeight = Math.max(popout.height, popout.nonAnimHeight);
            const left = popoutsWrapper.x;
            const top = popoutsWrapper.y;
            const naturalTop = AiConfig.fullHeight ? 0 : root.height - Math.min(AiConfig.panelHeight, root.height);
            if (left + popoutWidth <= root.width - ai.implicitWidth || left >= root.width || top + popoutHeight <= naturalTop)
                return 0;
            return top + popoutHeight + root.Tokens.spacing.small;
        }
        anchors.right: parent.right
        anchors.bottom: parent.bottom
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
