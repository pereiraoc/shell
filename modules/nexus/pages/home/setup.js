// Contas puras do setup desenhado no Home (SetupDiagram/SetupPiece/PieceList):
// encaixe na grade ao soltar uma peca, passo da grade conforme o espaco, as
// areas clicaveis da silhueta do notebook e a ordem/icone das pecas na lista
// da edicao. Testado em tests/qml/tst_setup_layout.qml.
.pragma library

// Arredonda `v` (cm) ao multiplo de `step` mais perto.
function snap(v, step) {
    return Math.round(v / step) * step;
}

// Onde a peca cai ao soltar: canto na grade; se a base ficou a ate `magnet` cm
// da linha da mesa (`deskCm`), encosta nela (mesmo fora da grade).
function dropPosition(xCm, yCm, hCm, step, deskCm, magnet) {
    const m = magnet === undefined ? 2 : magnet;
    const x = snap(xCm, step);
    let y = snap(yCm, step);
    if (Math.abs(yCm + hCm - deskCm) <= m)
        y = deskCm - hCm;
    return { x: x, y: y };
}

// Passo das linhas da grade: fina de 2,5 cm quando cabe (>= 8 px entre linhas),
// senao 5 cm; a forte e sempre de 10 cm.
function gridSteps(pxPerCm) {
    return { minor: pxPerCm * 2.5 >= 8 ? 2.5 : 5, major: 10 };
}

// Areas clicaveis do G16 aberto (assets/devices/rog-g16-open.svg, 918 x 1243),
// em fracoes da peca. A ordem importa: a ultima que contem o ponto ganha
// (a camera fica por cima da moldura da tela). `tab` vazio na tela = o nome
// do monitor interno, que o diagrama preenche.
function laptopParts() {
    const f = (x, y, w, h) => ({ x: x / 918, y: y / 1243, w: w / 918, h: h / 1243 });
    return [
        Object.assign({ id: "screen", page: "display", tab: "" }, f(21, 33, 882, 551)),
        Object.assign({ id: "camera", page: "camera", tab: "laptop" }, f(349, 0, 220, 62)),
        Object.assign({ id: "speakers", page: "sound", tab: "output" }, f(48, 690, 47, 295)),
        Object.assign({ id: "speakers", page: "sound", tab: "output" }, f(830, 690, 47, 295)),
        Object.assign({ id: "keyboard", page: "keyboard", tab: "laptop" }, f(95, 645, 735, 340)),
        Object.assign({ id: "touchpad", page: "mouse", tab: "touchpad" }, f(285, 997, 341, 225))
    ];
}

// Id da area que contem o ponto (fracoes), ou "" fora de todas.
function partAt(parts, fx, fy) {
    let hit = "";
    for (const p of parts) {
        if (fx >= p.x && fx <= p.x + p.w && fy >= p.y && fy <= p.y + p.h)
            hit = p.id;
    }
    return hit;
}

const KIND_ORDER = ["monitor", "laptop", "nas", "keyboard", "mouse", "headphones", "controller", "shelf", "mousepad"];

// Pecas na ordem da lista da edicao: telas, notebook, NAS, teclado, mouses,
// fones, controles e por fim a mesinha e o mousepad (estavel dentro do tipo).
function orderPieces(pieces) {
    const rank = p => {
        const i = KIND_ORDER.indexOf(p.kind);
        return i < 0 ? KIND_ORDER.length : i;
    };
    return pieces.map((p, i) => ({ p: p, i: i })).sort((a, b) => rank(a.p) - rank(b.p) || a.i - b.i).map(e => e.p);
}

const KIND_ICON = {
    monitor: "monitor",
    laptop: "laptop_mac",
    nas: "dns",
    keyboard: "keyboard",
    mouse: "mouse",
    headphones: "headphones",
    controller: "stadia_controller",
    shelf: "shelf_position",
    mousepad: "rectangle"
};

function kindIcon(kind) {
    return KIND_ICON[kind] ?? "devices_other";
}
