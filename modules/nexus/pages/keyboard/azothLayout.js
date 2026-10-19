.pragma library

// Teclado ROG Azoth (75 %, ANSI US, 81 teclas), em unidades de tecla, para o
// diagrama de Nexus > Keyboard > Azoth. Silhueta: 16u de largura; fila Fn com
// Esc, F1..F12 em grupos de quatro e, no canto superior direito, o OLED largo
// e o knob de tres posicoes; coluna da direita (de cima para baixo) Ins, Del,
// PgUp, PgDn; seta para cima sob a Shift direita e as outras tres na fila de
// baixo, com a seta direita fechando a coluna. As teclas com segunda funcao
// impressa (camada Fn: RESET, I..V, DEFAULT, LOCK, MACRO, PAUSE, SCRLK, HOME,
// END, MODE< e MODE>, conferidas no teclado) tem `id`, `legend` (o impresso)
// e `fn` (o que faz); o OLED e o knob sao elementos clicaveis proprios. Sem Qt:
// testavel com qmltestrunner.

var FN = {
    // legend = o que esta impresso na tecla como segunda funcao (camada Fn),
    // fn = o que faz; icon so para o cartao da tecla
    esc: { legend: "RESET", fn: "Factory reset: hold Fn + Esc until the LEDs blink green", icon: "restart_alt" },
    k1: { legend: "I", fn: "Profile 1", icon: "looks_one" }, k2: { legend: "II", fn: "Profile 2", icon: "looks_two" }, k3: { legend: "III", fn: "Profile 3", icon: "looks_3" },
    k4: { legend: "IV", fn: "Profile 4", icon: "looks_4" }, k5: { legend: "V", fn: "Profile 5", icon: "looks_5" }, k6: { legend: "DEFAULT", fn: "Default profile", icon: "looks_6" },
    win: { legend: "LOCK", fn: "Locks the Windows key (game mode); press again to unlock", icon: "lock" },
    lalt: { legend: "MACRO", fn: "Records a macro on the fly: press again to stop, then the key to put it on", icon: "fiber_manual_record" },
    ins: { legend: "PAUSE", fn: "Pause", icon: "pause" },
    del: { legend: "SCRLK", fn: "Scroll Lock", icon: "lock" },
    pgup: { legend: "HOME", fn: "Home", icon: "first_page" },
    pgdn: { legend: "END", fn: "End", icon: "last_page" },
    left: { legend: "MODE<", fn: "Previous lighting mode", icon: "skip_previous" },
    right: { legend: "MODE>", fn: "Next lighting mode", icon: "skip_next" },
    oled: { legend: "", fn: "OLED display: status, battery, profile, PC/Mac mode and the animation", icon: "screenshot_monitor" },
    knob: { legend: "", fn: "Knob: volume (turn), mute (press); the side button cycles the knob modes", icon: "radio_button_checked" }
};

var ROWS = [
    { y: 0, h: 1, keys: [
        { id: "esc", label: "ESC", w: 1 }, { gap: 0.1 },
        { label: "F1", w: 1 }, { label: "F2", w: 1 }, { label: "F3", w: 1 }, { label: "F4", w: 1 }, { gap: 0.1 },
        { label: "F5", w: 1 }, { label: "F6", w: 1 }, { label: "F7", w: 1 }, { label: "F8", w: 1 }, { gap: 0.1 },
        { label: "F9", w: 1 }, { label: "F10", w: 1 }, { label: "F11", w: 1 }, { label: "F12", w: 1 }, { gap: 0.2 },
        { id: "oled", label: "OLED", w: 1.7, kind: "oled" }, { gap: 0.1 }, { id: "knob", label: "", w: 0.7, kind: "knob" }
    ] },
    { y: 1.1, h: 1, keys: [
        { label: "`", top: "~", w: 1 }, { id: "k1", label: "1", top: "!", w: 1 }, { id: "k2", label: "2", top: "@", w: 1 }, { id: "k3", label: "3", top: "#", w: 1 },
        { id: "k4", label: "4", top: "$", w: 1 }, { id: "k5", label: "5", top: "%", w: 1 }, { id: "k6", label: "6", top: "^", w: 1 }, { label: "7", top: "&", w: 1 },
        { label: "8", top: "*", w: 1 }, { label: "9", top: "(", w: 1 }, { label: "0", top: ")", w: 1 }, { label: "-", top: "_", w: 1 },
        { label: "=", top: "+", w: 1 }, { label: "", glyph: "⟵", w: 2 }, { id: "ins", label: "INS", w: 1 }
    ] },
    { y: 2.1, h: 1, keys: [
        { label: "TAB", glyph: "⇤⇥", w: 1.5 }, { label: "Q", w: 1 }, { label: "W", w: 1 }, { label: "E", w: 1 }, { label: "R", w: 1 }, { label: "T", w: 1 },
        { label: "Y", w: 1 }, { label: "U", w: 1 }, { label: "I", w: 1 }, { label: "O", w: 1 }, { label: "P", w: 1 }, { label: "[", top: "{", w: 1 },
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
        { label: "SHIFT", glyph: "⇧", w: 1.75 }, { label: "↑", w: 1 }, { id: "pgdn", label: "PGDN", w: 1 }
    ] },
    { y: 5.1, h: 1, keys: [
        { label: "CTRL", w: 1.25 }, { id: "win", label: "", micon: "window", w: 1.25 }, { id: "lalt", label: "ALT", w: 1.25 }, { label: "", bar: true, w: 6.25 },
        { label: "ALT", w: 1 }, { label: "FN", w: 1 }, { label: "CTRL", w: 1 }, { id: "left", label: "←", w: 1 }, { label: "↓", w: 1 }, { id: "right", label: "→", w: 1 }
    ] }
];

var SPECIAL = Object.keys(FN);

function entry(k, label, x, y, w, h) {
    const id = k.id || "";
    const fn = id ? FN[id] : null;
    return { id: id, label: label, icon: fn ? fn.icon : "", legend: fn ? fn.legend : "", fn: fn ? fn.fn : "", kind: k.kind || "", top: k.top || "", glyph: k.glyph || "", micon: k.micon || "", bar: !!k.bar, corner: "tr", x: x, y: y, w: w, h: h };
}

// Teclas achatadas, com posicao absoluta em u:
// [{ id, label, icon, legend, fn, kind, top, glyph, micon, bar, corner, x, y, w, h }]
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

// "Fn + 1 · I" / "Fn + Win · LOCK" / "OLED" / "Knob"
function comboLabel(id) {
    const k = keys().find(x => x.id === id);
    if (!k)
        return "";
    if (k.kind === "oled")
        return "OLED";
    if (k.kind === "knob")
        return "Knob";
    return "Fn + " + (k.label || (k.micon === "window" ? "Win" : id)) + (k.legend ? " · " + k.legend : "");
}
