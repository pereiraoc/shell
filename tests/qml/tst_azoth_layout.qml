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
        // coluna da direita, de cima para baixo: INS, DEL, PGUP, PGDN em x = 15, uma por fila
        const col = ["INS", "DEL", "PGUP", "PGDN"].map(l => ks.find(k => k.label === l));
        verify(col.every(k => k.x === 15));
        verify(col[0].y < col[1].y && col[1].y < col[2].y && col[2].y < col[3].y);
        // setas em T invertido: ↑ sobre ↓ em x = 14; → fecha a coluna em x = 15
        compare(ks.find(k => k.label === "↑").x, 14);
        compare(ks.find(k => k.label === "↓").x, 14);
        compare(ks.find(k => k.id === "right").x, 15);
        // OLED largo e knob no canto superior direito, depois do F12, ate a borda
        const oled = ks.find(k => k.kind === "oled");
        const knob = ks.find(k => k.kind === "knob");
        const f12 = ks.find(k => k.label === "F12");
        verify(oled.x > f12.x + f12.w && oled.y === 0 && oled.w >= 1.5);
        fuzzyCompare(knob.x + knob.w, 16, 1e-9);
    }

    function test_fnFunctions() {
        const ks = A.keys();
        const ids = ks.filter(k => k.id).map(k => k.id);
        compare(ids.length, A.SPECIAL.length);
        verify(ids.every(id => A.SPECIAL.includes(id)));
        verify(ks.filter(k => k.id).every(k => k.fn !== "" && k.icon !== ""));
        // segunda funcao impressa, conferida no teclado
        const legends = ks.filter(k => k.legend).map(k => `${k.label || "win"}=${k.legend}`).sort().join(" ");
        compare(legends, "1=I 2=II 3=III 4=IV 5=V 6=DEFAULT ALT=MACRO DEL=SCRLK ESC=RESET INS=PAUSE PGDN=END PGUP=HOME win=LOCK ←=MODE< →=MODE>");
        // so o OLED e o knob sao clicaveis sem legenda impressa
        compare(ks.filter(k => k.id && !k.legend).map(k => k.kind).sort().join(","), "knob,oled");
        compare(A.comboLabel("lalt"), "Fn + ALT · MACRO");
        compare(A.comboLabel("win"), "Fn + Win · LOCK");
        compare(A.comboLabel("oled"), "OLED");
        compare(A.comboLabel("knob"), "Knob");
        compare(A.comboLabel("nope"), "");
        compare(ks.find(k => k.id === "k6").fn, "Default profile");
    }
}
