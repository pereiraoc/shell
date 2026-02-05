pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Properties
    property string currentMode: "unknown"
    property bool available: false
    property bool switching: false
    
    // Signals
    signal modeChanged(string newMode)
    signal switchFailed(string error)
    signal switchSuccess(string newMode)

    // Process to check availability
    Process {
        id: checkProcess
        command: ["which", "supergfxctl"]
        
        property bool hasRun: false
        
        running: !hasRun
        
        onExited: exitCode => {
            hasRun = true
            root.available = (exitCode === 0)
            console.log("GPU supergfxctl available:", root.available)
            
            if (root.available) {
                Qt.callLater(() => queryProcess.running = true)
            }
        }
    }

    // Process to query current mode
    Process {
        id: queryProcess
        command: ["supergfxctl", "-g"]
        stdout: SplitParser {
            id: queryParser
            onRead: data => {
                const mode = data.trim().toLowerCase()
                console.log("GPU Mode detected:", mode)
                root.currentMode = mode
                root.modeChanged(mode)
            }
        }
        
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.error("Failed to query GPU mode, exit code:", exitCode)
            }
        }
    }

    // Switch GPU mode
    function switchMode(newMode) {
        if (!available || switching) {
            return
        }

        switching = true
        
        // Capitalize first letter for supergfxctl
        const modeCapitalized = newMode.charAt(0).toUpperCase() + newMode.slice(1)
        
        const process = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["supergfxctl", "-m", "${modeCapitalized}"]
                running: true
            }
        `, root, "switchProcess")
        
        process.exited.connect((exitCode) => {
            root.switching = false
            
            if (exitCode === 0) {
                root.currentMode = newMode
                root.switchSuccess(newMode)
                
                // Re-query to confirm
                Qt.callLater(() => { queryCurrentMode() })
            } else {
                const error = process.stderr || "Unknown error"
                root.switchFailed(error)
            }
            
            process.destroy()
        })
    }

    // Check if mode requires reboot
    function requiresReboot(fromMode, toMode) {
        // AsusMuxDgpu uses MUX switch, requires reboot
        if (toMode === "asusmuxdgpu" || fromMode === "asusmuxdgpu") {
            return true
        }
        return false
    }
    
    // Check if mode requires logout
    function requiresLogout(fromMode, toMode) {
        // All switches require at least logout
        return true
    }

    // Get user-friendly mode name
    function getModeName(mode) {
        switch(mode) {
            case "integrated": return "Integrated"
            case "hybrid": return "Hybrid"
            case "asusmuxdgpu": return "Dedicated"
            case "nvidianomodes": return "NoModeset"
            default: return "Unknown"
        }
    }

    // Get mode icon (using emojis)
    function getModeIcon(mode) {
        switch(mode) {
            case "integrated": return "💻"  // Laptop only
            case "hybrid": return "⚡"      // Balanced
            case "asusmuxdgpu": return "🎮"   // Gaming/Performance
            default: return "❓"
        }
    }

    // Get mode description
    function getModeDescription(mode) {
        switch(mode) {
            case "integrated": return "Intel only - Best battery"
            case "hybrid": return "Balanced - Good battery + GPU"
            case "asusmuxdgpu": return "NVIDIA only - Best performance"
            default: return ""
        }
    }
}
