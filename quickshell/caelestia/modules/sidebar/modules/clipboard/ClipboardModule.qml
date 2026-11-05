pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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
    focus: selected
    signal closeRequested
    property bool confirmClear: false
    property bool initialized: false
    property bool pinnedOnly: false
    readonly property var filtered: ClipboardHistory.entries.filter(entry =>
        (!pinnedOnly || entry.pinned) && (!search.text || entry.label.toLowerCase().includes(search.text.toLowerCase())))

    onSelectedChanged: {
        if (selected && initialized) ClipboardHistory.refresh();
        else confirmClear = false;
    }
    Component.onCompleted: {
        ClipboardHistory.retain();
        initialized = true;
        if (selected) ClipboardHistory.refresh();
    }
    Component.onDestruction: if (initialized) ClipboardHistory.release()
    Keys.onEscapePressed: {
        if (confirmClear) confirmClear = false;
        else root.closeRequested();
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.selected
        onTriggered: ClipboardHistory.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: SidebarStyle.padding
        spacing: SidebarStyle.gap

        Sidebar.SidebarHeader {
            moduleId: "clipboard"
            IconButton {
                icon: "refresh"
                type: IconButton.Text
                disabled: ClipboardHistory.busy
                onClicked: ClipboardHistory.refresh()
            }
            IconButton {
                icon: "delete_sweep"
                type: IconButton.Text
                onClicked: root.confirmClear = !root.confirmClear
            }
            IconButton { icon: "close"; type: IconButton.Text; onClicked: root.closeRequested() }
        }
        StyledTextField {
            id: search
            Layout.fillWidth: true
            placeholderText: qsTr("Search copied text and images")
            leadingIcon: "search"
            verticalPadding: SidebarStyle.cardPadding
        }
        RowLayout {
            Layout.fillWidth: true
            TextButton {
                text: qsTr("All")
                type: !root.pinnedOnly ? TextButton.Tonal : TextButton.Text
                onClicked: root.pinnedOnly = false
            }
            TextButton {
                text: qsTr("Pinned")
                type: root.pinnedOnly ? TextButton.Tonal : TextButton.Text
                onClicked: root.pinnedOnly = true
            }
            StyledText {
                Layout.fillWidth: true
                text: ClipboardHistory.refreshing ? qsTr("Refreshing history…")
                    : ClipboardHistory.busy ? (ClipboardHistory.request.action === "copy" ? qsTr("Copying…") : ClipboardHistory.request.action === "pin" ? qsTr("Pinning…") : qsTr("Working…"))
                    : qsTr("%1 items").arg(root.filtered.length)
                horizontalAlignment: Text.AlignRight
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }
        StyledRect {
            visible: root.confirmClear
            Layout.fillWidth: true
            implicitHeight: confirmation.implicitHeight + SidebarStyle.cardPadding * 2
            radius: SidebarStyle.cardRadius
            color: Colours.palette.m3surfaceContainerHigh
            ColumnLayout {
                id: confirmation
                anchors.fill: parent
                anchors.margins: SidebarStyle.cardPadding
                spacing: SidebarStyle.smallGap
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Clear local history and the current clipboard? Pins are kept unless you choose Everything.")
                    wrapMode: Text.WordWrap
                    font: Tokens.font.body.small
                }
                RowLayout {
                    TextButton {
                        text: qsTr("History")
                        disabled: ClipboardHistory.busy
                        onClicked: { ClipboardHistory.perform("clear", ""); root.confirmClear = false; }
                    }
                    TextButton {
                        text: qsTr("Everything")
                        disabled: ClipboardHistory.busy
                        onClicked: { ClipboardHistory.perform("clear-all", ""); root.confirmClear = false; }
                    }
                    TextButton { text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.confirmClear = false }
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: ClipboardHistory.error || ClipboardHistory.message
            color: ClipboardHistory.error ? Colours.palette.m3error : Colours.palette.m3primary
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
        StyledListView {
            id: history
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: SidebarStyle.smallGap
            model: root.filtered

            delegate: StyledRect {
                id: entry
                required property var modelData
                width: history.width
                implicitHeight: entryContent.implicitHeight + SidebarStyle.cardPadding * 2
                radius: SidebarStyle.cardRadius
                color: Colours.palette.m3surfaceContainer

                ColumnLayout {
                    id: entryContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: SidebarStyle.cardPadding
                    spacing: SidebarStyle.smallGap
                    Image {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 112
                        visible: entry.modelData.image && !!entry.modelData.preview
                        source: entry.modelData.preview || ""
                        sourceSize.width: 640
                        sourceSize.height: 224
                        asynchronous: true
                        // Let unloading the view release decoded thumbnails,
                        // rather than keeping them in Qt's shared image cache.
                        cache: false
                        fillMode: Image.PreserveAspectFit
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: entry.modelData.label
                        textFormat: Text.PlainText
                        font: Tokens.font.body.small
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        MaterialIcon {
                            text: entry.modelData.pinned ? "keep" : entry.modelData.image ? "image" : "notes"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.small
                        }
                        Item { Layout.fillWidth: true }
                        IconButton {
                            icon: "content_copy"
                            type: IconButton.Text
                            disabled: ClipboardHistory.busy
                            onClicked: ClipboardHistory.perform("copy", entry.modelData.id)
                        }
                        IconButton {
                            icon: "content_paste_go"
                            type: IconButton.Text
                            disabled: ClipboardHistory.busy
                            onClicked: {
                                if (ClipboardHistory.perform("paste", entry.modelData.id)) root.closeRequested();
                            }
                        }
                        IconButton {
                            icon: entry.modelData.pinned ? "keep_off" : "keep"
                            type: IconButton.Text
                            disabled: ClipboardHistory.busy
                            onClicked: ClipboardHistory.perform(entry.modelData.pinned ? "delete" : "pin", entry.modelData.id)
                        }
                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            disabled: ClipboardHistory.busy
                            onClicked: ClipboardHistory.perform("delete", entry.modelData.id)
                        }
                    }
                }
            }
        }
        StyledText {
            visible: !root.filtered.length && !ClipboardHistory.busy
            Layout.fillWidth: true
            text: search.text ? qsTr("No matching entries") : qsTr("Nothing here yet. Copied items appear in Caelestia's clipboard history.")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.body.small
        }
     
    }
}
