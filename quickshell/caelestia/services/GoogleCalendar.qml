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
// Configure it in Nexus → Panels → Sidebar → Modules → Calendar & notes.
// The private calendar-url file stays compatible with existing installations.
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
    readonly property bool saving: credentialProc.running
    readonly property bool fetching: fetchProc.running
    readonly property string setupHint: qsTr("Add your secret iCal URL in Nexus → Panels → Sidebar → Modules → Calendar & notes.")
    property string settingsError: ""
    property string settingsMessage: ""
    property string pendingSecret: ""
    property string credentialAction: "save"
    property int generation: 0
    property bool fetchPending: false
    signal credentialsSaved

    property string _url: ""
    property string _rawIcs: ""

    function refresh(): void {
        urlFile.reload();
    }

    function saveUrl(url: string): bool {
        if (saving) return false;
        const value = url.trim();
        if (value.length > 8192 || !/^https?:\/\/\S+$/i.test(value)) {
            settingsError = qsTr("Paste a full HTTP(S) iCal URL. HTTPS is recommended.");
            return false;
        }
        pendingSecret = value;
        credentialAction = "save";
        settingsError = "";
        settingsMessage = "";
        credentialProc.exec(credentialProc.args);
        return true;
    }
    function clearUrl(): void {
        if (saving) return;
        pendingSecret = "";
        credentialAction = "clear";
        settingsError = "";
        settingsMessage = "";
        credentialProc.exec(credentialProc.args);
    }
    function requestFetch(): void {
        if (!_url) return;
        if (fetchProc.running) { fetchPending = true; return; }
        fetchProc.requestUrl = _url;
        fetchProc.requestGeneration = generation;
        fetchProc.stdinEnabled = true;
        fetchProc.exec(fetchProc.args);
    }

    on_RawIcsChanged: root._parse()

    Timer {
        interval: 30 * 60 * 1000 // 30 min
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    FileView {
        id: urlFile
        path: `${Paths.config}/calendar-url`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const url = text().trim();
            if (url !== root._url) root._url = url;
            else if (url) root.requestFetch();
            else root._error = root.setupHint;
        }
        onLoadFailed: {
            root._url = "";
            root._error = root.setupHint;
        }
    }

    Process {
        id: credentialProc
        readonly property list<string> args: ["python3", Paths.toLocalFile(Qt.resolvedUrl("../utils/scripts/calendar-url.py"))]
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify({ action: root.credentialAction, url: root.pendingSecret }) + "\n");
            root.pendingSecret = "";
        }
        stdout: SplitParser {
            onRead: line => {
                try {
                    const response = JSON.parse(line);
                    if (!response.ok) {
                        root.settingsError = response.error || qsTr("Could not save the calendar URL.");
                        return;
                    }
                    root.settingsMessage = root.credentialAction === "clear" ? qsTr("Calendar disconnected.") : qsTr("Secret URL saved privately. Updating the agenda…");
                    root.credentialsSaved();
                    root.refresh();
                } catch (_) {
                    root.settingsError = qsTr("Could not read the calendar settings response.");
                }
            }
        }
        stderr: SplitParser {}
        onExited: code => {
            root.pendingSecret = "";
            if (code !== 0) root.settingsError = qsTr("Calendar settings helper unavailable. Check Python 3 and config permissions.");
        }
    }

    Process {
        id: fetchProc

        property string requestUrl
        property int requestGeneration
        readonly property list<string> args: ["curl", "--silent", "--fail", "--location", "--max-time", "20", "--proto", "=http,https,file", "--proto-redir", "=http,https", "--config", "-"]
        stdinEnabled: true
        onStarted: {
            // curl reads the URL from its stdin config, never the process list.
            write("url = " + JSON.stringify(requestUrl) + "\n");
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                if (fetchProc.requestGeneration !== root.generation || !root._url) return;
                if (text.trim().length === 0) {
                    root._error = qsTr("Empty response from Google Calendar");
                    return;
                }
                root._error = "";
                root._rawIcs = text;
            }
        }
        stderr: SplitParser {}
        onExited: code => {
            if (code !== 0 && requestGeneration === root.generation && root._url)
                root._error = qsTr("Could not fetch the calendar. Check the URL and your network connection.");
            requestUrl = "";
            if (root.fetchPending) {
                root.fetchPending = false;
                Qt.callLater(root.requestFetch);
            }
        }
    }

    on_UrlChanged: {
        generation++;
        _events = [];
        _rawIcs = "";
        _error = _url ? "" : setupHint;
        fetchPending = false;
        if (fetchProc.running) {
            fetchPending = _url.length > 0;
            fetchProc.running = false;
        } else if (_url) requestFetch();
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
