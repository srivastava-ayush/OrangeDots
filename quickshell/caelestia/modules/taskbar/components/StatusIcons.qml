pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.taskbar.components.status

StyledRect {
    id: root

    property color colour: Colours.palette.m3secondary
    required property var bar
    readonly property alias items: iconColumn

    readonly property int spacing: Tokens.spacing.medium / 2
    readonly property bool horizontal: Taskbar.horizontal

    // Magnetic hover pill. The bar's existing hit-testing tells us which status
    // cell is under the pointer; the pill springs between cells instead of
    // blinking on and off as the pointer crosses each icon.
    property Item highlightedEntry: null
    property real hlTargetX: 0
    property real hlTargetY: 0
    property real hlTargetW: 0
    property real hlTargetH: 0

    // The bar reports the cell under the pointer on every move. A short grace
    // period covers the padding between icons; once the pointer is off the
    // icons (or their menu) for good, the pill must let go.
    function setHoveredEntry(item: Item): void {
        if (item) {
            clearHighlightTimer.stop();
            root.highlightedEntry = item;
        } else if (root.highlightedEntry)
            clearHighlightTimer.restart();
    }

    function clearHighlight(): void {
        clearHighlightTimer.stop();
        root.highlightedEntry = null;
    }

    Timer {
        id: clearHighlightTimer
        interval: 90
        onTriggered: {
            const popouts = root.bar?.popouts;
            // Moving from an icon into its menu passes through bar padding; do
            // not drop the pill once the pointer has reached the open menu.
            if (popouts && (popouts.hovered || popouts.anchorHovered))
                return;
            root.clearHighlight();
        }
    }

    function syncHighlight(): void {
        const item = root.highlightedEntry;
        if (!item)
            return;
        root.hlTargetX = iconColumn.x + item.x;
        root.hlTargetY = iconColumn.y + item.y;
        root.hlTargetW = item.width;
        root.hlTargetH = item.height;
    }

    onHighlightedEntryChanged: root.syncHighlight()

    // Entries can resize when lock indicators appear/disappear. Keep the pill
    // glued to the live cell instead of the position it had when hovered.
    Connections {
        target: root.highlightedEntry

        function onXChanged() { root.syncHighlight() }
        function onYChanged() { root.syncHighlight() }
        function onWidthChanged() { root.syncHighlight() }
        function onHeightChanged() { root.syncHighlight() }
    }

    component MagneticSpring: SpringAnimation {
        // Qt's spring/damping scale is the same one the dashboard and island
        // use; much larger values overshoot the per-frame integration and blow
        // up. This is slightly stiffer than the dashboard close, so the pill
        // snaps between cells and settles in a fraction of a second.
        spring: 6
        damping: 0.5
        mass: 1
        epsilon: 0.001
    }

    // Index of the first/last entry that isn't collapsed, for edge margin gating
    readonly property int firstPresent: {
        const values = model.values;
        for (let i = 0; i < values.length; i++)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }
    readonly property int lastPresent: {
        const values = model.values;
        for (let i = values.length - 1; i >= 0; i--)
            if (!collapsed(values[i]))
                return i;
        return -1;
    }

    // Entries that can shrink to nothing, spacing included
    function collapsed(entry: var): bool {
        if (entry.id === "lockStatus")
            return !Hypr.capsLock && !Hypr.numLock;
        return false;
    }

    function notificationIcon(): Item {
        return iconColumn.children.find(child => child.name === "notifications")?.item ?? null;
    }

    color: Taskbar.centerOnly ? "transparent" : Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    clip: true
    implicitWidth: horizontal ? iconColumn.implicitWidth + Tokens.padding.medium * 2 : Tokens.sizes.bar.innerWidth
    implicitHeight: horizontal ? Math.max(Tokens.sizes.bar.innerWidth, iconColumn.implicitHeight) : iconColumn.implicitHeight + Tokens.padding.medium * 2

    // Declared before the icon grid so it stays behind the glyphs.
    StyledRect {
        id: hoverPill
        objectName: "taskbarStatusHoverPill"

        x: root.hlTargetX
        y: root.hlTargetY
        width: root.hlTargetW
        height: root.hlTargetH
        radius: Tokens.rounding.full
        color: Taskbar.centerOnly ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : Colours.tPalette.m3secondaryContainer
        opacity: root.highlightedEntry ? 1 : 0

        // Snap to the first target while hidden so the pill is born on the icon,
        // then spring between cells so a fast sweep never flashes through empty
        // space. Each axis keeps its own velocity for a natural magnetic snap.
        Behavior on x {
            enabled: hoverPill.opacity > 0.01
            MagneticSpring {}
        }

        Behavior on y {
            enabled: hoverPill.opacity > 0.01
            MagneticSpring {}
        }

        Behavior on width {
            enabled: hoverPill.opacity > 0.01
            MagneticSpring {}
        }

        Behavior on height {
            enabled: hoverPill.opacity > 0.01
            MagneticSpring {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
    }

    // The pill stays while the pointer is inside the menu it opened from, then
    // clears as soon as that menu loses hover/closes. Without this, leaving a
    // status icon into its popout would leave the highlight stuck forever.
    HoverHandler {
        id: statusHover

        // Every visible status cell opens a popout, so show the hand cursor
        // over an icon but keep the normal arrow in the pill's padding.
        cursorShape: iconColumn.childAt(point.position.x, point.position.y) ? Qt.PointingHandCursor : Qt.ArrowCursor

        onHoveredChanged: {
            if (!hovered)
                root.setHoveredEntry(null);
        }
    }

    Connections {
        target: root.bar?.popouts

        function onHoveredChanged() {
            if (!root.bar.popouts.hovered && !root.bar.popouts.anchorHovered)
                root.setHoveredEntry(null);
        }

        function onHasCurrentChanged() {
            if (!root.bar.popouts.hasCurrent)
                root.setHoveredEntry(null);
        }

        function onAnchorHoveredChanged() {
            if (!root.bar.popouts.anchorHovered && !root.bar.popouts.hovered)
                root.setHoveredEntry(null);
        }
    }

    GridLayout {
        id: iconColumn

        anchors.centerIn: parent
        width: root.horizontal ? implicitWidth : Math.max(implicitWidth, parent.width)
        columns: root.horizontal ? model.values.length : 1
        rows: root.horizontal ? 1 : model.values.length

        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: ScriptModel {
                id: model

                values: {
                    const configured = root.Config.bar.statusIcons.values;
                    const entries = configured.filter(e => e.enabled && (e.id !== "notifications" || root.Config.notifs.shadeEnabled));
                    // Keep the bell inside the shared status pill, including for
                    // existing configurations that predate the notification icon.
                    if (root.Config.notifs.shadeEnabled && !configured.some(e => e.id === "notifications"))
                        entries.unshift({ id: "notifications", enabled: true });
                    return entries;
                }
            }

            DelegateChooser {
                role: "id"

                DelegateChoice {
                    roleValue: "notifications"
                    delegate: EntryWrapper {
                        NotificationIcon {
                            objectName: "taskbarNotifications"
                            bar: root.bar
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "lockStatus"
                    delegate: EntryWrapper {
                        LockStatus {
                            colour: root.colour
                            parentSpacing: root.spacing
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "audio"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2

                        MaterialIcon {
                            animate: true
                            text: Icons.getVolumeIcon(Audio.volume, Audio.muted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "microphone"
                    delegate: EntryWrapper {
                        margin: Tokens.spacing.extraSmall / 2
                        name: "audio" // Mic opens audio popout

                        MaterialIcon {
                            animate: true
                            text: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
                            color: root.colour
                            fontStyle: Tokens.font.icon.medium
                            fill: 1
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "kbLayout"
                    delegate: EntryWrapper {
                        StyledText {
                            animate: true
                            text: Hypr.kbLayout
                            color: root.colour
                            font: Tokens.font.mono.medium
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "network"
                    delegate: EntryWrapper {
                        MaterialIcon {
                            animate: true
                            text: Nmcli.activeEthernet ? "cable" : Nmcli.active ? Icons.getNetworkIcon(Nmcli.active.strength ?? 0) : "wifi_off"
                            color: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "bluetooth"
                    delegate: EntryWrapper {
                        BluetoothStatus {
                            colour: root.colour
                        }
                    }
                }
                DelegateChoice {
                    roleValue: "battery"
                    delegate: EntryWrapper {
                        BatteryStatus {
                            colour: root.colour
                        }
                    }
                }
            }
        }
    }

    component EntryWrapper: Item {
        id: entryWrapper

        required property var modelData
        required property int index
        property int margin: root.spacing / 2
        readonly property bool present: !root.collapsed(modelData)
        // Exclude inactive lock indicators from the layout entirely. Keeping a
        // zero-sized animated cell makes neighboring status icons jump/overlap.
        visible: present
        property real topGap: present && index !== root.firstPresent ? margin : 0
        property real bottomGap: present && index !== root.lastPresent ? margin : 0
        default property Item item
        property string name: modelData.id.toLowerCase()

        Layout.topMargin: root.horizontal ? 0 : Math.round(topGap)
        Layout.bottomMargin: root.horizontal ? 0 : Math.round(bottomGap)
        Layout.leftMargin: root.horizontal ? Math.round(topGap) : 0
        Layout.rightMargin: root.horizontal ? Math.round(bottomGap) : 0
        Layout.alignment: Qt.AlignCenter

        implicitWidth: root.horizontal && !present ? 0 : (item?.implicitWidth ?? 0)
        implicitHeight: item?.implicitHeight ?? 0

        children: item

        Binding {
            target: entryWrapper.item
            property: "anchors.centerIn"
            value: entryWrapper
            when: Taskbar.centerOnly && entryWrapper.item !== null
        }

    }
}
