.pragma library

// Funcoes puras do mapa da rede de casa (Network > Home): nome, icone por
// tipo, como cada aparelho esta ligado (chip), a arvore Internet > roteador >
// cabo / Wi-Fi por AP > tipo, e a fila otimista das edicoes. Entrada: os
// `devices` de `caelestia-nas network --all --json`. Sem Qt, sem estado:
// testadas em tests/qml/tst_homenet.qml. Os textos em ingles daqui sao so o
// padrao dos testes; a pagina passa os seus (Tr.tr) em `labels`.

// Tipos que o NetAlertX aceita (caelestia-nas network type), na ordem em que
// aparecem dentro de um grupo: equipamento de rede primeiro.
var TYPES = [
    { value: "Router", icon: "router" },
    { value: "AP", icon: "wifi" },
    { value: "Switch", icon: "lan" },
    { value: "NAS", icon: "dns" },
    { value: "Desktop", icon: "desktop_windows" },
    { value: "Laptop", icon: "laptop" },
    { value: "Tablet", icon: "tablet_android" },
    { value: "Phone", icon: "smartphone" },
    { value: "TV", icon: "tv" },
    { value: "Speaker", icon: "speaker" },
    { value: "Game Console", icon: "sports_esports" },
    { value: "Singleboard Computer (SBC)", icon: "memory" },
    { value: "Printer", icon: "print" },
    { value: "Camera", icon: "videocam" },
    { value: "IoT", icon: "sensors" },
    { value: "Other", icon: "devices_other" }
];

var INFRA = ["Router", "AP", "Switch"];

function typeIcon(type) {
    if (!type)
        return "help";
    const t = TYPES.find(x => x.value === type);
    return t ? t.icon : "devices_other";
}

function typeRank(type) {
    const i = TYPES.findIndex(x => x.value === type);
    return i < 0 ? TYPES.length : i;
}

// Rotulo curto do tipo para o chip/cabecalho ("Singleboard Computer (SBC)" -> "SBC")
function typeLabel(type) {
    if (type === "Singleboard Computer (SBC)")
        return "SBC";
    return type || "";
}

function isPlaceholder(s) {
    return !s || /^\((name not found|unknown)\)$/i.test(s) || s === "null";
}

function nickname(d) {
    return isPlaceholder(d?.name) ? "" : d.name;
}

function isWan(d) {
    return d?.mac === "internet";
}

