pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    readonly property list<ShellScreen> screens: Quickshell.screens.filter(s => GlobalConfig.forScreen(s.name).enabled)

    // Lado da barra por monitor (Nexus > Display). Barra na direita espelha o
    // shell naquele monitor: a barra e os popouts vao para a direita e os
    // paineis da borda direita (notificacoes, sidebar, OSD, sessao,
    // utilitarios) vao para a esquerda. "mirrorVisualiser" vira o
    // visualizador do fundo junto.
    //
    //     ~/.config/caelestia/bar-sides.json
    //     { "eDP-1": { "side": "right", "mirrorVisualiser": true } }
    //
    // Monitor ausente do arquivo = barra na esquerda (padrao do caelestia).
    property var barSides: ({})

    function isExcluded(screen: ShellScreen): bool {
        return !GlobalConfig.forScreen(screen.name).enabled;
    }

    function barRight(screenName: string): bool {
        return root.barSides[screenName]?.side === "right";
    }

    // Padrao: o visualizador acompanha a barra.
    function mirrorVisualiser(screenName: string): bool {
        return root.barRight(screenName) && root.barSides[screenName]?.mirrorVisualiser !== false;
    }

    function setBarOption(screenName: string, key: string, value: var): void {
        const next = JSON.parse(JSON.stringify(root.barSides));
        next[screenName] = Object.assign({}, next[screenName] ?? {}, { [key]: value });
        if (next[screenName].side !== "right")
            delete next[screenName];
        root.barSides = next;
        barSidesFile.setText(JSON.stringify(next, null, 4) + "\n");
    }

    FileView {
        id: barSidesFile

        path: `${Paths.config}/bar-sides.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.barSides = d && typeof d === "object" ? d : {};
            } catch (e) {
                root.barSides = {};
            }
        }
        onLoadFailed: root.barSides = {}
    }
}
