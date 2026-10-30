pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.settings

StyledRect {
    id: root

    implicitHeight: Math.max(232, layout.implicitHeight + Tokens.padding.large * 2)
    radius: Tokens.rounding.extraLarge
    color: Colours.tPalette.m3surfaceContainer

    Ref { service: Weather }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: Weather.locationName || qsTr("Weather")
                font: Tokens.font.title.small
                elide: Text.ElideRight
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
                onClicked: SettingsWindows.openDashboardSettings()
            }
        }

        ColumnLayout {
            objectName: "overviewWeatherConditions"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Weather.hasData
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    objectName: "overviewWeatherTemperature"
                    text: Weather.temperature(Weather.weather?.temperature)
                    font: Tokens.font.headline.large
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

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
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                MaterialIcon {
                    text: Weather.condition(Weather.weather?.code ?? -1, Weather.weather?.isDay ?? true).icon
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.extraLarge
                }
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
                    text: Weather.weather?.humidity == null ? "—" : `${Weather.weather.humidity}%`
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                Item { Layout.preferredWidth: Tokens.spacing.small }

                MaterialIcon {
                    text: "air"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Weather.wind(Weather.weather?.windSpeed)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall
                Layout.bottomMargin: Tokens.spacing.extraSmall
                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            RowLayout {
                objectName: "overviewWeatherForecast"
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: Weather.hasData ? Weather.weather.days : []

                    ColumnLayout {
                        id: day
                        objectName: "overviewWeatherForecastDay"
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            Layout.fillWidth: true
                            text: day.index === 0 ? qsTr("Today") : Qt.formatDate(new Date(`${day.modelData.date}T12:00:00`), "ddd")
                            font: Tokens.font.label.small
                            color: Colours.palette.m3onSurfaceVariant
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
                            text: `${Weather.temperature(day.modelData.high, false)} / ${Weather.temperature(day.modelData.low, false)}`
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: day.modelData.rainChance == null ? "—" : qsTr("%1% rain").arg(day.modelData.rainChance)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: Weather.error.length > 0
                text: qsTr("Update failed · showing saved forecast")
                color: Colours.palette.m3error
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        ColumnLayout {
            objectName: "overviewWeatherStatus"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !Weather.hasData
            spacing: Tokens.spacing.small

            Item { Layout.fillHeight: true }

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.loading ? "cloud_sync" : Weather.error ? "cloud_off" : "partly_cloudy_day"
                color: Colours.palette.m3primary
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.loading ? qsTr("Fetching weather…") : Weather.error || qsTr("Choose a location in weather settings")
                color: Weather.error ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }
        }
    }
}
