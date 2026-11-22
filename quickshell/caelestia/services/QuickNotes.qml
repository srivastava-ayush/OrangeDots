pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Independent of the calendar scratchpad. Notes and unfinished drafts survive
// module changes and shell restarts; no external account or service is used.
Singleton {
    id: root
    property var entries: []
    property string draftText: ""
    property string editingId: ""
    property bool loaded: false
    property bool writable: true
    property string error: ""

    function changed(): void { if (loaded && writable) saveTimer.restart(); }

    function saveDraft(): bool {
        const text = draftText.trim();
        if (!loaded || !writable || !text) return false;
        const existing = entries.find(entry => entry.id === editingId);
        const item = {
            id: existing?.id ?? `${Date.now()}-${Math.random().toString(16).slice(2)}`,
            kind: "note",
            text: text,
            created: existing?.created ?? Date.now()
        };
        entries = existing ? entries.map(entry => entry.id === item.id ? item : entry) : [item, ...entries];
        draftText = "";
        editingId = "";
        error = "";
        changed();
        return true;
    }

    function edit(id: string): bool {
        if (draftText.trim() && editingId !== id) {
            error = qsTr("Save or discard your current draft before editing another note.");
            return false;
        }
        const entry = entries.find(item => item.id === id);
        if (!entry) return false;
        editingId = id;
        draftText = entry.text;
        error = "";
        changed();
        return true;
    }

    function discardDraft(): void {
        draftText = "";
        editingId = "";
        if (writable) error = "";
        changed();
    }

    function remove(id: string): void {
        if (!writable) return;
        entries = entries.filter(entry => entry.id !== id);
        // Keep any text being edited as an unsaved draft instead of losing it.
        if (editingId === id) editingId = "";
    }

    function removeAll(): void {
        if (!loaded || !writable) return;
        const editing = entries.find(entry => entry.id === editingId);
        entries = [];
        // Bulk deletion never discards the text currently in the composer.
        if (editing) editingId = "";
    }

    onEntriesChanged: changed()
    onDraftTextChanged: changed()
    onEditingIdChanged: changed()

    Timer {
        id: saveTimer
        interval: 350
        onTriggered: storage.setText(JSON.stringify({ version: 2, entries: root.entries, draftText: root.draftText, editingId: root.editingId }))
    }

    FileView {
        id: storage
        path: `${Paths.state}/sidebar-notes.json`
        printErrors: false
        onLoaded: {
            if (root.loaded) return;
            try {
                const saved = JSON.parse(text());
                if (!Array.isArray(saved.entries) || !saved.entries.every(entry =>
                    entry && typeof entry.id === "string" && typeof entry.text === "string"))
                    throw new Error("Invalid notes data");
                // Older drafts and to-dos are plain notes now; keep their text
                // and IDs so nothing the user wrote is lost.
                const migrated = saved.entries.some(entry => entry.kind !== "note");
                root.entries = saved.entries.map(entry => ({
                    id: entry.id,
                    kind: "note",
                    text: entry.text,
                    created: entry.created ?? Date.now()
                }));
                if (typeof saved.draftText === "string") root.draftText = saved.draftText;
                if (typeof saved.editingId === "string" && saved.entries.some(entry => entry.id === saved.editingId))
                    root.editingId = saved.editingId;
                if (migrated) saveTimer.restart();
            } catch (_) {
                root.writable = false;
                root.error = qsTr("Could not read sidebar-notes.json. Your existing file has not been overwritten.");
            }
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }
}
