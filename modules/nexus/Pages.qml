import QtQuick
import Caelestia.Config
import qs.components
import qs.modules.nexus

Item {
    id: root

    required property NexusState nState

    property int lastPageIdx
    property int animOff
    property Item currentItem

    property int loadSerial

    function loadPage(idx: int): void {
        if (currentItem)
            currentItem.destroy();
        currentItem = null;

        // Paginas pesadas (Display) incubam de forma assincrona: trocar de
        // menu antes de terminar deixava a antiga nascer DEPOIS e ficar
        // empilhada sobre a nova. So a ultima pedida pode entrar.
        const serial = ++root.loadSerial;
        const comp = PageCompRegistry.forId(PageRegistry.pages[idx]?.id ?? "");
        const incubator = comp.incubateObject(container, {
            nState
        });

        const attach = () => {
            if (serial !== root.loadSerial) {
                incubator.object.destroy();
                return;
            }
            if (currentItem)
                currentItem.destroy();
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
