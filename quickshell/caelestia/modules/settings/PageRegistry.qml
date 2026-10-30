pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            id: "appearance",
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, shell tint, colours"),
            category: "appearance"
        },

        // Connectivity
        {
            id: "network",
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            id: "bluetooth",
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            id: "audio",
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            id: "power",
            label: qsTr("Power & sleep"),
            icon: "bedtime",
            description: qsTr("Idle timers, lock, suspend and hibernate"),
            category: "system"
        },

        // Shell
        {
            id: "panels",
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard & utilities, taskbar & notifications, launcher, calendar"),
            category: "shell"
        },
        {
            id: "apps",
            label: qsTr("Apps"),
            icon: "apps",
            description: qsTr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            id: "services",
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend, recorder settings"),
            category: "shell"
        },
        {
            id: "language",
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, display units"),
            category: "shell"
        },

        // About
        {
            id: "about",
            label: qsTr("About"),
            icon: "info",
            description: qsTr("Orange OS version and system information"),
            category: "about"
        },
    ]
}
