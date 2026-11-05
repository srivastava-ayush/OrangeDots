pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Independent of the calendar scratchpad. Entries and unfinished drafts survive
// module changes and shell restarts; no external account or service is used.
Singleton {
    id: root
    property var entries: []
    property string draftText: ""
    property string draftKind: "note"
    property string editingId: ""
    property bool loaded: false
    property bool writable: true
    property string error: ""
    readonly property int todoCount: entries.filter(entry => entry.kind === "todo" && !entry.done).length

    function changed(): void { if (loaded && writable) saveTimer.restart(); }
    function saveDraft(): bool {
        const text = draftText.trim();
        if (!loaded || !writable || !text) return false;
        const existing = entries.find(entry => entry.id === editingId);
        const item = {
            id: existing?.id ?? `${Date.now()}-${Math.random().toString(16).slice(2)}`,
            kind: draftKind,
            text: text,
            done: draftKind === "todo" ? (existing?.done ?? false) : false,
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
            error = qsTr("Save or discard your current draft before editing another item.");
            return false;
        }
        const entry = entries.find(item => item.id === id);
        if (!entry) return false;
        editingId = id;
        draftKind = entry.kind;
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
    function toggle(id: string): void {
        if (!writable) return;
        entries = entries.map(entry => entry.id === id && entry.kind === "todo"
            ? { id: entry.id, text: entry.text, kind: entry.kind, done: !entry.done, created: entry.created }
            : entry);
    }
    function remove(id: string): void {
        if (!writable) return;
        entries = entries.filter(entry => entry.id !== id);
        // Keep any text being edited as an unsaved draft instead of losing it.
        if (editingId === id) editingId = "";
    }
    function removeKind(kind: string): void {
        if (!loaded || !writable || !["note", "todo"].includes(kind)) return;
        const editing = entries.find(entry => entry.id === editingId);
        entries = entries.filter(entry => entry.kind !== kind);
        // Bulk deletion never discards the text currently in the composer.
        if (editing?.kind === kind) editingId = "";
    }

    onEntriesChanged: changed()
    onDraftTextChanged: changed()
    onDraftKindChanged: changed()
    onEditingIdChanged: changed()

    Timer {
        id: saveTimer
        interval: 350
        onTriggered: storage.setText(JSON.stringify({ version: 1, entries: root.entries, draftText: root.draftText, draftKind: root.draftKind, editingId: root.editingId }))
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
                    entry && typeof entry.id === "string" && typeof entry.text === "string"
                    && ["note", "todo", "link"].includes(entry.kind)))
                    throw new Error("Invalid notes data");
                // Links are ordinary notes now. Keep existing text and IDs.
                const migrated = saved.entries.some(entry => entry.kind === "link") || saved.draftKind === "link";
                root.entries = saved.entries.map(entry => entry.kind === "link"
                    ? { id: entry.id, text: entry.text, kind: "note", done: false, created: entry.created }
                    : entry);
                if (typeof saved.draftText === "string") root.draftText = saved.draftText;
                if (["note", "todo"].includes(saved.draftKind)) root.draftKind = saved.draftKind;
                if (typeof saved.editingId === "string" && saved.entries.some(entry => entry.id === saved.editingId)) root.editingId = saved.editingId;
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
