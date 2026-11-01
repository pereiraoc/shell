pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.modules.nexus.common

// "Open the app": o link para o aplicativo com que a ferramenta desta pagina
// conversa (asusctl -> ROG Control Center, OpenRazer -> Polychromatic, presets ->
// EasyEffects...). Regra (usuario, 01/11/2026): so entra app que a CLI da pagina
// integra de fato e que abre uma janela; biblioteca/daemon sem interface nao
// ganha botao. So os instalados aparecem (entrada .desktop); sem nenhum, a
// secao some. Clique: se o app ja tem janela aberta, traz para a frente (apps
// de instancia unica rodando na bandeja nao abriam "nada"); senao lanca e a
// linha mostra "Opening..." por alguns segundos, para o clique ter resposta.
//
//     AdvancedGroup {
//         apps: [{ id: "nwg-displays", text: Tr.tr("Arrange displays"), subtext: "..." },
//                { id: "rog-control-center", alt: ["org.foo.rog"], text: ..., subtext: ... }]
//     }
ColumnLayout {
    id: root

    property var apps: []
    // id do app lancado ha pouco (feedback na linha)
    property string opening: ""

    readonly property var installed: {
        DesktopEntries.applications.values; // reavalia quando a lista carrega
        const out = [];
        for (const a of root.apps) {
            for (const id of [a.id, ...(a.alt ?? [])]) {
                const e = DesktopEntries.byId(id);
                if (e) {
                    out.push(Object.assign({ entry: e }, a));
                    break;
                }
            }
        }
        return out;
    }

    // Janela ja aberta de um dos ids (classe Wayland = id do .desktop, em geral)
    function openWindow(a: var): var {
        const ids = [a.id, ...(a.alt ?? [])].map(s => String(s).toLowerCase());
        for (const t of Hyprland.toplevels.values) {
            const cls = String(t.lastIpcObject?.class ?? "").toLowerCase();
            if (cls !== "" && ids.includes(cls))
                return t;
        }
        return null;
    }

    function open(a: var): void {
        const t = root.openWindow(a);
        if (t) {
            Hyprland.dispatch(`focuswindow address:${t.address}`);
            return;
        }
        a.entry.execute();
        root.opening = a.id;
        openingTimer.restart();
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2
    visible: root.installed.length > 0

    Timer {
        id: openingTimer

        interval: 4000
        onTriggered: root.opening = ""
    }

    SectionHeader {
        text: Tr.tr("OPEN THE APP")
    }

    Repeater {
        model: root.installed

        NavRow {
            id: row

            required property var modelData
            required property int index
            readonly property bool isOpening: root.opening === row.modelData.id

            first: row.index === 0
            last: row.index === root.installed.length - 1
            icon: row.isOpening ? "hourglass_top" : "open_in_new"
            trailingIcon: "open_in_new"
            text: row.isOpening ? Tr.tr("Opening %1…").arg(row.modelData.text) : row.modelData.text
            subtext: row.modelData.subtext ?? ""
            onClicked: root.open(row.modelData)
        }
    }
}
