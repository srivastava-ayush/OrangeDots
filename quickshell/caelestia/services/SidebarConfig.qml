pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

Singleton {
    id: root

    // Preserve existing panel geometry/enabled JSON keys and user preferences.
    // AI provider settings remain in AiConfig; new module preferences live here.
    readonly property var layout: AiConfig
    readonly property QtObject leftLayout: QtObject {
        property bool enabled: true
        property int panelWidth: 460
        property int panelHeight: 800
        property bool fullHeight: true
        onEnabledChanged: root.changed()
        onPanelWidthChanged: root.changed()
        onPanelHeightChanged: root.changed()
        onFullHeightChanged: root.changed()
    }
    readonly property var modules: [
        { id: "ai", name: qsTr("AI"), icon: "forum" },
        { id: "calendar", name: qsTr("Google Calendar"), icon: "calendar_month" },
        { id: "clipboard", name: qsTr("Clipboard"), icon: "content_paste" },
        { id: "focus", name: qsTr("Focus"), icon: "self_improvement" },
        { id: "notes", name: qsTr("Notes"), icon: "edit_note" }
    ]
    property var enabledModules: ["ai", "calendar"]
    property var leftModules: []
    property string defaultModule: "ai"
    property string leftDefaultModule: ""
    property var moduleLabels: ({})
    property bool loaded: false

    function changed(): void { if (loaded) saveTimer.restart(); }
    function layoutFor(side: string): var { return side === "left" ? leftLayout : layout; }
    function modulesFor(side: string): var { return side === "left" ? leftModules : enabledModules; }
    function defaultFor(side: string): string { return side === "left" ? leftDefaultModule : defaultModule; }
    function setDefault(side: string, id: string): void {
        if (!modulesFor(side).includes(id)) return;
        if (side === "left") leftDefaultModule = id;
        else defaultModule = id;
    }
    function placement(id: string): string {
        return leftModules.includes(id) ? "left" : enabledModules.includes(id) ? "right" : "off";
    }
    function assignModule(id: string, side: string): void {
        if (!modules.some(module => module.id === id) || !["left", "right", "off"].includes(side)) return;
        if (placement(id) === side) return;
        // One owner per module. Shared module services keep notes, pins and
        // running focus timers independent of where their view is placed.
        leftModules = leftModules.filter(module => module !== id);
        enabledModules = enabledModules.filter(module => module !== id);
        if (side === "left") leftModules = [...leftModules, id];
        else if (side === "right") enabledModules = [...enabledModules, id];
    }

    function moduleName(id: string): string {
        return moduleLabels[id] || modules.find(module => module.id === id)?.name || id;
    }

    function setModuleLabel(id: string, text: string): void {
        if (!modules.some(module => module.id === id)) return;
        const labels = Object.assign({}, moduleLabels);
        const label = text.trim().replace(/\s+/g, " ").slice(0, 40);
        if (label) labels[id] = label;
        else delete labels[id];
        moduleLabels = labels;
    }

    onModuleLabelsChanged: if (loaded) saveTimer.restart()

    function setModuleEnabled(id: string, enabled: bool): void {
        // Keep the legacy right-only toggle contract. Central placement controls
        // use assignModule directly and can intentionally leave a side empty.
        if (!enabled && enabledModules.length === 1 && enabledModules.includes(id)) return;
        assignModule(id, enabled ? "right" : "off");
    }

    onEnabledModulesChanged: {
        const valid = modules.map(module => module.id).filter(id => enabledModules.includes(id));
        if (JSON.stringify(valid) !== JSON.stringify(enabledModules)) {
            enabledModules = valid;
            return;
        }
        if (!valid.includes(defaultModule)) defaultModule = valid[0] ?? "";
        if (loaded) saveTimer.restart();
    }
    onDefaultModuleChanged: {
        if (!enabledModules.includes(defaultModule)) {
            if (defaultModule === "" && !enabledModules.length) return;
            defaultModule = enabledModules[0] ?? "";
            return;
        }
        if (loaded) saveTimer.restart();
    }

    onLeftModulesChanged: {
        const valid = modules.map(module => module.id).filter(id => leftModules.includes(id));
        if (JSON.stringify(valid) !== JSON.stringify(leftModules)) { leftModules = valid; return; }
        if (!valid.includes(leftDefaultModule)) leftDefaultModule = valid[0] ?? "";
        changed();
    }
    onLeftDefaultModuleChanged: {
        if (!leftModules.includes(leftDefaultModule)) {
            if (leftDefaultModule === "" && !leftModules.length) return;
            leftDefaultModule = leftModules[0] ?? "";
            return;
        }
        changed();
    }

    Timer {
        id: saveTimer
        interval: 200
        onTriggered: storage.setText(JSON.stringify({ enabledModules: root.enabledModules, defaultModule: root.defaultModule, moduleLabels: root.moduleLabels, leftModules: root.leftModules, leftDefaultModule: root.leftDefaultModule, left: { enabled: root.leftLayout.enabled, panelWidth: root.leftLayout.panelWidth, panelHeight: root.leftLayout.panelHeight, fullHeight: root.leftLayout.fullHeight } }))
    }
    FileView {
        id: storage
        path: `${Paths.config}/sidebar-panel.json`
        printErrors: false
        onLoaded: {
            if (root.loaded) return;
            try {
                const saved = JSON.parse(text());
                if (Array.isArray(saved.enabledModules)) root.enabledModules = saved.enabledModules;
                if (typeof saved.defaultModule === "string") root.defaultModule = saved.defaultModule;
                if (Array.isArray(saved.leftModules)) root.leftModules = saved.leftModules.filter(id => !root.enabledModules.includes(id));
                if (typeof saved.leftDefaultModule === "string") root.leftDefaultModule = saved.leftDefaultModule;
                if (saved.left && typeof saved.left === "object") {
                    if (typeof saved.left.enabled === "boolean") root.leftLayout.enabled = saved.left.enabled;
                    if (typeof saved.left.fullHeight === "boolean") root.leftLayout.fullHeight = saved.left.fullHeight;
                    if (Number.isInteger(saved.left.panelWidth)) root.leftLayout.panelWidth = Math.max(360, Math.min(720, saved.left.panelWidth));
                    if (Number.isInteger(saved.left.panelHeight)) root.leftLayout.panelHeight = Math.max(480, Math.min(1600, saved.left.panelHeight));
                }
                if (saved.moduleLabels && typeof saved.moduleLabels === "object" && !Array.isArray(saved.moduleLabels)) {
                    for (const module of root.modules)
                        if (typeof saved.moduleLabels[module.id] === "string") root.setModuleLabel(module.id, saved.moduleLabels[module.id]);
                }
            } catch (_) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
