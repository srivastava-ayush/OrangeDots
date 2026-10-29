pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils
import "../utils/scripts/weather.js" as WeatherData

Singleton {
    id: root

    property int refCount: 0
    property int refreshMinutes: 30
    property bool loading: false
    property string error: ""
    property var weather: null
    property date updatedAt: new Date(0)

    readonly property string locationQuery: GlobalConfig.services.weatherLocation.trim()
    readonly property bool useFahrenheit: GlobalConfig.services.useFahrenheit
    readonly property bool hasData: weather !== null && dataQuery === locationQuery
    readonly property string locationName: resolvedQuery === locationQuery ? resolvedLocation?.name ?? locationQuery : locationQuery
    readonly property bool active: ready && settingsLoaded && refCount > 0 && locationQuery.length > 0

    property bool ready: false
    property bool settingsLoaded: false
    property string dataQuery: ""
    property string resolvedQuery: ""
    property var resolvedLocation: null
    property var request: null
    property int requestId: 0

    function temperature(value: var, includeUnit = true): string {
        return WeatherData.temperature(value, useFahrenheit, includeUnit);
    }

    function wind(value: var): string {
        return WeatherData.wind(value, useFahrenheit);
    }

    function condition(code: int, isDay = true): var {
        return WeatherData.condition(code, isDay);
    }

    function cancel(): void {
        requestId++;
        requestTimeout.stop();
        const previous = request;
        request = null;
        if (previous)
            previous.abort();
        loading = false;
    }

    function fail(message: string): void {
        cancel();
        error = message;
    }

    function get(url: string, generation: int, callback: var): void {
        const xhr = new XMLHttpRequest();
        request = xhr;
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || generation !== root.requestId)
                return;

            requestTimeout.stop();
            root.request = null;
            if (xhr.status < 200 || xhr.status >= 300) {
                root.fail(qsTr("Unable to reach the weather provider. Check your connection and retry."));
                return;
            }

            try {
                callback(JSON.parse(xhr.responseText));
            } catch (error) {
                root.fail(error.message || qsTr("Unable to read the weather response."));
            }
        };
        xhr.open("GET", url);
        requestTimeout.restart();
        xhr.send();
    }

    function fetchForecast(location: var, generation: int): void {
        get(WeatherData.forecastUrl(location), generation, response => {
            root.weather = WeatherData.forecast(response);
            root.dataQuery = root.locationQuery;
            root.updatedAt = new Date();
            root.error = "";
            root.loading = false;
        });
    }

    function refresh(): void {
        if (!active)
            return;

        cancel();
        error = "";
        loading = true;
        const generation = requestId;

        try {
            if (resolvedQuery === locationQuery && resolvedLocation) {
                fetchForecast(resolvedLocation, generation);
                return;
            }

            const location = WeatherData.coordinates(locationQuery);
            if (location) {
                resolvedLocation = location;
                resolvedQuery = locationQuery;
                fetchForecast(location, generation);
            } else {
                get(WeatherData.geocodingUrl(locationQuery), generation, response => {
                    root.resolvedLocation = WeatherData.resolveLocation(response);
                    root.resolvedQuery = root.locationQuery;
                    root.fetchForecast(root.resolvedLocation, generation);
                });
            }
        } catch (error) {
            fail(error.message);
        }
    }

    function refreshIfStale(): void {
        if (active && !loading && (!hasData || Date.now() - updatedAt.getTime() >= refreshMinutes * 60000))
            refreshSoon.restart();
    }

    onActiveChanged: {
        if (active) {
            refreshIfStale();
        } else {
            refreshSoon.stop();
            cancel();
        }
    }

    onLocationQueryChanged: {
        cancel();
        weather = null;
        error = "";
        resolvedLocation = null;
        resolvedQuery = "";
        refreshIfStale();
    }

    onRefreshMinutesChanged: {
        if (settingsLoaded)
            saveSettings.restart();
    }

    Component.onCompleted: ready = true
    Component.onDestruction: cancel()

    Timer {
        id: refreshSoon

        interval: 250
        onTriggered: root.refresh()
    }

    Timer {
        interval: root.refreshMinutes * 60000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: requestTimeout

        interval: 15000
        onTriggered: root.fail(qsTr("Weather request timed out. Try refreshing again."))
    }

    Timer {
        id: saveSettings

        interval: 250
        onTriggered: settingsFile.setText(JSON.stringify({ refreshMinutes: root.refreshMinutes }))
    }

    // Reuse the native weather location/unit/visibility options. Keep the new
    // polling preference in its own file so this feature needs no plugin rebuild.
    FileView {
        id: settingsFile

        path: `${Paths.config}/weather.json`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.settingsLoaded = false;
            try {
                const settings = JSON.parse(text());
                if (Number.isInteger(settings.refreshMinutes))
                    root.refreshMinutes = Math.max(5, Math.min(180, settings.refreshMinutes));
            } catch (error) {
                console.warn("Weather: unable to read refresh settings; using the current interval");
            }
            root.settingsLoaded = true;
        }
        onLoadFailed: root.settingsLoaded = true
    }
}
