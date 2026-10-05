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
    readonly property var otherButtons: root.buttons.filter(b => b.group !== "side")
    property string selected
    readonly property var selButton: root.buttons.find(b => b.id === root.selected) ?? root.buttons[0] ?? null

    // Fila: um clique com outra acao em curso espera e vai em seguida.
    property var queue: []

    // Rascunho dos estagios de DPI (aplicado ~0,6 s depois da ultima mudanca)
    property bool stagesInited
    property var stages: []
    property int active: 1
    property string wantedStages
    property string sentStages

    readonly property var actionGroups: [
        { title: qsTr("Basic"), actions: ["default", "disabled"] },
        { title: qsTr("Editing"), actions: ["copy", "paste", "cut", "undo", "redo", "select-all", "enter", "escape"] },
        { title: qsTr("Browser"), actions: ["back", "forward", "new-tab", "close-tab", "reopen-tab", "next-tab", "prev-tab", "reload"] },
        { title: qsTr("Media"), actions: ["play-pause", "next-track", "prev-track", "volume-up", "volume-down", "mute", "mic-mute"] },
        { title: qsTr("Desktop"), actions: ["launcher", "next-subgroup", "prev-subgroup", "next-group", "prev-group", "scratchpad", "close-window", "fullscreen", "float", "screenshot", "terminal", "lock"] }
    ]

    readonly property var actionLabels: ({
            "default": qsTr("Default"),
            "disabled": qsTr("Do nothing"),
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
            "mute": qsTr("Mute"),
            "mic-mute": qsTr("Mute microphone"),
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
        if (b.group === "side")
            return qsTr("types %1").arg(({ minus: "-", equal: "=" })[b.key] ?? b.key);
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

    function initStages(): void {
        if (root.stagesInited || !root.mouse || (root.mouse.dpi_stages ?? []).length === 0)
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
                    text: qsTr("Pick a button, then what it does. Remaps apply right away and only to this mouse; holding Ctrl, Alt or Super keeps the original key.")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                }

                // Grade lateral, na mesma disposicao do mouse (3 x 4)
                StyledText {
                    visible: root.sideButtons.length > 0
                    text: qsTr("Side buttons")
                    font: Tokens.font.body.small
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: root.sideButtons.length > 0
                    columns: 3
                    columnSpacing: Tokens.spacing.small
                    rowSpacing: Tokens.spacing.small

                    Repeater {
                        model: root.sideButtons

                        ButtonTile {
                            required property var modelData

                            title: modelData.id.split("-")[1]
                            detail: modelData.action === "default" ? root.defaultText(modelData) : root.actionText(modelData.action)
                            remapped: modelData.action !== "default"
                            selected: root.selButton?.id === modelData.id
                            onPicked: root.selected = modelData.id
                        }
                    }
                }

                StyledText {
                    visible: root.otherButtons.length > 0
                    text: qsTr("Other buttons")
                    font: Tokens.font.body.small
                }

                GridLayout {
                    Layout.fillWidth: true
                    visible: root.otherButtons.length > 0
                    columns: Math.max(2, Math.floor(width / 150))
                    columnSpacing: Tokens.spacing.small
                    rowSpacing: Tokens.spacing.small

                    Repeater {
                        model: root.otherButtons

                        ButtonTile {
                            required property var modelData

                            title: root.buttonName(modelData)
                            detail: modelData.action === "default" ? root.defaultText(modelData) : root.actionText(modelData.action)
                            remapped: modelData.action !== "default"
                            selected: root.selButton?.id === modelData.id
                            onPicked: root.selected = modelData.id
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
                        text: bridge.busyAction.startsWith("btn-") ? qsTr("Applying…") : root.selButton?.action === "default" ? qsTr("Default — %1").arg(root.defaultText(root.selButton)) : root.actionText(root.selButton?.action ?? "")
                        color: Colours.palette.m3primary
                        font: Tokens.font.label.medium
                    }
                }

                Repeater {
                    model: root.actionGroups

                    ColumnLayout {
                        id: group

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        StyledText {
                            text: group.modelData.title
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.medium
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            Repeater {
                                model: group.modelData.actions

                                ActionChip {
                                    required property string modelData

                                    text: root.actionText(modelData)
                                    selected: (root.selButton?.action ?? "default") === modelData
                                    onPicked: root.setAction(modelData)
                                }
                            }
                        }
                    }
                }

                TextFieldRow {
                    Layout.fillWidth: true
                    label: qsTr("Custom shortcut")
                    subtext: qsTr("Keys joined by +, sent to the window in focus. E.g. ctrl+shift+t, alt+F4, F13")
                    placeholderText: "ctrl+shift+F5"
                    value: (root.selButton?.action ?? "").startsWith("key-") ? root.actionText(root.selButton.action).toLowerCase() : ""
                    errorText: field.text !== "" && root.shortcutId(field.text) === "" ? qsTr("Use Ctrl, Alt, Shift or Super plus one key") : ""
                    smallField: true
                    onEditingFinished: v => {
                        const id = root.shortcutId(v);
                        if (id)
                            root.setAction(id);
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

        ChipSelectRow {
            first: true
            visible: !!root.mouse?.can_set_stages && root.stages.length > 0
            label: qsTr("Stage in use")
            subtext: qsTr("The DPI button on the mouse steps through these stages, in order")
            options: root.stages.map((d, i) => ({ value: String(i + 1), label: d >= 1000 ? `${d / 1000}k` : String(d) }))
            current: String(root.active)
            disabled: root.asleep
            onPicked: v => {
                root.active = Number(v);
                root.stagesEdited();
            }
        }

        Repeater {
            // Modelo = quantidade: mudar um valor nao recria as linhas (nao
            // perde o foco de quem esta digitando).
            model: root.mouse?.can_set_stages ? root.stages.length : 0

            StepperRow {
                required property int index

                label: qsTr("Stage %1").arg(index + 1)
                subtext: index + 1 === root.active ? qsTr("In use now") : ""
                value: root.stages[index] ?? 0
                from: 100
                to: root.mouse?.max_dpi ?? 30000
                stepSize: 50
                opacity: root.asleep ? 0.5 : 1
                onMoved: v => {
                    const s = root.stages.slice();
                    s[index] = Math.round(v / 50) * 50;
                    root.stages = s;
                    root.stagesEdited();
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.mouse?.can_set_stages && root.stages.length > 0
            last: true
            implicitHeight: stageBtns.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: stageBtns

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("%n stage(s) — up to 5", "", root.stages.length)
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                IconButton {
                    icon: "remove"
                    type: IconButton.Tonal
                    isRound: true
                    disabled: root.asleep || root.stages.length <= 1
                    onClicked: {
                        root.stages = root.stages.slice(0, -1);
                        root.active = Math.min(root.active, root.stages.length);
                        root.stagesEdited();
                    }
                }

                IconButton {
                    icon: "add"
                    type: IconButton.Tonal
                    isRound: true
                    disabled: root.asleep || root.stages.length >= 5
                    onClicked: {
                        const top = root.stages[root.stages.length - 1] ?? 800;
                        root.stages = [...root.stages, Math.min(root.mouse?.max_dpi ?? 30000, top * 2)];
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

    component ActionChip: StyledRect {
        id: chip

        property string text
        property bool selected

        signal picked

        implicitWidth: chipLabel.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: chipLabel.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: chip.selected ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: chip.radius
            color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            disabled: chip.selected
            onClicked: chip.picked()
        }

        StyledText {
            id: chipLabel

            anchors.centerIn: parent
            text: chip.text
            color: chip.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
        }
    }
}
