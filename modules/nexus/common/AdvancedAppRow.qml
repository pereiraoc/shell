import QtQuick
import Quickshell
import qs.modules.nexus.common

// Link para o app externo que cobre o caso avancado do assunto da pagina
// (regra "um dono por configuracao": o app nao ganha pagina propria no Nexus,
// ele vira uma linha dentro da pagina do assunto). Some se nao estiver
// instalado.
NavRow {
    id: root

    required property string desktopId
    // Ids alternativos (o pacote renomeou o .desktop, ou ha override local).
    property list<string> altIds

    // byId e exato: heuristicLookup acharia "parecido" e abriria outro app.
    // Le applications.values so para reavaliar quando a lista carrega
    // (byId e funcao: sozinha, a binding nunca seria refeita).
    readonly property var entry: {
        DesktopEntries.applications.values;
        for (const id of [root.desktopId, ...root.altIds]) {
            const e = DesktopEntries.byId(id);
            if (e)
                return e;
        }
        return null;
    }

    visible: root.entry !== null && root.entry !== undefined
    icon: "apps"
    trailingIcon: "open_in_new"
    onClicked: root.entry?.execute()
}
