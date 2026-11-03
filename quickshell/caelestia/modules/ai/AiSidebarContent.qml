pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings

FocusScope {
    id: root
    required property AiChatState chat
    signal closeRequested
    focus: true
    Keys.onEscapePressed: root.closeRequested()
    Component.onCompleted: Qt.callLater(() => composer.forceActiveFocus())

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../assets/dino.png")
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.ceil(root.width)
        sourceSize.height: Math.ceil(root.height)
        asynchronous: true
        cache: false
    }

    // Keep panel-space clicks from becoming a compositor edge drag.
    MouseArea { anchors.fill: parent }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
          
            ColumnLayout {
                Layout.fillWidth: true
                Layout.rightMargin: Tokens.spacing.medium
                spacing: 2
                StyledText { text: AiConfig.names[root.chat.provider] || "AI"; font: Tokens.font.title.medium }
                StyledText {
                    text: root.chat.resetting ? qsTr("Stopping previous chat…") : root.chat.permissions.length ? qsTr("Approval needed") : root.chat.busy ? qsTr("Working…") : root.chat.ready ? qsTr("Ready") : qsTr("Connecting…")
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
            IconButton {
                icon: "open_in_new"
                type: IconButton.Text
                disabled: !root.chat.sessionID || root.chat.provider === "ollama"
                onClicked: {
                    const command = root.chat.provider === "codex" ? ["codex", "resume", root.chat.sessionID] : root.chat.provider === "claude" ? ["claude", "--resume", root.chat.sessionID] : ["opencode", "mini", "--session", root.chat.sessionID];
                    Quickshell.execDetached([...GlobalConfig.general.apps.terminal, "-e", ...command]);
                }
            }
            IconButton {
                icon: "settings"
                type: IconButton.Text
                onClicked: { root.closeRequested(); SettingsWindows.openAiSettings(); }
            }
            TextButton {
                objectName: "aiChatClearMemory"
                text: qsTr("NUKE")
                type: TextButton.Tonal
                disabled: root.chat.resetting
                onClicked: root.chat.clearMemory()
            }
            IconButton { objectName: "aiChatClose"; icon: "close"; type: IconButton.Text; onClicked: root.closeRequested() }
        }

        StyledRect { Layout.fillWidth: true; implicitHeight: 1; color: Colours.palette.m3outlineVariant }

        ListView {
            id: history
            objectName: "aiChatHistory"
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.chat.messages
            spacing: Tokens.spacing.small
            clip: true
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds
            property bool followOutput: true
            onMovementEnded: followOutput = atYEnd
            onContentHeightChanged: if (followOutput) Qt.callLater(() => history.positionViewAtEnd())
            StyledScrollBar.vertical: StyledScrollBar { flickable: history }

            delegate: StyledRect {
                required property string role
                required property string text
                width: history.width
                implicitHeight: message.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.large
                color: role === "user" ? Qt.alpha(Colours.palette.m3secondaryContainer, 0.5) : Colours.tPalette.m3surfaceContainer

                TextEdit {
                    id: message
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.medium
                    text: parent.text
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primary
                    selectedTextColor: Colours.palette.m3onPrimary
                    font: Tokens.font.body.medium
                }
            }

        }

        Repeater {
            model: root.chat.permissions.slice(0, 1)
            StyledRect {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: approval.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainerHigh
                ColumnLayout {
                    id: approval
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.small
                    StyledText { text: qsTr("Allow %1?").arg(parent.parent.modelData.action); font: Tokens.font.title.small }
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(100, requestText.implicitHeight)
                        contentHeight: requestText.implicitHeight
                        clip: true
                        TextEdit {
                            id: requestText
                            width: parent.width
                            text: approval.parent.modelData.resources.join("\n") + (approval.parent.modelData.metadata ? "\n" + JSON.stringify(approval.parent.modelData.metadata, null, 2) : "")
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                    RowLayout {
                        TextButton { objectName: "aiChatDeny"; text: qsTr("Deny"); type: TextButton.Tonal; onClicked: root.chat.write({ type: "permission", id: approval.parent.modelData.id, decision: "reject" }) }
                        TextButton { objectName: "aiChatApprove"; text: qsTr("Allow once"); onClicked: root.chat.write({ type: "permission", id: approval.parent.modelData.id, decision: "once" }) }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.chat.forms > 0
            text: qsTr("The agent has a question. Use Open in terminal above to answer it.")
            wrapMode: Text.WordWrap
            font: Tokens.font.label.small
            color: Colours.palette.m3primary
        }
        StyledText {
            Layout.fillWidth: true
            visible: !!root.chat.error
            text: root.chat.error
            wrapMode: Text.WordWrap
            font: Tokens.font.label.small
            color: Colours.palette.m3error
        }
        TextButton { visible: !!root.chat.error; text: qsTr("Reconnect"); onClicked: root.chat.reconnect() }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Math.min(140, Math.max(52, composer.contentHeight + 24))
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerHigh
            Flickable {
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: composer.contentHeight
                clip: true
                TextEdit {
                    id: composer
                    objectName: "aiChatComposer"
                    width: parent.width
                    text: root.chat.draft
                    onTextChanged: root.chat.draft = text
                    wrapMode: TextEdit.Wrap
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primary
                    selectedTextColor: Colours.palette.m3onPrimary
                    font: Tokens.font.body.medium
                    Keys.onPressed: event => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                            root.chat.send();
                            event.accepted = true;
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            StyledText { Layout.fillWidth: true; text: qsTr("Enter to send · Shift+Enter for a new line"); font: Tokens.font.label.small; color: Colours.palette.m3outline; elide: Text.ElideRight }
            IconButton {
                icon: root.chat.busy ? "stop" : "arrow_upward"
                type: IconButton.Filled
                disabled: !root.chat.ready || (!root.chat.busy && !root.chat.draft.trim())
                onClicked: root.chat.busy ? root.chat.write({ type: "stop" }) : root.chat.send()
            }
        }
    }
}
