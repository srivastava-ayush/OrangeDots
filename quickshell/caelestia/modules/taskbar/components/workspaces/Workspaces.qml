pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

StyledClippingRect {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property bool onSpecial: (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: GlobalConfig.bar.workspaces.perMonitorWorkspaces ? (Hypr.monitorFor(screen).activeWorkspace?.id ?? 1) : Hypr.activeWsId

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }
    readonly property int groupOffset: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown

    property real blur: onSpecial ? 1 : 0
    readonly property bool horizontal: Taskbar.horizontal
    readonly property int length: (horizontal ? layout.implicitWidth : layout.implicitHeight) + Tokens.padding.small * 2

    implicitWidth: horizontal ? length : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Tokens.sizes.bar.innerWidth : length

    color: "transparent"
    radius: Tokens.rounding.full

    Item {
        anchors.fill: parent
        scale: root.onSpecial ? 0.8 : 1
        opacity: root.onSpecial ? 0.5 : 1
        visible: !root.fullscreen

        layer.enabled: root.blur > 0
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: root.blur
            blurMax: 32
        }

        GridLayout {
            id: layout

            anchors.centerIn: parent
            columns: root.horizontal ? workspaces.count : 1
            rows: root.horizontal ? 1 : workspaces.count
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                id: workspaces

                model: Config.bar.workspaces.shown

                Workspace {
                    activeWsId: root.activeWsId
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }
        }

        MouseArea {
            property bool firstClickWasActive

            anchors.fill: layout
            onClicked: event => {
                const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                if (!ws) {
                    firstClickWasActive = false;
                    return;
                }
                firstClickWasActive = root.activeWsId === ws;
                if (!firstClickWasActive)
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
            }
            onDoubleClicked: event => {
                const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                if (firstClickWasActive && ws === root.activeWsId)
                    Hypr.openSpecialOrMisc();
            }
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: specialWs

        asynchronous: true

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall

        active: opacity > 0

        scale: root.onSpecial ? 1 : 0.5
        opacity: root.onSpecial ? 1 : 0

        sourceComponent: SpecialWorkspaces {
            screen: root.screen
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Behavior on blur {
        Anim {
            type: Anim.StandardSmall
        }
    }
}
