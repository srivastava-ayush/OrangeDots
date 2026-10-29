const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");
const vm = require("node:vm");

// QML's library pragma is the only non-JavaScript line in the shared helper.
const source = fs.readFileSync(path.join(__dirname, "../utils/scripts/weather.js"), "utf8").replace(/^\.pragma library\r?\n/, "");
const weather = vm.createContext({ qsTr: text => text });
vm.runInContext(source, weather);

function fixture() {
    return {
        current: {
            temperature_2m: 0,
            apparent_temperature: -2,
            relative_humidity_2m: 75,
            wind_speed_10m: 16.09344,
            weather_code: 0,
            is_day: 0
        },
        daily: {
            time: ["2026-10-27", "2026-10-28", "2026-10-29"],
            weather_code: [0, 61, 71],
            temperature_2m_max: [3, 5, null],
            temperature_2m_min: [-2, 0, null],
            precipitation_probability_max: [0, 80, null]
        }
    };
}

test("coordinates accept zero, signed decimals, and boundary values", () => {
    assert.equal(weather.coordinates("0, 0").latitude, 0);
    assert.equal(weather.coordinates(" -.5, +77.25 ").longitude, 77.25);
    assert.equal(weather.coordinates("-90, 180").latitude, -90);
    assert.equal(weather.coordinates("London"), null);
});

test("coordinates reject out-of-range values instead of geocoding them", () => {
    assert.throws(() => weather.coordinates("91, 0"), /Latitude/);
    assert.throws(() => weather.coordinates("0, -181"), /longitude/);
});

test("geocoding handles a city and rejects empty or malformed results", () => {
    const location = weather.resolveLocation({ results: [{ name: "London", country: "United Kingdom", latitude: 51.5, longitude: -0.1 }] });
    assert.equal(location.name, "London, United Kingdom");
    assert.equal(location.longitude, -0.1);
    assert.throws(() => weather.resolveLocation({}), /Location not found/);
    assert.throws(() => weather.resolveLocation({ results: [] }), /Location not found/);
    assert.throws(() => weather.resolveLocation({ results: [{ latitude: null, longitude: 0 }] }), /Location not found/);
    assert.throws(() => weather.resolveLocation({ results: [{ latitude: 100, longitude: 0 }] }), /Location not found/);
});

test("API URLs encode city queries and explicitly request Celsius, km/h, and three days", () => {
    const geocoding = new URL(weather.geocodingUrl(" São Paulo & coast "));
    assert.equal(geocoding.searchParams.get("name"), "São Paulo & coast");
    const forecast = new URL(weather.forecastUrl(weather.coordinates("0, 0")));
    assert.equal(forecast.searchParams.get("latitude"), "0");
    assert.equal(forecast.searchParams.get("temperature_unit"), "celsius");
    assert.equal(forecast.searchParams.get("wind_speed_unit"), "kmh");
    assert.equal(forecast.searchParams.get("forecast_days"), "3");
});

test("forecast keeps valid zero values and does not turn missing data into zero", () => {
    const data = weather.forecast(fixture());
    assert.equal(data.temperature, 0);
    assert.equal(data.isDay, false);
    assert.equal(data.days[0].rainChance, 0);
    assert.equal(data.days[1].low, 0);
    assert.equal(data.days[2].high, null);
    assert.equal(data.days[2].rainChance, null);
});

test("forecast rejects missing current conditions and provider errors", () => {
    for (const response of [{}, { current: { temperature_2m: null } }, { current: { temperature_2m: "10" } }, { error: true }])
        assert.throws(() => weather.forecast(response), /invalid forecast/);
});

test("forecast permits missing daily or optional fields", () => {
    const data = weather.forecast({ current: { temperature_2m: 12 } });
    assert.equal(data.feelsLike, null);
    assert.equal(data.humidity, null);
    assert.equal(data.windSpeed, null);
    assert.equal(data.code, -1);
    assert.equal(data.days.length, 0);
});

test("filtering a malformed forecast date preserves the other days' data", () => {
    const response = fixture();
    response.daily.time[0] = "invalid";
    const data = weather.forecast(response);
    assert.equal(data.days[0].date, "2026-10-28");
    assert.equal(data.days[0].code, 61);
    assert.equal(data.days[0].rainChance, 80);
});

test("malformed optional forecast values use placeholders instead of coercion", () => {
    const response = fixture();
    response.current.relative_humidity_2m = "75";
    response.daily.weather_code[0] = "0";
    response.daily.temperature_2m_min[0] = "-2";
    const data = weather.forecast(response);
    assert.equal(data.humidity, null);
    assert.equal(data.days[0].code, -1);
    assert.equal(data.days[0].low, null);
});

test("temperature and wind units convert locally, with missing-value placeholders", () => {
    assert.equal(weather.temperature(0, false, true), "0°C");
    assert.equal(weather.temperature(0, true, true), "32°F");
    assert.equal(weather.temperature(-40, true, false), "-40°");
    assert.equal(weather.temperature(null, true, true), "—");
    assert.equal(weather.temperature(undefined, false, true), "—");
    assert.equal(weather.wind(16.09344, true), "10 mph");
    assert.equal(weather.wind(16.09344, false), "16 km/h");
    assert.equal(weather.wind(null, false), "—");
});

test("all Open-Meteo WMO condition codes have a description and icon", () => {
    const codes = [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99];
    for (const code of codes) {
        const condition = weather.condition(code, true);
        assert.notEqual(condition.text, "Unknown conditions");
        assert.ok(condition.icon);
    }
    assert.equal(weather.condition(0, false).icon, "bedtime");
    assert.equal(weather.condition(2, false).icon, "partly_cloudy_night");
    assert.equal(weather.condition(999, true).text, "Unknown conditions");
});
