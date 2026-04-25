pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        // Use screen.name as key instead of HyprlandMonitor object
        // This prevents stale references when monitors are added/removed
        const screenName = screen?.name ?? "unknown";
        console.log("[Visibilities] Loading screen:", screenName);
        screens.set(screenName, visibilities);
    }

    function getForActive(): PersistentProperties {
        const focusedName = Hypr.focusedMonitor?.name ?? "unknown";
        return screens.get(focusedName);
    }
}
