pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    property string query
    property var entries: []
    property bool loading: true

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        if (!q)
            return root.entries;

        const matches = [];
        for (let i = 0; i < root.entries.length; i++) {
            const entry = root.entries[i];
            if (entry.glyph === q || entry.keywords.includes(q))
                matches.push(entry);
        }
        return matches;
    }

    // Selection copies the glyph, closes the picker, and once the compositor
    // has handed focus back to the previously active window, types the glyph
    // there over the virtual-keyboard protocol (wtype). If wtype is missing the
    // picker still leaves the glyph on the clipboard.
    function copy(entry: var): void {
        if (!entry)
            return;

        const glyph = entry.glyph;
        Quickshell.clipboardText = glyph;
        root.screenState.emoji = false;
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; command -v wtype >/dev/null && exec wtype \"$1\"", "sh", glyph]);
    }

    function parseEmoji(text: string): void {
        const parsed = [];
        for (const line of text.split("\n")) {
            const trimmed = line.trim();
            if (!trimmed)
                continue;
            // Each line is "<glyph> [keywords…]" (see `caelestia emoji`).
            const space = trimmed.indexOf(" ");
            parsed.push({
                glyph: space === -1 ? trimmed : trimmed.slice(0, space),
                keywords: space === -1 ? "" : trimmed.slice(space + 1).toLowerCase()
            });
        }
        root.entries = parsed;
        root.loading = false;
    }

    // Same dataset as the CLI picker, so `caelestia emoji -f` refreshes both.
    Process {
        id: data

        running: root.screenState.emoji && root.entries.length === 0
        command: ["sh", "-c", "caelestia emoji 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.parseEmoji(text)
        }
        onExited: root.loading = false // qmllint disable signal-handler-parameters
    }

    Connections {
        function onEmojiChanged(): void {
            if (!root.screenState.emoji)
                search.text = "";
            else
                search.forceActiveFocus();
        }

        target: root.screenState
    }

    SearchBar {
        id: search

        objectName: "emojiSearch"

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        placeholderText: qsTr("Search emoji and glyphs")
        font: Tokens.font.body.medium

        onTextChanged: root.query = text
        onAccepted: root.copy(root.results[0])

        Keys.onEscapePressed: root.screenState.emoji = false
        Keys.onDownPressed: {
            if (root.results.length) {
                grid.forceActiveFocus();
                grid.currentIndex = 0;
            }
        }

        Component.onCompleted: forceActiveFocus()
    }

    GridView {
        id: grid

        anchors.top: search.bottom
        anchors.topMargin: Tokens.spacing.medium
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        readonly property int cellSize: 48

        cellWidth: cellSize
        cellHeight: cellSize
        // Keep re-created rows cheap while scrolling through the full set.
        cacheBuffer: cellSize * 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: grid
        }

        Keys.onEscapePressed: root.screenState.emoji = false
        Keys.onReturnPressed: root.copy(root.results[currentIndex])
        Keys.onEnterPressed: root.copy(root.results[currentIndex])

        delegate: Item {
            id: cell

            required property var modelData
            required property int index

            width: grid.cellSize
            height: grid.cellSize

            StyledRect {
                anchors.fill: parent
                anchors.margins: Math.round(Tokens.spacing.extraSmall / 2)
                radius: Tokens.rounding.medium
                color: GridView.isCurrentItem || cellHover.hovered ? Colours.tPalette.m3surfaceContainerHighest : "transparent"
            }

            StyledText {
                anchors.centerIn: parent

                text: cell.modelData.glyph
                color: Colours.palette.m3onSurface
                font.pointSize: 17
                renderType: Text.QtRendering
            }

            HoverHandler {
                id: cellHover
            }

            TapHandler {
                onTapped: root.copy(cell.modelData)
            }
        }
    }

    StyledText {
        anchors.centerIn: grid
        width: grid.width - Tokens.padding.extraLarge * 2
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap

        visible: !root.loading && root.results.length === 0
        text: root.query ? qsTr("No emoji match \"%1\"").arg(root.query) : qsTr("No emoji data. Run \"caelestia emoji -f\".")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }
}
