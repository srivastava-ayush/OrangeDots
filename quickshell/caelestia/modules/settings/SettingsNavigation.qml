import "navpane"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings

ColumnLayout {
    id: root

    required property SettingsState nState

    spacing: Tokens.spacing.large

    SearchBar {
        id: searchField

        objectName: "settingsSearch"
        Layout.fillWidth: true

        placeholderText: qsTr("Search settings")
        font: Tokens.font.body.large

        bg.color: Colours.tPalette.m3surfaceContainerLowest
        bg.border.color: Colours.palette.m3outlineVariant
        searchIcon.fontStyle: Tokens.font.icon.medium
        searchIcon.anchors.leftMargin: Tokens.padding.largeIncreased
        clearIcon.font: Tokens.font.icon.medium
        clearIcon.padding: Tokens.padding.extraSmall

        Behavior on bg.border.color {
            CAnim {}
        }

        Binding {
            target: searchField
            property: "text"
            value: root.nState.searchQuery
        }

        onTextChanged: {
            if (text !== root.nState.searchQuery)
                root.nState.searchQuery = text;
        }
    }

    NavLocations {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: -topMargin
        Layout.bottomMargin: -bottomMargin
        nState: root.nState
    }
}
