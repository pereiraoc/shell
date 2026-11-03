import QtQuick
import Caelestia.I18n
import qs.components.misc

// A ponte do NAS (caelestia-nas) com o que toda aba dele precisa: o "dois
// cliques" das acoes de risco medio (o shell nao tem dialogo de confirmacao) e
// a releitura a cada 30 s enquanto a aba esta na frente. Mora aqui, e nao na
// pagina, porque as abas do NAS vivem em paginas diferentes: Server, Storage
// (NAS) e Network (Home, Home Devices). Os Timers ficam dentro da ponte (Item):
// o PageBase so aceita Item como filho.
ToolBridge {
    id: root

    property string armed: ""
    // Releitura periodica (um ssh a cada 30 s) enquanto true.
    property bool live

    function press(action: var): void {
        if (!action?.id)
            return;
        if (action.risk === "medium" && root.armed !== action.id) {
            root.armed = action.id;
            disarm.restart();
            return;
        }
        root.armed = "";
        root.run(action);
    }

    function actionText(action: var): string {
        if (root.armed === action.id)
            return Tr.tr("Click again: %1").arg(action.label);
        if (root.busyAction === action.id)
            return Tr.tr("%1 — running…").arg(action.label);
        return action.label ?? "";
    }

    tool: "nas"

    Timer {
        id: disarm

        interval: 4000
        onTriggered: root.armed = ""
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.live
        onTriggered: root.refresh()
    }
}
