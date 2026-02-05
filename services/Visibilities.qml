pragma Singleton

import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        const monitor = Hypr.monitorFor(screen);
        if (monitor)
            screens.set(monitor, visibilities);
    }

    function getForActive(): PersistentProperties {
        return screens.get(Hypr.focusedMonitor);
    }
}
