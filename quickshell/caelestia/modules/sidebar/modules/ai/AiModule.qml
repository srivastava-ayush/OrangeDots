pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

Item {
    id: root
    required property ScreenState screenState
    required property bool selected
    signal closeRequested
    readonly property alias chatState: chatBackend

    AiChatState {
        id: chatBackend
        screenName: root.screenState.modelData.name
        // A quick hover reversal can reuse the adapter during the fade instead
        // of killing/restarting it. Hidden idle adapters still stop afterward.
        active: root.selected || root.visible
        onMemoryCleared: root.closeRequested()
    }

    Loader {
        objectName: "sidebarAiChatView"
        anchors.fill: parent
        // Only the lightweight backend survives while hidden. Keep the visual
        // tree just long enough to finish the outgoing crossfade/slide.
        active: root.selected || root.visible
        sourceComponent: AiChatContent {
            chat: chatBackend
            onCloseRequested: root.closeRequested()
        }
    }
}
