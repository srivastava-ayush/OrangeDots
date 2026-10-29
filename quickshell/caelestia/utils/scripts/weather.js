.pragma library

function isNumber(value) {
    return typeof value === "number" && isFinite(value);
}

function coordinates(query) {
    const match = query.trim().match(/^([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*,\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+))$/);
    if (!match)
        return null;

    const latitude = Number(match[1]);
    const longitude = Number(match[2]);
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)
        throw new Error(qsTr("Latitude must be between -90 and 90, and longitude between -180 and 180."));

    return { latitude, longitude, name: query.trim() };
}

function geocodingUrl(query) {
    return "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query.trim()) + "&count=1&language=en&format=json";
}

function resolveLocation(response) {
    const place = response?.results?.[0];
    if (!place || !isNumber(place.latitude) || !isNumber(place.longitude) || Math.abs(place.latitude) > 90 || Math.abs(place.longitude) > 180)
        throw new Error(qsTr("Location not found. Try a city name or latitude, longitude."));

    return {
        latitude: place.latitude,
        longitude: place.longitude,
        name: [place.name, place.country].filter(Boolean).join(", ")
    };
}

function forecastUrl(location) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + location.latitude + "&longitude=" + location.longitude
        + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
        + "&temperature_unit=celsius&wind_speed_unit=kmh&forecast_days=3&timezone=auto";
}

function forecast(response) {
    if (response?.error || !isNumber(response?.current?.temperature_2m))
        throw new Error(qsTr("The weather provider returned an invalid forecast."));

    const current = response.current;
    const daily = response.daily ?? {};
    const days = Array.isArray(daily.time) ? daily.time : [];
    return {
        temperature: current.temperature_2m,
        feelsLike: isNumber(current.apparent_temperature) ? current.apparent_temperature : null,
        humidity: isNumber(current.relative_humidity_2m) ? current.relative_humidity_2m : null,
        windSpeed: isNumber(current.wind_speed_10m) ? current.wind_speed_10m : null,
        code: isNumber(current.weather_code) ? current.weather_code : -1,
        isDay: current.is_day !== 0,
        days: days.slice(0, 3).map((date, index) => ({
            date,
            code: isNumber(daily.weather_code?.[index]) ? daily.weather_code[index] : -1,
            high: isNumber(daily.temperature_2m_max?.[index]) ? daily.temperature_2m_max[index] : null,
            low: isNumber(daily.temperature_2m_min?.[index]) ? daily.temperature_2m_min[index] : null,
            rainChance: isNumber(daily.precipitation_probability_max?.[index]) ? daily.precipitation_probability_max[index] : null
        })).filter(day => /^\d{4}-\d{2}-\d{2}$/.test(day.date))
    };
}

function temperature(value, fahrenheit, includeUnit) {
    if (!isNumber(value))
        return "—";
    const rounded = Math.round(fahrenheit ? value * 9 / 5 + 32 : value);
    return rounded + "°" + (includeUnit ? fahrenheit ? "F" : "C" : "");
}

function wind(value, fahrenheit) {
    if (!isNumber(value))
        return "—";
    return Math.round(fahrenheit ? value / 1.609344 : value) + (fahrenheit ? " mph" : " km/h");
}

function condition(code, isDay) {
    switch (code) {
    case 0: return { text: qsTr("Clear sky"), icon: isDay ? "sunny" : "bedtime" };
    case 1: return { text: qsTr("Mostly clear"), icon: isDay ? "partly_cloudy_day" : "partly_cloudy_night" };
    case 2: return { text: qsTr("Partly cloudy"), icon: isDay ? "partly_cloudy_day" : "partly_cloudy_night" };
    case 3: return { text: qsTr("Overcast"), icon: "cloud" };
    case 45: case 48: return { text: qsTr("Fog"), icon: "foggy" };
    case 51: case 53: case 55: return { text: qsTr("Drizzle"), icon: "rainy_light" };
    case 56: case 57: return { text: qsTr("Freezing drizzle"), icon: "weather_mix" };
    case 61: case 63: case 65: return { text: qsTr("Rain"), icon: "rainy" };
    case 66: case 67: return { text: qsTr("Freezing rain"), icon: "weather_mix" };
    case 71: case 73: case 75: case 77: return { text: qsTr("Snow"), icon: "weather_snowy" };
    case 80: case 81: case 82: return { text: qsTr("Rain showers"), icon: "rainy" };
    case 85: case 86: return { text: qsTr("Snow showers"), icon: "weather_snowy" };
    case 95: case 96: case 99: return { text: qsTr("Thunderstorm"), icon: "thunderstorm" };
    default: return { text: qsTr("Unknown conditions"), icon: "cloud" };
    }
}
