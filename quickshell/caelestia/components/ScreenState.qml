import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard

    // Notification shade (drag down from the top-right corner)
    property bool notifShade

    // Utility sidebar with calendar agenda + notes (bottom-right corner)
    property bool utilitySidebar

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
