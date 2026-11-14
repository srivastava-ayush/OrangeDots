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
            description: qsTr("Wallpaper, shell tint, colours, interface, desktop"),
            category: "appearance",
            keywords: ["wallpaper", "background", "theme", "colour", "color", "scheme", "dark", "light", "tint", "transparency", "interface", "rounding", "spacing", "padding", "font", "animation", "desktop", "clock", "visualiser", "visualizer", "appearance"]
        },

        // Connectivity
        {
            id: "network",
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet, VPN"),
            category: "connectivity",
            keywords: ["wifi", "wi-fi", "ethernet", "vpn", "network", "internet", "connection"]
        },
        {
            id: "bluetooth",
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true,
            keywords: ["bluetooth", "device", "pair", "pairing", "headphones", "mouse", "keyboard"]
        },
        {
            id: "audio",
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity",
            keywords: ["audio", "sound", "volume", "speaker", "microphone", "output", "input"]
        },

        // System
        {
            id: "power",
            label: qsTr("Power & sleep"),
            icon: "bedtime",
            description: qsTr("Idle timers, lock, suspend and hibernate"),
            category: "system",
            keywords: ["power", "sleep", "idle", "battery", "suspend", "hibernate", "lock", "screen", "fingerprint", "face", "howdy", "fprint"]
        },

        // Shell
        {
            id: "panels",
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard & utilities, taskbar & notifications, launcher, calendar"),
            category: "shell",
            keywords: ["panel", "dashboard", "taskbar", "bar", "launcher", "sidebar", "calendar", "notification", "shade", "tray", "status", "workspace", "clock", "active window"]
        },
        {
            id: "apps",
            label: qsTr("Apps"),
            icon: "apps",
            description: qsTr("Default apps, favourites, hidden apps"),
            category: "shell",
            keywords: ["app", "application", "default", "favourite", "favorite", "hidden", "terminal", "browser", "file manager"]
        },
        {
            id: "services",
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend, recorder, on-screen display"),
            category: "shell",
            keywords: ["service", "poll", "lyrics", "recorder", "record", "osd", "on-screen display", "volume", "brightness", "microphone", "notification", "gpu", "weather"]
        },
        {
            id: "language",
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, display units"),
            category: "shell",
            keywords: ["language", "region", "locale", "units", "temperature", "celsius", "fahrenheit", "clock", "twelve", "24 hour"]
        },

        // About
        {
            id: "about",
            label: qsTr("About"),
            icon: "info",
            description: qsTr("Orange OS version and system information"),
            category: "about",
            keywords: ["about", "version", "system", "orange", "information", "release"]
        },
    ]

    // Deep links surfaced by the Nexus search. `subPages` is the chain of
    // stack indices opened below the top-level page.
    readonly property list<var> searchEntries: [
        {
            label: qsTr("Wallpapers"),
            description: qsTr("Browse and apply wallpapers"),
            icon: "wallpaper",
            trail: qsTr("Wallpaper & style"),
            page: "appearance",
            subPages: [1],
            keywords: ["wallpaper", "background", "image", "picture"]
        },
        {
            label: qsTr("Shell tint"),
            description: qsTr("Tint shell surfaces and adjust tint strength"),
            icon: "format_color_fill",
            trail: qsTr("Wallpaper & style"),
            page: "appearance",
            subPages: [3],
            keywords: ["tint", "shell", "background", "colour", "color", "opacity"]
        },
        {
            label: qsTr("Colours"),
            description: qsTr("Scheme library, variant, dark or light mode"),
            icon: "palette",
            trail: qsTr("Wallpaper & style"),
            page: "appearance",
            subPages: [4],
            keywords: ["colour", "color", "scheme", "theme", "dark", "light", "variant", "palette", "material"]
        },
        {
            label: qsTr("Interface"),
            description: qsTr("Rounding, spacing, transparency, fonts, animation"),
            icon: "tune",
            trail: qsTr("Wallpaper & style"),
            page: "appearance",
            subPages: [5],
            keywords: ["interface", "rounding", "corner", "spacing", "padding", "transparency", "opacity", "font", "text", "animation", "deformation", "border", "smoothing"]
        },
        {
            label: qsTr("Desktop"),
            description: qsTr("Desktop clock and audio visualiser"),
            icon: "desktop_windows",
            trail: qsTr("Wallpaper & style"),
            page: "appearance",
            subPages: [6],
            keywords: ["desktop", "clock", "visualiser", "visualizer", "audio", "bars", "shadow", "wallpaper", "blur"]
        },
        {
            label: qsTr("Dashboard"),
            description: qsTr("Tabs, cards, weather, performance and hover area"),
            icon: "dashboard",
            trail: qsTr("Panels"),
            page: "panels",
            subPages: [1],
            keywords: ["dashboard", "weather", "performance", "card", "tab", "hover", "scale", "hot corner"]
        },
        {
            label: qsTr("Taskbar"),
            description: qsTr("Orientation, style, thickness and scroll actions"),
            icon: "dock_to_bottom",
            trail: qsTr("Panels"),
            page: "panels",
            subPages: [2],
            keywords: ["taskbar", "bar", "orientation", "notch", "thickness", "scroll", "persistent", "hover"]
        },
        {
            label: qsTr("Launcher"),
            description: qsTr("Launcher behaviour, display and search"),
            icon: "apps",
            trail: qsTr("Panels"),
            page: "panels",
            subPages: [3],
            keywords: ["launcher", "search", "apps", "fuzzy", "action prefix", "wallpaper"]
        },
        {
            label: qsTr("Workspaces"),
            description: qsTr("Workspace indicators and window icons"),
            icon: "workspaces",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 4],
            keywords: ["workspace", "indicator", "window", "icon", "taskbar", "scrolling"]
        },
        {
            label: qsTr("Active window"),
            description: qsTr("Window title display and popout"),
            icon: "web_asset",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 5],
            keywords: ["active window", "title", "window", "taskbar", "popout"]
        },
        {
            label: qsTr("Tray"),
            description: qsTr("System tray icons"),
            icon: "widgets",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 6],
            keywords: ["tray", "system tray", "icon", "taskbar"]
        },
        {
            label: qsTr("Status icons"),
            description: qsTr("Visible indicators and the notification bell"),
            icon: "signal_cellular_alt",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 7],
            keywords: ["status", "icon", "indicator", "bell", "taskbar", "network", "bluetooth", "battery"]
        },
        {
            label: qsTr("Clock"),
            description: qsTr("Date, icon and background for the taskbar clock"),
            icon: "schedule",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 8],
            keywords: ["clock", "time", "date", "taskbar", "format", "seconds"]
        },
        {
            label: qsTr("Notification shade"),
            description: qsTr("Status-group bell, hover popout and notification history"),
            icon: "notifications",
            trail: qsTr("Panels · Taskbar"),
            page: "panels",
            subPages: [2, 9],
            keywords: ["notification", "shade", "history", "bell", "popout", "hover", "taskbar"]
        },
        {
            label: qsTr("Sidebar"),
            description: qsTr("Left and right sidebars, shared modules and labels"),
            icon: "forum",
            trail: qsTr("Panels"),
            page: "panels",
            subPages: [10],
            keywords: ["sidebar", "panel", "left", "right", "modules", "labels", "calendar", "ai"]
        },
        {
            label: qsTr("Sidebar modules"),
            description: qsTr("Place modules on the left, right or disable them"),
            icon: "view_sidebar",
            trail: qsTr("Panels · Sidebar"),
            page: "panels",
            subPages: [10, 13],
            keywords: ["sidebar", "module", "placement", "left", "right", "calendar", "ai"]
        },
        {
            label: qsTr("Sidebar calendar"),
            description: qsTr("Calendar agenda, notes and visibility"),
            icon: "calendar_month",
            trail: qsTr("Panels · Sidebar · Modules"),
            page: "panels",
            subPages: [10, 13, 14],
            keywords: ["calendar", "agenda", "notes", "sidebar", "events", "ical"]
        },
        {
            label: qsTr("Notifications"),
            description: qsTr("Notification and toast behaviour"),
            icon: "notifications",
            trail: qsTr("Services"),
            page: "services",
            subPages: [1],
            keywords: ["notification", "toast", "timeout", "fullscreen", "history", "expire"]
        },
        {
            label: qsTr("Screen recorder"),
            description: qsTr("Resolution, quality, codec, frame rate and cursor"),
            icon: "screen_record",
            trail: qsTr("Services"),
            page: "services",
            subPages: [2],
            keywords: ["screen", "recorder", "record", "video", "codec", "quality", "frame rate", "cursor"]
        },
        {
            label: qsTr("On-screen display"),
            description: qsTr("Volume, brightness and microphone overlays"),
            icon: "volume_up",
            trail: qsTr("Services"),
            page: "services",
            subPages: [3],
            keywords: ["osd", "on-screen display", "overlay", "volume", "brightness", "microphone", "hide delay"]
        },
        {
            label: qsTr("Lock screen"),
            description: qsTr("Background, fingerprint and face unlock"),
            icon: "lock",
            trail: qsTr("Power & sleep"),
            page: "power",
            subPages: [1],
            keywords: ["lock", "screen", "lock screen", "fingerprint", "face", "howdy", "fprint", "password", "wallpaper"]
        },
    ]

    function normalise(value: var): string {
        return String(value ?? "").toLowerCase();
    }

    function matches(entry: var, query: string): bool {
        const terms = root.normalise(query).trim().split(/\s+/).filter(term => term.length > 0);
        if (terms.length === 0)
            return true;

        const haystack = root.normalise(`${entry.label} ${entry.description ?? ""} ${(entry.keywords ?? []).join(" ")}`);
        return terms.every(term => haystack.includes(term));
    }

    function categoryLabel(category: string): string {
        switch (category) {
        case "appearance":
            return qsTr("Appearance");
        case "connectivity":
            return qsTr("Connectivity");
        case "system":
            return qsTr("System");
        case "shell":
            return qsTr("Shell");
        case "about":
            return qsTr("About");
        default:
            return qsTr("Settings");
        }
    }

    function searchResults(query: string): var {
        if (root.normalise(query).trim().length === 0)
            return [];

        const results = [];

        root.pages.forEach((entry, index) => {
            if (!root.matches(entry, query))
                return;

            results.push({
                kind: "page",
                pageId: entry.id,
                pageIdx: index,
                label: entry.label,
                description: entry.description,
                icon: entry.icon,
                trail: root.categoryLabel(entry.category)
            });
        });

        root.searchEntries.forEach(entry => {
            if (!root.matches(entry, query))
                return;

            results.push({
                kind: "link",
                pageId: entry.page,
                subPages: entry.subPages,
                label: entry.label,
                description: entry.description,
                icon: entry.icon,
                trail: entry.trail
            });
        });

        return results;
    }
}