// Apelido > hostname do DHCP > fabricante > MAC
function bestName(d) {
    if (!d)
        return "?";
    if (!isPlaceholder(d.name))
        return d.name;
    if (d.hostname && !isPlaceholder(d.hostname))
        return d.hostname;
    if (d.vendor && !/^\(unknown/i.test(d.vendor))
        return d.vendor;
    return d.mac || "?";
}

// Nome curto de um no (AP/roteador) para o chip: o apelido ate o "(".
function shortName(d) {
    const n = bestName(d);
    const i = n.indexOf(" (");
    return i > 0 ? n.slice(0, i) : n;
}

function fmtSpeed(mbps) {
    if (mbps === null || mbps === undefined || isNaN(mbps) || mbps <= 0)
        return "";
    if (mbps >= 1000) {
        const g = mbps / 1000;
        return `${Number.isInteger(g) ? g : g.toFixed(1)} Gb/s`;
    }
    return `${Number.isInteger(mbps) ? mbps : Number(mbps).toFixed(1)} Mb/s`;
}

// Sem IP e tipo Switch: o switch sem gerencia (MAC sintetico); nao ha como
// pingar, entao "offline" nao quer dizer nada para ele.
function isPassive(d) {
    return !!d && !d.ip && d.type === "Switch";
}

// De onde veio a informacao do enlace: router|cast|ethtool|survey, ou "map"
// quando so o mapa do NetAlertX (parent/port) diz algo; "" = nada.
function sourceOf(d) {
    const c = d?.conn ?? {};
    if (c.source)
        return c.source;
    if (c.survey_at)
        return "survey";
    if (d?.parent && d.parent !== "internet" && d.parent !== "null")
        return "map";
    return "";
}

// Enlace de um aparelho: a quem ele se liga (up), por onde (wifi|cable|unknown)
// e a faixa. `byMac`: { mac: device } (minusculas).
function linkOf(d, byMac) {
    const c = d?.conn ?? {};
    const parent = (d?.parent && d.parent !== "null" && d.parent !== "internet") ? d.parent.toLowerCase() : "";
    const up = (c.via ? c.via.toLowerCase() : "") || parent;
    const parentDev = parent ? byMac[parent] : null;
    if (c.kind === "wifi")
        return { up: up, medium: "wifi", band: c.band || "" };
    if (c.kind === "ethernet")
        return { up: parent, medium: "cable", band: "" };
    if (d?.port === "wifi")
        return { up: parent, medium: "wifi", band: "" };
    // Pendurado num switch (so tem cabo) ou numa porta numerada: cabo
    if (parent && (/^\d+$/.test(d?.port ?? "") || parentDev?.type === "Switch"))
        return { up: parent, medium: "cable", band: "" };
    return { up: parent, medium: "unknown", band: "" };
}

// { mac: device }; os enderecos extras de um aparelho agrupado (`macs`)
// apontam para o mesmo aparelho, sem passar por cima de uma linha propria.
function indexByMac(devices) {
    const m = {};
    for (const d of devices ?? [])
        if (d?.mac)
            m[d.mac.toLowerCase()] = d;
    for (const d of devices ?? [])
        for (const a of d?.macs ?? []) {
            const k = (a?.mac ?? "").toLowerCase();
            if (k && !(k in m))
                m[k] = d;
        }
    return m;
}

var DEFAULT_LABELS = {
    wifi: "Wi-Fi",
    cable: "Cable",
    unknown: "Unknown",
    linkUnknown: "Linked, medium unknown",
    noConnection: "Unknown connection"
};

// Chip de conexao: { medium, icon, text, weak }. Ex.: "Wi-Fi 5G · AP auxiliar ·
// −49 dBm", "Cable · 1 Gb/s", "Cable", "Unknown".
function chip(d, byMac, labels) {
    const L = labels ?? DEFAULT_LABELS;
    const c = d?.conn ?? {};
    const k = linkOf(d, byMac ?? {});
    if (k.medium === "wifi") {
        const ap = k.up && byMac?.[k.up] ? shortName(byMac[k.up]) : (c.ssid || "");
        const parts = [`${L.wifi}${k.band ? " " + k.band : ""}`, ap];
        if (typeof c.signal_dbm === "number")
            parts.push(`−${Math.abs(c.signal_dbm)} dBm`);
        const rate = fmtSpeed(c.rate_mbps);
        if (rate)
            parts.push(rate);
        return { medium: "wifi", icon: "wifi", text: parts.filter(x => x).join(" · "), weak: typeof c.signal_dbm === "number" && c.signal_dbm <= -70 };
    }
    if (k.medium === "cable") {
        const sp = fmtSpeed(c.link_mbps);
        return { medium: "cable", icon: "cable", text: sp ? `${L.cable} · ${sp}` : L.cable, weak: false };
    }
    return { medium: "unknown", icon: "help", text: L.unknown, weak: false };
}

// -> ms. Dois formatos chegam: "2026-11-03T00:21:44" (conn.at/survey_at, hora
// local do NAS) e "2026-11-03 01:30:26" (first_seen/last_seen do NetAlertX, que
// grava em UTC; conferido em 03/11: last_seen 03:20 com o relogio em 00:20 -03).
function parseTime(s) {
    if (!s)
        return NaN;
    const str = String(s);
    if (/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}(:\d{2})?$/.test(str))
        return Date.parse(str.replace(" ", "T") + "Z");
    return Date.parse(str);
}

function minutesSince(s, now) {
    const t = parseTime(s);
    if (isNaN(t))
        return null;
    return Math.max(0, Math.round(((now ?? Date.now()) - t) / 60000));
}

