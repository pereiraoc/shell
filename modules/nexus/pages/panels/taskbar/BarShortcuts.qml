pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

// Atalhos da barra (V3-02): lista em ~/.config/caelestia/shortcuts.json, que
// o widget modules/bar/components/Shortcuts.qml observa. Vaults do Obsidian
// encontrados (flatpak ou nativo) viram atalho com um toque.
PageBase {
    id: root

    property var shortcuts: []
    property var vaults: []
    property string draftName
    property string draftIcon
    property string draftCommand
    property string draftCwd
    readonly property int barIndex: GlobalConfig.bar.entries.values.findIndex(e => e.id === "shortcuts")
    readonly property bool onBar: root.barIndex >= 0 && GlobalConfig.bar.entries.values[root.barIndex].enabled
    readonly property bool draftReady: root.draftName.trim() !== "" && root.draftCommand.trim() !== ""

    function save(list: var): void {
        root.shortcuts = list;
        file.setText(JSON.stringify({ shortcuts: list }, null, 4) + "\n");
    }

    function parse(text: string): void {
        try {
            const d = JSON.parse(text);
            root.shortcuts = Array.isArray(d.shortcuts) ? d.shortcuts : [];
        } catch (e) {
            root.shortcuts = [];
        }
    }

    // Entrada "shortcuts" na lista da barra (GlobalConfig.bar.entries): liga
    // a existente ou cria uma logo abaixo das workspaces
    function setOnBar(on: bool): void {
        const entries = GlobalConfig.bar.entries;
        const i = entries.values.findIndex(e => e.id === "shortcuts");
        if (i >= 0) {
            entries.at(i).enabled = on;
            return;
        }
        if (!on)
            return;
        entries.insert({ id: "shortcuts", enabled: true });
        const ws = entries.values.findIndex(e => e.id === "workspaces");
        const last = entries.values.length - 1;
        if (ws >= 0 && last > ws + 1)
            entries.move(last, ws + 1);
    }

    function addVaults(text: string): void {
        try {
            const d = JSON.parse(text);
            const list = [...root.vaults];
            for (const v of Object.values(d.vaults ?? {})) {
                if (v && v.path && !list.some(x => x.path === v.path))
                    list.push({ name: v.path.split("/").filter(x => x).pop(), path: v.path });
            }
            root.vaults = list;
        } catch (e) {
        }
    }

    function addDraft(): void {
        if (!root.draftReady)
            return;
        root.save([...root.shortcuts, { name: root.draftName.trim(), icon: root.draftIcon.trim(), command: root.draftCommand.trim(), cwd: root.draftCwd.trim(), enabled: true }]);
        nameField.clear();
        iconField.clear();
        commandField.clear();
        cwdField.clear();
        root.draftName = "";
        root.draftIcon = "";
        root.draftCommand = "";
        root.draftCwd = "";
    }

    function addVault(v: var): void {
        root.save([...root.shortcuts, { name: v.name, icon: "md.obsidian.Obsidian", command: `xdg-open "obsidian://open?vault=${encodeURIComponent(v.name)}"`, cwd: "", enabled: true }]);
    }

    title: Tr.tr("Shortcuts")
    isSubPage: true

    // PageBase so aceita Item como filho direto, e o ultimo Item vira o
    // conteudo: os arquivos ficam embrulhados aqui, antes do layout
    Item {
        FileView {
            id: file

            path: `${Paths.config}/shortcuts.json`
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: root.parse(text())
            onLoadFailed: root.shortcuts = []
        }

        FileView {
            path: `${Paths.home}/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json`
            printErrors: false
            onLoaded: root.addVaults(text())
        }

        FileView {
            path: `${Paths.config}/../obsidian/obsidian.json`
            printErrors: false
            onLoaded: root.addVaults(text())
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Taskbar")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Show on the taskbar")
            subtext: Tr.tr("Below the workspaces; takes no room while the list is empty")
            checked: root.onBar
            onToggled: root.setOnBar(checked)
        }

        SectionHeader {
            text: Tr.tr("Your shortcuts")
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: root.shortcuts.length === 0
            first: true
            last: true
            implicitHeight: emptyText.implicitHeight + Tokens.padding.large * 2

            StyledText {
                id: emptyText

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("Nothing yet. Add one below, or pick an Obsidian vault.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }
        }

        ListEditor {
            function labelFor(item: var): string {
                return item.name || item.command;
            }

            function toggledFor(item: var): bool {
                return item.enabled !== false;
            }

            z: 1
            first: true
            visible: root.shortcuts.length > 0
            values: root.shortcuts
            onItemMoved: (from, to) => {
                const l = [...root.shortcuts];
                const [m] = l.splice(from, 1);
                l.splice(to, 0, m);
                root.save(l);
            }
            onItemRemoved: index => {
                const l = [...root.shortcuts];
                l.splice(index, 1);
                root.save(l);
            }
            onItemToggled: (index, checked) => root.save(root.shortcuts.map((x, i) => i === index ? Object.assign({}, x, { enabled: checked }) : x))
        }

        SectionHeader {
            text: Tr.tr("Add a shortcut")
        }

        TextFieldRow {
            id: nameField

            first: true
            label: Tr.tr("Name")
            value: root.draftName
            maximumLength: 40
            onValueEdited: v => root.draftName = v
        }

        TextFieldRow {
            id: iconField

            label: Tr.tr("Icon")
            subtext: Tr.tr("Material symbol (folder, terminal…), an app icon name or an image path")
            value: root.draftIcon
            maximumLength: 300
            onValueEdited: v => root.draftIcon = v
        }

        TextFieldRow {
            id: commandField

            label: Tr.tr("Command")
            subtext: Tr.tr("Run by sh -c")
            value: root.draftCommand
            maximumLength: 500
            onValueEdited: v => root.draftCommand = v
        }

        TextFieldRow {
            id: cwdField

            label: Tr.tr("Folder")
            subtext: Tr.tr("Optional working directory")
            value: root.draftCwd
            maximumLength: 300
            onValueEdited: v => root.draftCwd = v
        }

        RowButton {
            last: true
            icon: "add"
            text: Tr.tr("Add to the list")
            subtext: root.draftReady ? Tr.tr("%1 → %2").arg(root.draftName.trim()).arg(root.draftCommand.trim()) : Tr.tr("Name and command are required")
            disabled: !root.draftReady
            onClicked: root.addDraft()
        }

        SectionHeader {
            visible: root.vaults.length > 0
            text: Tr.tr("Obsidian vaults")
        }

        Repeater {
            model: root.vaults

            RowButton {
                id: vaultRow

                required property var modelData
                required property int index

                readonly property bool added: root.shortcuts.some(s => s.command && s.command.includes(`vault=${encodeURIComponent(vaultRow.modelData.name)}`))

                first: index === 0
                last: index === root.vaults.length - 1
                icon: "book_2"
                text: modelData.name
                subtext: added ? Tr.tr("Already on the list · %1").arg(modelData.path) : modelData.path
                trailingIcon: added ? "check" : "add"
                disabled: added
                onClicked: root.addVault(modelData)
            }
        }
    }
}
