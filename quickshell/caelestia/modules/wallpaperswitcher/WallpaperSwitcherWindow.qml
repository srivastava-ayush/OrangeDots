pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Centred horizontal wallpaper strip, independent of the launcher's PathView
// picker. The surface is transparent and only mirrors input while it is open.
// Tile motion is staged in WallpaperSwitcherItem with critically damped springs.
PanelWindow {
    id: root

    required property WallpaperSwitcherState state

    readonly property bool shouldBeActive: state.opened
    property real progress: shouldBeActive ? 1 : 0
    // Set while the window pushes its own selection into the PathView, so the
    // view does not echo that change straight back into the state.
    property bool syncingStrip: false
    // Sign of the last highlight movement. The incoming tile uses it to slide
    // home from the side it travelled from.
    property int slideDirection: 1
    // Last PathView index, used to derive that direction.
    property int stripIndex: -1

    readonly property real screenWidth: screen?.width ?? 1920

    // Seven cards on the path with the highlight locked to the middle. PathView
    // spreads the visible delegates evenly over the path; the path is sized so
    // compact cards sit one gap apart. The highlighted card expands to a much
    // wider shape, and every delegate nudges itself so all visible gaps stay
    // the same size.
    readonly property int pathItemCount: 7
    // Read tokens through the window's content item: it is a QQuickItem and
    // inherits the window's screen, while the PanelWindow itself is not an Item
    // and would warn about screen-less token lookups during construction.
    readonly property real padding: contentItem.Tokens.padding.largeIncreased
    readonly property real stageWidth: Math.min(1800, Math.max(640, screenWidth - contentItem.Tokens.padding.extraLarge * 2))
    readonly property real stripWidth: stageWidth - padding * 2
    readonly property real tileGap: contentItem.Tokens.spacing.large
    // Slimmer neighbours without shrinking the highlight: compactWidth is the
    // non-selected tile width, while compactRatio maps it back to the same
    // full-sized card width used by the selected tile.
    readonly property real compactRatio: 0.53
    readonly property real compactWidth: Math.max(64, Math.round(stripWidth * 0.12))
    readonly property real cardWidth: Math.max(compactWidth + 24, Math.round(compactWidth / compactRatio))
    // The PathView path holds exactly the compact cards plus their even gaps,
    // so the highlight has room to grow without disturbing the neighbours.
    readonly property real pathLength: pathItemCount * (compactWidth + tileGap)
    // Allow the path to overhang both edges equally so its midpoint — and the
    // highlighted tile locked there — stays centred even when tiles are wide.
    readonly property real pathStart: (stripWidth - pathLength) / 2
    // A filtered list has fewer delegates than slots, and PathView then spreads
    // those delegates over the whole path. Track the real step so the gaps can
    // stay even for any result count.
    readonly property int visibleCount: Math.max(1, Math.min(pathItemCount, state.filteredEntries.length))
    readonly property real slotStep: pathLength / visibleCount
    readonly property real cardHeight: cardWidth / 16 * 9
    readonly property real labelHeight: 20
    readonly property real headerHeight: 44
    readonly property real stripHeight: cardHeight + contentItem.Tokens.spacing.extraSmall + labelHeight
    readonly property real stageHeight: padding * 2 + headerHeight + contentItem.Tokens.spacing.medium + stripHeight

    visible: progress > 0 || shouldBeActive
    color: "transparent"
    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "caelestia-wallpaper-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shouldBeActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // The close animation must not keep intercepting clicks or keyboard input.
    mask: Region { item: root.shouldBeActive ? surface : null }

    // The panel fade matches the tile travel so the whole reveal settles
    // together: ~360 ms in, ~290 ms out.
    Behavior on progress {
        Anim {
            type: root.shouldBeActive ? Anim.SlowSpatial : Anim.DefaultSpatial
            duration: Tokens.anim.durations.expressiveSlowSpatial * (root.shouldBeActive ? 0.55 : 0.45)
            easing.type: root.shouldBeActive ? Easing.OutQuint : Easing.InCubic
        }
    }

    function cycleByWheel(event: var): void {
        const delta = event.pixelDelta.y + event.pixelDelta.x || event.angleDelta.y + event.angleDelta.x;
        if (delta !== 0)
            state.cycle(delta < 0 ? 1 : -1);
        event.accepted = true;
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            Qt.callLater(() => searchInput.forceActiveFocus());
    }

    Item {
        id: surface

        objectName: "wallpaperSwitcherSurface"
        anchors.fill: parent
        focus: root.shouldBeActive
        onVisibleChanged: {
            if (visible && root.shouldBeActive)
                Qt.callLater(() => searchInput.forceActiveFocus());
        }

        // Fallback for when focus is not in the search field (for example after
        // clicking a card). Typing goes to the field, so keep it focused.
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.state.close();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.state.cycle(-1);
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.state.cycle(1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.state.accept();
            } else {
                return;
            }
            // Never forward typing to the window underneath the overlay.
            event.accepted = true;
        }

        // Full-screen dim behind the floating tiles. It fades with progress so
        // the desktop darkens as the switcher opens and clears on close.
        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, 0.55)
            opacity: root.progress
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.shouldBeActive
            onClicked: root.state.close()
        }

        Connections {
            target: root.state

            function onSelectedIndexChanged(): void {
                if (!strip)
                    return;
                if (strip.currentIndex !== root.state.selectedIndex) {
                    root.syncingStrip = true;
                    strip.currentIndex = root.state.selectedIndex;
                    root.syncingStrip = false;
                }
            }

            function onSearchChanged(): void {
                if (searchInput && searchInput.text !== root.state.search)
                    searchInput.text = root.state.search;
            }

            function onOpenedChanged(): void {
                if (!root.state.opened)
                    return;
                if (searchInput && searchInput.text !== root.state.search)
                    searchInput.text = root.state.search;
                if (strip && strip.currentIndex !== root.state.selectedIndex)
                    strip.currentIndex = root.state.selectedIndex;
                Qt.callLater(() => searchInput.forceActiveFocus());
            }
        }

        StyledClippingRect {
            id: panel

            objectName: "wallpaperSwitcherPanel"
            Accessible.role: Accessible.Dialog
            Accessible.name: qsTr("Wallpaper switcher")

            // Fixed full-size clip. The opening/closing motion now comes from
            // the tiles themselves: the highlight falls from the top and the
            // neighbours sweep in from the left and right edges. The panel
            // stays put and simply fades with progress.
            x: parent ? (parent.width - width) / 2 : 0
            y: parent ? (parent.height - height) / 2 : 0
            width: root.stageWidth
            height: root.stageHeight
            radius: Tokens.rounding.extraLarge
            color: "transparent"

            // Consume empty-card clicks instead of cancelling behind the card.
            MouseArea { anchors.fill: parent }

            WheelHandler {
                onWheel: event => root.cycleByWheel(event)
            }

            Item {
                id: stage

                // Fixed final size; only the tile transforms animate.
                width: root.stageWidth
                height: root.stageHeight
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                opacity: root.progress

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.padding
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.headerHeight

                        // Search sits in the exact centre of the header and
                        // takes focus as soon as the strip opens, so SUPER+TAB
                        // followed by typing filters without any extra click.
                        SearchBar {
                            id: searchInput

                            objectName: "wallpaperSwitcherSearch"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(420, root.stageWidth * 0.46)
                            // No placeholder: the field stays quiet until text
                            // is typed, with only a faint icon and background.
                            placeholderText: ""
                            bg.opacity: 0.3
                            searchIcon.opacity: 0.45
                            topPadding: Tokens.padding.small
                            bottomPadding: Tokens.padding.small

                            onTextChanged: {
                                if (root.state.search !== text)
                                    root.state.search = text;
                            }

                            Keys.onEscapePressed: root.state.close()
                            Keys.onReturnPressed: root.state.accept()
                            Keys.onEnterPressed: root.state.accept()
                            Keys.onUpPressed: root.state.cycle(-1)
                            Keys.onDownPressed: root.state.cycle(1)
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Tab) {
                                    root.state.cycle(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Backtab) {
                                    root.state.cycle(-1);
                                    event.accepted = true;
                                } else if (text.length === 0 && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                                    // Keep arrow browsing available before the
                                    // first keystroke; afterwards they move the
                                    // caret through what has been typed.
                                    root.state.cycle(event.key === Qt.Key_Left ? -1 : 1);
                                    event.accepted = true;
                                }
                            }
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.state.filteredEntries.length > 0 ? (root.state.selectedIndex + 1) + " / " + root.state.filteredEntries.length : qsTr("No matches")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }

                    Item { Layout.preferredHeight: Tokens.spacing.medium }

                    PathView {
                        id: strip

                        objectName: "wallpaperSwitcherStrip"
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.stripHeight
                        clip: true
                        interactive: true

                        // Wheel events land on the Flickable itself, so this
                        // handler must live here rather than on the panel.
                        WheelHandler {
                            onWheel: event => root.cycleByWheel(event)
                        }

                        model: root.state.filteredEntries
                        pathItemCount: root.pathItemCount
                        cacheItemCount: 4
                        snapMode: PathView.SnapToItem
                        preferredHighlightBegin: 0.5
                        preferredHighlightEnd: 0.5
                        highlightRangeMode: PathView.StrictlyEnforceRange
                        highlightMoveDuration: 260

                        // Dragging owns currentIndex while the finger is down;
                        // keep the state as the single source when keys move it.
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && root.stripIndex >= 0 && currentIndex !== root.stripIndex)
                                root.slideDirection = currentIndex > root.stripIndex ? 1 : -1;
                            root.stripIndex = currentIndex;
                            if (root.syncingStrip || !root.state.opened || root.state.filteredEntries.length === 0 || currentIndex < 0)
                                return;
                            if (root.state.selectedIndex !== currentIndex)
                                root.state.select(currentIndex);
                        }

                        delegate: WallpaperSwitcherItem {
                            width: root.cardWidth
                            height: root.stripHeight
                            fullTileWidth: root.cardWidth
                            compactTileWidth: root.compactWidth
                            slotStep: root.slotStep
                            tileGap: root.tileGap
                            slideDirection: root.slideDirection
                            maxStaggerOrder: Math.floor(root.pathItemCount / 2)
                            presented: root.state.opened
                            current: PathView.isCurrentItem
                            applied: modelData.path === Wallpapers.actualCurrent
                            onClicked: {
                                root.state.commit(index);
                            }
                        }

                        path: Path {
                            startX: root.pathStart
                            startY: root.stripHeight / 2

                            PathLine {
                                x: root.pathStart + root.pathLength / 2
                                relativeY: 0
                            }

                            PathLine {
                                x: root.pathStart + root.pathLength
                                relativeY: 0
                            }
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: root.state.filteredEntries.length === 0
                    text: root.state.entries.length === 0 ? qsTr("No wallpapers found") : qsTr("No wallpapers match your search")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }
    }
}
