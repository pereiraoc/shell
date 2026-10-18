.pragma library

// Transforma `hyprctl binds -j` no que a pagina Keyboard > Shortcuts desenha:
// categorias (1o campo do desc que o binds.lua poe) -> linhas (uma por
// descricao) -> combos (uma por combinacao de teclas, cada tecla um token para
// virar keycap). O 3o campo do desc traz tags: @main (entra em Essentials) e
// @icon:NOME (Material Symbol). Sem Qt: testavel com qmltestrunner
// (tests/qml/tst_shortcuts.qml).

var SEP = " · ";
var OTHER = "Other";

// modmask do Hyprland, na ordem em que aparecem no rotulo
var MODS = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];

var KEYS = {
    Return: "Enter", space: "Space", Tab: "Tab", Print: "PrtSc", Escape: "Esc",
    left: "←", right: "→", up: "↑", down: "↓",
    equal: "=", minus: "-", slash: "/",
    XF86MonBrightnessUp: "Fn + F8", XF86MonBrightnessDown: "Fn + F7"
};

function keyLabel(key, release) {
    if (key === "SUPER_L")
        return release ? "Super (tap)" : "Super";
    if (KEYS[key] !== undefined)
        return KEYS[key];
    if (key.indexOf("XF86") === 0)
        return key.slice(4);
    return key.length === 1 ? key.toUpperCase() : key;
}

// Teclas da combinacao, uma por keycap; `tap` = toque na tecla Super
function comboTokens(bind) {
    if (bind.key === "SUPER_L")
        return { tokens: ["Super"], tap: !!bind.release };
    const tokens = [];
    for (const [mask, name] of MODS)
        if (bind.modmask & mask)
            tokens.push(name);
    for (const part of keyLabel(bind.key, !!bind.release).split(" + "))
        tokens.push(part);
    return { tokens: tokens, tap: false };
}

function comboLabel(bind) {
    const c = comboTokens(bind);
    return c.tokens.join(" + ") + (c.tap ? " (tap)" : "");
}

// Tipo do keycap: modificadores tem cor propria na pagina
function modKind(token) {
    switch (token) {
    case "Super":
        return "super";
    case "Ctrl":
        return "ctrl";
    case "Shift":
        return "shift";
    case "Alt":
        return "alt";
    case "Fn":
        return "fn";
    default:
        return "key";
    }
}

// Teclas que formam familia e podem dividir um keycap: digitos, F1-F12, setas
var MERGEABLE = /^(\d|F\d{1,2}|[←→↑↓])$/;

// Combos da mesma linha que so diferem na ultima tecla, quando ela e de uma
// familia (Super + 1/2/3, Super + ←/→), viram uma so. Alternativas soltas
// (Enter / T), o toque no Super e combos de uma tecla ficam como estao.
function mergeCombos(combos) {
    const out = [];
    const byPrefix = {};
    for (const c of combos) {
        if (c.tap || c.tokens.length < 2 || !MERGEABLE.test(c.tokens[c.tokens.length - 1])) {
            out.push(c);
            continue;
        }
        const prefix = c.tokens.slice(0, -1);
        const key = prefix.join("\u0000");
        const last = c.tokens[c.tokens.length - 1];
        let m = byPrefix[key];
        if (!m) {
            m = { tokens: prefix.concat([last]), lasts: [last], tap: false, label: "" };
            byPrefix[key] = m;
            out.push(m);
        } else if (m.lasts.indexOf(last) < 0) {
            m.lasts.push(last);
            m.tokens = prefix.concat([m.lasts.join("/")]);
        }
    }
    return out.map(c => ({ label: c.tokens.join(" + ") + (c.tap ? " (tap)" : ""), tokens: c.tokens, tap: c.tap }));
}

// Reparte as categorias em `n` colunas, cada uma na coluna mais curta ate
// entao (peso = numero de linhas), mantendo a ordem de aparicao.
function distribute(cats, n) {
    const cols = [];
    const heights = [];
    for (let i = 0; i < n; i++) {
        cols.push([]);
        heights.push(0);
    }
    for (const c of cats) {
        let best = 0;
        for (let i = 1; i < n; i++)
            if (heights[i] < heights[best])
                best = i;
        cols[best].push(c);
        heights[best] += c.rows.length;
    }
    return cols;
}

// Botoes do mouse (code:N), LEDs (Caps/Num Lock) e binds sem descricao ficam fora
function isHuman(bind) {
    return !!bind.description && !!bind.key && bind.key.indexOf("code:") !== 0
        && bind.key !== "Caps_Lock" && bind.key !== "Num_Lock";
}

function split(description) {
    const parts = description.split(SEP);
    if (parts.length === 1)
        return { cat: OTHER, action: parts[0], tags: "" };
    return { cat: parts[0], action: parts[1], tags: parts.slice(2).join(" ") };
}

function parseTags(tags) {
    let main = false;
    let icon = "";
    for (const t of tags.split(/\s+/)) {
        if (t === "@main")
            main = true;
        else if (t.indexOf("@icon:") === 0)
            icon = t.slice(6);
    }
    return { main: main, icon: icon };
}

function group(binds) {
    const cats = [];
    const byName = {};
    for (const b of binds) {
        if (!isHuman(b))
            continue;
        const d = split(b.description);
        const tags = parseTags(d.tags);
        let cat = byName[d.cat];
        if (!cat) {
            cat = { name: d.cat, rows: [], byAction: {} };
            byName[d.cat] = cat;
            cats.push(cat);
        }
        let row = cat.byAction[d.action];
        if (!row) {
            row = { action: d.action, icon: "", main: false, combos: [] };
            cat.byAction[d.action] = row;
            cat.rows.push(row);
        }
        if (!row.icon && tags.icon)
            row.icon = tags.icon;
        row.main = row.main || tags.main;
        const combo = comboTokens(b);
        const label = comboLabel(b);
        if (!row.combos.some(c => c.label === label))
            row.combos.push({ label: label, tokens: combo.tokens, tap: combo.tap });
    }
    for (const c of cats)
        for (const r of c.rows)
            r.combos = mergeCombos(r.combos);
    return cats.map(c => ({ name: c.name, rows: c.rows }));
}

function parse(jsonText) {
    try {
        const arr = JSON.parse(jsonText);
        return Array.isArray(arr) ? group(arr) : [];
    } catch (e) {
        return [];
    }
}
