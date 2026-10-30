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
    width: win.width - bar.clampedWidth - clampedThickness - win.dragMaskPadding * 2
    height: win.height - bar.clampedHeight - clampedThickness - win.dragMaskPadding * 2
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
        height: Math.max(root.win.contentItem.Config.border.minThickness, root.panels.y)
    }

    R {
        panel: root.panels.launcher
        y: root.win.height - height
        height: panel.height * (1 - root.panels.launcher.offsetScale) + root.borderThickness
    }

    R {
        panel: root.panels.sessionWrapper
        x: root.win.width - width
        width: panel.width * (1 - root.panels.session.offsetScale) + root.borderThickness
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