// Ultima leitura de cada fonte de enlace (string ISO ou "")
function lastReads(devices) {
    const out = { router: "", survey: "", cast: "", ethtool: "" };
    for (const d of devices ?? []) {
        const c = d?.conn;
        if (!c)
            continue;
        const pairs = [[c.source, c.at], ["survey", c.survey_at]];
        for (const [src, at] of pairs) {
            if (!src || !at || !(src in out))
                continue;
            if (!out[src] || parseTime(at) > parseTime(out[src]))
                out[src] = at;
        }
    }
    return out;
}

function summary(devices) {
    const list = (devices ?? []).filter(d => !isWan(d));
    return {
        online: list.filter(d => d.online).length,
        fresh: list.filter(d => d.new).length,
        total: list.length,
        reads: lastReads(list)
    };
}

// Desconhecidos (new): online primeiro, mais recentes primeiro
function unknownDevices(devices) {
    return (devices ?? []).filter(d => d.new && !isWan(d)).sort((a, b) => {
        if (!!a.online !== !!b.online)
            return a.online ? -1 : 1;
        return (parseTime(b.first_seen) || 0) - (parseTime(a.first_seen) || 0);
    });
}

// O roteador principal: pendurado na Internet; senao o primeiro Router
function findRoot(devices) {
    const list = (devices ?? []).filter(d => !isWan(d));
    return list.find(d => d.parent === "internet") ?? list.find(d => d.type === "Router") ?? null;
}

// Roteador que nao e o principal: tudo atras dele esta em NAT (invisivel)
function isNat(d, rootMac) {
    return d?.type === "Router" && (d.mac ?? "").toLowerCase() !== rootMac;
}

function sortByType(list) {
    return list.slice().sort((a, b) => {
        const r = typeRank(a.type) - typeRank(b.type);
        if (r !== 0)
            return r;
        return bestName(a).localeCompare(bestName(b));
    });
}

var GROUP_ORDER = ["cable", "wifi:5G", "wifi:2.4G", "wifi:", "unknown", "none"];

function groupKey(link) {
    return link.medium === "wifi" ? `wifi:${link.band}` : link.medium;
}

function groupRank(key) {
    const i = GROUP_ORDER.indexOf(key);
    return i < 0 ? GROUP_ORDER.indexOf("wifi:") : i;
}

