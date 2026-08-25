pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

// Slides the shade in/out from above the top edge, mirroring the dashboard
// wrapper's offsetScale animation so PanelBg blob deformation tracks it.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.notifShade
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    opacity: 1 - offsetScale

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
