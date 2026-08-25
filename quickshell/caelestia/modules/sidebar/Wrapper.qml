pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components

// Slides the utility sidebar in/out from below the bottom edge, mirroring the
// notification shade wrapper's offsetScale animation so PanelBg blob
// deformation tracks it.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.utilitySidebar
    // True while the notes field holds keyboard focus, so the sidebar must
    // not auto-close mid-typing
    readonly property bool notesActive: (content.item as Sidebar)?.notesActive ?? false
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.fill: parent

        // Stays loaded once opened so notes typed in the sidebar survive
        // open/close cycles (PersistentProperties covers shell reloads)
        active: root.shouldBeActive || root.visible || item

        sourceComponent: Sidebar {}
    }
}
