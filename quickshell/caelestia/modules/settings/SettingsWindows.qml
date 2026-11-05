pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.settings

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        // Keep the public entry point, but never create a standalone window.
        const index = props?.["nState.currentPageIdx"] ?? 0;
        const page = PageRegistry.pages[index]?.id ?? "appearance";
        openPage(page, props?.["nState.subPageIdxStack"] ?? []);
    }

    function openPage(page: string, subPages: var): void {
        const fallbackScreen = Quickshell.screens[0];
        const host = ShellState.componentsForActive()
            ?? (fallbackScreen ? ShellState.componentsFor(fallbackScreen) : null);
        const popouts = host?.panels?.popouts;
        if (!popouts) {
            console.warn("Nexus cannot open before the shell panels are ready.");
            return;
        }
        // Reuse the very same morph/overlay path as Bluetooth/audio expansion.
        if (!popouts.hasCurrent && !popouts.isDetached)
            popouts.currentCenter = Taskbar.horizontal ? host.modelData.width / 2 : host.modelData.height / 2;
        popouts.openNexus(page, subPages);
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
