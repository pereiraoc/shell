import qs.config
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias howdy: howdy
    property string lockMessage
    property string state
    property string howdyState
    property string buffer

    // Auth method management
    property string currentMode: "face"
    property bool faceEnabled: true
    property bool pinEnabled: true
    property int faceFailedAttempts: 0
    property int pinFailedAttempts: 0
    property int passwordFailedAttempts: 0

    signal flashMsg

    function handleKey(event: KeyEvent): void {
        if (passwd.active || state === "max")
            return;

        // PIN mode: only accept numbers
        if (currentMode === "pin") {
            if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                buffer += event.text;
            } else if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) {
                    buffer = "";
                } else {
                    buffer = buffer.slice(0, -1);
                }
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                passwd.start();
            }
            return;
        }

        // Password mode: accept all characters
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
            if (res === PamResult.Success) {
                // Reset all counters on successful unlock
                root.faceFailedAttempts = 0;
                root.pinFailedAttempts = 0;
                root.passwordFailedAttempts = 0;
                root.faceEnabled = Config.lock.auth.enableFaceAuth;
                root.pinEnabled = Config.lock.auth.enablePinAuth;
                return root.lock.unlock();
            }

            // Track failures by method
            if (root.currentMode === "pin") {
                root.pinFailedAttempts++;
                if (root.pinFailedAttempts >= Config.lock.auth.maxPinRetries) {
                    root.pinEnabled = false;
                }
            } else if (root.currentMode === "password") {
                root.passwordFailedAttempts++;
                if (root.passwordFailedAttempts >= Config.lock.auth.maxPasswordRetries) {
                    // Total lockout after 30 password failures
                    root.faceEnabled = false;
                    root.pinEnabled = false;
                }
            }

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
        id: howdy

        property bool available
        property int tries
        property int errorTries

        function checkAvail(): void {
            // Use howdy for face auth when in face mode
            if (!available || !Config.lock.auth.enableFaceAuth || !root.lock.secure) {
                abort();
                return;
            }

            // Only start if in face mode
            if (root.currentMode !== "face") {
                abort();
                return;
            }

            tries = 0;
            errorTries = 0;
            start();
        }

        config: "howdy"
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success) {
                // Reset all counters on successful unlock
                root.faceFailedAttempts = 0;
                root.pinFailedAttempts = 0;
                root.passwordFailedAttempts = 0;
                root.faceEnabled = Config.lock.auth.enableFaceAuth;
                root.pinEnabled = Config.lock.auth.enablePinAuth;
                return root.lock.unlock();
            }

            // Track face auth failures
            root.faceFailedAttempts++;
            if (root.faceFailedAttempts >= Config.lock.auth.maxFaceRetries) {
                root.faceEnabled = false;
            }

            if (res === PamResult.Error) {
                root.howdyState = "error";
                errorTries++;
                if (errorTries < 5) {
                    abort();
                    errorRetry.restart();
                }
            } else if (res === PamResult.MaxTries) {
                tries++;
                if (tries < 3) {
                    root.howdyState = "fail";
                    start();
                } else {
                    root.howdyState = "max";
                    abort();
                }
            }

            root.flashMsg();
            howdyStateReset.start();
        }
    }

    Process {
        id: availProc

        command: ["sh", "-c", "command -v howdy >/dev/null 2>&1"]
        onExited: code => {
            // code 0 means howdy command exists
            howdy.available = (code === 0);
            if (howdy.available) {
                howdy.checkAvail();
            }
        }
    }

    Timer {
        id: errorRetry

        interval: 800
        onTriggered: howdy.start()
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
        id: howdyStateReset

        interval: 4000
        onTriggered: {
            root.howdyState = "";
            howdy.errorTries = 0;
        }
    }

    Connections {
        target: root.lock

        function onSecureChanged(): void {
            if (root.lock.secure) {
                availProc.running = true;
                root.buffer = "";
                root.state = "";
                root.howdyState = "";
                root.lockMessage = "";
                // Set default mode on lock
                root.currentMode = Config.lock.auth.defaultMethod;
            }
        }

        function onUnlock(): void {
            howdy.abort();
        }
    }

    // Watch for mode changes
    onCurrentModeChanged: {
        if (currentMode === "face") {
            howdy.checkAvail();
        } else {
            howdy.abort();
        }
    }
}
