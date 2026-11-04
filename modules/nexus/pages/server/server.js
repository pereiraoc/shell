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

// SSD do sistema do DXP4800 Plus: interno (placa-mae), NAO ocupa os 2 slots M.2 de baixo
var INTERNAL_SSD = /^TWSC TSC3AN128/;

function isInternalSsd(d) {
    return INTERNAL_SSD.test(String(d?.model ?? ""));
}

function internalSsd(disks) {
    return (disks ?? []).find(isInternalSsd) ?? null;
}

// Slot fisico pelo endereco PCI do controlador (nas-status "pci"). Conferido no aparelho em 03/11: o Lexar em
// 0000:02:00.0 esta no M.2 2, o mais perto da RAM; o M.2 1 (mais longe) ainda nao tem endereco conhecido.
var M2_SLOT_BY_PCI = { "0000:02:00.0": 2 };

// Slots M.2 de baixo (2, acesso pela tampa): [slot 1, slot 2], null = vazio. Os NVMe que nao sao o interno; quem
// tem slot conhecido pelo PCI vai nele, o resto ocupa o que sobrar.
function m2Slots(disks) {
    const ext = (disks ?? []).filter(d => (d.bus === "nvme" || (d.bus === undefined && d.kind === "ssd")) && !isInternalSsd(d)).sort((a, b) => String(a.dev).localeCompare(String(b.dev)));
    const slots = [null, null];
    const rest = [];
    for (const d of ext) {
        const n = M2_SLOT_BY_PCI[d.pci];
        if (n && !slots[n - 1])
            slots[n - 1] = d;
        else
            rest.push(d);
    }
    for (const d of rest) {
        const i = slots.indexOf(null);
        if (i >= 0)
            slots[i] = d;
    }
    return slots;
}

// Conectores de memoria: [RAM 1, RAM 2], null = vazio. Com `mem.dimms` (dmidecode no nas-status) cada pente no seu
// conector; sem ele (nas-status antigo) o total inteiro conta como RAM 1.
function ramSlots(mem) {
    if (Array.isArray(mem?.dimms) && mem.dimms.length) {
        const slots = [null, null];
        for (const d of mem.dimms)
            if (d.slot >= 1 && d.slot <= 2 && d.gb > 0)
                slots[d.slot - 1] = d;
        return slots;
    }
    // offline/antigo: o RAM 1 sempre teve pente (o NAS veio com um)
    return [{ slot: 1, gb: mem?.total ? Math.round(mem.total / 1024) : null }, null];
}

