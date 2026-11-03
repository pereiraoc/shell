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
// Unidades da aba Logs: stacks primeiro, depois os servicos do NixOS. `group`
// ("stack" | "service") vira o rotulo de cada linha no seletor.
function unitsForLogs(data) {
    const out = [];
    for (const s of data?.stacks ?? [])
        out.push({ value: s.unit, label: s.name, group: "stack" });
    for (const u of data?.services ?? [])
        out.push({ value: u.unit, label: String(u.unit).replace(/\.(service|timer|mount)$/, ""), group: "service" });
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

// ---------------------------------------------------------------- silhueta
// Baia n (1-4) -> disco SATA na porta n (nas-status.bay). Sem `bay` (nas-status
// antigo): os HDs na ordem em que aparecem.
function bayMap(disks) {
    const out = {};
    const sata = (disks ?? []).filter(d => d.bus === "ata" || (d.bus === undefined && d.kind === "hdd"));
    let next = 1;
    for (const d of sata) {
        const n = d.bay ?? next;
        if (n >= 1 && n <= 4 && !out[n])
            out[n] = d;
        next = Math.max(next, n + 1);
    }
    return out;
}

// Slots M.2 de baixo: [sistema, Lexar] = os NVMe na ordem (nvme0n1 = sistema).
function m2Slots(disks) {
    return (disks ?? []).filter(d => d.bus === "nvme" || (d.bus === undefined && d.kind === "ssd")).sort((a, b) => String(a.dev).localeCompare(String(b.dev))).slice(0, 2);
}

// Porta de rede pelo driver (atlantic = 10 GbE, igc = 2,5 GbE), ou null.
function lanPort(net, driver) {
    return (net ?? []).find(n => n.driver === driver) ?? null;
}

// Legenda de uma peca da silhueta.
function spotLegend(id, info) {
    const d = info ?? {};
    if (/^bay-\d$/.test(id)) {
        const n = Number(id.split("-")[1]);
        const disk = bayMap(d.disks)[n];
        if (!disk)
            return `Bay ${n} · empty`;
        return `Bay ${n} · ${disk.dev} ${disk.model ?? ""} · ${fmtBytes(disk.size)} · SMART ${disk.smart ?? "?"}${disk.temp != null ? ` · ${disk.temp} °C` : ""}`;
    }
    if (/^m2-\d$/.test(id)) {
        const n = Number(id.split("-")[1]);
        const disk = m2Slots(d.disks)[n - 1];
        if (!disk)
            return n === 2 ? "M.2 slot 2 · empty (Lexar NM790 pending)" : "M.2 slot 1 · empty";
        return `M.2 slot ${n} · ${disk.dev} ${disk.model ?? ""} · ${fmtBytes(disk.size)} · SMART ${disk.smart ?? "?"}${disk.temp != null ? ` · ${disk.temp} °C` : ""}${n === 1 ? " · system" : ""}`;
    }
    if (/^ram-\d$/.test(id)) {
        const n = Number(id.split("-")[1]);
        if (n === 1)
            return d.mem?.total ? `Memory slot 1 · ${Math.round(d.mem.total / 1024)} GB installed` : "Memory slot 1 · installed module";
        return "Memory slot 2 · empty (ADATA 16 GB pending)";
    }
    if (id === "power")
        return d.online === true ? `Power · on, up for ${fmtUptime(d.uptime_s)}` : "Power · out of reach";
    if (id === "fan") {
        const f = d.fans ?? {};
        return f.case_rpm != null ? `Fan · case ${Math.round(f.case_rpm)} rpm (${f.case_mode ?? "?"}) · CPU ${Math.round(f.cpu_rpm ?? 0)} rpm (${f.cpu_mode ?? "?"})` : "Fan · no reading";
    }
    if (id === "lan-10g" || id === "lan-2g5" || id === "led-net") {
        const p = id === "lan-2g5" ? lanPort(d.net, "igc") : lanPort(d.net, "atlantic");
        const name = id === "lan-2g5" ? "LAN 1 · 2.5 GbE" : "LAN 2 · 10 GbE";
        if (!p)
            return `${name} · unknown`;
        return `${name} (${p.iface}) · ${p.up ? `link ${p.speed_mbps ?? "?"} Mb/s` : "no cable"}${p.ip ? ` · ${p.ip}` : ""}`;
    }
    return "";
}

// Onde cada peca abre: { page, tab } do Nexus. Discos (baias e M.2) moram em
// Storage > NAS desde 02/11; o resto (memoria, ventoinha, portas) em Server > System.
function spotTarget(id) {
    if (/^(bay|m2)-/.test(id))
        return { page: "storage", tab: "nas" };
    return { page: "server", tab: "system" };
}

// ---------------------------------------------------------------- usuarios
// Aba Users: login central (Authelia) via `caelestia-nas users --json` e
// `caelestia-nas run user-*`. As acoes rodam em fila; enquanto correm, a lista
// mostra o resultado esperado (otimista) e a linha do usuario fica ocupada.

const USER_RE = /^[a-z][a-z0-9._-]{1,31}$/;
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
// Mesmo conjunto do MEDIUM do caelestia-nas: pedem dois cliques
const USER_MEDIUM = ["delete", "block", "passwd", "totp-reset"];

// "user-grant:bia:fotos" -> { verb: "grant", user: "bia", svc: "fotos" }; "user-code" -> { verb: "code" }
function parseUserAction(id) {
    const m = /^user-([a-z-]+)(?::([^:]+))?(?::([^:]+))?$/.exec(String(id ?? ""));
    if (!m)
        return null;
    return { verb: m[1], user: m[2] ?? "", svc: m[3] ?? "" };
}

function userActionId(verb, user, svc) {
    if (verb === "code")
        return "user-code";
    return svc ? `user-${verb}:${user}:${svc}` : `user-${verb}:${user}`;
}

function userActionRisk(verb) {
    return USER_MEDIUM.includes(verb) ? "medium" : "low";
}

// Liga/desliga um servico: grant ou revoke conforme o estado atual
function serviceToggleId(user, svc) {
    const has = (user?.services ?? []).includes(svc);
    return userActionId(has ? "revoke" : "grant", user?.name ?? "", svc);
}

// A lista com as acoes ainda na fila ja aplicadas (sem mexer no original).
// delete nao some: fica marcado `deleting` ate a releitura.
function applyPending(users, ids) {
    const out = (users ?? []).map(u => Object.assign({}, u, { services: (u.services ?? []).slice() }));
    for (const id of ids ?? []) {
        const a = parseUserAction(id);
        const u = a ? out.find(x => x.name === a.user) : null;
        if (!u)
            continue;
        switch (a.verb) {
        case "grant":
            if (!u.services.includes(a.svc))
                u.services.push(a.svc);
            break;
        case "revoke":
            u.services = u.services.filter(s => s !== a.svc);
            break;
        case "admin":
            u.admin = true;
            break;
        case "member":
            u.admin = false;
            break;
        case "block":
            u.blocked = true;
            break;
        case "unblock":
            u.blocked = false;
            break;
        case "delete":
            u.deleting = true;
            break;
        }
    }
    return out;
}

function userBusy(ids, name) {
    return !!name && (ids ?? []).some(id => parseUserAction(id)?.user === name);
}

// "" quando o formulario esta bom; senao a chave do problema
// ("name" | "exists" | "display" | "email")
function validateNewUser(form, users) {
    const f = form ?? {};
    if (!USER_RE.test(f.name ?? ""))
        return "name";
    if ((users ?? []).some(u => u.name === f.name))
        return "exists";
    if (!String(f.display ?? "").trim())
        return "display";
    if (!EMAIL_RE.test(f.email ?? ""))
        return "email";
    return "";
}

// argv de `caelestia-nas` para criar o usuario (sem o binario)
function addUserArgs(form) {
    const f = form ?? {};
    const svcs = (f.services ?? []).filter(s => s);
    return ["users", "add", f.name, String(f.display ?? "").trim(), f.email, ...(f.admin ? ["--admin"] : []), ...(svcs.length ? ["--services", svcs.join(",")] : []), "--json"];
}

// Liga/desliga um id numa lista (servicos marcados no formulario)
function toggleIn(list, id) {
    const l = list ?? [];
    return l.includes(id) ? l.filter(x => x !== id) : [...l, id];
}

// Por nome, estavel: mudar papel ou bloquear nao faz a linha pular de lugar
function sortUsers(users) {
    return (users ?? []).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
}
