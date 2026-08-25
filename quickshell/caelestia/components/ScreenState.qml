import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
