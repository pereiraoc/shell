import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Caelestia.Config

Scope {
    id: root

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    readonly property alias howdy: howdy
    property string lockMessage
    property string state
    property string fprintState
    property string howdyState
    property string buffer

    // === Auth method management (US-004) ===
    property string currentMode: GlobalConfig.lock.defaultMethod
    property bool faceEnabled: GlobalConfig.lock.enableFaceAuth
    property bool pinEnabled: GlobalConfig.lock.enablePinAuth
    property int faceFailedAttempts: 0
    property int pinFailedAttempts: 0
    property int passwordFailedAttempts: 0

    signal flashMsg

    // PIN salt — must match SecurityPane.qml
    readonly property string pinSalt: "caelestia-lock-2026"

    function hashPin(pin: string): string {
        return Qt.md5(pinSalt + pin + pinSalt);
    }

    function verifyPin(): void {
        const storedPinHash = GlobalConfig.lock.userPin;

        if (!storedPinHash || storedPinHash === "") {
            root.state = "error";
            root.lockMessage = qsTr("No PIN configured. Set one in Security settings.");
            root.buffer = "";
            root.flashMsg();
            stateReset.restart();
            return;
        }

        if (hashPin(root.buffer) === storedPinHash) {
            root.faceFailedAttempts = 0;
            root.pinFailedAttempts = 0;
            root.passwordFailedAttempts = 0;
            root.faceEnabled = GlobalConfig.lock.enableFaceAuth;
            root.pinEnabled = GlobalConfig.lock.enablePinAuth;
            root.buffer = "";
            root.lock.unlock();
        } else {
            root.pinFailedAttempts++;
            if (root.pinFailedAttempts >= GlobalConfig.lock.maxPinRetries) {
                root.pinEnabled = false;
            }
            root.state = "fail";
            root.buffer = "";
            root.flashMsg();
            stateReset.restart();
        }
    }

    function handleKey(event: KeyEvent): void {
        if (passwd.active || state === "max")
            return;

        // PIN mode: only digits, auto-submit on 4 digits
        if (currentMode === "pin") {
            if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                if (buffer.length < 4) {
                    buffer += event.text;
                    if (buffer.length === 4) {
                        verifyPin();
                    }
                }
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    buffer = "";
                } else {
                    buffer = buffer.slice(0, -1);
                }
            }
            return;
        }

        // Password / face modes: same handling (face just runs PamContext in parallel)
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (" abcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+[{]}\\|;:'\",<.>/?".includes(event.text.toLowerCase())) {
            buffer += event.text;
        }
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message;
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message;
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success)
                return root.lock.unlock();

            if (res === PamResult.Error)
                root.state = "error";
            else if (res === PamResult.MaxTries)
                root.state = "max";
            else if (res === PamResult.Failed)
                root.state = "fail";

            root.flashMsg();
            stateReset.restart();
        }
    }

    PamContext {
        id: fprint

        property bool available
        property int tries
        property int errorTries

        function checkAvail(): void {
            if (!available || !GlobalConfig.lock.enableFprint || !root.lock.secure) {
                abort();
                return;
            }

            tries = 0;
            errorTries = 0;
            start();
        }

        config: "fprint"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success)
                return root.lock.unlock();

            if (res === PamResult.Error) {
                root.fprintState = "error";
                errorTries++;
                if (errorTries < 5) {
                    abort();
                    errorRetry.restart();
                }
            } else if (res === PamResult.MaxTries) {
                tries++;
                if (tries < GlobalConfig.lock.maxFprintTries) {
                    root.fprintState = "fail";
                    start();
                } else {
                    root.fprintState = "max";
                    abort();
                }
            }

            root.flashMsg();
            fprintStateReset.start();
        }
    }

    // === Howdy face auth (US-004) ===
    // NOTA: pam_howdy.so requer permissões de root para acessar a câmera.
    // Quando invocado pelo PamContext do shell (user context), falha silenciosamente.
    // Stub mantido para compatibilidade com properties usadas pelo Center.qml
    // (pam.howdy.tries, pam.howdy.active). Para usar face recognition de verdade,
    // adicione `auth sufficient pam_howdy.so` em /etc/pam.d/passwd para o
    // sistema invocar Howdy quando a senha for digitada (com permissões corretas).
    QtObject {
        id: howdy

        property bool available: false
        property bool active: false
        property int tries: 0
        property int errorTries: 0

        function checkAvail(): void { /* no-op — face auth via system PAM stack */ }
        function abort(): void { /* no-op */ }
        function start(): void { /* no-op */ }
    }

    Process {
        id: availProc

        command: ["sh", "-c", "fprintd-list $USER"]
        onExited: code => { // qmllint disable signal-handler-parameters
            fprint.available = code === 0;
            fprint.checkAvail();
        }
    }

    Process {
        id: howdyAvailProc

        // 'howdy list' precisa sudo. Verifica só se o binário existe e
        // se há modelo treinado para o usuário atual.
        command: ["sh", "-c", "command -v howdy >/dev/null && ls /etc/howdy/models/$(id -un).dat 2>/dev/null"]
        onExited: code => { // qmllint disable signal-handler-parameters
            howdy.available = code === 0;
            howdy.checkAvail();
        }
    }

    Timer {
        id: errorRetry
        interval: 800
        onTriggered: fprint.start()
    }

    Timer {
        id: howdyErrorRetry
        interval: 800
        onTriggered: howdy.start()
    }

    Timer {
        id: howdyRetry
        interval: 1500
        onTriggered: {
            if (root.currentMode === "face" && root.faceEnabled)
                howdy.start();
        }
    }

    Timer {
        id: stateReset
        interval: 4000
        onTriggered: {
            if (root.state !== "max")
                root.state = "";
        }
    }

    Timer {
        id: fprintStateReset
        interval: 4000
        onTriggered: {
            root.fprintState = "";
            fprint.errorTries = 0;
        }
    }

    Timer {
        id: howdyStateReset
        interval: 4000
        onTriggered: {
            root.howdyState = "";
            howdy.errorTries = 0;
        }
    }

    Connections {
        function onSecureChanged(): void {
            if (root.lock.secure) {
                availProc.running = true;
                howdyAvailProc.running = true;
                root.buffer = "";
                root.state = "";
                root.fprintState = "";
                root.howdyState = "";
                root.lockMessage = "";
                root.currentMode = GlobalConfig.lock.defaultMethod;
            }
        }

        function onUnlock(): void {
            fprint.abort();
            howdy.abort();
        }

        target: root.lock
    }

    Connections {
        function onEnableFprintChanged(): void {
            fprint.checkAvail();
        }

        function onEnableFaceAuthChanged(): void {
            howdy.checkAvail();
        }

        target: GlobalConfig.lock
    }

    onCurrentModeChanged: {
        if (currentMode === "face" && faceEnabled) {
            howdy.checkAvail();
        } else {
            howdy.abort();
        }
    }
}
