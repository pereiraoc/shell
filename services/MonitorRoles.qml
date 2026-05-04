pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config

// US-005 — Resolve ordered monitor list (role 0, 1, 2, ..., N-1) para workspace
// allocation por monitor. Escalável a qualquer número de monitores.
//
// Identidade: hardware fingerprint via 'desc:' (não muda com hotplug/porta).
// Resolução: overrides do user primeiro, depois auto-fill em slots livres.
// Auto-fill: built-in (eDP-/LVDS-/DSI-) primeiro, depois alfabética por description.
//
// Friendly names só pros primeiros 4 (primary, secondary, tertiary, quaternary).
// Acima de 4: usar índice numérico ou nome "monitor-N".
//
// API:
//   orderedMonitors          -> [m0, m1, m2, ...] na ordem resolvida
//   count                    -> número de monitores conectados
//   monitorAtIndex(idx)      -> HyprlandMonitor | null
//   monitorForRole(role)     -> aceita "primary"/"secondary"/"tertiary"/"quaternary" ou "monitor-N"
//   indexForMonitor(monitor) -> 0..N-1 ou -1 se não encontrado
//   nameForIndex(idx)        -> "primary", "secondary", ..., ou "monitor-N" para idx >= 4
//   descOf(monitor)          -> "desc:HARDWARE_FINGERPRINT"
Singleton {
    id: root

    readonly property list<string> friendlyNames: ["primary", "secondary", "tertiary", "quaternary"]

    readonly property var orderedMonitors: resolveOrderedMonitors()
    readonly property int count: orderedMonitors.length

    function descOf(monitor): string {
        if (!monitor || !monitor.description) return "";
        return "desc:" + monitor.description;
    }

    function isBuiltin(monitor): bool {
        if (!monitor || !monitor.name) return false;
        return /^(eDP|LVDS|DSI)-/.test(monitor.name);
    }

    // Converte string de role ("primary", "monitor-5", etc.) → índice numérico (0..N-1) ou -1
    function indexForRole(role: string): int {
        if (!role) return -1;
        const friendly = friendlyNames.indexOf(role);
        if (friendly >= 0) return friendly;
        const match = role.match(/^monitor-(\d+)$/);
        if (match) return parseInt(match[1]);
        return -1;
    }

    function nameForIndex(idx: int): string {
        if (idx < 0) return "";
        if (idx < friendlyNames.length) return friendlyNames[idx];
        return "monitor-" + idx;
    }

    function monitorAtIndex(idx: int): var {
        if (idx < 0 || idx >= orderedMonitors.length) return null;
        return orderedMonitors[idx];
    }

    function monitorForRole(role: string): var {
        return monitorAtIndex(indexForRole(role));
    }

    function indexForMonitor(monitor): int {
        if (!monitor) return -1;
        for (let i = 0; i < orderedMonitors.length; i++) {
            if (orderedMonitors[i]?.name === monitor.name) return i;
        }
        return -1;
    }

    function resolveOrderedMonitors(): var {
        const monitors = Hyprland.monitors.values.slice();
        const overrides = GlobalConfig.monitorRoleOverrides ?? ({});
        const slots = []; // sparse array indexed by role index
        const usedNames = new Set();

        // 1. Aplica overrides — ordenados por desc para determinismo (ordem de iteração
        //    de objetos não é garantida em JS strict)
        const overrideEntries = Object.entries(overrides)
            .filter(([desc, role]) => indexForRole(role) >= 0)
            .sort(([a], [b]) => a.localeCompare(b));

        for (const [desc, role] of overrideEntries) {
            const idx = indexForRole(role);
            if (slots[idx]) continue; // slot já reservado por outro override
            const m = monitors.find(x => descOf(x) === desc);
            if (m && !usedNames.has(m.name)) {
                slots[idx] = m;
                usedNames.add(m.name);
            }
        }

        // 2. Monitores restantes ordenados: built-in primeiro, depois alfabética por description
        const remaining = monitors
            .filter(m => !usedNames.has(m.name))
            .sort((a, b) => {
                const aBuiltin = isBuiltin(a);
                const bBuiltin = isBuiltin(b);
                if (aBuiltin !== bBuiltin) return aBuiltin ? -1 : 1;
                return (a.description || "").localeCompare(b.description || "");
            });

        // 3. Preenche slots livres na ordem (0, 1, 2, ..., N+remaining)
        let nextIdx = 0;
        for (const m of remaining) {
            // Pula índices já preenchidos por overrides
            while (slots[nextIdx]) nextIdx++;
            slots[nextIdx] = m;
            nextIdx++;
        }

        // Compacta para array contíguo (no caso de overrides apontarem pra índices altos
        // mas não termos monitores suficientes, slots intermediários ficariam vazios).
        // Filter remove undefined/null slots e mantém ordem.
        return slots.filter(m => m);
    }

    Component.onCompleted: {
        const desc = orderedMonitors.map((m, i) => `${nameForIndex(i)}=${m?.name ?? "null"}`).join(", ");
        console.log("[MonitorRoles] resolved (count=" + count + "):", desc);
    }

    Connections {
        target: Hyprland.monitors
        function onValuesChanged(): void {
            console.log("[MonitorRoles] monitors changed (count=" + count + ")");
        }
    }

    Connections {
        target: GlobalConfig
        function onMonitorRoleOverridesChanged(): void {
            console.log("[MonitorRoles] overrides changed (count=" + count + ")");
        }
    }
}
