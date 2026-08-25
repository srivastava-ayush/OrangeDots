import Quickshell

PersistentProperties {
    property list<string> expandedNotifs: []

    // Distinct from the dashboard's "dashboard-notifs" so both lists keep
    // their own expansion state without clobbering each other on reload.
    reloadableId: "notifshade-notifs"
}
