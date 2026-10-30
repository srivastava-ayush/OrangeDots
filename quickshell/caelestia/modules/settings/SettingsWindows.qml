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
        nexusComp.createObject(parent ?? dummy, props);
    }

    function openDashboardSettings(): void {
        const win = nexusComp.createObject(dummy);
        if (win) {
            win.nState.currentPageIdx = PageRegistry.pages.findIndex(page => page.id === "panels");
            // Panels' first subpage is Dashboard. The new StackPage restores
            // this stack when it is loaded, without signalling the old page.
            win.nState.subPageIdxStack = [1];
        }
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            readonly property alias nState: nexus.nState

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: qsTr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx]?.label ?? PageRegistry.pages[0].label)

            SettingsView {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