// Arvore achatada para um Repeater. Cada linha: { kind, depth, rails, last, key, ... }
//   wan    { dev? }                      a Internet (linha mac "internet")
//   device { dev, kids, nat, unmanaged } um aparelho (os nos tem filhos)
//   link   { medium, band, count }       "Cable" / "Wi-Fi 5G" / ... / "none"
//   type   { type, count }               cabecalho de tipo dentro do grupo
//   note   { note: "nat"|"switch" }      limite do que da para ver
// rails[i]: desenhar a linha vertical da coluna i inteira (ancestral com irmaos
// abaixo); last: ultimo filho do pai (o "└"). opts.showOffline=false esconde
// offline sem filhos visiveis.
function buildMap(devices, opts) {
    const showOffline = opts?.showOffline !== false;
    const byMac = indexByMac(devices);
    const wan = (devices ?? []).find(isWan) ?? null;
    const root = findRoot(devices);
    const rootMac = root ? root.mac.toLowerCase() : "";
    const kids = {};
    const orphans = [];
    for (const d of devices ?? []) {
        if (isWan(d) || d === root || !d?.mac)
            continue;
        const k = linkOf(d, byMac);
        // Enlace para um endereco extra de um grupo: o no e o principal
        const upDev = k.up ? byMac[k.up] : null;
        const up = upDev && upDev.mac.toLowerCase() !== d.mac.toLowerCase() ? upDev.mac.toLowerCase() : "";
        if (!up) {
            orphans.push({ dev: d, link: { up: "", medium: "none", band: "" } });
            continue;
        }
        (kids[up] = kids[up] ?? []).push({ dev: d, link: k });
    }

    // Visivel: online, passivo, offline mostrado, ou com descendente visivel
    const seen = {};
    function visible(d) {
        const mac = d.mac.toLowerCase();
        if (seen[mac] !== undefined)
            return seen[mac];
        seen[mac] = false; // ciclo: nao volta aqui
        const v = showOffline || d.online || isPassive(d) || (kids[mac] ?? []).some(k => visible(k.dev));
        seen[mac] = v;
        return v;
    }

    function groupsOf(entries) {
        const groups = {};
        for (const e of entries) {
            if (!visible(e.dev))
                continue;
            const key = e.link.medium === "none" ? "none" : groupKey(e.link);
            (groups[key] = groups[key] ?? { medium: e.link.medium, band: e.link.band, devs: [] }).devs.push(e.dev);
        }
        return Object.keys(groups).sort((a, b) => groupRank(a) - groupRank(b)).map(k => groups[k]);
    }

    const rows = [];
    const done = {};

    function emitDevice(d, depth, prefix, last) {
        const mac = d.mac.toLowerCase();
        const nat = isNat(d, rootMac) && mac !== rootMac;
        const unmanaged = isPassive(d);
        const groups = done[mac] ? [] : groupsOf(kids[mac] ?? []);
        done[mac] = true;
        const extra = (nat ? 1 : 0) + (unmanaged ? 1 : 0);
        rows.push({ kind: "device", key: `d:${mac}`, depth: depth, rails: prefix, last: last, dev: d, kids: groups.length + extra, nat: nat, unmanaged: unmanaged });
        const childPrefix = depth === 0 ? [] : prefix.concat([!last]);
        const children = groups.length + extra;
        let i = 0;
        if (unmanaged) {
            rows.push({ kind: "note", key: `n:switch:${mac}`, depth: depth + 1, rails: childPrefix, last: ++i === children, note: "switch" });
        }
        if (nat) {
            rows.push({ kind: "note", key: `n:nat:${mac}`, depth: depth + 1, rails: childPrefix, last: ++i === children, note: "nat" });
        }
        for (const g of groups)
            emitGroup(g, mac, depth + 1, childPrefix, ++i === children);
    }

    function emitGroup(g, parentMac, depth, prefix, last) {
        const key = g.medium === "wifi" ? `wifi:${g.band}` : g.medium;
        rows.push({ kind: "link", key: `l:${parentMac}:${key}`, depth: depth, rails: prefix, last: last, medium: g.medium, band: g.band, count: g.devs.length });
        const childPrefix = prefix.concat([!last]);
        const sorted = sortByType(g.devs);
        let prevType = null;
        sorted.forEach((d, i) => {
            // Cabecalho so para um tipo com 2+ aparelhos no grupo; sozinho, o icone basta
            const count = sorted.filter(x => (x.type || "") === (d.type || "")).length;
            if (count > 1 && (d.type || "") !== prevType)
                rows.push({ kind: "type", key: `t:${parentMac}:${key}:${d.type}`, depth: depth + 1, rails: childPrefix, last: false, type: d.type || "", count: count });
            prevType = d.type || "";
            emitDevice(d, depth + 1, childPrefix, i === sorted.length - 1);
        });
    }

    rows.push({ kind: "wan", key: "wan", depth: 0, rails: [], last: true, dev: wan });
    if (root) {
        // Os orfaos (sem enlace conhecido) ficam no fim, como um grupo do roteador
        const rootGroups = groupsOf(kids[rootMac] ?? []);
        const orphanGroup = groupsOf(orphans);
        const all = rootGroups.concat(orphanGroup);
        done[rootMac] = true;
        rows.push({ kind: "device", key: `d:${rootMac}`, depth: 1, rails: [], last: true, dev: root, kids: all.length, nat: false, unmanaged: false });
        all.forEach((g, i) => emitGroup(g, rootMac, 2, [false], i === all.length - 1));
    } else {
        const g = groupsOf(orphans);
        g.forEach((x, i) => emitGroup(x, "", 1, [], i === g.length - 1));
    }
    return rows;
}

// ---------------------------------------------------------------- grupos
// Um aparelho com varios MACs (celular com MAC aleatorio por rede): o backend
// ja manda uma linha por grupo, com `macs` [{mac, ip, online, last_seen,
// hostname, ssid, band, kind}] e `active_mac`; `mac` e o principal.

function lc(s) {
    return (s ?? "").toLowerCase();
}

