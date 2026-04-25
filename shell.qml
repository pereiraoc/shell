//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import qs.config
import qs.services
import Quickshell
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root
    
    property int previousScreenCount: 0
    property int hotplugRetryCount: 0
    
    Background {}
    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }

    Shortcuts {}
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    // HDMI hotplug workaround - pulse ALL screens
    Connections {
        target: Quickshell
        function onScreensChanged() {
            const currentCount = Quickshell.screens.length;
            console.log("[Hotplug] Screens changed: " + root.previousScreenCount + " -> " + currentCount);
            
            root.hotplugRetryCount = 0;
            
            // Longer delay when adding screens
            if (currentCount > root.previousScreenCount) {
                console.log("[Hotplug] Screen added, using extended delay");
                hotplugWorkaround.interval = 1000;
            } else {
                hotplugWorkaround.interval = 500;
            }
            
            root.previousScreenCount = currentCount;
            hotplugWorkaround.restart();
        }
    }

    Timer {
        id: hotplugWorkaround
        interval: 500
        repeat: false
        onTriggered: {
            root.hotplugRetryCount++;
            console.log("[Hotplug] Triggering visibility pulse on ALL screens (attempt " + root.hotplugRetryCount + ")");
            
            // Refresh Hyprland state first
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
            
            // Pulse ALL screens, not just active
            const screenMap = Visibilities.screens;
            let pulsedCount = 0;
            screenMap.forEach((vis, screenName) => {
                if (vis) {
                    console.log("[Hotplug] Pulsing launcher on: " + screenName);
                    vis.launcher = true;
                    pulsedCount++;
                }
            });
            
            if (pulsedCount > 0) {
                hotplugWorkaround2.restart();
            } else {
                console.log("[Hotplug] No visibilities found, retrying...");
                if (root.hotplugRetryCount < 3) {
                    hotplugWorkaround.interval = 500;
                    hotplugWorkaround.restart();
                }
            }
        }
    }
    
    Timer {
        id: hotplugWorkaround2
        interval: 150
        repeat: false
        onTriggered: {
            // Turn off launcher on ALL screens
            const screenMap = Visibilities.screens;
            screenMap.forEach((vis, screenName) => {
                if (vis) {
                    vis.launcher = false;
                }
            });
            console.log("[Hotplug] Visibility pulse complete on all screens");
            
            // For screen additions, do a second pulse
            if (root.hotplugRetryCount < 2 && Quickshell.screens.length > 1) {
                console.log("[Hotplug] Scheduling follow-up pulse");
                hotplugWorkaround.interval = 500;
                hotplugWorkaround.restart();
            }
        }
    }
    
    Component.onCompleted: {
        root.previousScreenCount = Quickshell.screens.length;
        console.log("[Hotplug] Initial screen count: " + root.previousScreenCount);
    }

    // Apply persisted Hyprland settings on startup
    Timer {
        running: true
        interval: 100
        repeat: false
        onTriggered: {
            if (Config.hyprland?.gaps) {
                const innerGap = Config.hyprland.gaps.inner ?? 5;
                const outerGap = Config.hyprland.gaps.outer ?? 20;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", innerGap.toString()]);
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", outerGap.toString()]);
            }
        }
    }
}
