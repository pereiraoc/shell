import QtQuick
import QtTest
import "../../modules/nexus/pages/keyboard/laptopLayout.js" as L

TestCase {
    name: "LaptopLayout"

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    function test_specialKeysPresentOnce() {
        const ids = L.keys().filter(k => k.id).map(k => k.id);
        compare(ids, L.SPECIAL);
        verify(L.keys().filter(k => k.id).every(k => k.icon !== ""));
        compare(L.keys().filter(k => !k.id).every(k => k.icon === ""), true);
    }

    function test_noOverlapsAndInsideSize() {
        const ks = L.keys();
        const s = L.size();
        for (let i = 0; i < ks.length; i++) {
            verify(ks[i].w > 0 && ks[i].h > 0, `tecla ${i} sem tamanho`);
            verify(ks[i].x + ks[i].w <= s.w + 1e-9 && ks[i].y + ks[i].h <= s.h + 1e-9, `tecla ${ks[i].label} fora do teclado`);
            for (let j = i + 1; j < ks.length; j++)
                verify(!overlaps(ks[i], ks[j]), `${ks[i].label} sobrepoe ${ks[j].label}`);
        }
        // 15u de largura (filas de letras e a de baixo), 6.32u de altura
        compare(s.w, 15);
        fuzzyCompare(s.h, 6.32, 1e-9);
    }

    function test_rowsAreOrderedAndArrowsStacked() {
        const ks = L.keys();
        const up = ks.find(k => k.label === "▲ PGUP");
        const down = ks.find(k => k.label === "▼ PGDN");
        compare(up.x, down.x);
        fuzzyCompare(up.y + up.h, down.y, 1e-9);
        compare(up.h, 0.48);
        // T invertido: Home e End sao meias teclas na linha de baixo, ao lado do PgDn
        const home = ks.find(k => k.label === "◀ HOME");
        const end = ks.find(k => k.label === "END ▶");
        fuzzyCompare(home.y, down.y, 1e-9);
        fuzzyCompare(end.y, down.y, 1e-9);
        compare(home.h, 0.48);
        fuzzyCompare(home.x + home.w, down.x, 1e-9);
        // fila Fn comeca depois das hotkeys e antes dos numeros; hotkeys e fila Fn sao baixas
        const f1 = ks.find(k => k.id === "f1");
        const m1 = ks.find(k => k.id === "m1");
        const one = ks.find(k => k.label === "1");
        verify(m1.y < f1.y && f1.y < one.y);
        verify(m1.h < f1.h && f1.h < one.h);
        // respiros do manual: M1 acima da F2 (x = 2u); Esc, respiro, F1 em 1.38u; Delete fecha a fila
        compare(m1.x, 2);
        fuzzyCompare(f1.x, 1.38, 1e-9);
        const del = ks.find(k => k.label === "DELETE");
        const f12 = ks.find(k => k.id === "f12");
        verify(f12.x + f12.w < del.x && del.x + del.w <= 15);
    }

    function test_printedExtras() {
        const ks = L.keys();
        compare(ks.find(k => k.label === "1").top, "!");
        compare(ks.find(k => k.label === "TAB").glyph, "⇤⇥");
        compare(ks.find(k => k.label === "ENTER").glyph, "↵");
        compare(ks.filter(k => k.label === "SHIFT").every(k => k.glyph === "⇧"), true);
        compare(ks.find(k => k.micon === "window").label, "");
        compare(ks.find(k => k.bar).w, 5.2);
        compare(ks.find(k => k.glyph === "⟵").w, 2);
        // teclas comuns sem extras nao trazem lixo
        const q = ks.find(k => k.label === "Q");
        compare([q.top, q.glyph, q.micon, q.bar, q.icon], ["", "", "", false, ""]);
    }

    function test_labels() {
        compare(L.comboLabel("f11"), "Fn + F11");
        compare(L.comboLabel("m4"), "M4");
        compare(L.comboLabel("nope"), "");
        compare(L.isFn("f3"), true);
        compare(L.isFn("m3"), false);
    }
}
