pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.utils

// Shared across modules/screens: closing the sidebar never pauses the timer.
Singleton {
    id: root
    property bool loaded: false
    property string task: ""
    property int workMinutes: 25
    property int breakMinutes: 5
    property int longBreakMinutes: 15
    property int completed: 0
    property string phase: "focus"
    property int remaining: 25 * 60
    property bool running: false
    property double deadline: 0
    property bool autoStart: false
    property bool useDnd: false
    property bool showTaskbar: true
    property bool ownsDnd: false
    readonly property bool engaged: running || remaining !== durationFor(phase)
    readonly property string phaseName: phase === "focus" ? qsTr("Focus") : phase === "longBreak" ? qsTr("Long break") : qsTr("Break")
    readonly property string timeText: `${Math.floor(remaining / 60).toString().padStart(2, "0")}:${(remaining % 60).toString().padStart(2, "0")}`
    readonly property real progress: Math.max(0, Math.min(1, 1 - remaining / durationFor(phase)))

    function durationFor(id: string): int {
        return (id === "focus" ? workMinutes : id === "longBreak" ? longBreakMinutes : breakMinutes) * 60;
    }
    function save(): void { if (loaded) saveTimer.restart(); }
    function releaseDnd(): void {
        if (!ownsDnd) return;
        ownsDnd = false;
        if (Notifs.dnd) Notifs.dnd = false;
    }
    function syncDnd(): void {
        if (running && phase === "focus" && useDnd) {
            if (!Notifs.dnd) { ownsDnd = true; Notifs.dnd = true; }
        } else releaseDnd();
    }
    function start(): void {
        if (running || !loaded) return;
        if (remaining <= 0) remaining = durationFor(phase);
        deadline = Date.now() + remaining * 1000;
        running = true;
        syncDnd();
        save();
    }
    function pause(): void {
        if (!running) return;
        remaining = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
        running = false;
        releaseDnd();
        save();
    }
    function reset(): void {
        running = false;
        deadline = 0;
        remaining = durationFor(phase);
        releaseDnd();
        save();
    }
    function setPhase(id: string): void {
        if (!["focus", "break", "longBreak"].includes(id)) return;
        running = false;
        releaseDnd();
        phase = id;
        remaining = durationFor(id);
        deadline = 0;
        save();
    }
    function advance(finished: bool): void {
        const wasFocus = phase === "focus";
        running = false;
        releaseDnd();
        if (finished && wasFocus) completed++;
        phase = wasFocus ? (completed > 0 && completed % 4 === 0 ? "longBreak" : "break") : "focus";
        remaining = durationFor(phase);
        deadline = 0;
        if (finished) Toaster.toast(wasFocus ? qsTr("Focus complete") : qsTr("Break complete"), wasFocus ? qsTr("Time to recharge. Nice work!") : qsTr("Ready for your next focus session?"), wasFocus ? "self_improvement" : "timer");
        if (autoStart && finished) start();
        save();
    }
    function tick(): void {
        if (!running) return;
        remaining = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
        if (!remaining) advance(true);
    }
    function settingsChanged(): void {
        if (loaded && !running) remaining = durationFor(phase);
        save();
    }
    onTaskChanged: save()
    onWorkMinutesChanged: settingsChanged()
    onBreakMinutesChanged: settingsChanged()
    onLongBreakMinutesChanged: settingsChanged()
    onUseDndChanged: { if (loaded) syncDnd(); save(); }
    onAutoStartChanged: save()
    onShowTaskbarChanged: save()
    Connections {
        target: Notifs
        // If the user turns DND off manually, do not restore our old lease later.
        function onDndChanged(): void { if (!Notifs.dnd) root.ownsDnd = false; }
    }
    Timer { interval: 1000; repeat: true; running: root.running; onTriggered: root.tick() }
    Timer {
        id: saveTimer
        interval: 200
        onTriggered: storage.setText(JSON.stringify({ task: root.task, workMinutes: root.workMinutes, breakMinutes: root.breakMinutes, longBreakMinutes: root.longBreakMinutes, completed: root.completed, phase: root.phase, remaining: root.remaining, running: root.running, deadline: root.deadline, autoStart: root.autoStart, useDnd: root.useDnd, showTaskbar: root.showTaskbar, ownsDnd: root.ownsDnd }))
    }
    FileView {
        id: storage
        path: `${Paths.state}/focus-timer.json`
        printErrors: false
        onLoaded: {
            if (root.loaded) return;
            try {
                const saved = JSON.parse(text());
                for (const key of ["workMinutes", "breakMinutes", "longBreakMinutes"])
                    if (Number.isInteger(saved[key])) root[key] = Math.max(1, Math.min(180, saved[key]));
                if (typeof saved.task === "string") root.task = saved.task.slice(0, 500);
                if (Number.isInteger(saved.completed)) root.completed = Math.max(0, saved.completed);
                if (["focus", "break", "longBreak"].includes(saved.phase)) root.phase = saved.phase;
                root.remaining = Number.isInteger(saved.remaining) ? Math.max(0, Math.min(root.durationFor(root.phase), saved.remaining)) : root.durationFor(root.phase);
                for (const key of ["autoStart", "useDnd", "showTaskbar"])
                    if (typeof saved[key] === "boolean") root[key] = saved[key];
                if (saved.running === true && Number.isFinite(saved.deadline) && saved.deadline > 0) {
                    root.deadline = saved.deadline;
                    root.running = true;
                    root.ownsDnd = saved.ownsDnd === true && Notifs.dnd;
                } else if (saved.ownsDnd === true && Notifs.dnd) {
                    root.ownsDnd = true;
                    root.releaseDnd();
                }
            } catch (_) {}
            root.loaded = true;
            root.tick();
        }
        onLoadFailed: root.loaded = true
    }
}
