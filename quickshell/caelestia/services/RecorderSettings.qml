pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // gpu-screen-recorder is always asked for the source's native size. This is
    // intentionally not configurable: recordings must never be downscaled.
    readonly property string resolution: "native"
    readonly property list<string> qualities: ["medium", "high", "very_high", "ultra"]
    readonly property list<string> codecs: ["h264", "hevc", "av1"]
    readonly property list<string> frameRates: ["display", "30", "60", "90", "120", "144"]
    readonly property list<string> tunes: ["quality", "performance"]

    property string quality: "ultra"
    property string codec: "h264"
    property string frameRate: "display"
    property string tune: "quality"
    property bool cursor: true
    property bool loaded
    property list<string> unknownArgs: []

    readonly property bool isDefault: quality === "ultra" && codec === "h264" && frameRate === "display" && tune === "quality" && cursor

    function includes(list: var, value: var): bool {
        return list.indexOf(value) !== -1;
    }

    function setQuality(value: string): void {
        if (includes(qualities, value))
            quality = value;
    }

    function setCodec(value: string): void {
        if (includes(codecs, value))
            codec = value;
    }

    function setFrameRate(value: string): void {
        if (includes(frameRates, value) || /^[1-9][0-9]*$/.test(value))
            frameRate = value;
    }

    function setTune(value: string): void {
        if (includes(tunes, value))
            tune = value;
    }

    function setCursor(value: bool): void {
        cursor = value;
    }

    function reset(): void {
        quality = "ultra";
        codec = "h264";
        frameRate = "display";
        tune = "quality";
        cursor = true;
    }

    function splitArgs(args: var): var {
        const known = ["-s", "-q", "-k", "-f", "-cursor", "-tune"];
        const parsed = {};
        const unknown = [];

        for (let i = 0; i < args.length; i++) {
            const arg = args[i];
            if (typeof arg !== "string")
                continue;

            if (includes(known, arg)) {
                parsed[arg] = i + 1 < args.length && typeof args[i + 1] === "string" ? args[++i] : "";
            } else if (arg.startsWith("-")) {
                // Keep options owned by the user (bitrate, audio, replay, ...)
                // together with their values so unrelated CLI behaviour survives.
                unknown.push(arg);
                while (i + 1 < args.length && typeof args[i + 1] === "string" && !args[i + 1].startsWith("-"))
                    unknown.push(args[++i]);
            } else {
                unknown.push(arg);
            }
        }

        return { parsed, unknown };
    }

    function loadDocument(contents: string): void {
        let document = {};
        try {
            const parsed = JSON.parse(contents);
            if (parsed && typeof parsed === "object" && !Array.isArray(parsed))
                document = parsed;
        } catch (error) {
            // Missing or malformed JSON falls back to the maximum-quality defaults.
        }

        const record = document.record && typeof document.record === "object" && !Array.isArray(document.record) ? document.record : {};
        const args = Array.isArray(record.extraArgs) ? record.extraArgs.filter(arg => typeof arg === "string") : [];
        const split = splitArgs(args);
        const parsed = split.parsed;
        const downscaled = typeof parsed["-s"] === "string" && parsed["-s"] !== "" && parsed["-s"] !== "0x0";

        quality = includes(qualities, parsed["-q"]) ? parsed["-q"] : "ultra";
        codec = includes(codecs, parsed["-k"]) ? parsed["-k"] : "h264";
        frameRate = typeof parsed["-f"] === "string" && /^[1-9][0-9]*$/.test(parsed["-f"]) ? parsed["-f"] : "display";
        tune = includes(tunes, parsed["-tune"]) ? parsed["-tune"] : "quality";
        cursor = parsed["-cursor"] !== "no";

        unknownArgs = split.unknown;
        documentData = document;
        loaded = true;

        // A stale explicit cap would silently contradict the locked native
        // resolution shown in Nexus, so repair it as soon as it is seen.
        if (downscaled)
            saveTimer.restart();
    }

    function buildArgs(): var {
        const args = [...unknownArgs];

        // Force native resolution and always persist the selected video profile.
        args.push("-s", "0x0", "-q", quality, "-k", codec, "-tune", tune, "-cursor", cursor ? "yes" : "no");
        if (frameRate !== "display")
            args.push("-f", frameRate);

        return args;
    }

    function save(): void {
        if (!loaded)
            return;

        const next = Object.assign({}, documentData);
        const record = next.record && typeof next.record === "object" && !Array.isArray(next.record) ? Object.assign({}, next.record) : {};
        record.extraArgs = buildArgs();
        next.record = record;

        storage.setText(JSON.stringify(next, null, 4) + "\n");
    }

    property var documentData: ({})

    onQualityChanged: { if (loaded) saveTimer.restart(); }
    onCodecChanged: { if (loaded) saveTimer.restart(); }
    onFrameRateChanged: { if (loaded) saveTimer.restart(); }
    onTuneChanged: { if (loaded) saveTimer.restart(); }
    onCursorChanged: { if (loaded) saveTimer.restart(); }

    Timer {
        id: saveTimer

        interval: 200
        onTriggered: root.save()
    }

    FileView {
        id: storage

        path: `${Paths.config}/cli.json`
        printErrors: false
        onLoaded: root.loadDocument(text())
        onLoadFailed: root.loaded = true
    }
}
