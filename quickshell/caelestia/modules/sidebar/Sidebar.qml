pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

// Utility sidebar: agenda pulled from Google Calendar plus a scratchpad for
// quick notes. Slides up from the bottom-right corner.
StyledRect {
    id: root

    readonly property date today: new Date()
    // Refreshes the "ongoing" highlight once a minute while visible
    property date now: new Date()

    property string notesText

    readonly property real maxSidebarHeight: ((QsWindow.window as QsWindow)?.screen?.height ?? 1000) * 0.62
    readonly property int agendaMaxHeight: 380
    readonly property int notesMaxHeight: 240

    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.now = new Date()
    }

    readonly property bool notesActive: notesField.activeFocus

    implicitWidth: Tokens.sizes.notifs.width
    implicitHeight: Math.min(root.maxSidebarHeight, layout.implicitHeight + Tokens.padding.large * 2)

    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: root.Tokens.padding.large
        spacing: root.Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            spacing: root.Tokens.spacing.small

            MaterialIcon {
                text: "event_note"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Qt.formatDate(root.today, "ddd, MMM d").toUpperCase()
                color: Colours.palette.m3onSurface
                font: Tokens.font.headline.small
            }

            Loader {
                asynchronous: true
                active: GoogleCalendar.urlConfigured && GoogleCalendar.error.length > 0

                sourceComponent: MaterialIcon {
                    text: "sync_problem"
                    color: Colours.palette.m3error
                    fontStyle: Tokens.font.icon.medium
                }
            }
        }

        Item {
            id: bodyArea

            Layout.fillWidth: true
            // Natural size follows the content, but yields space down to the
            // minimum when the panel hits its height cap - the list scrolls
            Layout.preferredHeight: Math.min(root.agendaMaxHeight, Math.max(view.contentHeight, 120))
            Layout.minimumHeight: 90
            Layout.fillHeight: true
            clip: true

            StyledListView {
                id: view

                anchors.fill: parent

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: view
                }

                model: ScriptModel {
                    values: GoogleCalendar.urlConfigured ? GoogleCalendar.events : []
                }

                spacing: Tokens.spacing.small

                section {
                    property: "dayLabel"
                    labelPositioning: ViewSection.InlineLabels

                    delegate: Rectangle {
                        required property string section

                        width: view.width
                        height: sectionHeader.implicitHeight + Tokens.spacing.small

                        color: "transparent"

                        StyledText {
                            id: sectionHeader

                            anchors.top: parent.top
                            text: parent.section
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.medium
                        }
                    }
                }

                delegate: Item {
                    id: entry

                    required property var modelData

                    readonly property bool ongoing: !modelData.allDay && modelData.start <= root.now && root.now < modelData.end

                    width: view.width
                    implicitHeight: entryRow.implicitHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.rounding.medium
                        color: entry.ongoing ? Colours.layer(Colours.palette.m3secondaryContainer, 1) : "transparent"
                    }

                    RowLayout {
                        id: entryRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.preferredWidth: 110
                            text: entry.modelData.allDay ? qsTr("All day") : `${Qt.formatDateTime(entry.modelData.start, "HH:mm")} – ${Qt.formatDateTime(entry.modelData.end, "HH:mm")}`
                            color: entry.ongoing ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: entry.modelData.summary
                            color: entry.ongoing ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }
                    }
                }

                // Empty states
                Loader {
                    asynchronous: true
                    anchors.centerIn: parent
                    active: opacity > 0
                    opacity: GoogleCalendar.events.length === 0 ? 1 : 0

                    sourceComponent: ColumnLayout {
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: GoogleCalendar.urlConfigured ? "event_busy" : "link_off"
                            color: Colours.palette.m3outlineVariant
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 300
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: {
                                if (!GoogleCalendar.urlConfigured)
                                    return qsTr("Add your Google Calendar secret iCal URL to ~/.config/caelestia/calendar-url");
                                if (GoogleCalendar.error.length > 0)
                                    return GoogleCalendar.error;
                                return qsTr("Nothing scheduled");
                            }
                            color: Colours.palette.m3outlineVariant
                            font: Tokens.font.body.medium
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: notes

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Notes")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.medium
                }

                MaterialIcon {
                    text: "edit_note"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }
            }

            Item {
                id: notesWrap

                Layout.fillWidth: true
                // Grows with the text up to a cap, then scrolls; yields space
                // when the panel gets tight (same scheme as the agenda list)
                Layout.preferredHeight: Math.min(root.notesMaxHeight, notesFlick.contentHeight + Tokens.spacing.extraSmall)
                Layout.minimumHeight: 80

                Rectangle {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
                }

                Flickable {
                    id: notesFlick

                    anchors.fill: parent
                    clip: true

                    contentWidth: width
                    contentHeight: notesField.implicitHeight + Tokens.padding.small

                    TextArea.flickable: notesField

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: notesFlick
                    }
                }

                TextArea {
                    id: notesField

                    width: notesWrap.width

                    text: root.notesText
                    onTextChanged: root.notesText = text
                    wrapMode: TextArea.Wrap
                    placeholderText: qsTr("Jot something down...")
                    placeholderTextColor: Colours.palette.m3outlineVariant
                    color: Colours.palette.m3onSurface
                    selectionColor: Colours.palette.m3primary
                    selectedTextColor: Colours.palette.m3onPrimary
                    font.family: Tokens.font.body.medium.family
                    font.pointSize: Tokens.font.body.medium.pointSize

                    background: null

                    leftPadding: Tokens.padding.small
                    rightPadding: Tokens.padding.small
                    topPadding: Tokens.padding.small
                    bottomPadding: Tokens.padding.small

                    // Keep the cursor in view while typing into long notes
                    onCursorRectangleChanged: notesFlick.ensureVisible(cursorRectangle)
                }
            }
        }
    }

    PersistentProperties {
        reloadableId: "utilitysidebar-notes"

        property alias notesText: root.notesText
    }
}
