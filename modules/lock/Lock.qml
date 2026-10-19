pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc
import qs.utils

Scope {
    id: root

    property alias lock: lock
    property bool wantLockOnLogin
    property bool checkMarker

    WlSessionLock {
        id: lock

        signal unlock

        LockSurface {
            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        // Force a load of a screencopy so the one in the lock works
        // My guess is the ICC backend loads async on first request, which if the lock is
        // the first request it fails to capture (because it's async and the compositor
        // refuses capture when locked)
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: lock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: lock.unlock()
    }

    IpcHandler {
        function lock(): void {
            lock.locked = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }

        target: "lock"
    }

    // Entrada mais segura (01-pendencias): com autologin, a 1a tela da sessao
    // e o lock. Liga em Nexus > Security > Lock screen > "Lock at login"
    // (~/.config/caelestia/session.json). So no PRIMEIRO arranque do shell
    // nesta sessao: a marca em XDG_RUNTIME_DIR some no logout, entao
    // Super+Shift+R (restart do shell) nao trava a tela de novo.
    FileView {
        id: sessionConfig

        path: `${Paths.config}/session.json`
        printErrors: false
        onLoaded: {
            try {
                root.wantLockOnLogin = JSON.parse(text()).lockOnLogin === true;
            } catch (e) {
                root.wantLockOnLogin = false;
            }
            root.checkMarker = true;
        }
        onLoadFailed: root.checkMarker = true
    }

    FileView {
        id: firstStart

        // So ganha caminho depois de ler o session.json (reload() com
        // preload:false nunca emite loadFailed)
        path: root.checkMarker ? `${Quickshell.env("XDG_RUNTIME_DIR")}/caelestia-lock-on-login-done` : ""
        printErrors: false
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                return;
            // A marca e gravada sempre no 1o arranque: ligar o toggle no meio
            // da sessao nao trava no proximo restart do shell
            Qt.callLater(() => firstStart.setText("1"));
            if (root.wantLockOnLogin)
                lockOnLogin.start();
        }
    }

    // Depois do shell assentar: travar no meio da troca de geracao (reload)
    // era desfeito
    Timer {
        id: lockOnLogin

        interval: 2500
        onTriggered: lock.locked = true
    }
}
