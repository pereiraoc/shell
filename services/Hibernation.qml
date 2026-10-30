pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.utils

// Hibernacao feita pelo shell (CF-13): a despedida toca, o shell hiberna, e ao
// voltar o filme toca no sentido de ligar. O logind nao diz se o PrepareForSleep
// e suspensao ou hibernacao -- por isso a hibernacao passa por aqui, e o
// IdleMonitors pula o "bloquear antes de dormir" enquanto `active`.
//
// Opcoes em ~/.config/caelestia/boot.json (Nexus > Power > Start and shut down):
// A tampa NAO passa por aqui: e o logind (suspend-then-hibernate), para funcionar mesmo
// com o shell travado, e o "bloquear antes de dormir" vale para ela.
//   hibernateLock  bloquear ao VOLTAR da hibernacao (padrao false; nunca antes)
Singleton {
    id: root

    property bool active                 // entre a despedida e a volta
    property bool hibernateLock: false
    property bool farewell: true         // a despedida tambem vale para hibernar

    FileView {
        path: `${Paths.config}/boot.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.hibernateLock = d.hibernateLock === true;
                root.farewell = d.farewell !== false;
            } catch (e) {
                root.hibernateLock = false;
            }
        }
        onLoadFailed: {
            root.hibernateLock = false;
        }
    }
}
