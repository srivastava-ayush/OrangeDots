pragma ComponentBehavior: Bound

import "dash"
import "notifications"
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

    readonly property Props props: Props {}

    // Floor for the top row so the user card keeps a sane height; the row
    // grows beyond it when the keep-awake/recorder cards need more room.
    readonly property int topRowHeight: 176

    // Extra width beyond the content sum so the dash reads as a rectangle,
    // not a square. Tune this to taste.
    readonly property int extraWidth: 220

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

                Loader {
                    Layout.fillWidth: true
                    active: Config.utilities.cards.keepAwake
                    visible: active

                    sourceComponent: IdleInhibit {}
                }

                Loader {
                    Layout.fillWidth: true
                    active: Config.utilities.cards.recorder
                    visible: active
                    z: 1

                    sourceComponent: Record {
                        props: root.props
                        screenState: root.screenState
                    }
                }
            }
        }
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
