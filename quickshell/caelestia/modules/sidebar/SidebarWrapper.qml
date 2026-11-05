pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.settings

Item {
    id: root
    required property ScreenState screenState
    property string side: "right"
    readonly property bool onLeft: side === "left"
    readonly property var sideLayout: SidebarConfig.layoutFor(side)
    readonly property var moduleIds: SidebarConfig.modulesFor(side)
    // Keep the old panel/chat aliases available to runtime integrations.
    property var chatState: null
    property string selectedModule: SidebarConfig.defaultFor(side)
    readonly property bool shouldBeActive: (onLeft ? screenState.leftSidebar : screenState.ai) && sideLayout.enabled
    function close(): void {
        if (onLeft) screenState.leftSidebar = false;
        else screenState.ai = false;
    }
    function syncSelection(): void {
        if (!moduleIds.includes(selectedModule)) selectedModule = SidebarConfig.defaultFor(side);
    }
    property real topClearance: 0
    property real hideInset: 0
    property real preferredHeight: sideLayout.fullHeight && parent ? parent.height : sideLayout.panelHeight
    property real offsetScale: shouldBeActive ? 0 : 1
    implicitWidth: Math.min(sideLayout.panelWidth, parent ? parent.width : sideLayout.panelWidth)
    // Animate the preferred size, not the constrained height: an extra height
    // animation would lag behind the toast's moving edge and cause overlap.
    implicitHeight: Math.min(preferredHeight, parent ? Math.max(0, parent.height - topClearance) : preferredHeight)
    anchors.rightMargin: onLeft ? 0 : (-implicitWidth - 5) * offsetScale
    anchors.leftMargin: onLeft ? (-implicitWidth - hideInset - 5) * offsetScale : 0
    visible: offsetScale < 1
    opacity: 1 - offsetScale
    clip: true
    focus: shouldBeActive && !moduleIds.length
    Keys.onEscapePressed: root.close()

    Connections {
        target: root.sideLayout
        function onEnabledChanged(): void { if (!root.sideLayout.enabled) root.close(); }
    }
    Connections {
        target: SidebarConfig
        function onEnabledModulesChanged(): void { root.syncSelection(); }
        function onLeftModulesChanged(): void { root.syncSelection(); }
        function onDefaultModuleChanged(): void { if (!root.onLeft) root.selectedModule = SidebarConfig.defaultModule; }
        function onLeftDefaultModuleChanged(): void { if (root.onLeft) root.selectedModule = SidebarConfig.leftDefaultModule; }
    }

    Behavior on offsetScale {
        Anim { type: Anim.FastSpatial; easing.type: Easing.OutCubic }
    }
    Behavior on preferredHeight {
        Anim { type: Anim.FastSpatial; easing.type: Easing.OutCubic }
    }

    SidebarModules {
        id: moduleRegistry
        screenState: root.screenState
        selectedModule: root.selectedModule
        active: root.shouldBeActive
        onCloseRequested: root.close()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Flickable {
            visible: root.moduleIds.length > 1
            Layout.fillWidth: true
            Layout.preferredHeight: moduleTabs.implicitHeight
            Layout.leftMargin: SidebarStyle.padding
            Layout.rightMargin: SidebarStyle.padding
            Layout.topMargin: SidebarStyle.padding
            Layout.bottomMargin: 0
            contentWidth: moduleTabs.implicitWidth
            contentHeight: moduleTabs.implicitHeight
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Row {
                id: moduleTabs
                spacing: SidebarStyle.smallGap
                Repeater {
                    model: root.moduleIds
                    delegate: TextButton {
                        required property string modelData
                        objectName: "sidebarTab_" + modelData
                        text: SidebarConfig.moduleName(modelData)
                        type: root.selectedModule === modelData ? TextButton.Tonal : TextButton.Text
                        onHoveredChanged: if (hovered && root.shouldBeActive) root.selectedModule = modelData
                        onClicked: root.selectedModule = modelData
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.max(0, parent.width - SidebarStyle.padding * 2)
                visible: !root.moduleIds.length
                spacing: SidebarStyle.gap
                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Choose modules for this sidebar in Nexus.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font: Tokens.font.body.medium
                }
                TextButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Configure sidebar")
                    onClicked: { root.close(); SettingsWindows.openSidebarSettings(); }
                }
            }

            // Ordinary views exist only while visible (including the outgoing
            // fade). Keep AI's lightweight state owner, not its chat UI, alive
            // so closing/switching never discards conversations or live replies.
            Repeater {
                id: moduleLoaders
                model: SidebarConfig.modules
                onItemAdded: (index, loader) => {
                    if (loader.modelData.id === "ai")
                        root.chatState = Qt.binding(() => loader.item?.chatState ?? null);
                }
                onItemRemoved: (index, loader) => {
                    if (loader.modelData.id === "ai") root.chatState = null;
                }
                delegate: Loader {
                    id: moduleLoader
                    required property var modelData
                    objectName: "sidebarModuleLoader_" + modelData.id
                    readonly property bool current: root.selectedModule === modelData.id
                    property real transitionProgress: current ? 1 : 0
                    anchors.fill: parent
                    active: root.moduleIds.includes(modelData.id)
                        && (modelData.id === "ai" || (root.visible && transitionProgress > 0))
                    visible: transitionProgress > 0
                    enabled: current
                    opacity: transitionProgress
                    z: current ? 1 : 0
                    transform: Translate { y: (1 - moduleLoader.transitionProgress) * 10 }
                    sourceComponent: moduleRegistry.componentFor(modelData.id)

                    Behavior on transitionProgress {
                        Anim {
                            type: Anim.FastEffects
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
    }
}
