pragma Singleton

import Quickshell
import Caelestia.Config

// Shared rhythm for every sidebar module; keep content-specific layout inside
// these common outer/header/card measurements rather than hard-coded insets.
Singleton {
    readonly property real padding: Tokens.padding.large
    readonly property real gap: Tokens.spacing.medium
    readonly property real smallGap: Tokens.spacing.small
    readonly property real cardPadding: Tokens.padding.medium
    readonly property real cardRadius: Tokens.rounding.large
    readonly property real headerHeight: 48
}
