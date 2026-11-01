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
        const got = L.orderPieces([{ key: "mousepad", kind: "mousepad" }, { key: "mouse:naga", kind: "mouse" }, { key: "laptop", kind: "laptop" }, { key: "nas", kind: "nas" }, { key: "monitor:HDMI-A-1", kind: "monitor" }, { key: "shelf", kind: "shelf" }, { key: "keyboard", kind: "keyboard" }, { key: "headphones:WH", kind: "headphones" }, { key: "controller:0", kind: "controller" }]);
        compare(got.map(p => p.key).join(","), "monitor:HDMI-A-1,laptop,nas,shelf,mousepad,keyboard,mouse:naga,headphones:WH,controller:0");
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

    function test_kindIcon() {
        compare(L.kindIcon("monitor"), "monitor");
        compare(L.kindIcon("laptop"), "laptop_mac");
        compare(L.kindIcon("nas"), "dns");
        compare(L.kindIcon("keyboard"), "keyboard");
        compare(L.kindIcon("mouse"), "mouse");
        compare(L.kindIcon("headphones"), "headphones");
        compare(L.kindIcon("controller"), "stadia_controller");
        compare(L.kindIcon("shelf"), "shelf_position");
        compare(L.kindIcon("mousepad"), "rectangle");
        compare(L.kindIcon("whatever"), "devices_other");
    }
}