// Enderecos do aparelho no formato de `macs` (um so quando nao e grupo)
function addrsOf(d) {
    if (!d)
        return [];
    if ((d.macs ?? []).length > 0)
        return d.macs;
    const c = d.conn ?? {};
    return [{ mac: d.mac, ip: d.ip ?? "", online: !!d.online, last_seen: d.last_seen ?? "", hostname: d.hostname ?? null, ssid: c.ssid ?? null, band: c.band ?? null, kind: c.kind ?? null }];
}

// So os grupos (2+ enderecos); [] para um aparelho comum
function groupAddrs(d) {
    const m = d?.macs ?? [];
    return m.length > 1 ? m : [];
}

function isPrimary(d, mac) {
    return lc(d?.mac) === lc(mac);
}

function isActive(d, mac) {
    return lc(d?.active_mac || d?.mac) === lc(mac);
}

// Rede de um endereco: "SSID · 5G", "Wi-Fi 5G", "Cable"; "" = nunca visto no Wi-Fi
function addrNetwork(a, labels) {
    const L = labels ?? DEFAULT_LABELS;
    if (!a)
        return "";
    if (a.ssid)
        return a.band ? `${a.ssid} · ${a.band}` : a.ssid;
    if (a.kind === "wifi")
        return a.band ? `${L.wifi} ${a.band}` : L.wifi;
    if (a.kind === "ethernet")
        return L.cable;
    return "";
}

function hostnamesOf(d) {
    const out = [];
    for (const h of [d?.hostname, ...addrsOf(d).map(a => a.hostname)])
        if (h && !isPlaceholder(h) && out.indexOf(h.toLowerCase()) < 0)
            out.push(h.toLowerCase());
    return out;
}

// Sugestao do backend (aparelho novo com o hostname de um conhecido): so
// enquanto e novo; o nome vem da lista atual. -> { mac, name } | null
function suggestionFor(d, byMac) {
    const s = d?.suggest;
    if (!d?.new || !s?.mac || isPrimary(d, s.mac))
        return null;
    const target = byMac?.[lc(s.mac)];
    return { mac: target ? target.mac : s.mac, name: target ? bestName(target) : (isPlaceholder(s.name) ? s.mac : s.name) };
}

// Com quem `d` pode ser agrupado: os outros aparelhos editaveis (sem a
// Internet e o switch sem IP). Mesmo hostname primeiro, depois os novos, depois
// por nome. -> [{ dev, sameHost }]
function groupCandidates(devices, d) {
    if (!d)
        return [];
    const mine = hostnamesOf(d);
    const me = lc(d.mac);
    return (devices ?? []).filter(x => x && !isWan(x) && isEditable(x) && !isPassive(x) && lc(x.mac) !== me).map(x => ({
                dev: x,
                sameHost: hostnamesOf(x).some(h => mine.indexOf(h) >= 0)
            })).sort((a, b) => {
        if (a.sameHost !== b.sameHost)
            return a.sameHost ? -1 : 1;
        if (!!a.dev.new !== !!b.dev.new)
            return a.dev.new ? -1 : 1;
        return bestName(a.dev).localeCompare(bestName(b.dev));
    });
}

// Op de agrupar `d` com `other`: o conhecido fica de principal (um novo entra
// no grupo de um conhecido, nao o contrario); os enderecos todos do outro vao
// juntos (um principal de outro grupo leva o grupo inteiro).
function groupOp(d, other) {
    const flip = !!d?.new && !other?.new;
    const primary = flip ? other : d;
    const extra = flip ? d : other;
    return { verb: "group", mac: lc(primary?.mac), value: addrsOf(extra).map(a => lc(a.mac)).filter(m => m && m !== lc(primary?.mac)) };
}

function opMacs(op) {
    const v = op?.value;
    return Array.isArray(v) ? v.map(lc) : [];
}

