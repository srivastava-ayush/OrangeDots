pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Calendar & notes")
    isSubPage: true
    property bool revealUrl: false
    property bool confirmRemove: false

    readonly property Connections credentialConnection: Connections {
        target: GoogleCalendar
        function onCredentialsSaved(): void {
            feedUrl.clear();
            root.revealUrl = false;
            root.confirmRemove = false;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Secret iCal URL")
        }
        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: feedSettings.implicitHeight + Tokens.padding.large * 2
            ColumnLayout {
                id: feedSettings
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small
                StyledText {
                    Layout.fillWidth: true
                    text: GoogleCalendar.urlConfigured ? qsTr("A private calendar feed is configured.") : qsTr("Connect your calendar using its secret iCal address.")
                    wrapMode: Text.WordWrap
                    font: Tokens.font.body.small
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledTextField {
                        id: feedUrl
                        objectName: "calendarSecretUrl"
                        Layout.fillWidth: true
                        placeholderText: GoogleCalendar.urlConfigured ? qsTr("Paste a replacement URL") : "https://…"
                        echoMode: root.revealUrl ? TextInput.Normal : TextInput.Password
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                        maximumLength: 8192
                        verticalPadding: Tokens.padding.small
                        enabled: !GoogleCalendar.saving
                        onAccepted: GoogleCalendar.saveUrl(text)
                    }
                    IconButton {
                        icon: root.revealUrl ? "visibility_off" : "visibility"
                        type: IconButton.Text
                        onClicked: root.revealUrl = !root.revealUrl
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    TextButton {
                        objectName: "calendarSaveUrl"
                        text: GoogleCalendar.saving ? qsTr("Saving…") : GoogleCalendar.urlConfigured ? qsTr("Replace feed") : qsTr("Save feed")
                        disabled: GoogleCalendar.saving || !feedUrl.text.trim()
                        onClicked: GoogleCalendar.saveUrl(feedUrl.text)
                    }
                    TextButton {
                        objectName: "calendarRemoveUrl"
                        text: qsTr("Remove feed")
                        type: TextButton.Text
                        disabled: GoogleCalendar.saving || !GoogleCalendar.urlConfigured
                        onClicked: root.confirmRemove = true
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Google Calendar → Settings → Integrate calendar → Secret address in iCal format. Saved locally with owner-only permissions; never added to normal settings JSON. Existing secrets are not shown here.")
                    wrapMode: Text.WordWrap
                    font: Tokens.font.label.small
                    color: Colours.palette.m3onSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: !!GoogleCalendar.settingsError || !!GoogleCalendar.settingsMessage
                    text: GoogleCalendar.settingsError || GoogleCalendar.settingsMessage
                    wrapMode: Text.WordWrap
                    font: Tokens.font.label.small
                    color: GoogleCalendar.settingsError ? Colours.palette.m3error : Colours.palette.m3primary
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: root.confirmRemove
                    text: qsTr("Disconnect this feed and remove its saved secret? Your scratchpad notes will stay.")
                    wrapMode: Text.WordWrap
                    font: Tokens.font.body.small
                }
                RowLayout {
                    visible: root.confirmRemove
                    TextButton {
                        objectName: "calendarConfirmRemove"
                        text: qsTr("Disconnect")
                        disabled: GoogleCalendar.saving
                        onClicked: GoogleCalendar.clearUrl()
                    }
                    TextButton { text: qsTr("Cancel"); type: TextButton.Text; onClicked: root.confirmRemove = false }
                }
            }
        }
        SectionHeader {
            text: qsTr("Contents")
        }

        ToggleRow {
            first: true
            text: qsTr("Google Calendar agenda")
            checked: Config.sidebar.showAgenda
            onToggled: GlobalConfig.sidebar.showAgenda = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Notes")
            checked: Config.sidebar.showNotes
            onToggled: GlobalConfig.sidebar.showNotes = checked
        }
        InfoRow {
            first: true
            last: true
            label: qsTr("Google Calendar feed")
            value: GoogleCalendar.urlConfigured ? qsTr("Configured") : qsTr("Not configured")
            subtext: GoogleCalendar.error || qsTr("Module placement is configured in Sidebar → Modules.")
        }
    }
}
