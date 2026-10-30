pragma Singleton

import QtQuick
import qs.modules.settings.common
import qs.modules.settings.pages
import qs.modules.settings.pages.apps
import qs.modules.settings.pages.audio
import qs.modules.settings.pages.bluetooth
import qs.modules.settings.pages.network
import qs.modules.settings.pages.panels
import qs.modules.settings.pages.services
import qs.modules.settings.pages.wallandstyle
import qs.modules.settings.pages.panels.taskbar

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            // Wallpaper & style
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
                Component {
                    WallpaperSelect {}
                }
                Component {
                    WallpaperCategory {}
                }
                Component {
                    ColourSelect {}
                }
            }
        },

        // Connectivity
        Component {
            // Network
            StackPage {
                Component {
                    NetworkPage {}
                }
                Component {
                    EthernetDetailPage {}
                }
                Component {
                    AddNetworkPage {}
                }
                Component {
                    NetworkDetailPage {}
                }
                Component {
                    AddVpnPage {}
                }
                Component {
                    AllNetworksPage {}
                }
                Component {
                    SavedNetworksPage {}
                }
            }
        },
        Component {
            // Bluetooth
            StackPage {
                Component {
                    BluetoothPage {}
                }
                Component {
                    BtDeviceInfo {}
                }
                Component {
                    BluetoothPairing {}
                }
            }
        },
        Component {
            // Audio
            StackPage {
                Component {
                    AudioPage {}
                }
                Component {
                    AppVolumes {}
                }
            }
        },

        // System
        Component {
            StackPage {
                Component {
                    PowerAndSleepPage {}
                }
            }
        },

        // Shell
        Component {
            // Panels
            StackPage {
                Component {
                    PanelsPage {}
                }
                Component {
                    DashboardPanel {}
                }
                Component {
                    TaskbarPanel {}
                }
                Component {
                    LauncherPanel {}
                }
                Component {
                    CalendarNotesPanel {}
                }
                Component {
                    // Dashboard → Utilities (keep index 5 stable for navigation).
                    UtilitiesPanel {}
                }

                // Taskbar component sub-pages
                Component {
                    BarWorkspaces {}
                }
                Component {
                    BarActiveWindow {}
                }
                Component {
                    BarTray {}
                }
                Component {
                    BarStatusIcons {}
                }
                Component {
                    BarClock {}
                }
                Component {
                    // Taskbar → Notification shade (index 11).
                    NotificationShadePanel {}
                }
            }
        },
        Component {
            // Apps
            StackPage {
                Component {
                    AppsPage {}
                }
                Component {
                    AllApps {}
                }
                Component {
                    AppInfo {}
                }
            }
        },
        Component {
            // Services
            StackPage {
                Component {
                    ServicesPage {}
                }
                Component {
                    NotificationsPage {}
                }
                Component {
                    // Services → Screen recorder (index 2).
                    RecorderPanel {}
                }
            }
        },
        Component {
            // Language & region
            StackPage {
                Component {
                    LanguageAndRegion {}
                }
            }
        },

        // About
        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
            }
        }
    ]

}
