pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen

    readonly property bool disabled: Strings.testRegexList(Config.bar.excludedScreens, screen.name)
    readonly property bool horizontal: Taskbar.horizontal

    readonly property real leftInset: horizontal ? Config.border.thickness : thickness
    readonly property real topInset: horizontal ? thickness : Config.border.thickness
    readonly property int clampedWidth: Math.max(Config.border.minThickness, leftInset)
    readonly property int clampedHeight: Math.max(Config.border.minThickness, topInset)
    readonly property int padding: Math.max(Tokens.padding.small, Config.border.thickness)
    readonly property int contentWidth: Tokens.sizes.bar.innerWidth + padding * 2
    readonly property int exclusiveZone: !disabled && (Config.bar.persistent || screenState.bar) ? contentWidth : Config.border.thickness
    readonly property bool shouldBeVisible: !fullscreen && !disabled && (Config.bar.persistent || screenState.bar || isHovered || screenState.notifShade || (popouts.hasCurrent && !popouts.isDetached))
    property bool isHovered
    property real thickness: fullscreen ? 0 : Config.border.thickness

    function closeTray(): void {
        (content.item as Bar)?.closeTray();
    }

    function hasEntryAt(x: real, y: real): bool {
        const bar = content.item as Bar;
        if (!bar)
            return false;
        const pos = bar.mapFromItem(root, x, y);
        return bar.hasEntryAt(pos.x, pos.y);
    }

    function checkPopout(x: real, y: real): void {
        const bar = content.item as Bar;
        if (bar) {
            const pos = bar.mapFromItem(root, x, y);
            bar.checkPopout(pos.x, pos.y);
        }
    }

    function handleWheel(x: real, y: real, angleDelta: point): void {
        const bar = content.item as Bar;
        if (bar) {
            const pos = bar.mapFromItem(root, x, y);
            bar.handleWheel(pos.x, pos.y, angleDelta);
        }
    }

    clip: true
    visible: thickness > Config.border.thickness
    implicitWidth: horizontal ? 0 : thickness
    implicitHeight: horizontal ? thickness : 0
    width: horizontal ? parent.width : thickness
    height: horizontal ? thickness : parent.height

    onHorizontalChanged: {
        isHovered = false;
        closeTray();
        popouts.close();
    }

    states: State {
        name: "visible"
        when: root.shouldBeVisible

        PropertyChanges {
            root.thickness: root.contentWidth
        }
    }

    transitions: [
        Transition {
            from: ""
            to: "visible"

            Anim {
                target: root
                property: "thickness"
            }
        },
        Transition {
            from: "visible"
            to: ""

            Anim {
                target: root
                property: "thickness"
                type: Anim.Emphasized
            }
        }
    ]

    Loader {
        id: content

        x: root.horizontal ? 0 : root.width - width
        y: root.horizontal ? root.height - height : 0
        width: root.horizontal ? root.width : root.contentWidth
        height: root.horizontal ? root.contentWidth : root.height

        active: root.shouldBeVisible

        sourceComponent: Bar {
            width: root.horizontal ? root.width : root.contentWidth
            height: root.horizontal ? root.contentWidth : root.height
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts // qmllint disable incompatible-type
            fullscreen: root.fullscreen
        }
    }
}
