pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services

// Secao generica para uma ferramenta do contrato (caelestia-<tool>): titulo,
// resumo do `status` e um botao por acao de `actions`. A pagina so escolhe onde
// a secao fica:
//
//     ToolSection { tool: "mic-gain"; title: qsTr("MICROPHONE HARDWARE GAIN") }
//
// Acao com risk "medium" pede dois cliques (o shell nao tem dialogo de
// confirmacao); as "low" rodam no primeiro. `group` so troca o icone: "preset"
// (tune), "remove" (delete). Root: pkexec abre a caixa de senha
// do Caelestia (modules/polkit).
ColumnLayout {
    id: root

    required property string tool
    required property string title
    property string icon: "build"
    // Texto fixo sob o resumo (o que a ferramenta faz / onde usar no terminal).
    property string hint
    property bool first

    property string armed: ""

    readonly property alias bridge: bridge

    function levelColour(level: string): color {
        if (level === "error")
            return Colours.palette.m3error;
        if (level === "warn")
            return Colours.palette.m3tertiary;
        return Colours.palette.m3primary;
    }

    function press(action: var): void {
        if (action.risk === "medium" && root.armed !== action.id) {
            root.armed = action.id;
            disarm.restart();
            return;
        }
        root.armed = "";
        bridge.run(action);
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    ToolBridge {
        id: bridge

        tool: root.tool

        Timer {
            id: disarm

            interval: 4000
            onTriggered: root.armed = ""
        }
    }

    SectionHeader {
        first: root.first
        text: bridge.loading ? qsTr("%1  ·  refreshing…").arg(root.title) : root.title
    }

    InfoRow {
        readonly property bool failed: bridge.lastResult !== null && !bridge.lastResult.ok

        first: true
        last: bridge.actions.length === 0
        icon: bridge.error !== "" ? "error" : root.icon
        iconColour: bridge.error !== "" ? Colours.palette.m3error : root.levelColour(bridge.level)
        label: bridge.error !== "" ? qsTr("Could not read %1").arg(root.tool) : (bridge.summary || qsTr("Reading…"))
        subtext: bridge.error !== "" ? bridge.error : failed ? qsTr("Last action failed: %1").arg(bridge.lastResult.message ?? "") : root.hint
    }

    Repeater {
        model: bridge.actions.length

        RowButton {
            id: act

            // Modelo = quantidade: atualizar o status nao recria a linha
            // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
            // que vai sumir guarda o ultimo item ate ser destruida.
            property var modelData: bridge.actions[index] ?? ({})
            readonly property var liveItem: bridge.actions[index]
            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
            required property int index

            readonly property bool isArmed: root.armed === act.modelData.id
            readonly property bool isBusy: bridge.busyAction === act.modelData.id

            last: act.index === bridge.actions.length - 1
            color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
            icon: act.isBusy ? "hourglass_top" : act.modelData.group === "preset" ? "tune" : act.modelData.group === "remove" ? "delete" : "play_arrow"
            text: act.isArmed ? qsTr("Click again: %1").arg(act.modelData.label) : act.isBusy ? qsTr("%1 — running…").arg(act.modelData.label) : act.modelData.label
            subtext: act.modelData.detail ?? ""
            trailingIcon: act.modelData.root ? "lock" : ""
            disabled: bridge.busyAction !== "" && !act.isBusy
            onClicked: {
                if (!act.isBusy)
                    root.press(act.modelData);
            }
        }
    }
}
