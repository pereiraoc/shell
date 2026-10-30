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
//   lidHibernate   fechar a tampa hiberna (padrao true; com monitor externo
//                  ligado -- logind "Docked" -- nunca)
//   hibernateLock  bloquear ao VOLTAR da hibernacao (padrao false; nunca antes)
Singleton {
    id: root

    property bool active                 // entre a despedida e a volta
    property bool lidHibernate: true
    property bool hibernateLock: false
    property bool farewell: true         // a despedida tambem vale para hibernar

    signal requested(string reason)      // a Farewell toca e hiberna

    function request(reason: string): void {
        if (!root.active)
            root.requested(reason);
    }

    FileView {
        path: `${Paths.config}/boot.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.lidHibernate = d.lidHibernate !== false;
                root.hibernateLock = d.hibernateLock === true;
                root.farewell = d.farewell !== false;
            } catch (e) {
                root.lidHibernate = true;
                root.hibernateLock = false;
            }
        }
        onLoadFailed: {
            root.lidHibernate = true;
            root.hibernateLock = false;
        }
    }

    // Tampa: o logind avisa quando LidClosed muda. Iniciar um Process dentro do
    // onRead de outro nao e confiavel no Quickshell (ver GpuModeService): o onRead
    // so arma o timer, e o timer pergunta se ha monitor externo.
    Process {
        id: lidMonitor

        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("LidClosed") && line.includes("<true>") && root.lidHibernate && !root.active)
                    lidCheck.restart();
            }
        }
        onExited: monitorRestart.restart()   // gdbus caiu (ex.: dbus reiniciou): volta
    }

    Timer {
        id: monitorRestart

        interval: 5000
        onTriggered: lidMonitor.running = true
    }

    Timer {
        id: lidCheck

        interval: 300
        onTriggered: dockedProc.running = true
    }

    Process {
        id: dockedProc

        command: ["busctl", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", "Docked"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "b true")
                    console.info("hibernation: tampa fechada com monitor externo (docked) -- nada");
                else
                    root.request("lid");
            }
        }
    }
}
