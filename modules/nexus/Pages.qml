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

    function loadPage(idx: int, sync: bool): void {
        if (currentItem)
            currentItem.destroy();
        currentItem = null;

        // Paginas pesadas (Display) incubam de forma assincrona: trocar de
        // menu antes de terminar deixava a antiga nascer DEPOIS e ficar
        // empilhada sobre a nova. So a ultima pedida pode entrar.
        // A pagina INICIAL de uma janela nova nasce sincrona (a janela ainda
        // nem apareceu): assincrona, a subpagina pedida por IPC/Super+/
        // corria com a chegada dos dados e nascia sem largura, pingando.
        const serial = ++root.loadSerial;
        const comp = PageCompRegistry.forId(PageRegistry.pages[idx]?.id ?? "");
        const incubator = comp.incubateObject(container, {
            nState,
            pageIdx: idx
        }, sync ? Qt.Synchronous : Qt.Asynchronous);

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
        Component.onCompleted: root.loadPage(root.nState.currentPageIdx, true)
    }

    Connections {
        function onCurrentPageIdxChanged(): void {
            switchAnim.complete();
            root.animOff = root.Tokens.padding.medium * (root.nState.currentPageIdx > root.lastPageIdx ? 1 : -1);
            switchAnim.start();
            root.lastPageIdx = root.nState.currentPageIdx;
        }

        target: root.nState
    }

    // Troca de pagina "snappy" (18/10/2026): antes eram 200 ms de fade-out +
    // 300 ms de fade-in e deslize -- meio segundo parado a cada clique no menu,
    // sendo que a pagina nova nasce em 20-100 ms. Agora a antiga some na hora e
    // a nova entra num fade curto com um deslize pequeno.
    SequentialAnimation {
        id: switchAnim

        PropertyAction {
            target: container
            property: "opacity"
            value: 0
        }
        ScriptAction {
            script: root.loadPage(root.nState.currentPageIdx, false)
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
                duration: 120
            }
            Anim {
                target: container.anchors
                properties: "topMargin,bottomMargin"
                to: 0
                duration: 120
            }
        }
    }
}
