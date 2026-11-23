pragma Singleton

import Quickshell
import Caelestia.Config

// Shared rhythm for every sidebar module; keep content-specific layout inside
// these common outer/header/card measurements rather than hard-coded insets.
Singleton {
    // A singleton has no screen to resolve per-monitor attached tokens against.
    // These shared metrics already resolve to the global appearance config, so
    // read it explicitly instead of triggering screen-less attached lookups.
    readonly property real padding: GlobalConfig.appearance.padding.large
    readonly property real gap: GlobalConfig.appearance.spacing.medium
    readonly property real smallGap: GlobalConfig.appearance.spacing.small
    readonly property real cardPadding: GlobalConfig.appearance.padding.medium
    readonly property real cardRadius: GlobalConfig.appearance.rounding.large
    readonly property real headerHeight: 48
}
