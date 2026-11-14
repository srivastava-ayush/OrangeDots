pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Colours")
    isSubPage: true

    property var schemeEntries: []
    property string variant: ""
    readonly property bool loading: schemesProcess.running
    readonly property int variantIndex: variantValues.indexOf(variant)

    readonly property var variantValues: ["tonalspot", "vibrant", "expressive", "fidelity", "fruitsalad", "monochrome", "neutral", "rainbow", "content"]
    readonly property list<MenuItem> variantItems: [
        MenuItem {
            text: qsTr("Tonal spot")
        },
        MenuItem {
            text: qsTr("Vibrant")
        },
        MenuItem {
            text: qsTr("Expressive")
        },
        MenuItem {
            text: qsTr("Fidelity")
        },
        MenuItem {
            text: qsTr("Fruit salad")
        },
        MenuItem {
            text: qsTr("Monochrome")
        },
        MenuItem {
            text: qsTr("Neutral")
        },
        MenuItem {
            text: qsTr("Rainbow")
        },
        MenuItem {
            text: qsTr("Content")
        }
    ]

    function applyScheme(name: string, flavour: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "-n", name, "-f", flavour]);
    }

    function applyVariant(value: string): void {
        root.variant = value;
        Quickshell.execDetached(["caelestia", "scheme", "set", "-v", value]);
    }

    function loadSchemes(text: string): void {
        try {
            const data = JSON.parse(text);
            const entries = [];
            for (const [name, flavours] of Object.entries(data))
                for (const [flavour, colours] of Object.entries(flavours))
                    entries.push({ name, flavour, colours });

            entries.sort((a, b) => `${a.name} ${a.flavour}`.localeCompare(`${b.name} ${b.flavour}`));
            root.schemeEntries = entries;
        } catch (e) {
            console.warn(logCat, "Failed to parse the scheme list", e);
        }
    }

    Component.onCompleted: getVariant.running = true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: schemesProcess

            running: true
            command: ["caelestia", "scheme", "list"]
            stdout: StdioCollector {
                onStreamFinished: root.loadSchemes(text)
            }
        }

        Process {
            id: getVariant

            command: ["caelestia", "scheme", "get", "-v"]
            stdout: StdioCollector {
                onStreamFinished: root.variant = text.trim()
            }
        }

        LoggingCategory {
            id: logCat

            name: "caelestia.nexus"
            defaultLogLevel: LoggingCategory.Info
        }

        SectionHeader {
            first: true
            text: qsTr("Current theme")
        }

        InfoRow {
            first: true
            label: qsTr("Scheme")
            value: Colours.scheme || qsTr("Loading…")
            subtext: Colours.flavour ? qsTr("Flavour: %1").arg(Colours.flavour) : qsTr("Set by the wallpaper or scheme picker")
        }

        ToggleRow {
            objectName: "coloursDarkMode"
            text: qsTr("Dark theme")
            subtext: qsTr("Switch the active scheme between dark and light")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        SelectRow {
            objectName: "coloursVariant"
            last: true
            label: qsTr("Scheme variant")
            subtext: qsTr("Controls how accent colours are generated")
            menuItems: root.variantItems
            active: root.variantIndex >= 0 ? root.variantItems[root.variantIndex] : null
            fallbackText: root.variant || qsTr("Loading…")
            onSelected: item => root.applyVariant(root.variantValues[root.variantItems.indexOf(item)])
        }

        SectionHeader {
            text: qsTr("Scheme library")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: root.schemeEntries

                StyledRect {
                    id: tile

                    required property var modelData

                    readonly property bool current: modelData.name === Colours.scheme && modelData.flavour === Colours.flavour

                    Layout.fillWidth: true
                    implicitHeight: 74
                    color: Colours.tPalette.m3surfaceContainer
                    radius: Tokens.rounding.large
                    border.width: current ? 2 : 0
                    border.color: Colours.palette.m3primary

                    StateLayer {
                        onClicked: root.applyScheme(tile.modelData.name, tile.modelData.flavour)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        anchors.leftMargin: Tokens.padding.large
                        spacing: Tokens.spacing.medium

                        Row {
                            spacing: Tokens.spacing.extraSmall

                            Repeater {
                                model: [tile.modelData.colours.primary, tile.modelData.colours.secondary, tile.modelData.colours.tertiary]

                                StyledRect {
                                    required property string modelData

                                    implicitWidth: 14
                                    implicitHeight: 34
                                    radius: Tokens.rounding.small
                                    color: `#${modelData}`
                                    border.width: 1
                                    border.color: Qt.alpha(Colours.palette.m3onSurface, 0.08)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: tile.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: tile.modelData.flavour
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: tile.current
                            text: "check_circle"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.schemeEntries.length === 0
            Layout.margins: Tokens.padding.medium
            text: root.loading ? qsTr("Loading available schemes…") : qsTr("No schemes found. Make sure the caelestia CLI is installed.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowButton {
            objectName: "coloursRefresh"
            first: true
            icon: "refresh"
            text: root.loading ? qsTr("Loading schemes…") : qsTr("Refresh scheme list")
            disabled: root.loading
            onClicked: schemesProcess.running = true
        }

        RowButton {
            objectName: "coloursRandom"
            last: true
            icon: "shuffle"
            text: qsTr("Surprise me")
            subtext: qsTr("Switch to a random available scheme")
            onClicked: Quickshell.execDetached(["caelestia", "scheme", "set", "--random"])
        }
    }
}
