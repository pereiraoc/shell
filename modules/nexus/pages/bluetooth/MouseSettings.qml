pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Um mouse com driver (Devices > <mouse> > Buttons, DPI stages and power):
// remapear botoes (atalhos do Hyprland so deste mouse -- caelestia-peripherals
// `btn-<modelo>-<botao>-<acao>`), estagios de DPI do botao do mouse, tempo
// para dormir e alerta de bateria. Tudo aplica na hora.
PageBase {
    id: root

    readonly property var mouse: (bridge.info.mice ?? []).find(m => m.model === root.nState.selectedMouse) ?? null
    readonly property bool asleep: !!root.mouse?.asleep
    readonly property var buttons: root.mouse?.buttons ?? []
    readonly property var sideButtons: root.buttons.filter(b => b.group === "side")
    readonly property var otherButtons: root.buttons.filter(b => b.group !== "side" && !b.locked)
    property string selected
    // Chip "Custom shortcut" escolhido, campo aberto (ainda sem aplicar)
    property bool customOpen
    readonly property bool isCustom: (root.selButton?.action ?? "").startsWith("key-")
    // Nada escolhido ate clicar num botao; clicar de novo no mesmo desmarca
    readonly property var selButton: root.buttons.find(b => b.id === root.selected) ?? null

    // Fila: um clique com outra acao em curso espera e vai em seguida.
    property var queue: []

    // Rascunho dos estagios de DPI (aplicado ~0,6 s depois da ultima mudanca)
    property bool stagesInited
    property var stages: []
    property int active: 1
    property string wantedStages
    property string sentStages

    // Acoes que viram gravacao no proprio mouse (o "sends" ja mostra o efeito)
    readonly property var mouseActions: ({ "disabled": 1, "factory": 1, "documented": 1, "original": 1, "left-click": 1, "right-click": 1, "media-stop": 1, "copy": 1, "paste": 1, "cut": 1, "undo": 1, "redo": 1, "select-all": 1, "enter": 1, "escape": 1, "back": 1, "forward": 1, "middle-click": 1, "new-tab": 1, "close-tab": 1, "reopen-tab": 1, "next-tab": 1, "prev-tab": 1, "reload": 1, "dpi-up": 1, "dpi-down": 1, "play-pause": 1, "next-track": 1, "prev-track": 1, "volume-up": 1, "volume-down": 1, "mute": 1 })

    // Icone (Material Symbols) de cada acao, ao lado do nome
    readonly property var actionIcons: ({ "default": "work", "factory": "factory", "documented": "bookmark", "disabled": "block", "custom": "keyboard", "middle-click": "mouse", "dpi-up": "add_circle", "dpi-down": "do_not_disturb_on", "copy": "content_copy", "paste": "content_paste", "cut": "content_cut", "undo": "undo", "redo": "redo", "select-all": "select_all", "enter": "keyboard_return", "escape": "cancel", "back": "arrow_back", "forward": "arrow_forward", "new-tab": "add_box", "close-tab": "tab_close", "reopen-tab": "tab_recent", "next-tab": "keyboard_tab", "prev-tab": "keyboard_tab_rtl", "reload": "refresh", "play-pause": "play_pause", "next-track": "skip_next", "prev-track": "skip_previous", "volume-up": "volume_up", "volume-down": "volume_down", "mute": "volume_off", "mic-mute": "mic_off", "launcher": "apps", "mon-left": "keyboard_double_arrow_left", "mon-right": "keyboard_double_arrow_right", "cursor-left": "arrow_left_alt", "cursor-right": "arrow_right_alt", "ws-1-1": "grid_view", "ws-1-2": "grid_view", "ws-1-3": "grid_view", "ws-2-1": "grid_view", "ws-2-2": "grid_view", "ws-2-3": "grid_view", "ws-3-1": "grid_view", "ws-3-2": "grid_view", "ws-3-3": "grid_view", "left-click": "left_click", "right-click": "right_click", "media-stop": "stop", "maximize": "fit_screen", "exit-fullscreen": "fullscreen_exit", "pin": "keep", "settings": "settings", "screenshot-screen": "screenshot_monitor", "goto-ws-1": "looks_one", "goto-ws-2": "looks_two", "goto-ws-3": "looks_3", "move-ws-1": "move_down", "move-ws-2": "move_down", "move-ws-3": "move_down", "goto-group-1": "looks_one", "goto-group-2": "looks_two", "goto-group-3": "looks_3", "move-group-1": "move_down", "move-group-2": "move_down", "move-group-3": "move_down", "next-subgroup": "arrow_downward", "prev-subgroup": "arrow_upward", "next-group": "east", "prev-group": "west", "scratchpad": "stack", "close-window": "close", "fullscreen": "fullscreen", "float": "picture_in_picture", "screenshot": "screenshot_region", "terminal": "terminal", "lock": "lock" })

    // Basico (largura toda, com o campo do Custom ao lado) + pares de grupos
    // em 2 colunas; cada par tem o mesmo numero de opcoes (mesmas linhas)
    readonly property var basicActions: ["default", "factory", "disabled", "custom"]
    // Grupos em linhas de 2-3 itens afins; pares (esquerda/direita) com o
    // mesmo numero de linhas
    readonly property var actionGroups: [
        { title: qsTr("Mouse"), icon: "mouse", rows: [["left-click", "middle-click", "right-click"], ["back", "forward"]] },
        { title: qsTr("Monitors (Shift: move window)"), icon: "desktop_windows", rows: [["mon-left", "mon-right"], ["cursor-left", "cursor-right"]] },
        { title: qsTr("DPI"), icon: "speed", rows: [["dpi-down", "dpi-up"]] },
        { title: qsTr("Clipboard"), icon: "content_paste", rows: [["copy", "paste", "cut"]] },
        { title: qsTr("Editing"), icon: "edit_note", rows: [["undo", "redo", "select-all"], ["enter", "escape"]] },
        { title: qsTr("Window"), icon: "web_asset", rows: [["maximize", "fullscreen", "exit-fullscreen"], ["float", "pin", "close-window"]] },
        { title: qsTr("Media"), icon: "music_note", rows: [["play-pause", "media-stop"], ["prev-track", "next-track"]] },
        { title: qsTr("Volume"), icon: "volume_up", rows: [["volume-up", "volume-down"], ["mute", "mic-mute"]] },
        { title: qsTr("Browser tabs"), icon: "tab", rows: [["new-tab", "close-tab", "reopen-tab"], ["reload", "prev-tab", "next-tab"]] },
        { title: qsTr("Apps · screen"), icon: "apps", rows: [["launcher", "terminal", "settings"], ["screenshot", "screenshot-screen", "lock"]] },
        { title: qsTr("Workspaces"), icon: "view_carousel", rows: [["prev-subgroup", "scratchpad", "next-subgroup"], ["goto-ws-1", "goto-ws-2", "goto-ws-3"], ["move-ws-1", "move-ws-2", "move-ws-3"]] },
        { title: qsTr("Groups"), icon: "view_module", rows: [["prev-group", "next-group"], ["goto-group-1", "goto-group-2", "goto-group-3"], ["move-group-1", "move-group-2", "move-group-3"]] },
        { title: qsTr("Group · workspace (Shift: move window)"), icon: "grid_view", full: true, rows: [["ws-1-1", "ws-1-2", "ws-1-3"], ["ws-2-1", "ws-2-2", "ws-2-3"], ["ws-3-1", "ws-3-2", "ws-3-3"]] }
    ]

    // Nome curto dentro do grupo (o titulo do grupo da o contexto)
    readonly property var shortLabels: ({ "close-window": qsTr("Close"), "float": qsTr("Float"), "prev-track": qsTr("Previous"), "next-track": qsTr("Next"), "volume-up": qsTr("Up"), "volume-down": qsTr("Down"), "new-tab": qsTr("New"), "close-tab": qsTr("Close"), "reopen-tab": qsTr("Reopen"), "prev-tab": qsTr("Previous"), "next-tab": qsTr("Next"), "prev-subgroup": qsTr("Previous"), "next-subgroup": qsTr("Next"), "prev-group": qsTr("Previous"), "next-group": qsTr("Next"), "goto-ws-1": qsTr("Go to 1"), "goto-ws-2": qsTr("Go to 2"), "goto-ws-3": qsTr("Go to 3"), "move-ws-1": qsTr("Move to 1"), "move-ws-2": qsTr("Move to 2"), "move-ws-3": qsTr("Move to 3"), "goto-group-1": qsTr("Go to 1"), "goto-group-2": qsTr("Go to 2"), "goto-group-3": qsTr("Go to 3"), "move-group-1": qsTr("Move to 1"), "move-group-2": qsTr("Move to 2"), "move-group-3": qsTr("Move to 3"), "mon-left": qsTr("View left"), "mon-right": qsTr("View right"), "cursor-left": qsTr("Cursor left"), "cursor-right": qsTr("Cursor right"), "scratchpad": qsTr("Scratchpad"), "screenshot": qsTr("Area"), "screenshot-screen": qsTr("Screen"), "lock": qsTr("Lock"), "settings": qsTr("Settings"), "pin": qsTr("Pin"), "mic-mute": qsTr("Toggle mic"), "left-click": qsTr("Left"), "middle-click": qsTr("Middle"), "right-click": qsTr("Right"), "play-pause": qsTr("Play/Pause"), "mute": qsTr("Toggle mute"), "fullscreen": qsTr("Full"), "exit-fullscreen": qsTr("Exit full") })

    // Grade 3x3: ws-G-W (ir; Shift = mover a janela)
    function gridLabel(a: string, short: bool): string {
        const m = /^ws-(\d)-(\d)$/.exec(a);
        if (!m)
            return "";
        return short ? `G${m[1]}·W${m[2]}` : qsTr("Group %1, workspace %2").arg(m[1]).arg(m[2]);
    }

    readonly property var actionLabels: ({
            "default": qsTr("Default"),
            "disabled": qsTr("Do nothing"),
            "custom": qsTr("Custom"),
            "left-click": qsTr("Left click"),
            "mon-left": qsTr("View left monitor"),
            "mon-right": qsTr("View right monitor"),
            "cursor-left": qsTr("Move cursor left"),
            "cursor-right": qsTr("Move cursor right"),
            "right-click": qsTr("Right click"),
            "media-stop": qsTr("Stop"),
            "maximize": qsTr("Maximize"),
            "exit-fullscreen": qsTr("Exit fullscreen"),
            "pin": qsTr("Pin to all workspaces"),
            "settings": qsTr("Open settings"),
            "screenshot-screen": qsTr("Screenshot of the screen"),
            "goto-ws-1": qsTr("Go to workspace 1"),
            "goto-ws-2": qsTr("Go to workspace 2"),
            "goto-ws-3": qsTr("Go to workspace 3"),
            "move-ws-1": qsTr("Move window to workspace 1"),
            "move-ws-2": qsTr("Move window to workspace 2"),
            "move-ws-3": qsTr("Move window to workspace 3"),
            "goto-group-1": qsTr("Go to group 1"),
            "goto-group-2": qsTr("Go to group 2"),
            "goto-group-3": qsTr("Go to group 3"),
            "move-group-1": qsTr("Move window to group 1"),
            "move-group-2": qsTr("Move window to group 2"),
            "move-group-3": qsTr("Move window to group 3"),
            "factory": qsTr("Factory"),
            "middle-click": qsTr("Middle click"),
            "dpi-up": qsTr("DPI up"),
            "dpi-down": qsTr("DPI down"),
            "copy": qsTr("Copy"),
            "paste": qsTr("Paste"),
            "cut": qsTr("Cut"),
            "undo": qsTr("Undo"),
            "redo": qsTr("Redo"),
            "select-all": qsTr("Select all"),
            "enter": qsTr("Enter"),
            "escape": qsTr("Escape"),
            "back": qsTr("Back"),
            "forward": qsTr("Forward"),
            "new-tab": qsTr("New tab"),
            "close-tab": qsTr("Close tab"),
            "reopen-tab": qsTr("Reopen tab"),
            "next-tab": qsTr("Next tab"),
            "prev-tab": qsTr("Previous tab"),
            "reload": qsTr("Reload"),
            "play-pause": qsTr("Play / pause"),
            "next-track": qsTr("Next track"),
            "prev-track": qsTr("Previous track"),
            "volume-up": qsTr("Volume up"),
            "volume-down": qsTr("Volume down"),
            "mute": qsTr("Toggle mute"),
            "mic-mute": qsTr("Toggle microphone"),
            "launcher": qsTr("Launcher"),
            "next-subgroup": qsTr("Next workspace"),
            "prev-subgroup": qsTr("Previous workspace"),
            "next-group": qsTr("Next group"),
            "prev-group": qsTr("Previous group"),
            "scratchpad": qsTr("Scratchpad"),
            "close-window": qsTr("Close window"),
            "fullscreen": qsTr("Fullscreen"),
            "float": qsTr("Float window"),
            "screenshot": qsTr("Screenshot"),
            "terminal": qsTr("Terminal"),
            "lock": qsTr("Lock screen")
        })

    function buttonName(b: var): string {
        if (!b)
            return "";
        if (b.group === "side")
            return qsTr("Side button %1").arg(b.id.split("-")[1]);
        return ({
                "middle": qsTr("Wheel click"),
                "left": qsTr("Left click"),
                "right": qsTr("Right click"),
                "dpi-up": qsTr("DPI up button"),
                "dpi-down": qsTr("DPI down button"),
                "wheel-up": qsTr("Scroll up"),
                "wheel-down": qsTr("Scroll down"),
                "back": qsTr("Back button"),
                "forward": qsTr("Forward button"),
                "button-6": qsTr("Button 6"),
                "button-7": qsTr("Button 7"),
                "button-8": qsTr("Button 8"),
                "tilt-left": qsTr("Tilt wheel left"),
                "tilt-right": qsTr("Tilt wheel right")
            })[b.id] ?? b.id;
    }

    // O que o botao faz sem remap
    function defaultText(b: var): string {
        if (!b)
            return "";
        // Mouse com memoria lida: o original e o que estava gravado nele
        if (b.onboard)
            return b.original ?? "";
        // sends = o que o botao manda de verdade (mapa aprendido da memoria
        // do mouse, ou o de fabrica 1..=)
        if (b.group === "side")
            return qsTr("sends %1").arg(b.sends ?? ({ minus: "-", equal: "=" })[b.key] ?? b.key);
        return ({
                "middle": qsTr("middle click"),
                "back": qsTr("goes back"),
                "forward": qsTr("goes forward"),
                "tilt-left": qsTr("scrolls sideways"),
                "tilt-right": qsTr("scrolls sideways")
            })[b.id] ?? qsTr("its normal function");
    }

    // key-ctrl.shift-F5 -> "Ctrl+Shift+F5"
    function actionText(a: string): string {
        if (a === "original")
            return qsTr("Original");
        if (a === "documented")
            return qsTr("Default (documented)");
        if (root.gridLabel(a, false))
            return root.gridLabel(a, false);
        const m = /^key-([a-z.]+)-(.+)$/.exec(a ?? "");
        if (m)
            return [...(m[1] === "none" ? [] : m[1].split(".").map(x => x[0].toUpperCase() + x.slice(1))), m[2]].join("+");
        return root.actionLabels[a] ?? a;
    }

    // "ctrl+shift+F5" -> "key-ctrl.shift-F5" ("" se invalido)
    function shortcutId(text: string): string {
        const parts = text.trim().split(/\s*\+\s*/).filter(x => x);
        if (parts.length === 0)
            return "";
        const key = parts.pop();
        const mods = parts.map(p => p.toLowerCase().replace("control", "ctrl").replace("win", "super"));
        if (!/^[A-Za-z0-9_]{1,24}$/.test(key) || mods.some(x => !["super", "ctrl", "alt", "shift"].includes(x)))
            return "";
        return `key-${mods.length ? mods.join(".") : "none"}-${key.length === 1 ? key.toLowerCase() : key}`;
    }

    // O que o botao faz agora, curto (rotulo do desenho e legenda)
    function nowText(b: var): string {
        if (!b)
            return "";
        if (b.action !== "default" && !(b.action in root.mouseActions))
            return root.actionText(b.action);
        if (b.action === "default" && b.default_action)
            return root.actionText(b.default_action);
        return b.sends ?? root.defaultText(b);
    }

    // Chip: "Default: X" / "Factory: X" mostram o que dariam neste botao
    function chipText(a: string): string {
        const b = root.selButton;
        // "default" = herda do perfil base (Productivity)
        if (a === "default" && b)
            return qsTr("Productivity: %1").arg(b.default_action ? root.actionText(b.default_action) : (b.default_text ?? root.defaultText(b)));
        // perfil documentado no repo (CS): volta ao documentado
        if (a === "documented" && b?.documented_text)
            return qsTr("Default: %1").arg(b.documented_text);
        if (a === "factory" && b?.factory_text)
            return qsTr("Factory: %1").arg(b.factory_text);
        return root.actionText(a);
    }

    function chipSelected(a: string): bool {
        if (a === "default" && root.mouse?.profile === "Productivity")
            return false;
        if (a === "custom")
            return root.isCustom || root.customOpen;
        return !root.customOpen && (root.selButton?.action ?? "default") === a;
    }

    function chipPicked(a: string): void {
        if (a === "default" && root.mouse?.profile === "Productivity")
            return;
        if (a === "custom") {
            root.customOpen = true;
            customField.forceActiveFocus();
        } else {
            root.customOpen = false;
            root.setAction(a);
        }
    }

    // Laterais: o que o botao faz (o numero vai no canto, pelo desenho)
    function spotLabel(b: var): string {
        if (b.group !== "side")
            return "";
        const g = /^ws-(\d)-(\d)$/.exec(b.action);
        if (g)
            return `${g[1]}·${g[2]}`;
        const t = root.nowText(b);
        if (t.length <= 3)
            return t;
        // Nao cabe legivel na tecla: icone da acao ("icon:<nome>")
        return `icon:${root.actionIcons[b.action] ?? root.actionIcons[b.default_action] ?? "keyboard"}`;
    }

    function toggle(id: string): void {
        root.selected = root.selected === id ? "" : id;
        root.customOpen = false;
    }

    function applyCustom(): void {
        const id = root.shortcutId(customField.text);
        if (id) {
            root.setAction(id);
            root.customOpen = false;
        }
    }

    function run(id: string): void {
        if (bridge.busyAction === "")
            bridge.run({ id: id });
        else
            root.queue = [...root.queue, id];
    }

    function setAction(action: string): void {
        if (!root.mouse || !root.selButton)
            return;
        root.run(`btn-${root.mouse.model}-${root.selButton.id}-${action}`);
    }

    // Acompanha o mouse (trocar de perfil muda os estagios), menos quando ha
    // uma edicao sua ainda nao enviada
    function initStages(): void {
        if (!root.mouse || (root.mouse.dpi_stages ?? []).length === 0)
            return;
        if (root.wantedStages && root.wantedStages !== root.sentStages)
            return;
        if (bridge.busyAction.startsWith("stages-"))
            return;
        root.stagesInited = true;
        root.stages = [...root.mouse.dpi_stages];
        root.active = root.mouse.dpi_active ?? 1;
        root.sentStages = root.stagesId();
    }

    function stagesId(): string {
        return `stages-${root.mouse?.id}-${Math.min(root.active, root.stages.length)}-${root.stages.join(".")}`;
    }

    function stagesEdited(): void {
        root.wantedStages = root.stagesId();
        stagesTimer.restart();
    }

    title: root.mouse ? root.mouse.name.replace(/\s*\(.*?\)\s*$/, "") : qsTr("Mouse")
    description: qsTr("Buttons, DPI stages and power")
    isSubPage: true

    onMouseChanged: Qt.callLater(root.initStages)
    Component.onCompleted: root.initStages()

    ToolBridge {
        id: bridge

        tool: "peripherals"
        onBusyActionChanged: {
            if (bridge.busyAction !== "")
                return;
            if (root.queue.length > 0) {
                const [next, ...rest] = root.queue;
                root.queue = rest;
                bridge.run({ id: next });
            } else if (root.wantedStages && root.wantedStages !== root.sentStages) {
                root.sentStages = root.wantedStages;
                bridge.run({ id: root.wantedStages });
            }
        }
    }

    // PageBase so aceita Item como filho direto.
    Item {
        Timer {
            id: stagesTimer

            interval: 600
            onTriggered: {
                if (!root.wantedStages || root.wantedStages === root.sentStages)
                    return;
                if (bridge.busyAction === "") {
                    root.sentStages = root.wantedStages;
                    bridge.run({ id: root.wantedStages });
                }
            }
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: !root.mouse
            icon: "mouse"
            label: qsTr("Mouse not found")
            subtext: qsTr("It may be off or disconnected. Turn it on and come back.")
        }

        InfoRow {
            first: true
            last: true
            visible: root.asleep
            icon: "bedtime"
            label: qsTr("The mouse is asleep")
            subtext: qsTr("Move it to wake it up. Button remaps still work; DPI and power need it awake.")
        }

        ActionErrorRow {
            bridge: bridge
        }

        // ------------------------------------------------------- Perfis
        // Gravados no Linux; o escolhido vai para a memoria do mouse (vale
        // depois de desligar e em qualquer computador): botoes + DPI
        MouseProfileBar {
            visible: !!root.mouse?.onboard
            profiles: root.mouse?.profiles ?? []
            current: root.mouse?.profile ?? ""
            busy: bridge.busyAction.startsWith("prof-")
            onUse: n => root.run(`prof-${root.mouse.model}-use-${n}`)
            onCreate: n => root.run(`prof-${root.mouse.model}-new-${n}`)
            onRename: (o, n) => root.run(`prof-${root.mouse.model}-ren-${o}-${n}`)
            onRemove: n => root.run(`prof-${root.mouse.model}-del-${n}`)
        }

        // ------------------------------------------------------- Botoes
        SectionHeader {
            visible: root.buttons.length > 0
            text: qsTr("Buttons")
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: root.buttons.length > 0
            first: true
            implicitHeight: btnCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: btnCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: diagram.available ? qsTr("Click a button on the mouse, then pick what it does. Highlighted buttons are remapped. Remaps apply right away and only to this mouse; holding Ctrl, Alt or Super keeps the original key.") : qsTr("Pick a button, then what it does. Remaps apply right away and only to this mouse; holding Ctrl, Alt or Super keeps the original key.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                // Silhueta clicavel (mouses com desenho em assets/mice); os
                // outros ficam com as grades de botoes abaixo
                MouseDiagram {
                    id: diagram

                    Layout.fillWidth: true
                    model: root.mouse?.model ?? ""
                    buttons: root.buttons
                    selected: root.selButton?.id ?? ""
                    labeler: b => root.spotLabel(b)
                    onPicked: id => root.toggle(id)
                }

                // Botao sob o mouse (ou o escolhido): nome e o que faz agora
                StyledText {
                    readonly property var shown: root.buttons.find(b => b.id === diagram.hovered) ?? root.selButton

                    Layout.fillWidth: true
                    // Sempre ocupa o lugar (nada pula ao passar de um botao a outro)
                    visible: diagram.available
                    horizontalAlignment: Text.AlignHCenter
                    text: shown ? `${root.buttonName(shown)} · ${root.nowText(shown)}${shown.locked ? " · " + qsTr("locked") : ""}` : qsTr("Point at a button to see what it does, click it to change it")
                    color: diagram.hovered ? Colours.palette.m3onSurface : Colours.palette.m3outline
                    font: Tokens.font.label.medium
                    elide: Text.ElideRight
                }

                // Grade lateral, na mesma disposicao do mouse (3 x 4)
                StyledText {
                    visible: !diagram.available && root.sideButtons.length > 0
                    text: qsTr("Side buttons")
                    font: Tokens.font.body.small
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: !diagram.available && root.sideButtons.length > 0
                    columns: 3
                    columnSpacing: Tokens.spacing.small
                    rowSpacing: Tokens.spacing.small

                    Repeater {
                        model: root.sideButtons.length

                        ButtonTile {
                            // Modelo = quantidade: atualizar o status nao recria a linha
                            // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                            // que vai sumir guarda o ultimo item ate ser destruida.
                            property var modelData: root.sideButtons[index] ?? ({})
                            readonly property var liveItem: root.sideButtons[index]
                            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                            required property int index

                            title: modelData.id.split("-")[1]
                            detail: modelData.action === "default" ? root.defaultText(modelData) : root.actionText(modelData.action)
                            remapped: modelData.action !== "default"
                            selected: root.selButton?.id === modelData.id
                            onPicked: root.toggle(modelData.id)
                        }
                    }
                }

                StyledText {
                    visible: !diagram.available && root.otherButtons.length > 0
                    text: qsTr("Other buttons")
                    font: Tokens.font.body.small
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: !diagram.available && root.otherButtons.length > 0
                    columns: Math.max(2, Math.floor(width / 150))
                    columnSpacing: Tokens.spacing.small
                    rowSpacing: Tokens.spacing.small

                    Repeater {
                        model: root.otherButtons.length

                        ButtonTile {
                            // Modelo = quantidade: atualizar o status nao recria a linha
                            // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                            // que vai sumir guarda o ultimo item ate ser destruida.
                            property var modelData: root.otherButtons[index] ?? ({})
                            readonly property var liveItem: root.otherButtons[index]
                            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                            required property int index

                            title: root.buttonName(modelData)
                            detail: modelData.action === "default" ? root.defaultText(modelData) : root.actionText(modelData.action)
                            remapped: modelData.action !== "default"
                            selected: root.selButton?.id === modelData.id
                            onPicked: root.toggle(modelData.id)
                        }
                    }
                }
            }
        }

        // O que o botao escolhido faz
        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.selButton
            implicitHeight: pickCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: pickCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("%1 does").arg(root.buttonName(root.selButton))
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: bridge.busyAction.startsWith("btn-") || bridge.busyAction.startsWith("prof-") ? qsTr("Writing to the mouse…") : ["default", "factory"].includes(root.selButton?.action ?? "default") ? root.chipText(root.selButton?.action ?? "default") : root.actionText(root.selButton?.action ?? "")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                    }
                }

                RowLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: "tune"
                        color: Colours.palette.m3outline
                    }

                    StyledText {
                        text: qsTr("Basic")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.medium
                    }
                }

                // Basico em 2x2, uma opcao por celula: Default/Factory a esquerda,
                // Custom (com o campo do atalho sempre ao lado) e Do nothing a direita
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Tokens.spacing.large
                    rowSpacing: Tokens.spacing.small

                    ActionChip {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: root.actionIcons["default"]
                        text: root.chipText("default")
                        selected: root.chipSelected("default")
                        onPicked: root.chipPicked("default")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: Tokens.spacing.small

                        ActionChip {
                            icon: root.actionIcons["custom"]
                            text: root.chipText("custom")
                            selected: root.chipSelected("custom")
                            onPicked: root.chipPicked("custom")
                        }

                        StyledTextField {
                            id: customField

                            Layout.fillWidth: true
                            placeholderText: qsTr("e.g. ctrl+shift+t")
                            verticalPadding: Tokens.padding.small
                            text: root.isCustom ? root.actionText(root.selButton.action).toLowerCase() : ""
                            validate: v => root.shortcutId(v) !== ""
                            emptyIsValid: false
                            onActiveFocusChanged: if (activeFocus) root.customOpen = true
                            onAccepted: root.applyCustom()
                        }

                        IconButton {
                            icon: "check"
                            type: IconButton.Tonal
                            disabled: root.shortcutId(customField.text) === ""
                            onClicked: root.applyCustom()
                        }
                    }

                    // Perfil documentado (CS): "Default: X" volta ao documentado;
                    // senao "Factory: X"
                    ActionChip {
                        readonly property string act: root.selButton?.documented_text ? "documented" : "factory"

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: root.actionIcons[act]
                        text: root.chipText(act)
                        selected: root.chipSelected(act)
                        onPicked: root.chipPicked(act)
                    }

                    ActionChip {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: root.actionIcons["disabled"]
                        text: root.chipText("disabled")
                        selected: root.chipSelected("disabled")
                        onPicked: root.chipPicked("disabled")
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.customOpen || root.isCustom
                    text: customField.text !== "" && root.shortcutId(customField.text) === "" ? qsTr("Use Ctrl, Alt, Shift or Super plus one key, joined by +") : qsTr("Sent to the window in focus: ctrl+shift+t, alt+F4, F13…")
                    color: customField.text !== "" && root.shortcutId(customField.text) === "" ? Colours.palette.m3error : Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 520 ? 2 : 1
                    columnSpacing: Tokens.spacing.large
                    rowSpacing: Tokens.spacing.large

                    Repeater {
                        model: root.actionGroups

                        ColumnLayout {
                            id: group

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            Layout.columnSpan: group.modelData.full ? 2 : 1
                            spacing: Tokens.spacing.extraSmall

                            RowLayout {
                                spacing: Tokens.spacing.extraSmall

                                MaterialIcon {
                                    text: group.modelData.icon
                                    color: Colours.palette.m3outline
                                }

                                StyledText {
                                    text: group.modelData.title
                                    color: Colours.palette.m3outline
                                    font: Tokens.font.label.medium
                                }
                            }

                            // Uma linha por conjunto afim (2-3 itens que dividem a largura)
                            Repeater {
                                model: group.modelData.rows

                                RowLayout {
                                    id: chipLine

                                    required property var modelData

                                    Layout.fillWidth: true
                                    spacing: Tokens.spacing.small

                                    Repeater {
                                        model: chipLine.modelData

                                        ActionChip {
                                            required property string modelData

                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 1
                                            icon: root.actionIcons[modelData] ?? "keyboard"
                                            text: root.gridLabel(modelData, true) || (root.shortLabels[modelData] ?? root.chipText(modelData))
                                            selected: root.chipSelected(modelData)
                                            onPicked: root.chipPicked(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowButton {
            last: true
            visible: root.buttons.length > 0
            icon: "restart_alt"
            text: qsTr("Reset all buttons")
            subtext: qsTr("Every button goes back to what the mouse does by itself")
            disabled: !root.buttons.some(b => b.action !== "default")
            onClicked: root.run(`btn-${root.mouse.model}-reset`)
        }

        // ------------------------------------------------- Estagios de DPI
        SectionHeader {
            visible: !!root.mouse?.can_set_stages && root.stages.length > 0
            text: qsTr("DPI stages")
        }

        // Uma barra so: pontos arrastaveis (reordenam ao soltar), clique no
        // ponto = em uso, clique na barra = novo estagio, x = remove. Os
        // estagios sao do perfil em uso.
        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.mouse?.can_set_stages && root.stages.length > 0
            first: true
            last: true
            implicitHeight: dpiCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: dpiCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: root.mouse?.onboard ? qsTr("Stages of profile %1").arg(root.mouse.profile) : qsTr("Stages")
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        text: qsTr("In use: %1 DPI").arg(root.stages[root.active - 1] ?? "?")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Drag a point to change it, click it to use it, click the bar to add a stage (up to 5). The DPI buttons on the mouse step through them in order.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                DpiStageBar {
                    Layout.fillWidth: true
                    stages: root.stages
                    active: root.active
                    maxDpi: root.mouse?.max_dpi ?? 30000
                    disabled: root.asleep
                    onEdited: (s, a) => {
                        root.stages = s;
                        root.active = a;
                        root.stagesEdited();
                    }
                }
            }
        }

        // ------------------------------------------------------- Energia
        SectionHeader {
            visible: root.mouse?.idle_s != null || (root.mouse?.low_battery_choices ?? []).length > 0
            text: qsTr("Power")
        }

        ChipSelectRow {
            first: true
            last: (root.mouse?.low_battery_choices ?? []).length === 0
            visible: root.mouse?.idle_s != null
            label: qsTr("Sleep after")
            subtext: qsTr("Turns the mouse off when you stop using it, to save battery")
            options: [60, 300, 600, 900].map(s => ({ value: String(s), label: qsTr("%1 min").arg(s / 60) }))
            current: String(root.mouse?.idle_s ?? "")
            disabled: root.asleep
            busy: bridge.busyAction.startsWith(`idle-`)
            onPicked: v => root.run(`idle-${root.mouse.id}-${v}`)
        }

        ChipSelectRow {
            first: root.mouse?.idle_s == null
            last: true
            visible: (root.mouse?.low_battery_choices ?? []).length > 0
            label: qsTr("Low battery warning")
            subtext: qsTr("The mouse blinks when the battery drops below this")
            options: (root.mouse?.low_battery_choices ?? []).map(p => ({ value: String(p), label: `${p}%` }))
            current: String(root.mouse?.low_battery ?? "")
            disabled: root.asleep
            busy: bridge.busyAction.startsWith(`lowbat-`)
            onPicked: v => root.run(`lowbat-${root.mouse.id}-${v}`)
        }

        // ------------------------------------------------------- Sobre
        SectionHeader {
            visible: !!root.mouse
            text: qsTr("About")
        }

        InfoRow {
            first: true
            visible: !!root.mouse
            icon: "memory"
            label: qsTr("Firmware")
            value: root.mouse?.firmware ?? qsTr("Unknown while asleep")
        }

        InfoRow {
            last: true
            visible: !!root.mouse
            icon: "usb"
            label: qsTr("USB id")
            value: root.mouse?.vidpid ?? "?"
        }
    }

    component ButtonTile: StyledRect {
        id: tile

        property string title
        property string detail
        property bool remapped
        property bool selected

        signal picked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: tileCol.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.medium
        color: tile.selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: tile.radius
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            onClicked: tile.picked()
        }

        ColumnLayout {
            id: tileCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.small
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: tile.title
                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.label.large
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: tile.detail
                color: tile.selected ? Colours.palette.m3onPrimaryContainer : tile.remapped ? Colours.palette.m3primary : Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }

    // Chip com icone na frente (reconhecer pelo icone e mais rapido que ler)
    component ActionChip: StyledRect {
        id: chip

        property string text
        property string icon
        property bool selected

        signal picked

        implicitWidth: chipIcon.implicitWidth + chipRow.spacing + chipLabel.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: chip.selected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: chip.radius
            color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            disabled: chip.selected
            onClicked: chip.picked()
        }

        Row {
            id: chipRow

            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                id: chipIcon

                anchors.verticalCenter: parent.verticalCenter
                visible: chip.icon !== ""
                text: chip.icon
                color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                fill: chip.selected ? 1 : 0
            }

            StyledText {
                id: chipLabel

                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, chip.width - Tokens.padding.medium * 2 - chipRow.spacing - chipIcon.implicitWidth)
                text: chip.text
                elide: Text.ElideRight
                color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }
        }
    }
}
