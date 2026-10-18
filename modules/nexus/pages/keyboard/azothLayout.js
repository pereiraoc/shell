.pragma library

// Teclado ROG Azoth (75 %, ANSI US, 81 teclas), em unidades de tecla, para o
// diagrama de Nexus > Keyboard > Azoth. Silhueta: 16u de largura; fila Fn com
// Esc, F1..F12 em grupos de quatro e, no canto superior direito, o OLED largo
// e o knob de tres posicoes; coluna da direita (de cima para baixo) Ins, Del,
// PgUp, PgDn; seta para cima sob a Shift direita e as outras tres na fila de
// baixo, com a seta direita fechando a coluna. As teclas com funcao na
// camada Fn (manual E25289/QSG) tem `id` e `fn` (o que Fn + tecla faz); o OLED
// e o knob sao elementos clicaveis proprios. Sem Qt: testavel com qmltestrunner.

var FN = {
    esc: { fn: "Factory reset (hold until the LEDs blink green)", icon: "restart_alt" },
    tab: { fn: "PC / Mac mode (swaps Alt and Win)", icon: "swap_horiz" },
    lalt: { fn: "Record a macro on the fly (press again to stop, then the key to assign)", icon: "fiber_manual_record" },
    k1: { fn: "Profile 1", icon: "looks_one" }, k2: { fn: "Profile 2", icon: "looks_two" }, k3: { fn: "Profile 3", icon: "looks_3" },
    k4: { fn: "Profile 4", icon: "looks_4" }, k5: { fn: "Profile 5", icon: "looks_5" }, k6: { fn: "Profile 6 (default)", icon: "looks_6" },
    p: { fn: "Print screen", icon: "screenshot_region" },
    f12: { fn: "Stealth", icon: "visibility_off" },
    ins: { fn: "Pause", icon: "pause" },
    del: { fn: "Scroll Lock", icon: "lock" },
    pgup: { fn: "Home", icon: "first_page" },
    pgdn: { fn: "End", icon: "last_page" },
    rctrl: { fn: "Menu", icon: "menu" },
    up: { fn: "Keyboard brightness up", icon: "backlight_high" },
    down: { fn: "Keyboard brightness down", icon: "backlight_low" },
    left: { fn: "Previous lighting effect", icon: "skip_previous" },
    right: { fn: "Next lighting effect", icon: "skip_next" },
    oled: { fn: "OLED display: status, battery, profile, PC/Mac mode and the animation", icon: "screenshot_monitor" },
    knob: { fn: "Knob: volume (turn), mute (press); the side button cycles the knob modes", icon: "radio_button_checked" }
};