// Uma op sobre a lista (sem mexer nos objetos de entrada)
function applyOp(list, op) {
    const mac = lc(op.mac);
    switch (op.verb) {
    case "name":
    case "type":
    case "known":
        return list.map(d => {
            if (lc(d.mac) !== mac)
                return d;
            const out = Object.assign({}, d);
            if (op.verb === "name")
                out.name = op.value;
            else if (op.verb === "type")
                out.type = op.value;
            else
                out.new = false;
            return out;
        });
    case "group": {
        const ms = opMacs(op).filter(m => m !== mac);
        if (!list.some(d => lc(d.mac) === mac))
            return list;
        const moved = [];
        const rest = [];
        for (const d of list) {
            if (lc(d.mac) === mac) {
                rest.push(d);
                continue;
            }
            if (ms.indexOf(lc(d.mac)) >= 0) {
                // a linha propria some; os enderecos dela vao para o principal
                moved.push(...addrsOf(d));
                continue;
            }
            const keep = (d.macs ?? []).filter(a => ms.indexOf(lc(a.mac)) < 0);
            if (keep.length !== (d.macs ?? []).length) {
                moved.push(...(d.macs ?? []).filter(a => ms.indexOf(lc(a.mac)) >= 0));
                const out = Object.assign({}, d);
                if (keep.length > 1)
                    out.macs = keep;
                else
                    delete out.macs;
                rest.push(out);
                continue;
            }
            rest.push(d);
        }
        return rest.map(d => {
            if (lc(d.mac) !== mac)
                return d;
            const out = Object.assign({}, d);
            const all = addrsOf(d).slice();
            for (const a of moved)
                if (!all.some(x => lc(x.mac) === lc(a.mac)))
                    all.push(a);
            out.macs = all;
            if (!out.active_mac)
                out.active_mac = d.mac;
            out.new = false;
            return out;
        });
    }
    case "ungroup":
        return list.map(d => {
            const m = d.macs ?? [];
            if (!m.some(a => lc(a.mac) === mac))
                return d;
            const out = Object.assign({}, d);
            const keep = m.filter(a => lc(a.mac) !== mac);
            if (keep.length > 1)
                out.macs = keep;
            else
                delete out.macs;
            return out;
        });
    case "delete":
        return applyOp(list, { verb: "ungroup", mac: mac }).filter(d => lc(d.mac) !== mac);
    default:
        return list;
    }
}

// Fila otimista: ops [{ verb: name|type|known|group|ungroup|delete, mac, value }]
// aplicadas em ordem sobre a lista. group: mac = principal, value = [MACs].
function applyPending(devices, ops) {
    if (!ops || ops.length === 0)
        return devices ?? [];
    let list = devices ?? [];
    for (const op of ops)
        list = applyOp(list, op);
    return list;
}

// name/type trocam o valor da mesma op; group/ungroup/delete sao uma op por alvo
function opKey(op) {
    const base = `${op.verb}~${lc(op.mac)}`;
    return op.verb === "group" ? `${base}~${opMacs(op).join(",")}` : base;
}

// Junta uma op na fila: a mesma (verbo+MAC) ainda nao iniciada e trocada; a
// que esta rodando (indice 0) fica.
function enqueueOp(queue, op) {
    const q = (queue ?? []).slice();
    const k = opKey(op);
    for (let i = 1; i < q.length; i++) {
        if (opKey(q[i]) === k) {
            q[i] = op;
            return q;
        }
    }
    if (q.length > 0 && opKey(q[0]) === k && JSON.stringify(q[0].value ?? null) === JSON.stringify(op.value ?? null))
        return q;
    q.push(op);
    return q;
}

function opArgs(op) {
    const mac = (op.mac ?? "").toUpperCase();
    switch (op.verb) {
    case "known":
    case "ungroup":
    case "delete":
        return ["network", op.verb, mac, "--json"];
    case "group":
        return ["network", "group", mac, ...opMacs(op).map(m => m.toUpperCase()), "--json"];
    default:
        return ["network", op.verb, mac, op.value, "--json"];
    }
}

function busyFor(queue, mac) {
    const m = lc(mac);
    return (queue ?? []).some(op => lc(op.mac) === m || lc(op.owner) === m || opMacs(op).indexOf(m) >= 0);
}

// Algum endereco do aparelho na fila
function busyForDev(queue, d) {
    return addrsOf(d).some(a => busyFor(queue, a.mac));
}

function isEditable(d) {
    return !!d && /^[0-9a-f]{2}(:[0-9a-f]{2}){5}$/i.test(d.mac ?? "");
}
