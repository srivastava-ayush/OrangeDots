pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root
    required property ScreenState screenState
    readonly property alias chatState: chatBackend
    readonly property bool shouldBeActive: screenState.ai && AiConfig.enabled
    property real topClearance: 0
    property real offsetScale: shouldBeActive ? 0 : 1
    implicitWidth: Math.min(AiConfig.panelWidth, parent ? parent.width : AiConfig.panelWidth)
    implicitHeight: Math.min(AiConfig.fullHeight && parent ? parent.height : AiConfig.panelHeight, parent ? Math.max(0, parent.height - topClearance) : AiConfig.panelHeight)
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    visible: offsetScale < 1
    opacity: 1 - offsetScale
    clip: true

    Connections {
        target: AiConfig
        function onEnabledChanged(): void { if (!AiConfig.enabled) root.screenState.ai = false; }
    }

    Behavior on offsetScale {
        Anim { type: Anim.FastSpatial; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        Anim { type: Anim.FastSpatial; easing.type: Easing.OutCubic }
    }

    AiChatState {
        id: chatBackend
        screenName: root.screenState.modelData.name
        active: root.shouldBeActive
        onMemoryCleared: root.screenState.ai = false
    }

    Loader {
        anchors.fill: parent
        active: root.visible || root.screenState.ai
        sourceComponent: AiSidebarContent {
            chat: chatBackend
            onCloseRequested: root.screenState.ai = false
        }
    }
}