var ROWS = [
    { y: 0, h: 1, keys: [
        { id: "esc", label: "ESC", w: 1 }, { gap: 0.1 },
        { label: "F1", w: 1 }, { label: "F2", w: 1 }, { label: "F3", w: 1 }, { label: "F4", w: 1 }, { gap: 0.1 },
        { label: "F5", w: 1 }, { label: "F6", w: 1 }, { label: "F7", w: 1 }, { label: "F8", w: 1 }, { gap: 0.1 },
        { label: "F9", w: 1 }, { label: "F10", w: 1 }, { label: "F11", w: 1 }, { id: "f12", label: "F12", w: 1 }, { gap: 0.2 },
        { id: "oled", label: "OLED", w: 1.7, kind: "oled" }, { gap: 0.1 }, { id: "knob", label: "", w: 0.7, kind: "knob" }
    ] },
    { y: 1.1, h: 1, keys: [
        { label: "`", top: "~", w: 1 }, { id: "k1", label: "1", top: "!", w: 1 }, { id: "k2", label: "2", top: "@", w: 1 }, { id: "k3", label: "3", top: "#", w: 1 },
        { id: "k4", label: "4", top: "$", w: 1 }, { id: "k5", label: "5", top: "%", w: 1 }, { id: "k6", label: "6", top: "^", w: 1 }, { label: "7", top: "&", w: 1 },
        { label: "8", top: "*", w: 1 }, { label: "9", top: "(", w: 1 }, { label: "0", top: ")", w: 1 }, { label: "-", top: "_", w: 1 },
        { label: "=", top: "+", w: 1 }, { label: "", glyph: "⟵", w: 2 }, { id: "ins", label: "INS", w: 1 }
    ] },
    { y: 2.1, h: 1, keys: [
        { id: "tab", label: "TAB", glyph: "⇤⇥", w: 1.5 }, { label: "Q", w: 1 }, { label: "W", w: 1 }, { label: "E", w: 1 }, { label: "R", w: 1 }, { label: "T", w: 1 },
        { label: "Y", w: 1 }, { label: "U", w: 1 }, { label: "I", w: 1 }, { label: "O", w: 1 }, { id: "p", label: "P", w: 1 }, { label: "[", top: "{", w: 1 },
        { label: "]", top: "}", w: 1 }, { label: "\\", top: "|", w: 1.5 }, { id: "del", label: "DEL", w: 1 }
    ] },
    { y: 3.1, h: 1, keys: [
        { label: "CAPS", w: 1.75 }, { label: "A", w: 1 }, { label: "S", w: 1 }, { label: "D", w: 1 }, { label: "F", w: 1 }, { label: "G", w: 1 },
        { label: "H", w: 1 }, { label: "J", w: 1 }, { label: "K", w: 1 }, { label: "L", w: 1 }, { label: ";", top: ":", w: 1 }, { label: "'", top: "\"", w: 1 },
        { label: "ENTER", glyph: "↵", w: 2.25 }, { id: "pgup", label: "PGUP", w: 1 }
    ] },
    { y: 4.1, h: 1, keys: [
        { label: "SHIFT", glyph: "⇧", w: 2.25 }, { label: "Z", w: 1 }, { label: "X", w: 1 }, { label: "C", w: 1 }, { label: "V", w: 1 }, { label: "B", w: 1 },
        { label: "N", w: 1 }, { label: "M", w: 1 }, { label: ",", top: "<", w: 1 }, { label: ".", top: ">", w: 1 }, { label: "/", top: "?", w: 1 },
        { label: "SHIFT", glyph: "⇧", w: 1.75 }, { id: "up", label: "↑", w: 1 }, { id: "pgdn", label: "PGDN", w: 1 }
    ] },
    { y: 5.1, h: 1, keys: [
        { label: "CTRL", w: 1.25 }, { label: "", micon: "window", w: 1.25 }, { id: "lalt", label: "ALT", w: 1.25 }, { label: "", bar: true, w: 6.25 },
        { label: "ALT", w: 1 }, { label: "FN", w: 1 }, { id: "rctrl", label: "CTRL", w: 1 }, { id: "left", label: "←", w: 1 }, { id: "down", label: "↓", w: 1 }, { id: "right", label: "→", w: 1 }
    ] }
];

var SPECIAL = Object.keys(FN);

function entry(k, label, x, y, w, h) {
    const id = k.id || "";
    const fn = id ? FN[id] : null;
    return { id: id, label: label, icon: fn ? fn.icon : "", fn: fn ? fn.fn : "", kind: k.kind || "", top: k.top || "", glyph: k.glyph || "", micon: k.micon || "", bar: !!k.bar, corner: "tr", x: x, y: y, w: w, h: h };
}

// Teclas achatadas, com posicao absoluta em u:
// [{ id, label, icon, fn, kind, top, glyph, micon, bar, corner, x, y, w, h }]
function keys() {
    const out = [];
    for (const row of ROWS) {
        let x = 0;
        for (const k of row.keys) {
            if (k.gap) {
                x += k.gap;
                continue;
            }
            out.push(entry(k, k.label, x, row.y, k.w, row.h));
            x += k.w;
        }
    }
    return out;
}

function size() {
    let w = 0;
    let h = 0;
    for (const row of ROWS) {
        w = Math.max(w, row.keys.reduce((a, k) => a + (k.gap || k.w), 0));
        h = Math.max(h, row.y + row.h);
    }
    return { w: w, h: h };
}

// "Fn + 1" / "OLED" / "Knob"
function comboLabel(id) {
    const k = keys().find(x => x.id === id);
    if (!k)
        return "";
    if (k.kind === "oled")
        return "OLED";
    if (k.kind === "knob")
        return "Knob";
    return "Fn + " + k.label;
}
