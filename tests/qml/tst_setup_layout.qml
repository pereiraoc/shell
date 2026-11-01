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
        compare(got.map(p => p.key).join(","), "monitor:HDMI-A-1,laptop,nas,keyboard,mouse:naga,headphones:WH,controller:0,shelf,mousepad");
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
