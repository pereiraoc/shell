import QtQuick
import QtTest
import "../../modules/nexus/pages/keyboard/shortcuts.js" as S

TestCase {
    name: "Shortcuts"

    readonly property var sample: [
        { modmask: 64, key: "Return", release: false, description: "Aplicações · Terminal (Kitty) · @main @icon:terminal" },
        { modmask: 64, key: "T", release: false, description: "Aplicações · Terminal (Kitty) · @main @icon:terminal" },
        { modmask: 64, key: "SUPER_L", release: true, description: "Aplicações · Launcher · @main @icon:apps" },
        { modmask: 65, key: "T", release: false, description: "Aplicações · Terminal (Foot) · @icon:terminal" },
        { modmask: 64, key: "1", release: false, description: "Workspaces · Ir para › subgrupo · @main @icon:grid_view" },
        { modmask: 64, key: "2", release: false, description: "Workspaces · Ir para › subgrupo · @main @icon:grid_view" },
        { modmask: 64, key: "3", release: false, description: "Workspaces · Ir para › subgrupo · @main @icon:grid_view" },
        { modmask: 64, key: "F1", release: false, description: "Workspaces · Ir para › grupo · @main @icon:view_module" },
        { modmask: 64, key: "F2", release: false, description: "Workspaces · Ir para › grupo · @main @icon:view_module" },
        { modmask: 64, key: "equal", release: false, description: "Janelas · Tamanho da janela › aumentar · @icon:zoom_in" },
        { modmask: 68, key: "left", release: false, description: "Janelas · Janela seguinte / anterior › todos · @main @icon:swap_horiz" },
        { modmask: 68, key: "right", release: false, description: "Janelas · Janela seguinte / anterior › todos · @main @icon:swap_horiz" },
        { modmask: 0, key: "XF86MonBrightnessUp", release: false, description: "Brilho · Brilho da tela › mais · @icon:brightness_high" },
        { modmask: 0, key: "", release: false, description: "" },
        { modmask: 0, key: "code:70", release: false, description: "Mouse · lateral" },
        { modmask: 0, key: "Caps_Lock", release: false, description: "LED" },
        { modmask: 64, key: "slash", release: false, description: "Sem separador" }
    ]

    function test_keyLabels() {
        compare(S.keyLabel("Return", false), "Enter");
        compare(S.keyLabel("left", false), "←");
        compare(S.keyLabel("XF86MonBrightnessUp", false), "Fn + F8");
        compare(S.keyLabel("XF86AudioMute", false), "AudioMute");
        compare(S.keyLabel("t", false), "T");
        compare(S.keyLabel("SUPER_L", true), "Super (tap)");
    }

    function test_comboTokens() {
        compare(S.comboTokens({ modmask: 65, key: "T", release: false }), { tokens: ["Super", "Shift", "T"], tap: false });
        compare(S.comboTokens({ modmask: 64, key: "SUPER_L", release: true }), { tokens: ["Super"], tap: true });
        compare(S.comboTokens({ modmask: 0, key: "XF86MonBrightnessUp", release: false }), { tokens: ["Fn", "F8"], tap: false });
    }

    function test_comboLabel() {
        compare(S.comboLabel({ modmask: 65, key: "T", release: false }), "Super + Shift + T");
        compare(S.comboLabel({ modmask: 64, key: "SUPER_L", release: true }), "Super (tap)");
    }

    function test_modKind() {
        compare(S.modKind("Super"), "super");
        compare(S.modKind("Ctrl"), "ctrl");
        compare(S.modKind("Shift"), "shift");
        compare(S.modKind("Alt"), "alt");
        compare(S.modKind("Fn"), "fn");
        compare(S.modKind("T"), "key");
    }

    // combo = { label, prefix: teclas antes da ultima, alts: alternativas da ultima (1+), tap }
    function test_mergeCombos_families() {
        const merged = S.mergeCombos([
            { tokens: ["Super", "1"], tap: false },
            { tokens: ["Super", "2"], tap: false },
            { tokens: ["Super", "3"], tap: false },
            { tokens: ["Alt", "Tab"], tap: false }
        ]);
        compare(merged.length, 2);
        compare(merged[0], { label: "Super + 1/2/3", prefix: ["Super"], alts: ["1", "2", "3"], tap: false });
        compare(merged[1], { label: "Alt + Tab", prefix: ["Alt"], alts: ["Tab"], tap: false });
        // alternativas soltas (Enter / T) nao formam familia: uma por linha
        compare(S.mergeCombos([{ tokens: ["Super", "Enter"], tap: false }, { tokens: ["Super", "T"], tap: false }]).map(c => c.label), ["Super + Enter", "Super + T"]);
        // F-keys e setas sao familia; o toque no Super fica so
        compare(S.mergeCombos([{ tokens: ["Super", "Shift", "F1"], tap: false }, { tokens: ["Super", "Shift", "F2"], tap: false }])[0].alts, ["F1", "F2"]);
        compare(S.mergeCombos([{ tokens: ["Super"], tap: true }]), [{ label: "Super (tap)", prefix: [], alts: ["Super"], tap: true }]);
    }

    function test_parse_groupsVariantsAndFamilies() {
        const cats = S.parse(JSON.stringify(sample));
        compare(cats.map(c => c.name), ["Aplicações", "Workspaces", "Janelas", "Brilho", "Other"]);
        // grupos sem " › ": titulo = acao, uma variante sem nome
        const apps = cats[0];
        compare(apps.groups.map(g => g.title), ["Terminal (Kitty)", "Launcher", "Terminal (Foot)"]);
        compare(apps.groups[0].items.length, 1);
        compare(apps.groups[0].items[0].variant, "");
        compare(apps.groups[0].items[0].combos.map(c => c.label), ["Super + Enter", "Super + T"]);
        compare(apps.groups[0].icon, "terminal");
        compare(apps.groups[0].main, true);
        compare(apps.groups[2].main, false);
        // "Ir para › subgrupo/grupo" vira um grupo com duas variantes, teclas em familia
        const ws = cats[1];
        compare(ws.groups.map(g => g.title), ["Ir para"]);
        compare(ws.groups[0].items.map(i => i.variant), ["subgrupo", "grupo"]);
        compare(ws.groups[0].items[0].combos[0].alts, ["1", "2", "3"]);
        compare(ws.groups[0].items[1].combos[0].alts, ["F1", "F2"]);
        compare(ws.groups[0].icon, "grid_view");
        // setas opostas na mesma variante
        compare(cats[2].groups[1].items[0].combos[0], { label: "Super + Ctrl + ←/→", prefix: ["Super", "Ctrl"], alts: ["←", "→"], tap: false });
        compare(cats[2].groups[0].items[0].main, false);
        compare(cats[4].groups[0].title, "Sem separador");
        compare(cats[4].groups[0].icon, "");
    }

    function test_parse_dropsNonHumanBinds() {
        const cats = S.parse(JSON.stringify(sample));
        const all = cats.reduce((acc, c) => acc.concat(c.groups.reduce((a, g) => a.concat(g.items.reduce((b, i) => b.concat(i.combos.map(x => x.label)), [])), [])), []);
        verify(!all.some(x => x.indexOf("code:") >= 0));
        verify(!all.some(x => x.indexOf("Caps") >= 0));
        compare(all.length, 10); // Enter, T, tap, Foot, 1/2/3, F1/F2, =, ←/→, Fn+F8, Sem separador
    }

    function test_distribute_balancesByItems() {
        const cats = [
            { name: "A", groups: [{ items: [1, 2, 3, 4] }] },
            { name: "B", groups: [{ items: [1, 2, 3] }, { items: [1, 2, 3, 4] }] },
            { name: "C", groups: [{ items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13] }] },
            { name: "D", groups: [{ items: [1, 2, 3] }] },
            { name: "E", groups: [{ items: [1] }] }
        ];
        compare(S.distribute(cats, 3).map(c => c.map(x => x.name)), [["A", "D", "E"], ["B"], ["C"]]);
        compare(S.distribute(cats, 1).map(c => c.map(x => x.name)), [["A", "B", "C", "D", "E"]]);
        compare(S.distribute([], 3), [[], [], []]);
    }

    function test_parse_badInput() {
        compare(S.parse("nao e json"), []);
        compare(S.parse("{}"), []);
        compare(S.parse("[]"), []);
    }
}
