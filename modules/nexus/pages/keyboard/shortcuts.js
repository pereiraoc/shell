.pragma library

// Transforma `hyprctl binds -j` no que a pagina Keyboard > Shortcuts desenha:
// categorias (prefixo "Cat · " do desc que o binds.lua poe) -> linhas (uma
// por descricao) -> chips (uma por combinacao de teclas). Sem Qt: testavel
// com qmltestrunner (tests/qml/tst_shortcuts.qml).

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

function comboLabel(bind) {
    // Toque no Super: o proprio Super e a tecla; nao repetir como modificador
    if (bind.key === "SUPER_L")
        return keyLabel(bind.key, !!bind.release);
    const parts = [];
    for (const [mask, name] of MODS)
        if (bind.modmask & mask)
            parts.push(name);
    parts.push(keyLabel(bind.key, !!bind.release));
    return parts.join(" + ");
}

// Botoes do mouse (code:N), LEDs (Caps/Num Lock) e binds sem descricao ficam fora
function isHuman(bind) {
    return !!bind.description && !!bind.key && bind.key.indexOf("code:") !== 0
        && bind.key !== "Caps_Lock" && bind.key !== "Num_Lock";
}

function split(description) {
    const i = description.indexOf(SEP);
    return i < 0 ? [OTHER, description] : [description.slice(0, i), description.slice(i + SEP.length)];
}

function group(binds) {
    const cats = [];
    const byName = {};
    for (const b of binds) {
        if (!isHuman(b))
            continue;
        const [catName, action] = split(b.description);
        let cat = byName[catName];
        if (!cat) {
            cat = { name: catName, rows: [], byAction: {} };
            byName[catName] = cat;
            cats.push(cat);
        }
        let row = cat.byAction[action];
        if (!row) {
            row = { action: action, combos: [] };
            cat.byAction[action] = row;
            cat.rows.push(row);
        }
        const label = comboLabel(b);
        if (row.combos.indexOf(label) < 0)
            row.combos.push(label);
    }
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
