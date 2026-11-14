pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.taskbar as Bar

Region {
    id: root

    required property Bar.TaskbarWrapper bar
    required property PanelLayout panels
    required property var win

    readonly property real borderThickness: win.contentItem.Config.border.thickness
    readonly property real clampedThickness: win.contentItem.Config.border.clampedThickness

    x: bar.clampedWidth + win.dragMaskPadding
    y: bar.clampedHeight + win.dragMaskPadding
    // The XOR mask normally passes the desktop through. While the session
    // menu or emoji picker is visible, capture empty desktop clicks as modal
    // dismissals too.
    width: panels.session.visible || panels.emojiPicker.visible ? 0 : win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: panels.session.visible || panels.emojiPicker.visible ? 0 : win.height - bar.clampedHeight - clampedThickness - win.dragMaskPadding * 2
    intersection: Intersection.Xor

    R {
        panel: root.panels.dashboard
        y: 0
        height: panel.height * (1 - root.panels.dashboard.offsetScale) + root.panels.y
    }

    R {
        panel: root.panels.mediaIsland
        y: 0
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height * (1 - root.panels.mediaIsland.offsetScale) + root.panels.y : 0
    }

    // Widen only the edge strip, not the invisible area beside the open panel.
    R {
        panel: root.panels.dashboard
        x: panel.x + root.panels.x + (panel.width - width) / 2
        y: 0
        width: root.panels.dashboard.hoverWidth
        height: root.panels.dashboard.hoverHeight
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.leftSidebar
        x: 0
        width: panel.visible ? panel.width * (1 - root.panels.leftSidebar.offsetScale) + root.panels.x : 0
        height: panel.visible ? panel.height : 0
    }

    R {
        panel: root.panels.ai
        x: root.win.width - width
        width: panel.visible ? panel.width * (1 - root.panels.ai.offsetScale) + root.borderThickness : 0
        height: panel.visible ? panel.height : 0
    }

    R {
        panel: root.panels.sessionWrapper
        y: panel.y + root.panels.y + root.panels.session.y
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height : 0
    }

    R {
        panel: root.panels.emojiPicker
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height : 0
    }

    R {
        panel: root.panels.osdWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.osd.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.notifications
        y: 0
        width: panel.visible ? panel.width : 0
        height: panel.visible ? panel.height + root.panels.y : 0
    }

    R {
        panel: root.panels.popoutsWrapper
        y: panel.y + root.panels.y + root.panels.popoutsWrapper.hoverY
        width: root.panels.popoutsWrapper.hoverWidth
        height: root.panels.popoutsWrapper.hoverHeight
    }

    component R: Region {
        required property Item panel

        x: panel.x + root.panels.x
        y: panel.y + root.panels.y
        width: panel.width
        height: panel.height
        intersection: Intersection.Subtract
    }
}
