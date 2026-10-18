.pragma library

// Teclado do ROG Zephyrus G16 GU603 (ANSI US), em unidades de tecla (1u = o
// passo de uma tecla comum), para o diagrama de Nexus > Keyboard > Laptop keys.
// Medido do manual da ASUS (E25289, p. 16): as quatro hotkeys (M1-M4) ficam
// acima das F2-F5, baixinhas; a fila Fn (Esc, F1..F12, Delete) e mais baixa que
// as outras e tem respiros entre os grupos de quatro; as setas sao Home / PgUp
// / PgDn / End (as setas valem com Fn). So as 16 teclas especiais tem `id`
// (m1..m4, f1..f12) e um icone da funcao impressa; as outras so desenham o
// contexto. Sem Qt: testavel com qmltestrunner (tests/qml/tst_laptop_layout.qml).

var ICONS = {
    m1: "volume_down", m2: "volume_up", m3: "mic_off", m4: "settings",
    f1: "volume_off", f2: "backlight_low", f3: "backlight_high", f4: "palette",
    f5: "mode_fan", f6: "screenshot_region", f7: "brightness_low", f8: "brightness_high",
    f9: "screenshot_monitor", f10: "touchpad_mouse", f11: "bedtime", f12: "airplanemode_active"
};

// Linhas: y e h em u; cada entrada e uma tecla { label, w, id? }, um respiro
// { gap } ou duas meias teclas empilhadas { stack: [cima, baixo], w }.
var ROWS = [
    { y: 0, h: 0.5, keys: [
        { gap: 2 },
        { id: "m1", label: "M1", w: 1 }, { id: "m2", label: "M2", w: 1 }, { id: "m3", label: "M3", w: 1 }, { id: "m4", label: "M4", w: 1 }
    ] },
    { y: 0.84, h: 0.62, keys: [
        { label: "Esc", w: 1 }, { gap: 0.38 },
        { id: "f1", label: "F1", w: 1 }, { id: "f2", label: "F2", w: 1 }, { id: "f3", label: "F3", w: 1 }, { id: "f4", label: "F4", w: 1 }, { gap: 0.17 },
        { id: "f5", label: "F5", w: 1 }, { id: "f6", label: "F6", w: 1 }, { id: "f7", label: "F7", w: 1 }, { id: "f8", label: "F8", w: 1 }, { gap: 0.19 },
        { id: "f9", label: "F9", w: 1 }, { id: "f10", label: "F10", w: 1 }, { id: "f11", label: "F11", w: 1 }, { id: "f12", label: "F12", w: 1 }, { gap: 0.05 },
        { label: "Delete", w: 1 }
    ] },
    { y: 1.52, h: 0.96, keys: [
        { label: "`", w: 1 }, { label: "1", w: 1 }, { label: "2", w: 1 }, { label: "3", w: 1 }, { label: "4", w: 1 }, { label: "5", w: 1 },
        { label: "6", w: 1 }, { label: "7", w: 1 }, { label: "8", w: 1 }, { label: "9", w: 1 }, { label: "0", w: 1 }, { label: "-", w: 1 },
        { label: "=", w: 1 }, { label: "⌫", w: 2 }
    ] },
    { y: 2.48, h: 0.96, keys: [
        { label: "Tab", w: 1.5 }, { label: "Q", w: 1 }, { label: "W", w: 1 }, { label: "E", w: 1 }, { label: "R", w: 1 }, { label: "T", w: 1 },
        { label: "Y", w: 1 }, { label: "U", w: 1 }, { label: "I", w: 1 }, { label: "O", w: 1 }, { label: "P", w: 1 }, { label: "[", w: 1 },
        { label: "]", w: 1 }, { label: "\\", w: 1.5 }
    ] },
    { y: 3.44, h: 0.96, keys: [
        { label: "Caps", w: 1.75 }, { label: "A", w: 1 }, { label: "S", w: 1 }, { label: "D", w: 1 }, { label: "F", w: 1 }, { label: "G", w: 1 },
        { label: "H", w: 1 }, { label: "J", w: 1 }, { label: "K", w: 1 }, { label: "L", w: 1 }, { label: ";", w: 1 }, { label: "'", w: 1 },
        { label: "Enter", w: 2.25 }
    ] },
    { y: 4.4, h: 0.96, keys: [
        { label: "Shift", w: 2.25 }, { label: "Z", w: 1 }, { label: "X", w: 1 }, { label: "C", w: 1 }, { label: "V", w: 1 }, { label: "B", w: 1 },
        { label: "N", w: 1 }, { label: "M", w: 1 }, { label: ",", w: 1 }, { label: ".", w: 1 }, { label: "/", w: 1 }, { label: "Shift", w: 2.75 }
    ] },
    { y: 5.36, h: 0.96, keys: [
        { label: "Ctrl", w: 1.25 }, { label: "Fn", w: 1 }, { label: "Win", w: 1 }, { label: "Alt", w: 1 }, { label: "", w: 5.2 },
        { label: "Alt", w: 1 }, { label: "Ctrl", w: 1.25 }, { label: "◀ Home", w: 1.1 }, { stack: ["▲ PgUp", "▼ PgDn"], w: 1.1 }, { label: "End ▶", w: 1.1 }
    ] }
];

var SPECIAL = ["m1", "m2", "m3", "m4", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12"];

// Teclas achatadas, com posicao absoluta em u: [{ id, label, icon, x, y, w, h }]
function keys() {
    const out = [];
    for (const row of ROWS) {
        let x = 0;
        for (const k of row.keys) {
            if (k.gap) {
                x += k.gap;
                continue;
            }
            if (k.stack) {
                const h = row.h / 2;
                out.push({ id: "", label: k.stack[0], icon: "", x: x, y: row.y, w: k.w, h: h });
                out.push({ id: "", label: k.stack[1], icon: "", x: x, y: row.y + h, w: k.w, h: h });
            } else {
                const id = k.id || "";
                out.push({ id: id, label: k.label, icon: id ? ICONS[id] : "", x: x, y: row.y, w: k.w, h: row.h });
            }
            x += k.w;
        }
    }
    return out;
}

// Tamanho total em u
function size() {
    let w = 0;
    let h = 0;
    for (const row of ROWS) {
        w = Math.max(w, row.keys.reduce((a, k) => a + (k.gap || k.w), 0));
        h = Math.max(h, row.y + row.h);
    }
    return { w: w, h: h };
}

function isFn(id) {
    return id.length > 0 && id[0] === "f";
}

// "Fn + F11" / "M4"
function comboLabel(id) {
    const k = keys().find(x => x.id === id);
    if (!k)
        return "";
    return isFn(id) ? "Fn + " + k.label : k.label;
}
