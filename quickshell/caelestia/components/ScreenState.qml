import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool ai
    property bool leftSidebar

    // Notification shade (taskbar bell popout; also exposed through drawer IPC)
    property bool notifShade

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
