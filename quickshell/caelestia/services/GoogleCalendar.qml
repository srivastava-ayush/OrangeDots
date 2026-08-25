pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Google Calendar agenda service.
//
// Uses the calendar's "secret address in iCal format" (Calendar settings ->
// "Integrate calendar" -> Secret iCal address) so no OAuth is required.
// Put the URL on a single line in:
//   ~/.config/caelestia/calendar-url
//
// Events overlapping the next 7 days are exposed via `events`, sorted with
// all-day events first. Recurring events appear only at their first
// occurrence (RRULE expansion is not attempted).
Singleton {
    id: root

    // Each item: { start: date, end: date, allDay: bool, summary: string, dayLabel: string }
    readonly property list<var> events: _events
    property list<var> _events: []

    // Human-readable failure reason; empty when everything is fine
    readonly property string error: _error
    property string _error: ""

    readonly property bool urlConfigured: _url.length > 0

    property string _url: ""
    property string _rawIcs: ""

    function refresh(): void {
        urlProc.exec(urlProc.cmdArgs);
    }

    Component.onCompleted: root.refresh()

    on_RawIcsChanged: root._parse()

    Timer {
        interval: 30 * 60 * 1000 // 30 min
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: urlProc

        readonly property list<string> cmdArgs: ["sh", "-c", `cat '${Paths.config}/calendar-url' 2>/dev/null || true`]

        command: cmdArgs
        stdout: StdioCollector {
            onStreamFinished: {
                const url = text.trim();
                if (!url) {
                    root._url = "";
                    root._error = qsTr("Add your Google Calendar secret iCal URL to ~/.config/caelestia/calendar-url");
                    return;
                }
                if (url !== root._url)
                    root._url = url;
                else
                    fetchProc.exec(fetchProc.cmdArgs); // same url, just refetch
            }
        }
    }

    Process {
        id: fetchProc

        property string url

        readonly property list<string> cmdArgs: ["curl", "-sL", "--max-time", "20", url]

        command: cmdArgs
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) {
                    root._error = qsTr("Empty response from Google Calendar");
                    return;
                }
                root._error = "";
                root._rawIcs = text;
            }
        }
    }

    on_UrlChanged: if (_url.length > 0) {
        fetchProc.url = _url;
        fetchProc.exec(fetchProc.cmdArgs);
    }

    function _parse(): void {
        const horizonEnd = new Date();
        horizonEnd.setDate(horizonEnd.getDate() + 7);

        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        const lines = _rawIcs.replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "").split(/\r?\n/);
        const events = [];
        let inEvent = false;
        let subDepth = 0;
        let cancelled = false;
        let start = null;
        let end = null;
        let allDay = false;
        let summary = "";

        for (const line of lines) {
            if (line.startsWith("BEGIN:VEVENT")) {
                inEvent = true;
                subDepth = 0;
                cancelled = false;
                start = end = null;
                allDay = false;
                summary = "";
                continue;
            }
            if (!inEvent)
                continue;

            if (line.startsWith("BEGIN:")) {
                subDepth++; // VALARM etc.
                continue;
            }
            if (line.startsWith("END:")) {
                if (subDepth > 0) {
                    subDepth--;
                    continue;
                }
                // End of VEVENT
                if (!cancelled && start !== null && summary.length > 0) {
                    const evEnd = end ?? (allDay ? _addDays(start, 1) : new Date(start.getTime() + 3600000));
                    if (evEnd > todayStart && start < horizonEnd)
                        events.push({
                            start,
                            end: evEnd,
                            allDay,
                            summary,
                            dayLabel: _dayLabel(start),
                            dayKey: Qt.formatDate(start, "yyyy-MM-dd")
                        });
                }
                inEvent = false;
                continue;
            }
            if (subDepth > 0)
                continue;

            const sep = line.indexOf(":");
            if (sep === -1)
                continue;
            const name = line.slice(0, sep);
            const value = line.slice(sep + 1);

            if (name.startsWith("STATUS") && value === "CANCELLED")
                cancelled = true;
            else if (name.startsWith("SUMMARY"))
                summary = value.replace(/\\,/g, ",").replace(/\\n/gi, " ").replace(/\\\\/g, "\\").trim();
            else if (name.startsWith("DTSTART")) {
                const parsed = _date(value);
                if (parsed) {
                    start = parsed.date;
                    allDay = parsed.allDay;
                }
            } else if (name.startsWith("DTEND")) {
                const parsed = _date(value);
                if (parsed)
                    end = parsed.date;
            }
        }

        // All-day events first within a day, then chronological
        events.sort((a, b) => {
            const da = Qt.formatDate(a.start, "yyyy-MM-dd").localeCompare(Qt.formatDate(b.start, "yyyy-MM-dd"));
            if (da !== 0)
                return da;
            if (a.allDay !== b.allDay)
                return a.allDay ? -1 : 1;
            return a.start - b.start;
        });

        _events = events;
    }

    function _date(value: string): var {
        // Handles VALUE=DATE (20250825), local (20250825T090000) and UTC (20250825T090000Z).
        // TZID-qualified times are treated as local wall time.
        const m = value.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?/);
        if (!m)
            return null;
        const [, y, mo, d, hh, mm, ss, z] = m;
        if (hh === undefined)
            return {
                date: new Date(Number(y), Number(mo) - 1, Number(d)),
                allDay: true
            };
        const date = z ? new Date(Date.UTC(Number(y), Number(mo) - 1, Number(d), Number(hh), Number(mm), Number(ss))) : new Date(Number(y), Number(mo) - 1, Number(d), Number(hh), Number(mm), Number(ss));
        return {
            date,
            allDay: false
        };
    }

    function _addDays(date: date, days: int): date {
        const d = new Date(date);
        d.setDate(d.getDate() + days);
        return d;
    }

    function _dayLabel(date: date): string {
        return Qt.formatDate(date, "ddd, MMM d").toUpperCase();
    }
}
