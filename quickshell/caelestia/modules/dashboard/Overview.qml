pragma ComponentBehavior: Bound

import "overview"
import "utilities/cards"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root
    objectName: "dashboardOverview"

    required property ScreenState screenState
    required property FileDialog facePicker
    property real preferredHeight: Tokens.sizes.dashboard.mediaTabHeight

    // Shared UI state for the recorder card and its recording list
    readonly property var props: dashProps

    PersistentProperties {
        id: dashProps

        property bool recordingListExpanded
        property string recordingMode
        property string recordingConfirmDelete

        reloadableId: "dashboard-recording"
    }

    // Match Performance's height through layout, without scaling text/controls.
    readonly property int weatherCardWidth: Math.max(360, Tokens.sizes.dashboard.weatherWidth)
    implicitWidth: Tokens.sizes.dashboard.mediaTabWidth
    implicitHeight: preferredHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            id: row
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            spacing: Tokens.spacing.medium

            Rect {
                id: userCard
                objectName: "overviewProfileCard"
                Layout.preferredWidth: Math.min(260, Tokens.sizes.dashboard.userWidth)
                Layout.minimumWidth: Layout.preferredWidth
                Layout.maximumWidth: Layout.preferredWidth
                Layout.fillHeight: true
                implicitHeight: userContent.implicitHeight

                radius: Tokens.rounding.extraLarge

                User {
                    id: userContent
                    screenState: root.screenState
                    facePicker: root.facePicker
                }
            }

            ColumnLayout {
                id: utilCards

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.medium

                RowLayout {
                    objectName: "overviewQuickControls"
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        active: Config.utilities.cards.keepAwake
                        visible: active

                        sourceComponent: IdleInhibit {}
                    }

                    BlackoutCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                    }

                    GameModeCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: recorderCard.active || weatherCard.active
                    spacing: Tokens.spacing.medium

                    Loader {
                        id: recorderCard
                        objectName: "overviewRecorder"

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 0
                        active: Config.utilities.cards.recorder
                        visible: active
                        z: 1

                        sourceComponent: Record {
                            props: root.props
                            screenState: root.screenState
                        }
                    }

                    Loader {
                        id: weatherCard
                        objectName: "overviewWeather"

                        Layout.fillWidth: !recorderCard.active
                        Layout.fillHeight: true
                        Layout.preferredWidth: root.weatherCardWidth
                        active: Config.dashboard.showWeather
                        visible: active

                        sourceComponent: WeatherCard {}
                    }
                }
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
