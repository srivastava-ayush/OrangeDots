pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.settings

Singleton {
    id: root

    // Detached Nexus: a real XDG toplevel, so it can be moved, resized, pinned
    // and focused like any other window instead of living inside the taskbar's
    // layer surface.
    readonly property LazyLoader nexusWindowLoader: LazyLoader {
        id: nexusWindowLoader

        property string queuedPage: "appearance"
        property var queuedSubPages: []
        property ShellScreen targetScreen

        activeAsync: false

        FloatingWindow {
            id: nexusWindow

            function navigateTo(page: string, subPages: var): void {
                nexusWindowView.navigateTo(page, subPages);
            }

            title: qsTr("Nexus")
            screen: nexusWindowLoader.targetScreen
            color: "transparent"
            surfaceFormat.opaque: false
            implicitWidth: nexusClip.implicitWidth
            implicitHeight: nexusClip.implicitHeight
            minimumSize.width: TokenConfig.sizes.nexus.minWidth
            minimumSize.height: TokenConfig.sizes.nexus.minHeight
            contentItem.Config.screen: nexusWindowLoader.targetScreen?.name ?? ""

            StyledClippingRect {
                id: nexusClip

                anchors.fill: parent
                radius: Tokens.rounding.extraLarge
                implicitHeight: Math.round((nexusWindowLoader.targetScreen?.height ?? 1080) * Tokens.sizes.nexus.heightMult)
                implicitWidth: Math.round(implicitHeight * Tokens.sizes.nexus.ratio)

                SettingsView {
                    id: nexusWindowView

                    anchors.fill: parent
                    focus: true
                    detachable: false
                    nState.screen: nexusWindowLoader.targetScreen
                    Component.onCompleted: navigateTo(nexusWindowLoader.queuedPage, nexusWindowLoader.queuedSubPages)
                    onClose: nexusWindowLoader.activeAsync = false
                }
            }

            // Closing from the compositor (Alt+F4, window rules, …) must reset
            // the loader so the next request creates a fresh window.
            onVisibleChanged: {
                if (!visible)
                    nexusWindowLoader.activeAsync = false;
            }
        }
    }

    readonly property var window: nexusWindowLoader.item
    readonly property bool windowOpen: !!root.window

    function create(parent: Item, props: var): void {
        // Keep the public entry point, but never create a standalone window
        // unless explicitly asked for via popOut().
        const index = props?.["nState.currentPageIdx"] ?? 0;
        const page = PageRegistry.pages[index]?.id ?? "appearance";
        openPage(page, props?.["nState.subPageIdxStack"] ?? []);
    }

    function openPage(page: string, subPages: var): void {
        // A detached window is already the most "open" Nexus; reuse it instead
        // of stacking a second settings surface on top.
        if (root.windowOpen) {
            root.window.navigateTo(page, subPages);
            return;
        }
        const fallbackScreen = Quickshell.screens[0];
        const host = ShellState.componentsForActive()
            ?? (fallbackScreen ? ShellState.componentsFor(fallbackScreen) : null);
        const popouts = host?.panels?.popouts;
        if (!popouts) {
            console.warn("Nexus cannot open before the shell panels are ready.");
            return;
        }
        // Reuse the very same morph/overlay path as Bluetooth/audio expansion.
        // Seed the origin with the status-icon cluster so the overlay grows out
        // of the taskbar and collapses back into it, instead of materialising
        // at the screen centre. currentCenter survives close, so the exit
        // animation retraces the same point.
        if (!popouts.hasCurrent && !popouts.isDetached)
            popouts.currentCenter = host.panels?.statusIconCenter ?? (Taskbar.horizontal ? host.modelData.width / 2 : host.modelData.height / 2);
        popouts.openNexus(page, subPages);
    }

    // Tear the overlay off the taskbar and host the same page in a normal
    // window. The caller is responsible for closing the attached overlay.
    function popOut(page: string, subPages: var, screen: ShellScreen): void {
        nexusWindowLoader.queuedPage = PageRegistry.pages.some(entry => entry.id === page) ? page : "appearance";
        nexusWindowLoader.queuedSubPages = Array.isArray(subPages) ? subPages.slice() : [];
        nexusWindowLoader.targetScreen = screen ?? Quickshell.screens[0] ?? null;
        nexusWindowLoader.activeAsync = true;
    }

    function closeWindow(): void {
        nexusWindowLoader.activeAsync = false;
    }

    function openDashboardSettings(): void {
        openPage("panels", [1]);
    }

    function openAiSettings(): void {
        // Compatibility for existing callers; the panel is now module-neutral.
        openSidebarSettings();
    }

    function openSidebarSettings(): void {
        openPage("panels", [10]);
    }

    function openCalendarSettings(): void {
        openPage("panels", [10, 13, 14]);
    }
}
