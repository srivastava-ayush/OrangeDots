pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.taskbar.popouts // Keep the typed popout reference consistent across imports.

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property real borderThickness
    required property bool horizontal
    property real hideInset: 0

    readonly property alias content: content
    readonly property bool bottomAligned: !horizontal && content.currentName === "notifications" && !content.isDetached
    // Include the destination bounds while opening, so a fast pointer can enter
    // the panel before its slide animation has finished.
    readonly property real hoverWidth: content.hasCurrent ? Math.max(width, content.width, content.nonAnimWidth) : width
    readonly property real hoverHeight: content.hasCurrent ? Math.max(height, content.height, content.nonAnimHeight) : height
    readonly property real hoverY: content.hasCurrent && bottomAligned ? Math.min(0, content.height - content.nonAnimHeight) : 0
    property real offsetScale: content.isDetached || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (horizontal ? 1 : 1 - offsetScale)
    implicitHeight: content.implicitHeight * (horizontal ? 1 - offsetScale : 1)

    function clampedPosition(length: real, popoutLength: real): real {
        return Math.max(0, Math.min(content.currentCenter - borderThickness - popoutLength / 2, length - popoutLength));
    }

    x: {
        if (content.isDetached)
            return (parent.width - content.nonAnimWidth) / 2;
        return horizontal ? clampedPosition(parent.width, content.nonAnimWidth) : 0;
    }
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;
        if (bottomAligned)
            return Math.max(0, parent.height - content.height);

        return horizontal ? 0 : clampedPosition(parent.height, content.nonAnimHeight);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        // Follow height changes directly so the shade stays flush with the
        // shell bottom throughout opening and notification-list updates.
        enabled: root.offsetScale < 1 && !root.bottomAligned

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    HoverHandler {
        id: popoutHover
    }

    PopoutWrapper {
        id: content

        screen: root.screen
        screenState: root.screenState
        offsetScale: root.offsetScale
        hovered: popoutHover.hovered

        // Switching between left and centre anchors can temporarily stretch the
        // item and leave an explicit width behind (e.g. 10px for a 310px popup).
        // Keep both dimensions bound to the content and slide using coordinates.
        width: implicitWidth
        height: implicitHeight
        x: root.horizontal ? (parent.width - width) / 2 : (-width - root.hideInset - 5) * root.offsetScale
        y: root.horizontal ? (-height - root.hideInset - 5) * root.offsetScale : (parent.height - height) / 2
    }
}
