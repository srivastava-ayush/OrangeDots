pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Shell tint")
    isSubPage: true

    readonly property var presets: [
        { name: qsTr("VOID"), colour: "#000000", strength: 1 },
        { name: qsTr("Graphite"), colour: "#242424" },
        { name: qsTr("Navy"), colour: "#243447" },
        { name: qsTr("Teal"), colour: "#173f3b" },
        { name: qsTr("Plum"), colour: "#422b42" },
        { name: qsTr("Brown"), colour: "#49362b" },
        { name: qsTr("Olive"), colour: "#353e28" },
        { name: qsTr("Slate"), colour: "#455268" },
        { name: qsTr("Cream"), colour: "#e8ddc5" }
    ]

    function applyPreset(preset: var): void {
        ShellTint.setColour(preset.colour);
        if (preset.strength !== undefined)
            ShellTint.strength = preset.strength;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Shell background")
        }

        ToggleRow {
            objectName: "shellTintEnabled"
            first: true
            text: qsTr("Custom shell tint")
            subtext: qsTr("Tint the taskbar, popouts, dashboard and other shell backgrounds")
            checked: ShellTint.enabled
            onToggled: ShellTint.enabled = checked
        }

        TextFieldRow {
            objectName: "shellTintColour"
            label: qsTr("Tint colour")
            subtext: qsTr("Any hex colour, such as #243447 or #345")
            errorText: qsTr("Use #RRGGBB or #RGB")
            placeholderText: "#243447"
            maximumLength: 7
            value: ShellTint.colour
            validate: value => ShellTint.normaliseColour(value).length > 0
            onEditingFinished: value => ShellTint.setColour(value)
        }

        SliderRow {
            objectName: "shellTintStrength"
            last: true
            icon: "opacity"
            label: qsTr("Tint strength")
            valueLabel: `${Math.round(ShellTint.strength * 100)}%`
            value: ShellTint.strength
            enabled: ShellTint.enabled
            onMoved: value => ShellTint.strength = value
        }

        SectionHeader {
            text: qsTr("Preset colours")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: root.presets

                StyledRect {
                    id: swatch

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: Tokens.rounding.medium
                    color: modelData.colour
                    border.width: ShellTint.enabled && ShellTint.colour === modelData.colour ? 2 : 0
                    border.color: Colours.on(color)
                    Accessible.name: modelData.name

                    StyledText {
                        anchors.centerIn: parent
                        text: swatch.modelData.name
                        color: Colours.on(swatch.color)
                        font: Tokens.font.label.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyPreset(swatch.modelData)
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("Custom colour")
        }

        SliderRow {
            objectName: "shellTintRed"
            first: true
            icon: "palette"
            label: qsTr("Red")
            value: ShellTint.colourValue.r
            valueLabel: Math.round(value * 255)
            onMoved: value => ShellTint.setChannel("r", value)
        }

        SliderRow {
            objectName: "shellTintGreen"
            icon: "palette"
            label: qsTr("Green")
            value: ShellTint.colourValue.g
            valueLabel: Math.round(value * 255)
            onMoved: value => ShellTint.setChannel("g", value)
        }

        SliderRow {
            objectName: "shellTintBlue"
            last: true
            icon: "palette"
            label: qsTr("Blue")
            value: ShellTint.colourValue.b
            valueLabel: Math.round(value * 255)
            onMoved: value => ShellTint.setChannel("b", value)
        }

        SectionHeader {
            text: qsTr("Live preview")
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 110
            color: Colours.tPalette.m3surface
            radius: Tokens.rounding.extraLarge

            RowLayout {
                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Shell background")
                    color: Colours.palette.m3onSurface
                }

                Repeater {
                    model: [Colours.tPalette.m3surfaceContainerLow, Colours.tPalette.m3surfaceContainer, Colours.tPalette.m3surfaceContainerHigh]

                    StyledRect {
                        required property color modelData

                        implicitWidth: 42
                        implicitHeight: 42
                        radius: Tokens.rounding.medium
                        color: modelData
                    }
                }
            }
        }

        InfoRow {
            first: true
            label: qsTr("Wallpaper theme")
            value: Colours.scheme || qsTr("Current theme")
            subtext: qsTr("Accent colours stay theme-based. Transparency is controlled separately.")
        }

        RowButton {
            objectName: "shellTintReset"
            last: true
            icon: "restart_alt"
            text: qsTr("Reset shell tint")
            subtext: qsTr("Restore the wallpaper-derived shell backgrounds")
            onClicked: ShellTint.reset()
        }
    }
}
