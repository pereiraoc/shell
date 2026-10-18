import QtQuick
import QtTest
import "../../modules/nexus/pages/keyboard/azothLayout.js" as A

TestCase {
    name: "AzothLayout"

    function overlaps(a, b) {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    function test_silhouette() {
        const ks = A.keys();
        const s = A.size();
        // 81 teclas + OLED + knob
        compare(ks.filter(k => k.kind === "").length, 81);
        compare(ks.filter(k => k.kind === "oled").length, 1);
        compare(ks.filter(k => k.kind === "knob").length, 1);
        compare(s.w, 16);
        fuzzyCompare(s.h, 6.1, 1e-9);
        for (let i = 0; i < ks.length; i++) {
            verify(ks[i].x + ks[i].w <= s.w + 1e-9 && ks[i].y + ks[i].h <= s.h + 1e-9, `${ks[i].label} fora`);
            for (let j = i + 1; j < ks.length; j++)
                verify(!overlaps(ks[i], ks[j]), `${ks[i].label} sobrepoe ${ks[j].label}`);
        }
        // coluna da direita: INS, PGUP, PGDN alinhados em x = 15; setas em T invertido (↑ sobre ↓ em x = 14)
        const col = ["INS", "PGUP", "PGDN"].map(l => ks.find(k => k.label === l));
        verify(col.every(k => k.x === 15));
        compare(ks.find(k => k.id === "up").x, 14);
        compare(ks.find(k => k.id === "down").x, 14);
        compare(ks.find(k => k.id === "right").x, 15);
        // OLED e knob no canto superior direito, a direita do DEL
        const oled = ks.find(k => k.kind === "oled");
        const del = ks.find(k => k.id === "del");
        verify(oled.x > del.x + del.w && oled.y === 0);
    }

    function test_fnFunctions() {
        const ks = A.keys();
        const ids = ks.filter(k => k.id).map(k => k.id);
        compare(ids.length, A.SPECIAL.length);
        verify(ids.every(id => A.SPECIAL.includes(id)));
        verify(ks.filter(k => k.id).every(k => k.fn !== "" && k.icon !== ""));
        compare(A.comboLabel("tab"), "Fn + TAB");
        compare(A.comboLabel("oled"), "OLED");
        compare(A.comboLabel("knob"), "Knob");
        compare(A.comboLabel("nope"), "");
        compare(ks.find(k => k.id === "k6").fn, "Profile 6 (default)");
    }
}
