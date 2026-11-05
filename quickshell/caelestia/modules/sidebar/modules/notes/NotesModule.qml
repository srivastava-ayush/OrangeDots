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
    required property ScreenState screenState
    required property bool selected
    signal closeRequested
    focus: selected
    property string filter: "all"
    property string pendingDelete: ""
    property string pendingBulkDelete: ""
    readonly property var filtered: QuickNotes.entries.filter(entry =>
        (filter === "all" || entry.kind === filter)
        && (!search.text || entry.text.toLowerCase().includes(search.text.toLowerCase())))

    Keys.onEscapePressed: {
        if (pendingBulkDelete) pendingBulkDelete = "";
        else if (pendingDelete) pendingDelete = "";
        else root.closeRequested();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SidebarStyle.padding
        spacing: SidebarStyle.gap

        Sidebar.SidebarHeader {
            moduleId: "notes"
            StyledText {
                text: qsTr("%1 to do").arg(QuickNotes.todoCount)
                font: Tokens.font.label.small
                color: Colours.palette.m3onSurfaceVariant
            }
            IconButton { icon: "close"; type: IconButton.Text; onClicked: root.closeRequested() }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: SidebarStyle.smallGap
            Repeater {
                model: [ { id: "note", label: qsTr("Note") }, { id: "todo", label: qsTr("To-do") } ]
                delegate: TextButton {
                    required property var modelData
                    text: modelData.label
                    type: QuickNotes.draftKind === modelData.id ? TextButton.Tonal : TextButton.Text
                    onClicked: QuickNotes.draftKind = modelData.id
                }
            }
            Item { Layout.fillWidth: true }
            StyledText {
                visible: !!QuickNotes.editingId
                text: qsTr("Editing")
                font: Tokens.font.label.small
                color: Colours.palette.m3primary
            }
        }
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            color: Colours.palette.m3surfaceContainer
            radius: SidebarStyle.cardRadius
            clip: true
            Controls.ScrollView {
                anchors.fill: parent
                anchors.margins: SidebarStyle.cardPadding
                Controls.TextArea {
                    id: composer
                    text: QuickNotes.draftText
                    placeholderText: QuickNotes.draftKind === "todo" ? qsTr("What needs doing?") : qsTr("Jot down notes or links…")
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
                text: qsTr("Discard")
                type: TextButton.Text
                onClicked: QuickNotes.discardDraft()
            }
            TextButton {
                text: QuickNotes.draftKind === "todo" ? qsTr("Delete all todos") : qsTr("Delete all notes")
                type: TextButton.Text
                disabled: !QuickNotes.loaded || !QuickNotes.writable || !QuickNotes.entries.some(entry => entry.kind === QuickNotes.draftKind)
                onClicked: root.pendingBulkDelete = QuickNotes.draftKind
            }
            TextButton {
                text: QuickNotes.editingId ? qsTr("Save changes") : qsTr("Add")
                disabled: !QuickNotes.loaded || !QuickNotes.writable || !QuickNotes.draftText.trim()
                onClicked: QuickNotes.saveDraft()
            }
        }
        StyledRect {
            visible: !!root.pendingBulkDelete
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
                    text: root.pendingBulkDelete === "todo"
                        ? qsTr("Delete all todos, including completed ones? Notes and your current draft will be kept.")
                        : qsTr("Delete all notes? Todos and your current draft will be kept.")
                    wrapMode: Text.WordWrap
                    font: Tokens.font.body.small
                }
                RowLayout {
                    TextButton {
                        text: qsTr("Delete all")
                        onClicked: { QuickNotes.removeKind(root.pendingBulkDelete); root.pendingBulkDelete = ""; }
                    }
                    TextButton { text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.pendingBulkDelete = "" }
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
            placeholderText: qsTr("Search notes and todos")
            leadingIcon: "search"
            verticalPadding: SidebarStyle.cardPadding
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: SidebarStyle.smallGap
            Repeater {
                model: [ { id: "all", label: qsTr("All") }, { id: "note", label: qsTr("Notes") }, { id: "todo", label: qsTr("To-dos") } ]
                delegate: TextButton {
                    required property var modelData
                    text: modelData.label
                    type: root.filter === modelData.id ? TextButton.Tonal : TextButton.Text
                    onClicked: root.filter = modelData.id
                }
            }
        }
        StyledListView {
            id: notes
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
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
                        IconButton {
                            icon: card.modelData.kind === "todo" ? (card.modelData.done ? "check_circle" : "radio_button_unchecked") : "notes"
                            type: IconButton.Text
                            onClicked: {
                                if (card.modelData.kind === "todo") QuickNotes.toggle(card.modelData.id);
                                else if (QuickNotes.edit(card.modelData.id)) composer.forceActiveFocus();
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: card.modelData.text
                            textFormat: Text.PlainText
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 5
                            elide: Text.ElideRight
                            font: Tokens.font.body.small
                            opacity: card.modelData.done ? 0.5 : 1
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
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
                        StyledText { Layout.fillWidth: true; text: qsTr("Delete this item?"); font: Tokens.font.label.small }
                        TextButton { text: qsTr("Delete"); onClicked: { QuickNotes.remove(card.modelData.id); root.pendingDelete = ""; } }
                        TextButton { text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.pendingDelete = "" }
                    }
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: !root.filtered.length
            text: search.text ? qsTr("No matches") : qsTr("A little space for your thoughts, tasks and links.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font: Tokens.font.label.small
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
