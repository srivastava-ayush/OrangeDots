import QtQuick
import Caelestia.Config
import qs.components
import qs.modules.settings

Item {
    id: root

    required property SettingsState nState

    property int lastPageIdx
    property int animOff
    property Item currentItem
    property int loadGeneration: 0

    function reloadCurrentPage(): void {
        switchAnim.stop();
        container.opacity = 1;
        container.anchors.topMargin = 0;
        container.anchors.bottomMargin = 0;
        loadPage(nState.currentPageIdx);
    }

    function loadPage(idx: int): void {
        const generation = ++loadGeneration;
        if (currentItem) {
            const previous = currentItem;
            currentItem = null;
            previous.destroy();
        }

        const comp = PageComponents.pageComps[idx] ?? PageComponents.pageComps[0];
        const incubator = comp.incubateObject(container, {
            nState
        });

        const attach = () => {
            if (!incubator.object) return;
            if (generation !== root.loadGeneration) {
                incubator.object.destroy();
                return;
            }
            incubator.object.anchors.fill = container;
            currentItem = incubator.object;
        };

        if (incubator.status === Component.Ready)
            attach();
        else
            incubator.onStatusChanged = status => {
                if (status === Component.Ready)
                    attach();
            };
    }

    Item {
        id: container

        objectName: "PageContainer"
        anchors.fill: parent
        layer.enabled: opacity < 1
        Component.onCompleted: root.loadPage(root.nState.currentPageIdx)
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            switchAnim.complete();
            root.animOff = root.Tokens.padding.extraLarge * (root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    SequentialAnimation {
        id: switchAnim

        Anim {
            target: container
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx)
        }
        PropertyAction {
            target: container.anchors
            property: "topMargin"
            value: root.animOff
        }
        PropertyAction {
            target: container.anchors
            property: "bottomMargin"
            value: -root.animOff
        }
        ParallelAnimation {
            Anim {
                target: container
                property: "opacity"
                from: 0
                to: 1
                type: Anim.SlowEffects
            }
            Anim {
                target: container.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                type: Anim.SlowEffects
            }
        }
    }
}
