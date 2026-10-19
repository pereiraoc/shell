pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Atalhos do usuario na barra (V3-02): ~/.config/caelestia/shortcuts.json,
// editado em Nexus > Panels > Taskbar > Shortcuts. Cada um = nome, icone
// (simbolo Material, icone do tema ou caminho de imagem), comando e pasta.
Column {
    id: root

    property list<var> shortcuts: []
    readonly property int count: shortcuts.length

    function parse(text: string): void {
        try {
            const d = JSON.parse(text);
            root.shortcuts = (d.shortcuts ?? []).filter(s => s && s.command && s.enabled !== false);
        } catch (e) {
            console.warn("shortcuts.json:", e);
            root.shortcuts = [];
        }
    }

    function launch(s: var): void {
        const opts = { command: ["sh", "-c", s.command] };
        if (s.cwd)
            opts.workingDirectory = s.cwd;
        Quickshell.execDetached(opts);
    }

    spacing: Tokens.spacing.small

    Repeater {
        model: root.shortcuts

        Item {
            id: item

            required property var modelData

            readonly property string icon: modelData.icon ?? ""
            readonly property bool isImage: icon.includes("/")
            readonly property string themePath: !isImage && icon ? Quickshell.iconPath(icon, true) : ""

            implicitWidth: Tokens.font.body.small.pointSize * 2
            implicitHeight: implicitWidth

            StateLayer {
                radius: Tokens.rounding.full
                onClicked: root.launch(item.modelData)
            }

            IconImage {
                anchors.fill: parent
                visible: item.isImage || item.themePath !== ""
                asynchronous: true
                source: item.isImage ? `file://${item.icon}` : item.themePath
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: !item.isImage && item.themePath === ""
                text: item.icon || "bolt"
                color: Colours.palette.m3secondary
                fontStyle: Tokens.font.icon.medium
            }
        }
    }

    FileView {
        path: `${Paths.config}/shortcuts.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
        onLoadFailed: root.shortcuts = []
    }
}
