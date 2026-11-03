pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root
    property bool loaded
    property bool enabled: true
    property string provider: "opencode"
    property int panelWidth: 460
    property int panelHeight: 800
    property bool fullHeight: true
    property bool autoApproveTools: true
    property string directory: Paths.home
    property string opencodeModel
    property string codexModel
    property string claudeModel
    property string ollamaModel
    property string opencodeEffort
    property string codexEffort
    property string claudeEffort
    property string ollamaEffort
    property string ollamaUrl: "http://127.0.0.1:11434"
    readonly property var providers: ["opencode", "codex", "claude", "ollama"]
    readonly property var names: ({ opencode: "OpenCode", codex: "Codex", claude: "Claude Code", ollama: "Ollama" })
    readonly property string providerName: names[provider] || "OpenCode"

    function modelFor(id: string): string {
        return ({ opencode: opencodeModel, codex: codexModel, claude: claudeModel, ollama: ollamaModel })[id] || "";
    }
    function effortFor(id: string): string {
        return root[id + "Effort"] || "";
    }
    function effortOptions(id: string): var {
        if (id === "codex") return ["", "none", "minimal", "low", "medium", "high", "xhigh"];
        if (id === "claude") return ["", "low", "medium", "high", "xhigh", "max"];
        if (id === "ollama") return ["", "on", "off", "low", "medium", "high"];
        return ["", "low", "medium", "high", "xhigh", "max"];
    }
    function changed(): void { if (loaded) saveTimer.restart(); }
    onEnabledChanged: changed()
    onAutoApproveToolsChanged: changed()
    onProviderChanged: {
        if (!providers.includes(provider)) { provider = "opencode"; return; }
        changed();
    }
    onPanelWidthChanged: changed()
    onFullHeightChanged: changed()
    onPanelHeightChanged: {
        const bounded = Math.max(480, Math.min(1600, panelHeight));
        if (panelHeight !== bounded) { panelHeight = bounded; return; }
        changed();
    }
    onDirectoryChanged: changed()
    onOpencodeModelChanged: changed()
    onCodexModelChanged: changed()
    onClaudeModelChanged: changed()
    onOllamaModelChanged: changed()
    onOllamaUrlChanged: changed()
    onOpencodeEffortChanged: changed()
    onCodexEffortChanged: changed()
    onClaudeEffortChanged: changed()
    onOllamaEffortChanged: changed()

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: storage.setText(JSON.stringify({ enabled: root.enabled, autoApproveTools: root.autoApproveTools, provider: root.provider, panelWidth: root.panelWidth, panelHeight: root.panelHeight, fullHeight: root.fullHeight, directory: root.directory, opencodeModel: root.opencodeModel, codexModel: root.codexModel, claudeModel: root.claudeModel, ollamaModel: root.ollamaModel, ollamaUrl: root.ollamaUrl, opencodeEffort: root.opencodeEffort, codexEffort: root.codexEffort, claudeEffort: root.claudeEffort, ollamaEffort: root.ollamaEffort }))
    }
    FileView {
        id: storage
        path: `${Paths.config}/ai-panel.json`
        printErrors: false
        onLoaded: {
            if (root.loaded) return;
            try {
                const saved = JSON.parse(text());
                if (typeof saved.enabled === "boolean") root.enabled = saved.enabled;
                if (typeof saved.autoApproveTools === "boolean") root.autoApproveTools = saved.autoApproveTools;
                if (root.providers.includes(saved.provider)) root.provider = saved.provider;
                if (Number.isInteger(saved.panelWidth)) root.panelWidth = Math.max(360, Math.min(720, saved.panelWidth));
                if (Number.isInteger(saved.panelHeight)) root.panelHeight = saved.panelHeight;
                if (typeof saved.fullHeight === "boolean") root.fullHeight = saved.fullHeight;
                if (typeof saved.directory === "string" && saved.directory.startsWith("/")) root.directory = saved.directory;
                for (const key of ["opencodeModel", "codexModel", "claudeModel", "ollamaModel", "ollamaUrl", "opencodeEffort", "codexEffort", "claudeEffort", "ollamaEffort"])
                    if (typeof saved[key] === "string") root[key] = saved[key];
            } catch (_) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
