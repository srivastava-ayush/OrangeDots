pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings

Item {
    id: root

    readonly property SettingsState nState: SettingsState {
        id: nState

        onClose: root.close()
    }
    property color blobColour: Colours.tPalette.m3surfaceContainerLow

    signal close
    Keys.onEscapePressed: root.close()

    function navigateTo(page: string, subPages: var): void {
        nState.searchOpen = false;
        nState.subPageIdxStack = [];
        nState.currentPageIdx = Math.max(0, PageRegistry.pages.findIndex(entry => entry.id === page));
        nState.subPageIdxStack = Array.isArray(subPages) ? subPages.slice() : [];
        pages.reloadCurrentPage();
    }

    implicitWidth: Math.round(implicitHeight * Tokens.sizes.nexus.ratio)
    implicitHeight: Math.round(nState.screen.height * Tokens.sizes.nexus.heightMult)

    Behavior on blobColour {
        CAnim {}
    }

    TapHandler {
        onTapped: root.focus = true
    }

    BlobGroup {
        id: blobGroup

        smoothing: root.Tokens.rounding.medium
        color: root.blobColour
    }

    BlobInvertedRect {
        anchors.fill: parent
        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.large

        borderLeft: navPane.width + navPane.anchors.margins * 2
        borderRight: Tokens.padding.medium
        borderTop: Tokens.padding.medium
        borderBottom: Tokens.padding.medium
    }

    BlobRect {
        id: windowBtnRect

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.extraSmall

        group: blobGroup
        opacity: root.blobColour.a
        radius: Tokens.rounding.medium

        implicitWidth: windowBtn.implicitWidth + Tokens.padding.small * 2
        implicitHeight: windowBtn.implicitHeight + Tokens.padding.small
    }

    IconButton {
        id: windowBtn
        objectName: "nexusClose"

        anchors.centerIn: windowBtnRect
        icon: "close"
        type: IconButton.Text
        label.fill: 0
        inactiveOnColour: hovered ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        stateLayer.opacity: 0
        onClicked: root.close()

        label.scale: pressed ? 0.8 : 1
        label.renderType: Text.QtRendering

        Behavior on label.scale {
            Anim {}
        }
    }

    SettingsNavigation {
        id: navPane

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        nState: nState
        width: Math.min(Tokens.sizes.nexus.maxNavWidth, Math.round(root.width / 3))
    }

    SettingsPages {
        id: pages
        anchors.left: navPane.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: navPane.anchors.margins + anchors.margins
        anchors.margins: Tokens.padding.extraLarge

        nState: nState
    }
}
