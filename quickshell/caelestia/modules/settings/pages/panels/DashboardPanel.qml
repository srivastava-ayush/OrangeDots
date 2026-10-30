pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.settings.common

PageBase {
    id: root

    title: qsTr("Dashboard")
    isSubPage: true

    readonly property list<MenuItem> weatherUnits: [
        MenuItem { text: qsTr("Celsius (°C)") },
        MenuItem { text: qsTr("Fahrenheit (°F)") }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Ref {
            service: Weather
        }

        // General
        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            first: true
            text: qsTr("Enabled")
            checked: Config.dashboard.enabled
            onToggled: GlobalConfig.dashboard.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Show on hover")
            subtext: qsTr("Reveal when the cursor reaches the screen edge")
            checked: Config.dashboard.showOnHover
            onToggled: GlobalConfig.dashboard.showOnHover = checked
        }

        SectionHeader {
            text: qsTr("Size")
        }

        StepperRow {
            objectName: "dashboardScale"
            first: true
            label: qsTr("Dashboard scale (%)")
            subtext: qsTr("Scale text and controls together · automatically limited to fit the screen")
            value: Config.dashboard.scale
            from: 60
            to: 140
            stepSize: 5
            onMoved: value => GlobalConfig.dashboard.scale = value
        }

        RowButton {
            objectName: "dashboardScaleReset"
            last: true
            icon: "restart_alt"
            text: qsTr("Reset size to 100%")
            onClicked: GlobalConfig.dashboard.scale = 100
        }

        // Tabs
        SectionHeader {
            text: qsTr("Tabs")
        }

        ToggleRow {
            first: true
            text: qsTr("Dashboard")
            checked: Config.dashboard.showDashboard
            onToggled: GlobalConfig.dashboard.showDashboard = checked
        }

        ToggleRow {
            text: qsTr("Media")
            checked: Config.dashboard.showMedia
            onToggled: GlobalConfig.dashboard.showMedia = checked
        }

        ToggleRow {
            text: qsTr("Performance")
            checked: Config.dashboard.showPerformance
            onToggled: GlobalConfig.dashboard.showPerformance = checked
        }

        NavRow {
            objectName: "dashboardCalendarSettings"
            last: true
            icon: "event_note"
            text: qsTr("Calendar & notes")
            subtext: Config.sidebar.enabled ? qsTr("Google Calendar agenda and scratchpad") : qsTr("Disabled")
            onClicked: root.nState.openSubPage(4)
        }

        SectionHeader {
            text: qsTr("Utilities")
        }

        NavRow {
            objectName: "dashboardUtilities"
            first: true
            last: true
            icon: "construction"
            text: qsTr("Utilities")
            subtext: qsTr("Dashboard utility cards and overview hot corner")
            onClicked: root.nState.openSubPage(5)
        }

        SectionHeader {
            text: qsTr("Weather")
        }

        ToggleRow {
            first: true
            text: qsTr("Show weather")
            subtext: qsTr("Display a weather card beside the screen recorder")
            checked: Config.dashboard.showWeather
            onToggled: GlobalConfig.dashboard.showWeather = checked
        }

        TextFieldRow {
            label: qsTr("Location")
            subtext: qsTr("City name, or latitude, longitude for an exact location")
            placeholderText: qsTr("London or 51.51, -0.13")
            maximumLength: 128
            value: GlobalConfig.services.weatherLocation
            onEditingFinished: value => GlobalConfig.services.weatherLocation = value.trim()
        }

        SelectRow {
            label: qsTr("Weather units")
            subtext: qsTr("Temperature and wind speed; system temperatures are separate")
            menuItems: root.weatherUnits
            active: root.weatherUnits[GlobalConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheit = root.weatherUnits.indexOf(item) === 1
        }

        StepperRow {
            label: qsTr("Refresh interval")
            subtext: qsTr("Minutes between updates while weather is displayed")
            value: Weather.refreshMinutes
            from: 5
            to: 180
            stepSize: 5
            onMoved: value => Weather.refreshMinutes = value
        }

        InfoRow {
            label: qsTr("Resolved location")
            value: Weather.locationName || qsTr("Not set")
            subtext: qsTr("No automatic location tracking · data from Open-Meteo")
        }

        RowButton {
            icon: "refresh"
            text: Weather.loading ? qsTr("Updating weather…") : qsTr("Refresh weather now")
            subtext: Weather.hasData ? qsTr("Last updated %1").arg(Qt.formatTime(Weather.updatedAt, GlobalConfig.services.useTwelveHourClock ? "hh:mm a" : "HH:mm")) : qsTr("No API key required")
            disabled: Weather.loading || !Weather.locationQuery
            onClicked: Weather.refresh()
        }

        RowButton {
            objectName: "weatherDataLicense"
            last: true
            icon: "open_in_new"
            text: qsTr("Weather data & license")
            subtext: qsTr("Open-Meteo · CC BY 4.0")
            onClicked: Qt.openUrlExternally("https://open-meteo.com/en/licence")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.margins: Tokens.padding.small
            visible: Weather.error.length > 0
            text: Weather.error
            color: Colours.palette.m3error
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        // Performance widgets
        SectionHeader {
            text: qsTr("Performance widgets")
        }

        ToggleRow {
            first: true
            text: qsTr("Battery")
            checked: Config.dashboard.performance.showBattery
            onToggled: GlobalConfig.dashboard.performance.showBattery = checked
        }

        ToggleRow {
            text: qsTr("GPU")
            checked: Config.dashboard.performance.showGpu
            onToggled: GlobalConfig.dashboard.performance.showGpu = checked
        }

        ToggleRow {
            text: qsTr("CPU")
            checked: Config.dashboard.performance.showCpu
            onToggled: GlobalConfig.dashboard.performance.showCpu = checked
        }

        ToggleRow {
            text: qsTr("Memory")
            checked: Config.dashboard.performance.showMemory
            onToggled: GlobalConfig.dashboard.performance.showMemory = checked
        }

        ToggleRow {
            text: qsTr("Storage")
            checked: Config.dashboard.performance.showStorage
            onToggled: GlobalConfig.dashboard.performance.showStorage = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Network")
            checked: Config.dashboard.performance.showNetwork
            onToggled: GlobalConfig.dashboard.performance.showNetwork = checked
        }

        // Behaviour
        SectionHeader {
            text: qsTr("Behaviour")
        }

        StepperRow {
            first: true
            last: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the dashboard opens")
            value: Config.dashboard.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.dashboard.dragThreshold = v
        }
    }
}
