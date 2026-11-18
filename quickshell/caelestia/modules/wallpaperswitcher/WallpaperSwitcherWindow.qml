pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Centred horizontal wallpaper strip, independent of the launcher's PathView
// picker. The surface is transparent and only mirrors input while it is open.
PanelWindow {
    id: root

    required property WallpaperSwitcherState state

    readonly property bool shouldBeActive: state.opened
    property real progress: shouldBeActive ? 1 : 0
    // Set while the window pushes its own selection into the PathView, so the
    // view does not echo that change straight back into the state.
    property bool syncingStrip: false

    readonly property real screenWidth: screen?.width ?? 1920

    // Seven cards on the path with the highlight locked to the middle. PathView
    // spreads the visible delegates evenly over the path; the path is sized so
    // compact cards sit one gap apart. The highlighted card expands to a much
    // wider shape, and every delegate nudges itself so all visible gaps stay
    // the same size.
    readonly property int pathItemCount: 7
    readonly property real padding: Tokens.padding.largeIncreased
    readonly property real stageWidth: Math.min(1400, Math.max(640, screenWidth - Tokens.padding.extraLarge * 2))
    readonly property real stripWidth: stageWidth - padding * 2
    readonly property real tileGap: Tokens.spacing.large
    readonly property real compactRatio: 0.62
    readonly property real compactWidth: Math.max(64, Math.round(stripWidth * 0.115))
    readonly property real cardWidth: Math.max(compactWidth + 24, Math.round(compactWidth / compactRatio))
    // The PathView path holds exactly the compact cards plus their even gaps,
    // so the highlight has room to grow without disturbing the neighbours.
    readonly property real pathLength: pathItemCount * (compactWidth + tileGap)
    readonly property real pathStart: Math.max(0, (stripWidth - pathLength) / 2)
    // A filtered list has fewer delegates than slots, and PathView then spreads
    // those delegates over the whole path. Track the real step so the gaps can
    // stay even for any result count.
    readonly property int visibleCount: Math.max(1, Math.min(pathItemCount, state.filteredEntries.length))
    readonly property real slotStep: pathLength / visibleCount
    readonly property real cardHeight: cardWidth / 16 * 9
    readonly property real labelHeight: 20
    readonly property real headerHeight: 44
    readonly property real stripHeight: cardHeight + Tokens.spacing.extraSmall + labelHeight
    readonly property real stageHeight: padding * 2 + headerHeight + Tokens.spacing.medium + stripHeight

    // The card is painted by the same liquid blob material as the session
    // menu, so it squashes and stretches while the reveal moves it. The blob
    // shader always fills opaque, so the glass alpha is applied to the whole
    // backdrop item instead; the value matches the scrim/threshold pairing in
    // Colours.reloadHyprRules().
    readonly property color panelColour: Colours.tPalette.m3surfaceContainer
    readonly property real panelOpacity: panelColour.a
    readonly property real scrimOpacity: 0.25
    readonly property real blobDeformScale: (0.2 * contentItem.Config.appearance.deformScale) / 10000
    readonly property int blobSmoothing: contentItem.Config.border.smoothing

    visible: progress > 0 || shouldBeActive
    color: "transparent"
    contentItem.Config.screen: screen.name
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

    // Mirror the session menu's curve but run it faster: the panel is small
    // enough that a ~210 ms summon still reads as deliberate, while dismissal
    // stays shorter so it feels crisp.
    Behavior on progress {
        Anim {
            type: root.shouldBeActive ? Anim.SlowSpatial : Anim.DefaultSpatial
            duration: root.shouldBeActive ? Tokens.anim.durations.expressiveSlowSpatial * 0.32 : Tokens.anim.durations.expressiveDefaultSpatial * 0.36
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

        StyledRect {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, root.scrimOpacity)
            // Dim promptly, independently of the slower card reveal.
            opacity: Math.min(1, root.progress * 1.5)
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.shouldBeActive
            onClicked: root.state.close()
        }

        // Liquid card backdrop, matching the session menu. The blob tracks the
        // growing panel's geometry, so its own velocity drives the squash and
        // stretch that make the reveal feel like a bubble inflating.
        Item {
            id: panelBackdrop

            readonly property real pad: 48

            x: panel.x - pad
            y: panel.y - pad
            width: panel.width + pad * 2
            height: panel.height + pad * 2
            // Translucent glass: the blob shader's alpha is always opaque, so
            // the shell transparency is applied to the whole deformed layer.
            opacity: root.panelOpacity
            visible: panel.width > 0 && panel.height > 0
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                blurMax: 15
                shadowColor: Qt.alpha(Colours.palette.m3shadow, 0.9 * root.progress)
            }

            BlobGroup {
                id: panelBlob

                color: root.panelColour
                smoothing: root.blobSmoothing
            }

            BlobRect {
                group: panelBlob

                x: panelBackdrop.pad
                y: panelBackdrop.pad
                width: panel.width
                height: panel.height
                radius: Tokens.rounding.extraLarge
                deformScale: root.blobDeformScale
            }
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

            // Mirror the session menu: the card grows out of an anchor point
            // instead of sliding. Here the point starts at the top centre, so
            // opening drops the strip down from the top edge and closing
            // shrinks it back there. The content stays at its final size and is
            // centred inside the growing clip, so the layout never squashes.
            readonly property real anchorX: parent ? parent.width / 2 : width / 2
            readonly property real anchorY: 0
            readonly property real targetX: parent ? parent.width / 2 : anchorX
            readonly property real targetY: parent ? parent.height / 2 : anchorY

            x: anchorX + (targetX - anchorX) * root.progress - width / 2
            y: anchorY + (targetY - anchorY) * root.progress - height / 2
            width: root.stageWidth * root.progress
            height: root.stageHeight * root.progress
            // The blob behind the card paints the surface. The panel itself
            // stays transparent and only clips the content to the same rounded
            // shape, so the backdrop can bulge past these bounds while it
            // deforms.
            radius: Tokens.rounding.extraLarge
            color: "transparent"

            // Consume empty-card clicks instead of cancelling behind the card.
            MouseArea { anchors.fill: parent }

            WheelHandler {
                onWheel: event => root.cycleByWheel(event)
            }

            Item {
                id: stage

                // Fixed final size, centred inside the growing clip, matching
                // the session menu's reveal scale.
                width: root.stageWidth
                height: root.stageHeight
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                scale: 0.94 + root.progress * 0.06
                opacity: root.progress
                transformOrigin: Item.Center

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.padding
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.headerHeight

                        RowLayout {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "image"
                                color: Colours.palette.m3primary
                                fontStyle: Tokens.font.icon.small
                            }

                            StyledText {
                                text: qsTr("Wallpaper")
                                font: Tokens.font.title.small
                            }
                        }

                        // Search sits in the exact centre of the header and
                        // takes focus as soon as the strip opens, so SUPER+TAB
                        // followed by typing filters without any extra click.
                        SearchBar {
                            id: searchInput

                            objectName: "wallpaperSwitcherSearch"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(420, root.stageWidth * 0.46)
                            placeholderText: qsTr("Search wallpapers")
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
                        highlightMoveDuration: 220

                        // Dragging owns currentIndex while the finger is down;
                        // keep the state as the single source when keys move it.
                        onCurrentIndexChanged: {
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
