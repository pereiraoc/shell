pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    // Janelas abertas, para o botao da barra alternar em vez de empilhar.
    property list<QtObject> windows: []

    function create(parent: Item, props: var): void {
        const w = nexusComp.createObject(parent ?? dummy, props);
        root.windows = [...root.windows, w];
    }

    // Botao da barra: fecha se ja houver Nexus aberto, senao abre.
    function toggle(): void {
        if (root.windows.length > 0) {
            for (const w of [...root.windows])
                w.destroy();
        } else {
            root.create();
        }
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            Component.onDestruction: root.windows = root.windows.filter(x => x !== win)

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: qsTr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
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
