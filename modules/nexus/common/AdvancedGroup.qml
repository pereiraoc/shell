pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.nexus.common

// Secao "Advanced" com os apps externos do assunto. So os instalados
// aparecem, e first/last saem da lista visivel (cantos certos); sem nenhum
// instalado a secao inteira some.
//
//     AdvancedGroup {
//         apps: [{ id: "nwg-displays", text: qsTr("Arrange displays"), subtext: "..." },
//                { id: "rog-control-center", alt: ["org.foo.rog"], text: ..., subtext: ... }]
//     }
ColumnLayout {
    id: root

    property var apps: []

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

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2
    visible: root.installed.length > 0

    SectionHeader {
        text: qsTr("Advanced")
    }

    Repeater {
        model: root.installed

        NavRow {
            required property var modelData
            required property int index

            first: index === 0
            last: index === root.installed.length - 1
            icon: "apps"
            trailingIcon: "open_in_new"
            text: modelData.text
            subtext: modelData.subtext ?? ""
            onClicked: modelData.entry.execute()
        }
    }
}
