pragma ComponentBehavior: Bound

import "dash"
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

    required property ScreenState screenState
    required property FileDialog facePicker

    // Shared UI state for the recorder card and its recording list
    readonly property var props: dashProps

    PersistentProperties {
        id: dashProps

        property bool recordingListExpanded
        property string recordingConfirmDelete

        reloadableId: "dashboard-recording"
    }

    // Floor for the top row so the user card keeps a sane height; the row
    // grows beyond it when the utility, recorder, or weather cards need more room.
    readonly property int topRowHeight: 352

    // Extra width beyond the content sum so the dash reads as a rectangle
    // and the three utility toggles have room for their labels.
    readonly property int extraWidth: 480

    // Give the horizontal forecast more room within the existing dashboard;
    // the recorder uses the remaining width and adapts its header.
    readonly property int weatherCardWidth: Math.max(420, Tokens.sizes.dashboard.weatherWidth)

    implicitWidth: Tokens.sizes.dashboard.userWidth + Tokens.sizes.dashboard.weatherWidth + Tokens.spacing.medium * 3 + root.extraWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            id: row
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(root.topRowHeight, utilCards.implicitHeight)
            spacing: Tokens.spacing.medium

            Rect {
                Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
                Layout.fillHeight: true

                radius: Tokens.rounding.extraLarge

                User {
                    screenState: root.screenState
                    facePicker: root.facePicker
                }
            }

            ColumnLayout {
                id: utilCards

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.medium

                RowLayout {
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
                    visible: recorderCard.active || weatherCard.active
                    spacing: Tokens.spacing.medium

                    Loader {
                        id: recorderCard

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
