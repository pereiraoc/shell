import QtQuick
import QtTest
import "../../modules/nexus/pages/home/setup.js" as L

TestCase {
    name: "SetupLayout"

    function test_snap() {
        compare(L.snap(3.7, 2.5), 2.5);
        compare(L.snap(3.8, 2.5), 5);
        compare(L.snap(-1.2, 2.5), 0);
        compare(L.snap(10, 2.5), 10);
    }

    function test_dropPosition() {
        // encaixa nos dois eixos
        let p = L.dropPosition(31.1, 12.4, 10, 2.5, 50);
        compare(p.x, 30);
        compare(p.y, 12.5);
        // base a ate 2 cm da linha da mesa: encosta nela (mesmo fora da grade)
        p = L.dropPosition(0, 41.3, 10, 2.5, 50);
        compare(p.y, 40);
        p = L.dropPosition(0, 38.6, 10, 2.5, 50);
        compare(p.y, 40);
        // longe da mesa: so a grade
        p = L.dropPosition(0, 20.1, 10, 2.5, 50);
        compare(p.y, 20);
    }

    function test_gridSteps() {
        // com espaco (>= 8 px entre linhas) a grade fina e de 2,5 cm
        compare(L.gridSteps(4).minor, 2.5);
        compare(L.gridSteps(4).major, 10);
        // apertado: so 5 cm
        compare(L.gridSteps(2.8).minor, 5);
        compare(L.gridSteps(2.8).major, 10);
    }

    function test_laptopParts() {
        const parts = L.laptopParts();
        const ids = parts.map(p => p.id);
        verify(ids.includes("screen") && ids.includes("camera") && ids.includes("keyboard") && ids.includes("touchpad") && ids.includes("speakers"));
        // fracoes validas
        for (const p of parts) {
            verify(p.x >= 0 && p.y >= 0 && p.x + p.w <= 1 && p.y + p.h <= 1, p.id);
            verify(p.page !== "", p.id);
        }
        // pontos de referencia na silhueta do G16 (918 x 1243): meio da tela,
        // camera, tecla G, touchpad, grade esquerda, canto do chassi
        compare(L.partAt(parts, 460 / 918, 300 / 1243), "screen");
        compare(L.partAt(parts, 460 / 918, 20 / 1243), "camera");
        compare(L.partAt(parts, 400 / 918, 830 / 1243), "keyboard");
        compare(L.partAt(parts, 455 / 918, 1100 / 1243), "touchpad");
        compare(L.partAt(parts, 72 / 918, 840 / 1243), "speakers");
        compare(L.partAt(parts, 850 / 918, 840 / 1243), "speakers");
        compare(L.partAt(parts, 10 / 918, 1230 / 1243), "");
    }

    function test_orderPieces() {
        const got = L.orderPieces([{ key: "mousepad", kind: "mousepad" }, { key: "mouse:naga", kind: "mouse" }, { key: "laptop", kind: "laptop" }, { key: "nas", kind: "nas" }, { key: "tablet", kind: "tablet" }, { key: "monitor:HDMI-A-1", kind: "monitor" }, { key: "shelf", kind: "shelf" }, { key: "keyboard", kind: "keyboard" }, { key: "headphones:WH", kind: "headphones" }, { key: "controller:0", kind: "controller" }]);
        compare(got.map(p => p.key).join(","), "monitor:HDMI-A-1,laptop,tablet,nas,shelf,mousepad,keyboard,mouse:naga,headphones:WH,controller:0");
    }

    // O layout salvo do usuario (cm): teclado e mouses dentro do mousepad,
    // estojos dos fones apoiados na mesinha, headphone no suporte solto
    readonly property var desk: [{ key: "mousepad", kind: "mousepad", device: false, x: 24, y: 51.5, w: 90, h: 25 }, { key: "keyboard", kind: "keyboard", device: true, x: 38.5, y: 54, w: 32.6, h: 13.8 }, { key: "mouse:naga", kind: "mouse", device: true, x: 93.5, y: 55, w: 7.5, h: 12 }, { key: "mouse:atheris", kind: "mouse", device: true, x: 105, y: 56, w: 7.1, h: 10 }, { key: "shelf", kind: "shelf", device: false, x: 25, y: 37, w: 59, h: 13 }, { key: "headphones:WF", kind: "headphones", device: true, x: 68.5, y: 33, w: 6.5, h: 4 }, { key: "headphones:FC", kind: "headphones", device: true, x: 77, y: 32, w: 5, h: 5 }, { key: "headphones:WH", kind: "headphones", device: true, x: 1.5, y: 22, w: 21.7, h: 28 }, { key: "laptop", kind: "laptop", device: true, x: 85, y: 1.9, w: 35.5, h: 48 }, { key: "monitor:HDMI-A-1", kind: "monitor", device: true, x: 24, y: 2.5, w: 59, h: 34.6 }, { key: "nas", kind: "nas", device: true, x: -19, y: 32.2, w: 17.8, h: 17.8 }]

    function test_childOf() {
        const pad = desk[0], shelf = desk[4];
        verify(L.childOf(desk[1], pad));
        verify(L.childOf(desk[2], pad));
        verify(L.childOf(desk[3], pad));
        verify(!L.childOf(desk[7], pad));
        verify(L.childOf(desk[5], shelf));
        verify(L.childOf(desk[6], shelf));
        verify(!L.childOf(desk[9], shelf));
        // mesa nao e filha de mesa; sem geometria nao e filho
        verify(!L.childOf(shelf, pad));
        verify(!L.childOf({ key: "x", kind: "mouse", device: true }, pad));
    }

    function test_treePieces() {
        const rows = L.treePieces(desk);
        compare(rows.map(r => `${r.depth}:${r.key}`).join(","), "0:monitor:HDMI-A-1,0:laptop,0:nas,0:shelf,1:headphones:WF,1:headphones:FC,0:mousepad,1:keyboard,1:mouse:naga,1:mouse:atheris,0:headphones:WH");
    }

    function test_splitColumns() {
        const rows = L.treePieces(desk);
        const cols = L.splitColumns(rows, 2);
        compare(cols.length, 2);
        compare(cols[0].map(r => r.key).join(","), "monitor:HDMI-A-1,laptop,nas,shelf,headphones:WF,headphones:FC");
        compare(cols[1].map(r => r.key).join(","), "mousepad,keyboard,mouse:naga,mouse:atheris,headphones:WH");
        // uma coluna = tudo; grupo nunca se parte
        compare(L.splitColumns(rows, 1)[0].length, rows.length);
        const three = L.splitColumns(rows, 3);
        verify(three.every(c => c.length === 0 || c[0].depth === 0));
        compare(three.reduce((n, c) => n + c.length, 0), rows.length);
    }

    function test_autoLayout_mesa_completa() {
        const a = L.autoLayout({ deskY: 50, shelfH: 8.3, laptopRight: true, nas: { w: 17.8, h: 17.8 }, stand: { w: 21.7, h: 28 },
            buds: [{ key: "headphones:WF", w: 6.5, h: 6.1 }, { key: "headphones:FC", w: 6, h: 7 }],
            monitors: [{ key: "monitor:HDMI-A-1", w: 59, h: 34.6 }], tablet: { w: 28.5, h: 19 }, laptop: { w: 35.5, h: 48 },
            mousepad: { w: 90, h: 25 }, keyboard: { w: 32.6, h: 13.8 }, mice: [{ key: "mouse:naga", w: 7.5, h: 12 }, { key: "mouse:atheris", w: 7.1, h: 10 }],
            controllers: [{ key: "controller:0", w: 15.3, h: 10.2 }] });
        // mesinha = LG + tablet + folgas, do topo dela ate a mesa; tablet em pe nela
        compare(a.shelf.w, 59 + 28.5 + 2 + 4);
        fuzzyCompare(a.shelf.y, 41.7, 0.001);
        fuzzyCompare(a.pos["tablet"].y, 41.7 - 19, 0.001);
        fuzzyCompare(a.pos["monitor:HDMI-A-1"].x + 59 + 2, a.pos["tablet"].x, 0.001);
        // ordem: NAS, suporte, estojos lado a lado, mesinha, notebook
        verify(a.pos["nas"].x < a.pos["headphones:WH-1000XM5"].x);
        fuzzyCompare(a.pos["headphones:WF"].x, a.pos["headphones:WH-1000XM5"].x + 21.7 + 1, 0.001);
        fuzzyCompare(a.pos["headphones:FC"].x, a.pos["headphones:WF"].x + 6.5 + 1, 0.001);
        verify(a.pos["headphones:FC"].x < a.shelf.x && a.shelf.x + a.shelf.w < a.pos["laptop"].x);
        // grupo de cima e mousemat centrados no mesmo eixo
        fuzzyCompare(a.pos["nas"].x, -a.width / 2, 0.001);
        fuzzyCompare(a.pos["laptop"].x + 35.5, a.width / 2, 0.001);
        compare(a.pos["mousepad"].x, -45);
        // teclado centrado na metade esquerda; mouses + controle lado a lado centrados na direita
        fuzzyCompare(a.pos["keyboard"].x + 32.6 / 2, -45 + 22.5, 0.001);
        fuzzyCompare(a.pos["keyboard"].y, 52 + (25 - 13.8) / 2, 0.001);
        const rightW = 7.5 + 3 + 7.1 + 3 + 15.3;
        fuzzyCompare(a.pos["mouse:naga"].x, 22.5 - rightW / 2, 0.001);
        fuzzyCompare(a.pos["mouse:atheris"].x, a.pos["mouse:naga"].x + 7.5 + 3, 0.001);
        fuzzyCompare(a.pos["controller:0"].x + 15.3, 22.5 + rightW / 2, 0.001);
        fuzzyCompare(a.pos["mouse:naga"].y, 52 + (25 - 12) / 2, 0.001);
        // estojos e NAS na mesa
        compare(a.pos["headphones:WF"].y, 50 - 6.1);
        compare(a.pos["nas"].y, 50 - 17.8);
    }

    function test_autoLayout_viagem_so_tablet() {
        const a = L.autoLayout({ deskY: 50, shelfH: 8.3, laptopRight: true, nas: null, stand: null, buds: [], monitors: [],
            tablet: { w: 28.5, h: 19 }, laptop: { w: 35.5, h: 48 }, mousepad: { w: 90, h: 25 }, keyboard: null, mice: [], controllers: [] });
        compare(a.shelf, null);
        compare(a.pos["tablet"].y, 50 - 19);
        // tablet + notebook centrados sobre o mousemat
        fuzzyCompare(a.pos["tablet"].x, -(28.5 + 4 + 35.5) / 2, 0.001);
        fuzzyCompare(a.pos["laptop"].x + 35.5, (28.5 + 4 + 35.5) / 2, 0.001);
        compare(a.pos["mousepad"].x, -45);
    }

    function test_autoLayout_notebook_a_esquerda() {
        const a = L.autoLayout({ deskY: 50, shelfH: 8.3, laptopRight: false, nas: { w: 17.8, h: 17.8 }, stand: null, buds: [],
            monitors: [{ key: "monitor:HDMI-A-1", w: 59, h: 34.6 }], tablet: null, laptop: { w: 35.5, h: 48 }, mousepad: { w: 90, h: 25 },
            keyboard: null, mice: [], controllers: [] });
        verify(a.pos["laptop"].x < a.shelf.x && a.shelf.x < a.pos["nas"].x);
        fuzzyCompare(a.pos["laptop"].x, -a.width / 2, 0.001);
    }

    function test_groupPieces() {
        const rows = L.groupPieces([{ key: "mousepad", kind: "mousepad" }, { key: "mouse:naga", kind: "mouse" }, { key: "laptop", kind: "laptop" },
            { key: "nas", kind: "nas" }, { key: "tablet", kind: "tablet" }, { key: "monitor:HDMI-A-1", kind: "monitor" }, { key: "shelf", kind: "shelf" },
            { key: "keyboard", kind: "keyboard" }, { key: "headphones:WH-1000XM5", kind: "headphones" }, { key: "headphones:WF", kind: "buds" },
            { key: "router:aa", kind: "router" }, { key: "controller:0", kind: "controller" }]);
        compare(rows.map(r => `${r.depth}:${r.header ? "group:" + r.group : r.key}`).join(","),
            "0:group:laptop,1:laptop,0:group:keyboard-mouse,1:mousepad,1:keyboard,1:mouse:naga,0:group:monitors,1:monitor:HDMI-A-1,1:tablet,1:shelf,0:group:headphones,1:headphones:WH-1000XM5,0:group:buds,1:headphones:WF,0:group:controllers,1:controller:0,0:group:storage,1:nas,0:group:routers,1:router:aa");
        // grupo sem peca nao aparece
        compare(L.groupPieces([{ key: "laptop", kind: "laptop" }]).length, 2);
    }

    function test_autoLayout_roteadores_ao_lado_do_nas() {
        const a = L.autoLayout({ deskY: 50, shelfH: 8.3, laptopRight: true, nas: { w: 17.8, h: 17.8 }, routers: [{ key: "router:a", w: 20, h: 14 }, { key: "router:b", w: 20, h: 14 }],
            stand: null, buds: [], monitors: [], tablet: null, laptop: { w: 35.5, h: 48 }, mousepad: { w: 90, h: 25 }, keyboard: null, mice: [], controllers: [] });
        fuzzyCompare(a.pos["router:a"].x, a.pos["nas"].x + 17.8 + 4, 0.001);
        fuzzyCompare(a.pos["router:b"].x, a.pos["router:a"].x + 22, 0.001);
        compare(a.pos["router:a"].y, 50 - 14);
        verify(a.pos["router:b"].x + 20 < a.pos["laptop"].x);
    }

    function test_kindIcon() {
        compare(L.kindIcon("monitor"), "monitor");
        compare(L.kindIcon("laptop"), "laptop_mac");
        compare(L.kindIcon("nas"), "dns");
        compare(L.kindIcon("tablet"), "tablet_android");
        compare(L.kindIcon("router"), "router");
        compare(L.kindIcon("buds"), "earbuds");
        compare(L.kindIcon("keyboard"), "keyboard");
        compare(L.kindIcon("mouse"), "mouse");
        compare(L.kindIcon("headphones"), "headphones");
        compare(L.kindIcon("controller"), "stadia_controller");
        compare(L.kindIcon("shelf"), "shelf_position");
        compare(L.kindIcon("mousepad"), "rectangle");
        compare(L.kindIcon("whatever"), "devices_other");
    }
}
