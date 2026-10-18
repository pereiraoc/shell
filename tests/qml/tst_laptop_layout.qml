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
        // 15.25u de largura (fila de baixo), 7.2u de altura
        compare(s.w, 15);
        compare(s.h, 7.2);
    }

    function test_rowsAreOrderedAndArrowsStacked() {
        const ks = L.keys();
        const up = ks.find(k => k.label === "↑");
        const down = ks.find(k => k.label === "↓");
        compare(up.x, down.x);
        compare(up.y + up.h, down.y);
        compare(up.h, 0.5);
        // fila Fn comeca depois das hotkeys e antes dos numeros
        const f1 = ks.find(k => k.id === "f1");
        const m1 = ks.find(k => k.id === "m1");
        const one = ks.find(k => k.label === "1");
        verify(m1.y < f1.y && f1.y < one.y);
    }

    function test_labels() {
        compare(L.comboLabel("f11"), "Fn + F11");
        compare(L.comboLabel("m4"), "M4");
        compare(L.comboLabel("nope"), "");
        compare(L.isFn("f3"), true);
        compare(L.isFn("m3"), false);
    }
}
