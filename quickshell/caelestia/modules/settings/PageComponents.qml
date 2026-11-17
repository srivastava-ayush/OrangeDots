
pragma Singleton

import QtQuick
import qs.modules.settings.common
import qs.modules.settings.pages
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
        // 1. Desktop & Style
        Component {
            StackPage {
                Component { WallpaperAndStyle {} }
                Component { WallpaperSelect {} }
                Component { WallpaperCategory {} }
                Component { ColourSelect {} }
                Component { ColoursPage {} }
                Component { InterfacePage {} }
                Component { DesktopPage {} }
            }
        },

        // 2. Panels
        Component {
            StackPage {
                Component { PanelsPage {} }
                Component { DashboardPanel {} }
                Component { TaskbarPanel {} }
                Component { LauncherPanel {} }

                // Taskbar sub-pages
                Component { BarWorkspaces {} }
                Component { BarActiveWindow {} }
                Component { BarTray {} }
                Component { BarStatusIcons {} }
                Component { BarClock {} }
                Component { NotificationShadePanel {} }

                // Sidebar sub-pages
                Component { SidebarPanel {} }
                Component { SidebarSidePanel { side: "left" } }
                Component { SidebarSidePanel { side: "right" } }
                Component { SidebarModulesPanel {} }
                Component { SidebarCalendarPanel {} }

                // Launcher sub-pages
                Component { AllApps {} }
                Component { AppInfo {} }
            }
        },

        // 3. WiFi / Network
        Component {
            StackPage {
                Component { NetworkPage {} }
                Component { EthernetDetailPage {} }
                Component { AddNetworkPage {} }
                Component { NetworkDetailPage {} }
                Component { AddVpnPage {} }
                Component { AllNetworksPage {} }
                Component { SavedNetworksPage {} }
            }
        },

        // 4. Bluetooth
        Component {
            StackPage {
                Component { BluetoothPage {} }
                Component { BtDeviceInfo {} }
                Component { BluetoothPairing {} }
            }
        },

        // 5. Audio
        Component {
            StackPage {
                Component { AudioPage {} }
                Component { AppVolumes {} }
            }
        },

        // 6. Power & Sleep
        Component {
            StackPage {
                Component { PowerAndSleepPage {} }
                Component { LockScreenPage {} }
            }
        },

        // 7. Services
        Component {
            StackPage {
                Component { ServicesPage {} }
                Component { NotificationsPage {} }
                Component { RecorderPanel {} }
                Component { OnScreenDisplayPage {} }
            }
        },

        // 8. Language & Region
        Component {
            StackPage {
                Component { LanguageAndRegion {} }
            }
        },

        // 9. Apps
        Component {
            StackPage {
                Component { AppsPage {} }
            }
        },

        // 10. About
        Component {
            StackPage {
                Component { AboutPage {} }
            }
        }
    ]
}
