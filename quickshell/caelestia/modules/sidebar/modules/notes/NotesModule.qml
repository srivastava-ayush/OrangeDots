pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.modules.sidebar as Sidebar

FocusScope {
    id: root
    objectName: "sidebarNotes"
    required property ScreenState screenState
    required property bool selected
    signal closeRequested
    focus: selected
    property string pendingDelete: ""
    readonly property var filtered: QuickNotes.entries.filter(entry =>
        !search.text || entry.text.toLowerCase().includes(search.text.toLowerCase()))

    Keys.onEscapePressed: {
        if (pendingDelete) pendingDelete = "";
        else root.closeRequested();
    }

    // The panel can shrink at runtime when a banner or popout claims vertical
    // space (see PanelLayout.topClearance). Keep the whole module scrollable so
    // the composer and its buttons are never clipped or squeezed to zero.
    StyledFlickable {
        id: flick
        objectName: "notesFlick"
        anchors.fill: parent
        // Never scroll sideways: the rows flex and the status label yields its
        // width first, so nothing gets cut at the 360px minimum sidebar width.
        contentWidth: width
        contentHeight: Math.max(height, content.implicitHeight + SidebarStyle.padding * 2)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: content
            objectName: "notesContent"
            x: SidebarStyle.padding
            y: SidebarStyle.padding
            width: Math.max(0, flick.width - SidebarStyle.padding * 2)
            spacing: SidebarStyle.gap

            Sidebar.SidebarHeader {
                moduleId: "notes"
                StyledText {
                    text: qsTr("%1 notes").arg(QuickNotes.entries.length)
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
                IconButton { icon: "close"; type: IconButton.Text; onClicked: root.closeRequested() }
            }

            StyledRect {
                id: composerArea
                objectName: "notesComposerArea"
                Layout.fillWidth: true
                // Give the writing area almost half the panel. The rest of the
                // module scrolls vertically in the single outer Flickable.
                Layout.preferredHeight: Math.max(200, Math.round(flick.height * 0.45))
                Layout.minimumHeight: 160
                color: Colours.palette.m3surfaceContainer
                radius: SidebarStyle.cardRadius
                clip: true
                Controls.ScrollView {
                    anchors.fill: parent
                    anchors.margins: SidebarStyle.cardPadding
                    Controls.TextArea {
                        id: composer
                        text: QuickNotes.draftText
                        placeholderText: qsTr("Jot down notes or links…")
                        color: Colours.palette.m3onSurface
                        placeholderTextColor: Colours.palette.m3onSurfaceVariant
                        selectionColor: Colours.palette.m3primary
                        selectedTextColor: Colours.palette.m3onPrimary
                        font: Tokens.font.body.small
                        wrapMode: TextEdit.Wrap
                        textFormat: TextEdit.PlainText
                        background: null
                        onTextChanged: if (activeFocus && QuickNotes.draftText !== text) QuickNotes.draftText = text
                        Keys.onPressed: event => {
                            if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                QuickNotes.saveDraft();
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: SidebarStyle.smallGap
                StyledText {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: qsTr("Draft saved locally")
                    elide: Text.ElideRight
                    visible: !!QuickNotes.draftText
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
                TextButton {
                    visible: !!QuickNotes.draftText || !!QuickNotes.editingId
                    Layout.minimumWidth: implicitWidth
                    text: qsTr("Discard")
                    type: TextButton.Text
                    onClicked: QuickNotes.discardDraft()
                }
                TextButton {
                    Layout.minimumWidth: implicitWidth
                    text: qsTr("Delete all")
                    type: TextButton.Text
                    disabled: !QuickNotes.loaded || !QuickNotes.writable || !QuickNotes.entries.length
                    onClicked: root.pendingDelete = "__all__"
                }
                TextButton {
                    Layout.minimumWidth: implicitWidth
                    text: QuickNotes.editingId ? qsTr("Save changes") : qsTr("Add")
                    disabled: !QuickNotes.loaded || !QuickNotes.writable || !QuickNotes.draftText.trim()
                    onClicked: QuickNotes.saveDraft()
                }
            }

            StyledRect {
                visible: root.pendingDelete === "__all__"
                Layout.fillWidth: true
                implicitHeight: bulkConfirmation.implicitHeight + SidebarStyle.cardPadding * 2
                radius: SidebarStyle.cardRadius
                color: Colours.palette.m3surfaceContainerHigh
                ColumnLayout {
                    id: bulkConfirmation
                    anchors.fill: parent
                    anchors.margins: SidebarStyle.cardPadding
                    spacing: SidebarStyle.smallGap
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Delete all notes? Your current draft will be kept.")
                        wrapMode: Text.WordWrap
                        font: Tokens.font.body.small
                    }
                    RowLayout {
                        spacing: SidebarStyle.smallGap
                        TextButton {
                            Layout.minimumWidth: implicitWidth
                            text: qsTr("Delete all")
                            onClicked: { QuickNotes.removeAll(); root.pendingDelete = ""; }
                        }
                        TextButton { Layout.minimumWidth: implicitWidth; text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.pendingDelete = "" }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !!QuickNotes.error
                text: QuickNotes.error
                color: Colours.palette.m3error
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            StyledTextField {
                id: search
                Layout.fillWidth: true
                placeholderText: qsTr("Search notes")
                leadingIcon: "search"
                verticalPadding: SidebarStyle.cardPadding
            }

            // Expand to the full list height so there is a single scroll area:
            // the outer Flickable. Nested scrolling made lower buttons feel
            // unresponsive when the panel was short.
            StyledListView {
                id: notes
                Layout.fillWidth: true
                Layout.fillHeight: false
                implicitHeight: contentHeight
                interactive: false
                clip: false
                spacing: SidebarStyle.smallGap
                model: root.filtered
                delegate: StyledRect {
                    id: card
                    required property var modelData
                    width: notes.width
                    implicitHeight: cardContent.implicitHeight + SidebarStyle.cardPadding * 2
                    radius: SidebarStyle.cardRadius
                    color: Colours.palette.m3surfaceContainer
                    ColumnLayout {
                        id: cardContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: SidebarStyle.cardPadding
                        spacing: SidebarStyle.smallGap
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: SidebarStyle.smallGap
                            IconButton {
                                icon: "notes"
                                type: IconButton.Text
                                onClicked: if (QuickNotes.edit(card.modelData.id)) composer.forceActiveFocus()
                            }
                            StyledText {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: card.modelData.text
                                textFormat: Text.PlainText
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 5
                                elide: Text.ElideRight
                                font: Tokens.font.body.small
                            }
                        }
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: SidebarStyle.smallGap
                            IconButton { icon: "content_copy"; type: IconButton.Text; onClicked: Quickshell.clipboardText = card.modelData.text }
                            IconButton {
                                icon: "edit"
                                type: IconButton.Text
                                onClicked: if (QuickNotes.edit(card.modelData.id)) composer.forceActiveFocus()
                            }
                            IconButton { icon: "delete"; type: IconButton.Text; onClicked: root.pendingDelete = card.modelData.id }
                        }
                        RowLayout {
                            visible: root.pendingDelete === card.modelData.id
                            Layout.fillWidth: true
                            spacing: SidebarStyle.smallGap
                            StyledText { Layout.fillWidth: true; text: qsTr("Delete this note?"); font: Tokens.font.label.small }
                            TextButton { Layout.minimumWidth: implicitWidth; text: qsTr("Delete"); onClicked: { QuickNotes.remove(card.modelData.id); root.pendingDelete = ""; } }
                            TextButton { Layout.minimumWidth: implicitWidth; text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.pendingDelete = "" }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !root.filtered.length
                text: search.text ? qsTr("No matches") : qsTr("A little space for your thoughts and links.")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
