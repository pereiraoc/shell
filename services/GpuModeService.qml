pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // activeMode = the REAL mode running now (only changes on boot/login)
    // configuredMode = what supergfxctl -g returns (changes immediately after -m)
    // pendingMode = configuredMode if different from activeMode
    property string activeMode: ""
    property string configuredMode: ""
    property string pendingMode: ""
    property bool available: false
    property bool switching: false
    property bool loading: true
    property int switchTimeRemaining: 0
    property string targetMode: ""
    property string lastError: ""
    property string pendingConfirmation: ""

    // Internal: stores nvidia detection result for use in onExited
    property string __nvidiaDetectionResult: ""

    signal modeChanged(string newMode)
    signal switchFailed(string error)
    signal switchSuccess(string newMode)

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.switching && root.switchTimeRemaining > 0
        onTriggered: {
            root.switchTimeRemaining--
            if (root.switchTimeRemaining <= 0) {
                root.switching = false
                root.targetMode = ""
            }
        }
    }

    Timer {
        id: confirmationTimer
        interval: 3000
        running: root.pendingConfirmation !== ""
        onTriggered: {
            console.log("[GPU] Confirmation timeout")
            root.pendingConfirmation = ""
        }
    }

    Timer {
        id: errorTimer
        interval: 10000  // 10s — enough for user to read the error
        running: root.lastError !== ""
        onTriggered: { root.lastError = "" }
    }

    Timer {
        id: switchTimeout
        interval: 120000  // 120s safety net — the OS-level timeout in the command should fire first
        repeat: false
        onTriggered: {
            if (root.switchProcess) {
                console.log("[GPU] Switch process timeout (QML safety) — possible hang")
                root.switching = false
                root.targetMode = ""
                root.switchTimeRemaining = 0
                root.lastError = "supergfxd not responding"
                root.switchFailed("timeout")
                root.switchProcess.destroy()
                root.switchProcess = null
            }
        }
    }

    Timer {
        id: startupTimer
        interval: 100
        running: true
        onTriggered: {
            console.log("[GPU] Startup")
            checkProcess.running = true
        }
    }

    Process {
        id: checkProcess
        command: ["which", "supergfxctl"]
        onExited: exitCode => {
            root.available = (exitCode === 0)
            if (root.available) detectActiveMode.running = true
            else root.loading = false
        }
    }

    // Detect the REAL active mode by checking if NVIDIA is accessible
    // nvidia-smi works = NVIDIA active = Hybrid or Dedicated
    // nvidia-smi fails or HANGS (common in integrated mode when dGPU is off) = assume Integrated
    // timeout 5: if nvidia-smi hangs (GPU powered off), we get nvidia_off after 5s instead of blocking forever
    //
    // IMPORTANT: queryProcess is started ONLY from onExited (never from SplitParser.onRead).
    // Starting a Process from another Process's SplitParser.onRead does not work reliably in Quickshell.
    Process {
        id: detectActiveMode
        command: ["sh", "-c", "timeout 5 nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null && echo 'nvidia_active' || echo 'nvidia_off'"]
        stdout: SplitParser {
            onRead: data => {
                const output = data.trim()
                if (output === "") return
                // Store last meaningful line — will be processed in onExited
                root.__nvidiaDetectionResult = output
                console.log("[GPU] NVIDIA detection (stdout):", output)
            }
        }
        onExited: exitCode => {
            const result = root.__nvidiaDetectionResult
            console.log("[GPU] NVIDIA detection done, exit:", exitCode, "result:", result)

            if (result === "nvidia_off" || result === "") {
                root.activeMode = "integrated"
                console.log("[GPU] Detected active mode: integrated (NVIDIA off)")
            } else {
                // NVIDIA accessible = either Hybrid or Dedicated
                // We'll refine this after getting configured mode
                root.activeMode = "__nvidia_active__"
                console.log("[GPU] Detected: NVIDIA is active")
            }

            // Always start queryProcess from here (onExited), never from SplitParser.onRead
            queryProcess.running = true
        }
    }

    // Query the configured mode from supergfxctl
    // Wrapped with timeout to avoid hangs (supergfxctl -g can hang when supergfxd is unresponsive)
    Process {
        id: queryProcess
        command: ["sh", "-c", "timeout 5 supergfxctl -g 2>/dev/null"]
        property bool timedOut: false
        stdout: SplitParser {
            onRead: data => {
                if (queryProcess.timedOut) return
                const mode = data.trim().toLowerCase()
                if (mode === "") return
                console.log("[GPU] Configured mode:", mode)
                // If we detected NVIDIA is active but don't know exact mode yet,
                // trust the configured mode (both Hybrid and Dedicated have NVIDIA active)
                if (root.activeMode === "__nvidia_active__") {
                    root.activeMode = mode
                    console.log("[GPU] NVIDIA active, using configured mode as active:", mode)
                } else if (root.activeMode === "") {
                    root.activeMode = mode
                    console.log("[GPU] No nvidia detection result; assuming active = configured:", mode)
                }
                root.configuredMode = mode
                // Update pending
                if (mode !== root.activeMode) {
                    root.pendingMode = mode
                } else {
                    root.pendingMode = ""
                }
                console.log("[GPU] Active:", root.activeMode, "| Configured:", root.configuredMode, "| Pending:", root.pendingMode)
                root.loading = false
                root.modeChanged(root.activeMode)
            }
        }
        onExited: exitCode => {
            if (queryProcess.timedOut) return
            // Exit 124 = timeout killed supergfxctl; or no stdout at all → assume configured = active
            if (exitCode === 124 || (root.loading && root.configuredMode === "")) {
                queryProcess.timedOut = true
                console.log("[GPU] supergfxctl -g timeout or no output (exit:", exitCode, "), assuming configured = active")
                root.configuredMode = root.activeMode !== "" ? root.activeMode : "integrated"
                root.pendingMode = ""
                root.loading = false
                if (root.activeMode === "") root.activeMode = root.configuredMode
                root.modeChanged(root.activeMode)
                return
            }
            if (exitCode !== 0) {
                console.log("[GPU] supergfxctl -g failed with exit:", exitCode)
                root.activeMode = "error"
                root.loading = false
            }
        }
    }

    property var switchProcess: null

    // All mode switches are instant (~3s): the command saves intent, actual change happens on reboot.
    // supergfxd does NOT persist config itself for Hybrid/Integrated switches (only Dedicated/MUX
    // persists via firmware). Our code persists the config via /usr/local/bin/gpu-mode-persist.
    function getEstimatedTime(fromMode, toMode) {
        return 0  // All switches are instant + reboot
    }

    function getRequiredAction(fromMode, toMode) {
        return "reboot"  // All switches require reboot to apply
    }

    function getActionText(action) {
        if (action === "reboot") return "Reboot required"
        return ""
    }

    // Returns true if switching between these modes takes a long time
    function isSlowSwitch(fromMode, toMode) {
        return false  // No slow switches — all are instant + reboot
    }

    function switchMode(newMode) {
        console.log("[GPU] switchMode:", newMode, "| active:", activeMode, "| configured:", configuredMode, "| pending:", pendingMode, "| conf:", pendingConfirmation)

        if (!available || switching || loading) return

        // Clicking current active mode with no pending = do nothing
        if (newMode === activeMode && pendingMode === "") {
            pendingConfirmation = ""
            return
        }

        // Clicking the already pending mode = cancel confirmation
        if (newMode === pendingMode) {
            pendingConfirmation = ""
            return
        }

        // Confirmation flow
        if (pendingConfirmation === newMode) {
            console.log("[GPU] Confirmed")
            pendingConfirmation = ""
            executeSwitch(newMode)
            return
        }

        console.log("[GPU] Asking confirmation for:", newMode)
        pendingConfirmation = newMode
    }

    function executeSwitch(newMode) {
        switching = true
        targetMode = newMode
        switchTimeRemaining = 0
        lastError = ""

        let cmd = newMode
        if (newMode === "integrated") cmd = "Integrated"
        else if (newMode === "hybrid") cmd = "Hybrid"
        else if (newMode === "asusmuxdgpu") cmd = "AsusMuxDgpu"

        console.log("[GPU] From:", configuredMode, "To:", newMode)
        console.log("[GPU] Executing:", cmd)

        // Persist mode to /etc/supergfxd.conf — this is what the daemon reads on next boot.
        // supergfxd does NOT persist config for Hybrid/Integrated switches (only MUX/Dedicated
        // persists via firmware). Our helper writes the config directly.
        //
        // For Dedicated (AsusMuxDgpu): also call supergfxctl -m to set the hardware MUX.
        // For Hybrid/Integrated: do NOT call supergfxctl -m — it triggers WaitLogout which
        // causes session lag (Hybrid) or compositor crash (Integrated). Just persist + reboot.
        //
        // IMPORTANT: Create Process with running: false, connect the exited handler,
        // THEN set running = true. This avoids a race condition where the process
        // exits before the signal handler is connected.
        // Call supergfxctl -m when Dedicated (MUX) is involved — either as source or target.
        // MUX is a hardware switch that only supergfxctl can change; persist alone won't flip it.
        // For Hybrid <-> Integrated (software-only), skip supergfxctl -m to avoid session lag/crash.
        const needsDaemon = (cmd === "AsusMuxDgpu" || root.activeMode === "asusmuxdgpu")
        const shellCmd = needsDaemon
            ? `sudo /usr/local/bin/gpu-mode-persist ${cmd} && timeout 15 supergfxctl -m ${cmd} 2>/dev/null || true`
            : `sudo /usr/local/bin/gpu-mode-persist ${cmd}`
        switchProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["sh", "-c", "${shellCmd}"]
                running: false
            }
        `, root, "switchProcess")

        switchProcess.exited.connect((exitCode) => {
            switchTimeout.stop()
            console.log("[GPU] Completed:", exitCode)

            if (exitCode === 0) {
                // Config persisted + daemon notified (best-effort).
                // Show "Pending Reboot to X" immediately.
                root.switching = false
                root.targetMode = ""
                root.lastError = ""
                root.configuredMode = newMode
                root.pendingMode = newMode !== root.activeMode ? newMode : ""
                root.switchSuccess(newMode)
            } else {
                // Persist failed — config NOT updated, show error
                root.switching = false
                root.targetMode = ""
                root.lastError = "Failed to save mode"
                root.switchFailed("" + exitCode)
            }

            if (switchProcess) {
                switchProcess.destroy()
                switchProcess = null
            }
        })

        // Now start the process (handler is connected, no race)
        switchProcess.running = true
        switchTimeout.restart()
    }

    function refresh() {
        if (available && !switching) {
            pendingConfirmation = ""
            queryProcess.timedOut = false
            queryProcess.running = true
        }
    }

    function getModeName(mode) {
        switch(mode) {
            case "integrated": return "Integrated"
            case "hybrid": return "Hybrid"
            case "asusmuxdgpu": return "Dedicated"
            case "": return "..."
            default: return mode
        }
    }

    function getModeDescription(mode) {
        switch(mode) {
            case "integrated": return "Intel iGPU only"
            case "hybrid": return "Intel iGPU + NVIDIA dGPU"
            case "asusmuxdgpu": return "NVIDIA dGPU only"
            default: return ""
        }
    }
}
