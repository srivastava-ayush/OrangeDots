pragma Singleton

import Quickshell

// Keep the scratchpad outside the dashboard's lazy loaders so changing tabs or
// closing the dashboard never destroys the draft. This remains session-local,
// just like the old sidebar; no notes or calendar credentials are written here.
Singleton {
    id: root

    property string text

    PersistentProperties {
        // Preserve the old sidebar's reload identity and property name.
        reloadableId: "utilitysidebar-notes"
        property alias notesText: root.text
    }
}