function ramLegend(n, r) {
    if (!r)
        return `Memory slot ${n} · empty`;
    if (!r.gb)
        return `Memory slot ${n} · installed module`;
    if (!r.part)
        return `Memory slot ${n} · ${r.gb} GB installed`;
    const maker = String(r.maker ?? "").split(" ")[0];
    const speed = r.configured ? ` · ${r.configured} MT/s${r.speed && r.speed !== r.configured ? ` (rated ${r.speed})` : ""}` : "";
    return `Memory slot ${n} · ${r.gb} GB ${maker} ${r.part}${speed}`;
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
            return `M.2 slot ${n} · empty`;
        return `M.2 slot ${n} · ${disk.dev} ${disk.model ?? ""} · ${fmtBytes(disk.size)} · SMART ${disk.smart ?? "?"}${disk.temp != null ? ` · ${disk.temp} °C` : ""}`;
    }
    if (/^ram-\d$/.test(id)) {
        const n = Number(id.split("-")[1]);
        return ramLegend(n, ramSlots(d.mem)[n - 1]);
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

// ---------------------------------------------------------------- cards dos servicos
// Stack ou unidade do NixOS -> logo de marca (assets/services/<slug>.svg, Simple
// Icons em branco, pintado na cor do tema) ou, sem logo, um simbolo Material.
const SERVICE_META = {
    arr: { art: "sonarr", title: "*arr suite" },
    authelia: { art: "authelia", title: "Authelia" },
    foundry: { art: "foundryvirtualtabletop", title: "Foundry VTT" },
    pleitost: { glyph: "menu_book", title: "Pleitost" },
    odysseus: { glyph: "neurology", title: "Odysseus" },
    adguardhome: { art: "adguard", title: "AdGuard Home (DNS filter)" },
    homeassistant: { art: "homeassistant", title: "Home Assistant" },
    immich: { art: "immich", title: "Immich" },
    jellyfin: { art: "jellyfin", title: "Jellyfin" },
    mail: { glyph: "mail", title: "Mail (Stalwart)" },
    mosquitto: { art: "eclipsemosquitto", title: "Mosquitto" },
    navidrome: { glyph: "library_music", title: "Navidrome" },
    netalertx: { glyph: "lan", title: "NetAlertX" },
    nextcloud: { art: "nextcloud", title: "Nextcloud" },
    ntfy: { art: "ntfy", title: "ntfy" },
    supabase: { art: "supabase", title: "Supabase" },
    tv: { glyph: "live_tv", title: "Live TV (Dispatcharr)" },
    zigbee2mqtt: { art: "zigbee2mqtt", title: "Zigbee2MQTT" },
    caddy: { art: "caddy", title: "Caddy" },
    netbird: { glyph: "vpn_lock", title: "NetBird" },
    docker: { art: "docker", title: "Docker" },
    "nas-fan": { glyph: "mode_fan", title: "Fan control" },
    "nas-backup": { glyph: "backup", title: "Backup" },
    "nas-disk-alert": { glyph: "notification_important", title: "Disk alerts" },
    "btrfs-scrub-srv-storage": { glyph: "fact_check", title: "Btrfs scrub" },
    sshd: { glyph: "terminal", title: "SSH" },
    fail2ban: { glyph: "gpp_maybe", title: "fail2ban" },
    "avahi-daemon": { glyph: "wifi_tethering", title: "Avahi (.local)" },
    smartd: { glyph: "monitor_heart", title: "SMART monitor" },
    "srv-storage": { glyph: "hard_drive", title: "Storage mount" }
};

// "caddy.service" -> "caddy"; nome de stack passa igual
function serviceKey(name) {
    return String(name ?? "").replace(/\.(service|timer|mount|socket)$/, "");
}

function serviceArt(name) {
    const m = SERVICE_META[serviceKey(name)];
    return m?.art ? `assets/services/${m.art}.svg` : "";
}

function serviceGlyph(name) {
    return SERVICE_META[serviceKey(name)]?.glyph ?? "deployed_code";
}

function serviceTitle(name) {
    const k = serviceKey(name);
    return SERVICE_META[k]?.title ?? k;
}

// Tipo da unidade (timer/mount) vira um sufixo curto no card
function unitKind(unit) {
    const m = /\.(timer|mount|socket)$/.exec(String(unit ?? ""));
    return m ? m[1] : "";
}

// Chave da bolinha: on (verde), failed (vermelho), busy (amarelo), off (cinza).
// Parada de proposito (sem dongle / autoStart = false) e "off", nao erro.
function dotKey(stateKey) {
    if (stateKey === "on" || stateKey === "failed" || stateKey === "off")
        return stateKey;
    return "busy";
}

// Uma linha de resumo para o card: containers rodando de N, ou o estado
function stackSummary(s) {
    if (s?.where === "pc")
        return "Runs on this PC (NAS publishes it on the VPN)";
    if (s?.site)
        return "Static site served by Caddy";
    const cs = s?.containers ?? [];
    if (cs.length === 0)
        return s?.condition_met === false ? "Waiting for its device" : s?.auto_start === false ? "Stopped (manual start)" : "No containers";
    const up = cs.filter(c => c.state === "running").length;
    const unhealthy = cs.filter(c => /unhealthy/.test(c.status ?? "")).length;
    let t = cs.length === 1 ? (cs[0].status ?? cs[0].state ?? "") : `${up}/${cs.length} containers up`;
    if (unhealthy > 0 && cs.length > 1)
        t += ` · ${unhealthy} unhealthy`;
    return t;
}

// Nome da VPN como o produto escreve ("netbird" -> "NetBird")
function overlayName(kind) {
    return ({ netbird: "NetBird", tailscale: "Tailscale", wireguard: "WireGuard", zerotier: "ZeroTier" })[kind] ?? (kind || "?");
}

// Grupos da aba Services (ordem = ordem na tela). Stack ou unidade fora do
// mapa cai em "other" (grupo "Other" no fim), para nada sumir.
const SERVICE_GROUPS = [
    { key: "media", title: "Media", members: ["jellyfin", "navidrome", "tv", "arr"] },
    { key: "files", title: "Photos & files", members: ["immich", "nextcloud"] },
    { key: "home", title: "Smart home", members: ["homeassistant", "zigbee2mqtt", "mosquitto", "netalertx"] },
    { key: "apps", title: "Apps & games", members: ["odysseus", "foundry", "pleitost", "supabase"] },
    { key: "comms", title: "Login, mail & alerts", members: ["authelia", "mail", "ntfy"] },
    { key: "net", title: "Network & access", members: ["caddy", "netbird", "adguardhome", "sshd", "fail2ban", "avahi-daemon"] },
    { key: "disks", title: "Disks & backup", members: ["srv-storage", "btrfs-scrub-srv-storage", "smartd", "nas-backup", "nas-disk-alert"] },
    { key: "platform", title: "Platform", members: ["docker", "nas-fan"] }
];

// items: lista de stacks ({name}) ou unidades ({unit}); nameOf tira o nome.
// Devolve [{ key, title, items }] so com grupos nao vazios, na ordem acima;
// dentro do grupo, a ordem dos members.
function groupServices(items, nameOf) {
    const out = [];
    const used = new Set();
    for (const g of SERVICE_GROUPS) {
        const its = [];
        for (const m of g.members)
            for (const it of items ?? [])
                if (serviceKey(nameOf(it)) === m && !used.has(it)) {
                    its.push(it);
                    used.add(it);
                }
        if (its.length > 0)
            out.push({ key: g.key, title: g.title, items: its });
    }
    const rest = (items ?? []).filter(it => !used.has(it));
    if (rest.length > 0)
        out.push({ key: "other", title: "Other", items: rest });
    return out;
}

// Apps que nao sao stack Docker (Pleitost = site estatico que o Caddy serve de
// /srv/appdata/pleitost/www): cada `open:<app>` sem stack vira um "site" com o
// estado do caddy.service, para o card aparecer no grupo dele.
function staticSites(actions, stacks, services) {
    const names = new Set((stacks ?? []).map(s => s.name));
    const caddy = (services ?? []).find(u => u.unit === "caddy.service");
    return (actions ?? []).filter(a => typeof a.id === "string" && a.id.startsWith("open:") && !names.has(a.id.slice(5))).map(a => ({
        name: a.id.slice(5),
        site: true,
        active: caddy?.active ?? "inactive",
        since: caddy?.since ?? null,
        unit: "caddy.service",
        containers: [],
        detail: a.detail ?? ""
    }));
}

// Unidades do sistema para os cards: o par x.service + x.timer vira um card so
// (o do timer); um oneshot "inactive/dead" entre execucoes NAO e problema.
function visibleUnits(services) {
    const timers = new Set((services ?? []).filter(u => /\.timer$/.test(u.unit)).map(u => serviceKey(u.unit)));
    return (services ?? []).filter(u => !(/\.service$/.test(u.unit) && timers.has(serviceKey(u.unit))));
}

// Resumo do card de unidade. backup = data.backup do nas-status (tem o proximo horario).
function unitSummary(u, services, backup) {
    const key = serviceKey(u.unit);
    if (/\.timer$/.test(u.unit)) {
        const svc = (services ?? []).find(x => x.unit === key + ".service");
        const parts = ["Scheduled"];
        if (key === "nas-backup" && backup?.next)
            parts.push("next " + String(backup.next).replace("T", " ").slice(5, 16));
        if (svc?.active === "activating")
            parts.push("running now");
        else if (svc?.result && svc.result !== "success")
            parts.push("last run failed");
        else if (svc)
            parts.push("last run ok");
        return parts.join(" · ");
    }
    if (u.active === "inactive" && u.result === "success" && (u.sub === "dead" || u.sub === "exited"))
        return "Idle · last run ok";
    if (u.active === "active" && u.sub === "exited")
        return "Applied (one-shot)";
    if (/\.mount$/.test(u.unit))
        return u.active === "active" ? "Mounted" : "Not mounted";
    return u.active === "active" ? "Running" : (u.sub ?? "");
}

// Estado da bolinha de uma unidade: timer cujo servico falhou na ultima vez = falhou
function unitStateKey(u, services) {
    if (/\.timer$/.test(u?.unit ?? "")) {
        const svc = (services ?? []).find(x => x.unit === serviceKey(u.unit) + ".service");
        if (svc && (svc.active === "failed" || (svc.result && svc.result !== "success")))
            return "failed";
    }
    return stateKey(u?.active);
}
