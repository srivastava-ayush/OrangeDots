pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus

StyledRect {
    id: root

    implicitHeight: Math.max(208, layout.implicitHeight + Tokens.padding.large * 2)
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    Ref {
        service: Weather
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Weather")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.locationName || qsTr("Choose a location")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                icon: "refresh"
                type: IconButton.Text
                disabled: Weather.loading || !Weather.locationQuery
                onClicked: Weather.refresh()
            }

            IconButton {
                icon: "settings"
                type: IconButton.Text
                onClicked: WindowFactory.openDashboardSettings()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Weather.hasData
            spacing: Tokens.spacing.medium

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: Weather.condition(Weather.weather?.code ?? -1, Weather.weather?.isDay ?? true).icon
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Weather.temperature(Weather.weather?.temperature)
                        font: Tokens.font.headline.medium
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.condition(Weather.weather?.code ?? -1, Weather.weather?.isDay ?? true).text
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Feels like %1").arg(Weather.temperature(Weather.weather?.feelsLike))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        text: "humidity_percentage"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        text: Weather.weather?.humidity === null || !Weather.hasData ? "—" : `${Weather.weather.humidity}%`
                        font: Tokens.font.body.small
                    }

                    MaterialIcon {
                        text: "air"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Weather.wind(Weather.weather?.windSpeed)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.small

                Repeater {
                    model: Weather.hasData ? Weather.weather.days : []

                    ColumnLayout {
                        id: day

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.fillWidth: true
                            text: day.index === 0 ? qsTr("Today") : Qt.formatDate(new Date(`${day.modelData.date}T12:00:00`), "ddd")
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: Weather.condition(day.modelData.code).icon
                            color: Colours.palette.m3secondary
                            fontStyle: Tokens.font.icon.medium
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: `${Weather.temperature(day.modelData.high, false)}/${Weather.temperature(day.modelData.low, false)}`
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Tokens.spacing.extraSmall / 2

                            MaterialIcon {
                                text: "water_drop"
                                color: Colours.palette.m3onSurfaceVariant
                                fontStyle: Tokens.font.icon.builders.small.scale(0.65).build()
                            }

                            StyledText {
                                text: day.modelData.rainChance === null ? "—" : `${day.modelData.rainChance}%`
                                color: Colours.palette.m3onSurfaceVariant
                                font: Tokens.font.label.small
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Weather.hasData
            spacing: Tokens.spacing.medium

            Item {
                Layout.fillHeight: true
            }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.loading ? "cloud_sync" : Weather.error ? "cloud_off" : "partly_cloudy_day"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.loading ? qsTr("Fetching weather…") : Weather.error || qsTr("Set your location in Nexus → Panels → Dashboard.")
                color: Weather.error ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item {
                Layout.fillHeight: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                visible: Weather.hasData
                text: Weather.loading ? qsTr("Updating…") : Weather.error ? qsTr("Update failed · cached forecast") : qsTr("Updated %1").arg(Qt.formatTime(Weather.updatedAt, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "HH:mm"))
                color: Weather.error ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }

            StyledText {
                text: "<a href=\"https://open-meteo.com/\">Open-Meteo</a> · CC BY 4.0"
                textFormat: Text.StyledText
                linkColor: Colours.palette.m3primary
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
        }
    }
}
