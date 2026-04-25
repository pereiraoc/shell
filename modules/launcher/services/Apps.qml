pragma Singleton

import qs.config
import qs.utils
import Caelestia
import Quickshell

Searcher {
    id: root

    function launch(entry: DesktopEntry): void {
        // Se for AppEntry (wrapper Caelestia), usar o DesktopEntry interno
        const desktopEntry = (entry && entry.entry) ? entry.entry : entry;
        const id = desktopEntry?.id ?? "";
        const name = desktopEntry?.name ?? "";

        appDb.incrementFrequency(id);

        if (desktopEntry?.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--"].concat(Config.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`).concat(Array.from(desktopEntry.command || [])),
                workingDirectory: desktopEntry.workingDirectory || ""
            });
        else if (id === "steam" || (name && name.indexOf("Games Hub (Steam)") >= 0)) {
            // Steam: executar wrapper com caminho absoluto, sem app2unit
            const wrapper = `${Paths.home}/.local/bin/steam-caelestia`;
            Quickshell.execDetached({
                command: [wrapper],
                workingDirectory: Paths.home
            });
        }
        else
            Quickshell.execDetached({
                command: ["app2unit", "--"].concat(Array.from(desktopEntry?.command || [])),
                workingDirectory: desktopEntry?.workingDirectory || ""
            });
    }

    function search(search: string): list<var> {
        const prefix = Config.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name"];
            weights = [1];

            if (!search.startsWith(`${prefix}t `))
                return query(search).map(e => e.entry);
        }

        const results = query(search.slice(prefix.length + 2)).map(e => e.entry);
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: Config.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        entries: DesktopEntries.applications.values.filter(a => !Config.launcher.hiddenApps.includes(a.id))
    }
}
