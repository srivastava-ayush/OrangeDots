pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    readonly property alias layout: layout
    readonly property alias items: items
    readonly property alias expandIcon: expandIcon

    readonly property int padding: Config.bar.tray.background ? Tokens.padding.medium : Tokens.padding.extraSmall
    readonly property int spacing: Config.bar.tray.background ? Tokens.spacing.medium : Tokens.spacing.extraSmall
    readonly property bool horizontal: Taskbar.horizontal

    property bool expanded

    readonly property real nonAnimLength: {
        const length = horizontal ? layout.implicitWidth : layout.implicitHeight;
        const iconLength = horizontal ? expandIcon.implicitWidth : expandIcon.implicitHeight;
        if (!Config.bar.tray.compact)
            return length + padding * 2;
        // In Top mode reserve a complete arrow cell and padding on both
        // edges; the vertical tray's shortened arrow geometry clips here.
        if (horizontal)
            return (expanded ? length + spacing : 0) + iconLength + padding * 2;
        const pad = (Config.bar.tray.background ? Tokens.padding.extraSmall : 0) + padding;
        if (expanded)
            return iconLength + length + spacing + pad;
        return Math.max(Config.bar.tray.background ? Tokens.sizes.bar.innerWidth : 0, iconLength + pad);
    }
    readonly property real nonAnimWidth: horizontal ? nonAnimLength : Tokens.sizes.bar.innerWidth
    readonly property real nonAnimHeight: horizontal ? Math.max(Tokens.sizes.bar.innerWidth, layout.implicitHeight, expandIcon.implicitHeight) : nonAnimLength

    clip: true
    visible: width > 0 && height > 0

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    color: Qt.alpha(Colours.tPalette.m3surfaceContainer, (!Taskbar.centerOnly && Config.bar.tray.background && items.count > 0) ? Colours.tPalette.m3surfaceContainer.a : 0)
    radius: Tokens.rounding.full

    Grid {
        id: layout

        // Coordinates avoid transient conflicting anchors when the bar rotates.
        x: root.horizontal ? root.padding : (root.width - width) / 2
        y: root.horizontal ? (root.height - height) / 2 : root.padding
        columns: root.horizontal ? Math.max(1, items.count) : 1
        spacing: Tokens.spacing.small

        opacity: root.expanded || !Config.bar.tray.compact ? 1 : 0

        add: Transition {
            Anim {
                properties: "scale"
                from: 0
                to: 1
                easing: Tokens.anim.standardDecel
            }
        }

        move: Transition {
            Anim {
                properties: "scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            // Let the positioner apply new coordinates immediately. Animating
            // old vertical positions into a horizontal row can cross/clip icons
            // during a live orientation change.
        }

        Repeater {
            id: items

            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            TrayItem {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    Loader {
        id: expandIcon

        asynchronous: true

        x: root.horizontal ? root.width - width - root.padding : (root.width - width) / 2
        y: root.horizontal ? (root.height - height) / 2 : root.height - height

        active: Config.bar.tray.compact && items.count > 0

        sourceComponent: Item {
            implicitWidth: expandIconInner.implicitWidth
            implicitHeight: expandIconInner.implicitHeight - (root.horizontal ? 0 : Tokens.padding.small)

            MaterialIcon {
                id: expandIconInner

                x: (parent.width - width) / 2
                y: root.horizontal ? (parent.height - height) / 2 : parent.height - height - (Config.bar.tray.background ? Tokens.padding.extraSmall : -Tokens.padding.small)
                text: root.horizontal ? "chevron_left" : "expand_less"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    Anim {}
                }

            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {}
    }
}
