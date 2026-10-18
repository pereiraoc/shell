.pragma library

// Transforma `hyprctl binds -j` no que a pagina Keyboard > Shortcuts desenha:
//   categoria (1o campo do desc) -> grupos (titulo curto; "Grupo › variante" na
//   acao) -> itens (uma variante) -> combos (uma por linha; a ultima tecla pode
//   ter alternativas em familia: 1/2/3, F1/F2/F3, setas).
// O 3o campo do desc traz tags: @main (entra em Essentials) e @icon:NOME.
// Sem Qt: testavel com qmltestrunner (tests/qml/tst_shortcuts.qml).

var SEP = " · ";
var GROUP_SEP = " › ";
var OTHER = "Other";

// modmask do Hyprland, na ordem em que aparecem no rotulo
var MODS = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]];

var KEYS = {
    Return: "Enter", space: "Space", Tab: "Tab", Print: "PrtSc", Escape: "Esc",
    left: "←", right: "→", up: "↑", down: "↓",
    equal: "=", minus: "-", slash: "/",
    XF86MonBrightnessUp: "Fn + F8", XF86MonBrightnessDown: "Fn + F7"
};

// Teclas que formam familia e dividem um contorno: digitos, F1-F12, setas
var MERGEABLE = /^(\d|F\d{1,2}|[←→↑↓])$/;

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

function labelOf(prefix, alts, tap) {
    return prefix.join(" + ") + (prefix.length > 0 ? " + " : "") + alts.join("/") + (tap ? " (tap)" : "");
}

// [{ tokens, tap }] -> [{ label, prefix, alts, tap }]. Combos que so diferem na
// ultima tecla, quando ela e de uma familia, juntam as alternativas em `alts`
// (Super + 1/2/3); alternativas soltas (Enter / T), o toque no Super e combos
// de uma tecla ficam como estao. Ordem = primeira aparicao.
function mergeCombos(combos) {
    const out = [];
    const byPrefix = {};
    for (const c of combos) {
        const last = c.tokens[c.tokens.length - 1];
        const prefix = c.tokens.slice(0, -1);
        if (c.tap || c.tokens.length < 2 || !MERGEABLE.test(last)) {
            out.push({ prefix: prefix, alts: [last], tap: !!c.tap });
            continue;
        }
        const key = prefix.join("\u0000");
        let m = byPrefix[key];
        if (!m) {
            m = { prefix: prefix, alts: [last], tap: false };
            byPrefix[key] = m;
            out.push(m);
        } else if (m.alts.indexOf(last) < 0) {
            m.alts.push(last);
        }
    }
    return out.map(c => ({ label: labelOf(c.prefix, c.alts, c.tap), prefix: c.prefix, alts: c.alts, tap: c.tap }));
}

// Botoes do mouse (code:N), LEDs (Caps/Num Lock) e binds sem descricao ficam fora
function isHuman(bind) {
    return !!bind.description && !!bind.key && bind.key.indexOf("code:") !== 0
        && bind.key !== "Caps_Lock" && bind.key !== "Num_Lock";
}

function split(description) {
    const parts = description.split(SEP);
    const d = parts.length === 1
        ? { cat: OTHER, action: parts[0], tags: "" }
        : { cat: parts[0], action: parts[1], tags: parts.slice(2).join(" ") };
    const g = d.action.indexOf(GROUP_SEP);
    d.title = g < 0 ? d.action : d.action.slice(0, g);
    d.variant = g < 0 ? "" : d.action.slice(g + GROUP_SEP.length);
    return d;
}

// "next / previous window (all monitors)" -> texto + nota, para a nota ir
// numa linha menor em vez de quebrar o texto
function splitNote(text) {
    const m = /^(.*\S)\s+\(([^()]*)\)$/.exec(text);
    return m ? { text: m[1], note: m[2] } : { text: text, note: "" };
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
            cat = { name: d.cat, groups: [], byTitle: {} };
            byName[d.cat] = cat;
            cats.push(cat);
        }
        let grp = cat.byTitle[d.title];
        if (!grp) {
            grp = { title: d.title, icon: "", main: false, items: [], byVariant: {} };
            cat.byTitle[d.title] = grp;
            cat.groups.push(grp);
        }
        let item = grp.byVariant[d.variant];
        if (!item) {
            item = { variant: d.variant, icon: "", main: false, raw: [], combos: [] };
            grp.byVariant[d.variant] = item;
            grp.items.push(item);
        }
        if (!item.icon && tags.icon)
            item.icon = tags.icon;
        if (!grp.icon && tags.icon)
            grp.icon = tags.icon;
        item.main = item.main || tags.main;
        grp.main = grp.main || tags.main;
        const c = comboTokens(b);
        const label = comboLabel(b);
        if (!item.raw.some(r => r.label === label))
            item.raw.push({ label: label, tokens: c.tokens, tap: c.tap });
    }
    return cats.map(c => ({
        name: c.name,
        groups: c.groups.map(g => ({
            title: g.title,
            icon: g.icon,
            main: g.main,
            items: g.items.map(i => {
                const v = splitNote(i.variant);
                return { variant: v.text, note: v.note, icon: i.icon, main: i.main, combos: mergeCombos(i.raw) };
            })
        }))
    }));
}

// Reparte as categorias em `n` colunas, cada uma na coluna mais curta ate
// entao (peso = numero de itens), mantendo a ordem de aparicao.
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
        heights[best] += c.groups.reduce((acc, g) => acc + g.items.length, 0);
    }
    return cols;
}

function parse(jsonText) {
    try {
        const arr = JSON.parse(jsonText);
        return Array.isArray(arr) ? group(arr) : [];
    } catch (e) {
        return [];
    }
}
