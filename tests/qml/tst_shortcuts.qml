import QtQuick
import QtTest
import "../../modules/nexus/pages/keyboard/shortcuts.js" as S

TestCase {
    name: "Shortcuts"

    readonly property var sample: [
        { modmask: 64, key: "Return", release: false, dispatcher: "exec", arg: "kitty", description: "Aplicações · Terminal (Kitty) · @main @icon:terminal" },
        { modmask: 64, key: "T", release: false, dispatcher: "exec", arg: "kitty", description: "Aplicações · Terminal (Kitty) · @main @icon:terminal" },
        { modmask: 64, key: "SUPER_L", release: true, dispatcher: "exec", arg: "launcher", description: "Aplicações · Launcher · @main @icon:apps" },
        { modmask: 65, key: "T", release: false, dispatcher: "exec", arg: "foot", description: "Aplicações · Terminal (Foot) · @icon:terminal" },
        { modmask: 64, key: "equal", release: false, dispatcher: "exec", arg: "bigger", description: "Janelas · Aumentar janela · @icon:zoom_in" },
        { modmask: 68, key: "left", release: false, dispatcher: "exec", arg: "prev", description: "Janelas · Janela anterior · @main @icon:swap_horiz" },
        { modmask: 0, key: "XF86MonBrightnessUp", release: false, dispatcher: "global", arg: "caelestia:brightnessUp", description: "Brilho · Mais brilho · @icon:brightness_high" },
        { modmask: 0, key: "", release: false, dispatcher: "__lua", arg: "82", description: "" },
        { modmask: 0, key: "code:70", release: false, dispatcher: "__lua", arg: "90", description: "Mouse · lateral" },
        { modmask: 0, key: "Caps_Lock", release: false, dispatcher: "__lua", arg: "36", description: "LED" },
        { modmask: 64, key: "slash", release: false, dispatcher: "exec", arg: "help", description: "Sem separador" }
    ]

    function labels(row) {
        return row.combos.map(c => c.label);
    }

    function test_keyLabels() {
        compare(S.keyLabel("Return", false), "Enter");
        compare(S.keyLabel("space", false), "Space");
        compare(S.keyLabel("Print", false), "PrtSc");
        compare(S.keyLabel("left", false), "←");
        compare(S.keyLabel("equal", false), "=");
        compare(S.keyLabel("minus", false), "-");
        compare(S.keyLabel("slash", false), "/");
        compare(S.keyLabel("XF86MonBrightnessUp", false), "Fn + F8");
        compare(S.keyLabel("XF86MonBrightnessDown", false), "Fn + F7");
        compare(S.keyLabel("XF86AudioMute", false), "AudioMute");
        compare(S.keyLabel("t", false), "T");
        compare(S.keyLabel("F3", false), "F3");
        compare(S.keyLabel("SUPER_L", true), "Super (tap)");
    }

    function test_comboTokens() {
        compare(S.comboTokens({ modmask: 65, key: "T", release: false }), { tokens: ["Super", "Shift", "T"], tap: false });
        compare(S.comboTokens({ modmask: 77, key: "x", release: false }), { tokens: ["Super", "Ctrl", "Alt", "Shift", "X"], tap: false });
        compare(S.comboTokens({ modmask: 64, key: "SUPER_L", release: true }), { tokens: ["Super"], tap: true });
        compare(S.comboTokens({ modmask: 0, key: "XF86MonBrightnessUp", release: false }), { tokens: ["Fn", "F8"], tap: false });
        compare(S.comboTokens({ modmask: 0, key: "Print", release: false }), { tokens: ["PrtSc"], tap: false });
    }

    function test_comboLabel_orderAndTap() {
        compare(S.comboLabel({ modmask: 65, key: "T", release: false }), "Super + Shift + T");
        compare(S.comboLabel({ modmask: 77, key: "x", release: false }), "Super + Ctrl + Alt + Shift + X");
        compare(S.comboLabel({ modmask: 64, key: "SUPER_L", release: true }), "Super (tap)");
        compare(S.comboLabel({ modmask: 0, key: "XF86MonBrightnessUp", release: false }), "Fn + F8");
    }

    function test_parse_groupsAndMerges() {
        const cats = S.parse(JSON.stringify(sample));
        compare(cats.map(c => c.name), ["Aplicações", "Janelas", "Brilho", "Other"]);
        const apps = cats[0];
        compare(apps.rows.map(r => r.action), ["Terminal (Kitty)", "Launcher", "Terminal (Foot)"]);
        compare(labels(apps.rows[0]), ["Super + Enter", "Super + T"]);
        compare(apps.rows[0].combos[0].tokens, ["Super", "Enter"]);
        compare(labels(apps.rows[1]), ["Super (tap)"]);
        compare(apps.rows[1].combos[0], { label: "Super (tap)", tokens: ["Super"], tap: true });
        compare(cats[1].rows.map(r => r.combos[0].label), ["Super + =", "Super + Ctrl + ←"]);
        compare(cats[3].rows[0].action, "Sem separador");
    }

    function test_parse_tags() {
        const cats = S.parse(JSON.stringify(sample));
        const apps = cats[0];
        compare(apps.rows[0].main, true);
        compare(apps.rows[0].icon, "terminal");
        compare(apps.rows[2].main, false);
        compare(apps.rows[2].icon, "terminal");
        compare(cats[2].rows[0].main, false);
        compare(cats[2].rows[0].icon, "brightness_high");
        compare(cats[3].rows[0].main, false);
        compare(cats[3].rows[0].icon, "");
    }

    function test_parse_dropsNonHumanBinds() {
        const cats = S.parse(JSON.stringify(sample));
        // sem flatMap: o motor JS do QML nao tem (ES2019)
        const all = cats.reduce((acc, c) => acc.concat(c.rows.reduce((a, r) => a.concat(labels(r)), [])), []);
        verify(!all.some(x => x.indexOf("code:") >= 0));
        verify(!all.some(x => x.indexOf("Caps") >= 0));
        compare(all.length, 8); // 2 Kitty + Launcher + Foot + Aumentar + anterior + Mais brilho + Sem separador
    }

    function test_mergeCombos_sameModifiers() {
        // Super+1, Super+2, Super+3 -> um keycap "1/2/3"; combos de modificadores diferentes ficam separadas
        const merged = S.mergeCombos([
            { label: "Super + 1", tokens: ["Super", "1"], tap: false },
            { label: "Super + 2", tokens: ["Super", "2"], tap: false },
            { label: "Super + 3", tokens: ["Super", "3"], tap: false },
            { label: "Alt + Tab", tokens: ["Alt", "Tab"], tap: false }
        ]);
        compare(merged.length, 2);
        compare(merged[0].tokens, ["Super", "1/2/3"]);
        compare(merged[0].label, "Super + 1/2/3");
        compare(merged[1].tokens, ["Alt", "Tab"]);
        // o toque no Super nunca e juntado com outra tecla
        const tap = S.mergeCombos([{ label: "Super (tap)", tokens: ["Super"], tap: true }, { label: "Super + T", tokens: ["Super", "T"], tap: false }]);
        compare(tap.length, 2);
        // alternativas soltas (Enter / T) nao formam familia: uma por linha
        const alt = S.mergeCombos([{ label: "Super + Enter", tokens: ["Super", "Enter"], tap: false }, { label: "Super + T", tokens: ["Super", "T"], tap: false }]);
        compare(alt.map(c => c.label), ["Super + Enter", "Super + T"]);
        // F1/F2/F3 e setas sao familia
        compare(S.mergeCombos([{ label: "", tokens: ["Super", "Shift", "F1"], tap: false }, { label: "", tokens: ["Super", "Shift", "F2"], tap: false }])[0].tokens, ["Super", "Shift", "F1/F2"]);
    }

    function test_parse_mergesLoopKeys() {
        const cats = S.parse(JSON.stringify([
            { modmask: 64, key: "1", release: false, description: "Workspaces · Ir ao subgrupo 1, 2 ou 3 · @main @icon:grid_view" },
            { modmask: 64, key: "2", release: false, description: "Workspaces · Ir ao subgrupo 1, 2 ou 3 · @main @icon:grid_view" },
            { modmask: 64, key: "3", release: false, description: "Workspaces · Ir ao subgrupo 1, 2 ou 3 · @main @icon:grid_view" },
            { modmask: 64, key: "left", release: false, description: "Janelas · Mover janela · @icon:open_with" },
            { modmask: 64, key: "right", release: false, description: "Janelas · Mover janela · @icon:open_with" }
        ]));
        compare(cats[0].rows[0].combos.length, 1);
        compare(cats[0].rows[0].combos[0].tokens, ["Super", "1/2/3"]);
        compare(cats[1].rows[0].combos[0].tokens, ["Super", "←/→"]);
    }

    function test_modKind() {
        compare(S.modKind("Super"), "super");
        compare(S.modKind("Ctrl"), "ctrl");
        compare(S.modKind("Shift"), "shift");
        compare(S.modKind("Alt"), "alt");
        compare(S.modKind("Fn"), "fn");
        compare(S.modKind("T"), "key");
        compare(S.modKind("1/2/3"), "key");
    }

    function test_distribute_balancesByRows() {
        const cats = [
            { name: "A", rows: [1, 2, 3, 4] },
            { name: "B", rows: [1, 2, 3, 4, 5, 6, 7] },
            { name: "C", rows: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] },
            { name: "D", rows: [1, 2, 3] },
            { name: "E", rows: [1] }
        ];
        const cols = S.distribute(cats, 3);
        compare(cols.length, 3);
        compare(cols.map(c => c.map(x => x.name)), [["A", "D", "E"], ["B"], ["C"]]);
        compare(S.distribute(cats, 1).map(c => c.map(x => x.name)), [["A", "B", "C", "D", "E"]]);
        compare(S.distribute([], 3), [[], [], []]);
    }

    function test_parse_badInput() {
        compare(S.parse("nao e json"), []);
        compare(S.parse("{}"), []);
        compare(S.parse("[]"), []);
    }
}
