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
        interval: 5000
        running: root.lastError !== ""
        onTriggered: { root.lastError = "" }
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
    // nvidia-smi fails = NVIDIA off = Integrated
    Process {
        id: detectActiveMode
        command: ["sh", "-c", "nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null && echo 'nvidia_active' || echo 'nvidia_off'"]
        stdout: SplitParser {
            onRead: data => {
                const output = data.trim()
                console.log("[GPU] NVIDIA detection:", output)
                
                if (output === "nvidia_off") {
                    // NVIDIA not accessible = Integrated mode is active
                    root.activeMode = "integrated"
                    console.log("[GPU] Detected active mode: integrated (NVIDIA off)")
                } else {
                    // NVIDIA accessible = either Hybrid or Dedicated
                    // We'll refine this after getting configured mode
                    root.activeMode = "__nvidia_active__"
                    console.log("[GPU] Detected: NVIDIA is active")
                }
                queryProcess.running = true
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                queryProcess.running = true
            }
        }
    }

    Process {
        id: queryProcess
        command: ["supergfxctl", "-g"]
        stdout: SplitParser {
            onRead: data => {
                const mode = data.trim().toLowerCase()
                console.log("[GPU] Configured mode:", mode)
                
                // If we detected NVIDIA is active but don't know exact mode yet
                if (root.activeMode === "__nvidia_active__") {
                    // If configured is Dedicated, active is probably still Hybrid or Dedicated
                    // Best guess: if MUX (dedicated) was never actually applied (needs reboot),
                    // then active is Hybrid. We assume Hybrid as default when NVIDIA is on.
                    // The only way to truly be in Dedicated is after a reboot with MUX configured.
                    // Since we can't know for sure, assume Hybrid when NVIDIA is active.
                    root.activeMode = "hybrid"
                    console.log("[GPU] Assumed active mode: hybrid (NVIDIA is active)")
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
            if (exitCode !== 0) {
                root.activeMode = "error"
                root.loading = false
            }
        }
    }

    property var switchProcess: null

    // MEASURED times (2026-02-05):
    // Hybrid <-> Integrated: ~55s (rounded to 60s for UX)
    // Anything <-> Dedicated: 0s (MUX switch, requires reboot to apply)
    function getEstimatedTime(fromMode, toMode) {
        // Dedicated: instant command, actual change on reboot
        if (toMode === "asusmuxdgpu" || fromMode === "asusmuxdgpu") return 0
        // Hybrid <-> Integrated: ~60s (NVIDIA power state change)
        if ((fromMode === "integrated" && toMode === "hybrid") ||
            (fromMode === "hybrid" && toMode === "integrated")) return 60
        // Same mode = no change
        return 0
    }

    function getRequiredAction(fromMode, toMode) {
        if (toMode === "asusmuxdgpu" || fromMode === "asusmuxdgpu") return "reboot"
        return "logout"
    }

    function getActionText(action) {
        if (action === "reboot") return "Reboot required"
        if (action === "logout") return "Logout required"
        return ""
    }

    // Returns true if switching between these modes takes a long time (~60s)
    function isSlowSwitch(fromMode, toMode) {
        return getEstimatedTime(fromMode, toMode) > 0
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
        // Calculate time from CONFIGURED mode (what supergfxctl will see) to new mode
        const time = getEstimatedTime(configuredMode, newMode)
        switching = true
        targetMode = newMode
        switchTimeRemaining = time
        lastError = ""
        
        let cmd = newMode
        if (newMode === "integrated") cmd = "Integrated"
        else if (newMode === "hybrid") cmd = "Hybrid"
        else if (newMode === "asusmuxdgpu") cmd = "AsusMuxDgpu"
        
        console.log("[GPU] From:", configuredMode, "To:", newMode, "Time:", time)
        console.log("[GPU] Executing:", cmd, "| estimated:", time, "s")
        
        switchProcess = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["supergfxctl", "-m", "${cmd}"]
                running: true
            }
        `, root, "switchProcess")
        
        switchProcess.exited.connect((exitCode) => {
            console.log("[GPU] Completed:", exitCode)
            // If timer is still running (slow op), wait for it
            if (root.switchTimeRemaining <= 0) {
                root.switching = false
                root.targetMode = ""
            }
            // Timer will set switching=false when it reaches 0
            
            if (exitCode === 0) {
                root.lastError = ""
                // Update configured and pending
                root.configuredMode = newMode
                root.pendingMode = newMode !== root.activeMode ? newMode : ""
                root.switchSuccess(newMode)
            } else {
                root.lastError = "Failed (" + exitCode + ")"
                root.switchFailed("" + exitCode)
            }
            
            if (switchProcess) {
                switchProcess.destroy()
                switchProcess = null
            }
        })
    }

    function refresh() {
        if (available && !switching) {
            pendingConfirmation = ""
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
