.pragma library

// Funcoes puras da pagina Server (Nexus): formatacao e filtros sobre o JSON de
// `caelestia-nas status/actions`. Sem Qt, sem estado: testadas em
// tests/qml/tst_server.qml.

function fmtBytes(n) {
    if (n === null || n === undefined || isNaN(n))
        return "?";
    const units = [["TB", 1099511627776], ["GB", 1073741824], ["MB", 1048576], ["KB", 1024]];
    for (const [u, s] of units)
        if (n >= s)
            return `${(n / s).toFixed(1)} ${u}`;
    return `${n} B`;
}

function fmtUptime(s) {
    if (s === null || s === undefined || isNaN(s))
        return "?";
    const d = Math.floor(s / 86400);
    const h = Math.floor((s % 86400) / 3600);
    const m = Math.floor((s % 3600) / 60);
    if (d > 0)
        return `${d} d ${h} h`;
    if (h > 0)
        return `${h} h ${m} min`;
    return `${m} min`;
}

// "2026-11-01T03:30:00" (hora local, como o nas-status grava) -> minutos ate `now` (ms)
function minutesSince(iso, now) {
    if (!iso)
        return null;
    const t = Date.parse(iso);
    if (isNaN(t))
        return null;
    return Math.max(0, Math.round(((now ?? Date.now()) - t) / 60000));
}

function fmtAgo(iso, now) {
    const m = minutesSince(iso, now);
    if (m === null)
        return "";
    if (m < 60)
        return `${m} min ago`;
    if (m < 48 * 60)
        return `${Math.floor(m / 60)} h ago`;
    return `${Math.floor(m / 1440)} d ago`;
}

// ActiveState do systemd -> chave estavel para rotulo/icone
function stateKey(active) {
    switch (active) {
    case "active":
        return "on";
    case "activating":
    case "reloading":
        return "starting";
    case "deactivating":
        return "stopping";
    case "failed":
        return "failed";
    default:
        return "off";
    }
}

function stateIcon(key) {
    return ({ on: "check_circle", starting: "hourglass_top", stopping: "hourglass_bottom", failed: "error", off: "radio_button_unchecked" })[key] ?? "help";
}

function pickActions(actions, prefix) {
    return (actions ?? []).filter(a => typeof a.id === "string" && a.id.startsWith(prefix));
}

function stackActions(actions, name) {
    return (actions ?? []).filter(a => typeof a.id === "string" && /^(start|stop|restart):/.test(a.id) && a.id.endsWith(":" + name));
}

function actionById(actions, id) {
    return (actions ?? []).find(a => a.id === id) ?? null;
}

// "lan" | "overlay" | "ssh" | "offline"
function reachKey(data) {
    if (!data || data.online !== true)
        return "offline";
    return data.reach ?? "ssh";
}

// Opcoes do seletor de unidade da aba Logs: stacks primeiro, depois as nativas
function unitsForLogs(data) {
    const out = [];
    for (const s of data?.stacks ?? [])
        out.push({ value: s.unit, label: s.name });
    for (const u of data?.services ?? [])
        out.push({ value: u.unit, label: String(u.unit).replace(/\.(service|timer|mount)$/, "") });
    return out;
}

function storageFs(data, mount) {
    return (data?.filesystems ?? []).find(f => f.mount === mount) ?? null;
}

function pct(fs) {
    return fs && fs.pct !== null && fs.pct !== undefined ? fs.pct / 100 : 0;
}

function fsLevel(fs) {
    if (!fs)
        return "ok";
    if ((fs.btrfs?.scrub?.errors ?? 0) > 0 || fs.pct >= 90)
        return "error";
    if (fs.pct >= 75)
        return "warn";
    return "ok";
}

function backupLevel(b, now) {
    if (!b)
        return "ok";
    if (b.last_result === "failed")
        return "error";
    const m = minutesSince(b.last_start, now);
    if (b.alert || (m !== null && m > 36 * 60))
        return "warn";
    return "ok";
}
