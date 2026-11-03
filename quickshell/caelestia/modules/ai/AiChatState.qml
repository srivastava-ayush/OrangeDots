pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.services
import qs.utils

Scope {
    id: root
    required property string screenName
    property bool active
    property bool connectionEnabled: true
    property bool busy
    property bool ready
    property bool failed
    property bool loaded
    property bool restarting
    property bool resetting
    property bool clearingMemory
    property bool memoryReleased
    property string provider: "opencode"
    property var sessions: ({})
    property string sessionID
    property string directory: AiConfig.directory
    property string draft
    property string error
    property var permissions: []
    property int forms: 0
    readonly property alias messages: messages
    readonly property string bridgeDirectory: Paths.toLocalFile(Qt.resolvedUrl("../../utils/opencode"))
    signal updated
    signal memoryCleared
    signal requestSent(var command)

    onActiveChanged: if (active) { memoryReleased = false; applyProvider(); syncDirectory(); failed = false; error = ""; }
    onBusyChanged: if (!busy) Qt.callLater(() => { root.applyProvider(); root.syncDirectory(); })

    function rows(): var {
        const result = [];
        for (let i = Math.max(0, messages.count - 40); i < messages.count; i++) {
            const row = messages.get(i);
            result.push({ id: row.id, role: row.role, text: row.text });
        }
        return result;
    }
    function restore(): void {
        const saved = sessions[provider] || {};
        sessionID = saved.sessionID || "";
        directory = sessionID && typeof saved.directory === "string" && saved.directory.startsWith("/") ? saved.directory : AiConfig.directory;
        messages.clear();
        for (const row of (saved.rows || []).slice(-40))
            if (typeof row.text === "string" && ["user", "assistant"].includes(row.role))
                messages.append({ id: row.id || "restored", role: row.role, text: row.text.slice(-60000) });
    }
    function applyProvider(): void {
        if (!loaded || !AiConfig.loaded || busy || resetting || memoryReleased || provider === AiConfig.provider) return;
        save();
        provider = AiConfig.provider;
        restore();
        permissions = [];
        forms = 0;
        ready = false;
        restart();
    }
    function initCommand(): var {
        if (!sessionID) directory = AiConfig.directory;
        return { type: "init", sessionID, directory, autoApproveTools: AiConfig.autoApproveTools, model: AiConfig.modelFor(provider), effort: AiConfig.effortFor(provider), ollamaUrl: AiConfig.ollamaUrl, history: rows() };
    }
    function syncDirectory(): void {
        if (!loaded || !AiConfig.loaded || sessionID || busy || resetting || memoryReleased || directory === AiConfig.directory) return;
        directory = AiConfig.directory;
        ready = false;
        save();
        restart();
    }

    function write(command: var): void {
        requestSent(command);
        if (bridge.running) bridge.write(JSON.stringify(command) + "\n");
    }
    function save(): void {
        if (!loaded || memoryReleased) return;
        const updated = Object.assign({}, sessions);
        updated[provider] = { sessionID, directory, rows: rows() };
        sessions = updated;
        // Provider-native sessions keep their own durable transcript. Keep our
        // bounded UI cache in RAM, not world-readable shell preference files.
        const identifiers = {};
        for (const key of Object.keys(sessions)) identifiers[key] = { sessionID: sessions[key].sessionID, directory: sessions[key].directory };
        storage.setText(JSON.stringify({ sessions: identifiers }));
    }
    function reconnect(): void {
        if (!sessionID) directory = AiConfig.directory;
        failed = false;
        error = "";
        // A fresh adapter avoids leaking CLI children or resetting a live one.
        if (bridge.running) restart();
    }
    function send(): void {
        if (!ready || busy || resetting || !draft.trim()) return;
        const text = draft;
        draft = "";
        busy = true;
        error = "";
        messages.append({ id: "pending-user", role: "user", text });
        write({ type: "send", text, effort: AiConfig.effortFor(provider) });
        updated();
    }
    function newChat(): void {
        if (resetting) return;
        // Interrupt provider-native work before dropping its session ID. In
        // particular, killing our OpenCode adapter alone cannot stop its service.
        if (bridge.running) {
            resetting = true;
            ready = false;
            write({ type: "reset" });
        } else finishNewChat();
    }
    function clearMemory(): void {
        if (resetting) return;
        clearingMemory = true;
        // An idle/broken session needs no remote cancellation. Forget it even
        // if its old location is unavailable and cannot return a snapshot.
        if (!busy) finishNewChat();
        else newChat();
    }
    function finishNewChat(): void {
        const release = clearingMemory;
        clearingMemory = false;
        memoryReleased = release;
        resetting = false;
        ready = false;
        busy = false;
        draft = "";
        error = "";
        sessionID = "";
        directory = AiConfig.directory;
        messages.clear();
        permissions = [];
        forms = 0;
        if (release) {
            // Forget every provider cache and resume ID belonging to this
            // sidebar. Do not delete native transcripts or stop shared services.
            sessions = ({});
            storage.setText(JSON.stringify({ sessions: {} }));
            failed = true;
            memoryCleared();
        } else {
            save();
            restart();
        }
        updated();
    }
    function restart(): void {
        // Restart only our adapter, not OpenCode or any existing session.
        if (bridge.running) {
            restarting = true;
            failed = true;
        } else reconnect();
    }
    function receive(line: string): void {
        try {
            const event = JSON.parse(line);
            if (event.type === "reset-ready") {
                if (resetting) finishNewChat();
                return;
            }
            // Old stream snapshots must not repopulate a freshly reset chat.
            if (memoryReleased || restarting || (resetting && event.type !== "error")) return;
            if (event.type === "ready") ready = true;
            else if (event.type === "session") {
                sessionID = event.id;
                directory = event.directory;
                save();
            } else if (event.type === "busy") busy = event.value;
            else if (event.type === "permissions") permissions = event.items;
            else if (event.type === "snapshot") {
                messages.clear();
                for (const row of event.rows) messages.append(row);
                permissions = event.permissions;
                busy = event.busy;
                forms = event.forms;
                save();
            } else if (event.type === "delta") {
                let index = -1;
                for (let i = 0; i < messages.count; i++) if (messages.get(i).id === event.id) { index = i; break; }
                if (index < 0) {
                    if (messages.count >= 40) messages.remove(0);
                    messages.append({ id: event.id, role: "assistant", text: event.text });
                } else messages.setProperty(index, "text", (messages.get(index).text + event.text).slice(-60000));
            } else if (event.type === "error") { clearingMemory = false; resetting = false; error = event.message; busy = false; }
            updated();
        } catch (_) { error = qsTr("Invalid response from AI provider bridge."); }
    }

    ListModel { id: messages }
    FileView {
        id: storage
        path: `${Paths.state}/ai-sidebar-${root.screenName.replace(/[^a-zA-Z0-9_-]/g, "_")}.json`
        printErrors: false
        onLoaded: {
            if (root.loaded) return;
            try {
                const saved = JSON.parse(text());
                root.sessions = saved.sessions || (saved.sessionID ? { opencode: saved } : {});
            } catch (_) {}
            root.provider = AiConfig.provider;
            root.restore();
            root.loaded = true;
        }
        onLoadFailed: { root.provider = AiConfig.provider; root.loaded = true; }
    }
    Connections {
        target: AiConfig
        function onProviderChanged(): void { root.applyProvider(); }
        function onLoadedChanged(): void { root.applyProvider(); }
        function onDirectoryChanged(): void { root.syncDirectory(); }
        function onAutoApproveToolsChanged(): void {
            if (root.provider === "opencode" && root.ready)
                root.write({ type: "approval-policy", autoApproveTools: AiConfig.autoApproveTools });
        }
    }
    Process {
        id: bridge
        command: ["node", `${root.bridgeDirectory}/entry.mjs`, root.provider, root.directory]
        running: root.connectionEnabled && AiConfig.loaded && root.loaded && !root.failed && (root.active || root.busy)
        stdinEnabled: true
        onStarted: root.write(root.initCommand())
        stdout: SplitParser { onRead: line => root.receive(line) }
        stderr: StdioCollector {}
        onExited: code => {
            root.ready = false;
            if (root.resetting) {
                root.clearingMemory = false;
                root.resetting = false;
                root.error = qsTr("The provider disconnected before confirming cancellation. Reconnect and retry New chat.");
            }
            if (root.restarting) {
                root.restarting = false;
                Qt.callLater(root.reconnect);
                return;
            }
            if (code !== 0 && (root.active || root.busy) && !root.failed) {
                root.error = root.error || (root.provider === "opencode" ? qsTr("OpenCode bridge unavailable. Install Node.js/OpenCode, then run npm ci --prefix %1").arg(root.bridgeDirectory) : qsTr("%1 bridge unavailable. Check Node.js and the provider setup in Nexus → Panels → AI panel.").arg(AiConfig.names[root.provider]));
                root.failed = true;
            }
            root.busy = false;
        }
    }
}
