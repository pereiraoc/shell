// Contas puras do setup desenhado no Home (SetupDiagram/SetupPiece/PieceList):
// encaixe na grade ao soltar uma peca, passo da grade conforme o espaco, as
// areas clicaveis da silhueta do notebook e a arvore/colunas/icone das pecas
// na lista da edicao. Testado em tests/qml/tst_setup_layout.qml.
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

const KIND_ORDER = ["monitor", "laptop", "nas", "shelf", "mousepad", "keyboard", "mouse", "headphones", "controller"];

function rank(p) {
    const i = KIND_ORDER.indexOf(p.kind);
    return i < 0 ? KIND_ORDER.length : i;
}

// Pecas na ordem do tipo (estavel dentro do tipo): telas, notebook, NAS,
// mesinha, mousepad, teclado, mouses, fones, controles.
function orderPieces(pieces) {
    return pieces.map((p, i) => ({ p: p, i: i })).sort((a, b) => rank(a.p) - rank(b.p) || a.i - b.i).map(e => e.p);
}

const CHILD_KINDS = ["keyboard", "mouse", "headphones", "controller"];

// `a` (periferico: teclado, mouse, fone, controle) esta dentro de `b`
// (mesinha/mousepad, { x, y, w, h } em cm)? Dentro = o centro cai no retangulo
// (teclado e mouse no mousepad); ou apoiado em cima = a base encosta no topo de
// `b` (ate 1,5 cm) com o centro na largura dele (estojos dos fones na
// mesinha). Telas, notebook e NAS nunca viram filhos (o monitor tambem apoia
// na mesinha, mas na lista fica no topo).
function childOf(a, b) {
    if (!CHILD_KINDS.includes(a.kind) || b.device || [a.x, a.y, a.w, a.h, b.x, b.y, b.w, b.h].some(v => typeof v !== "number"))
        return false;
    const cx = a.x + a.w / 2, cy = a.y + a.h / 2;
    const inX = cx >= b.x && cx <= b.x + b.w;
    if (inX && cy >= b.y && cy <= b.y + b.h)
        return true;
    return inX && Math.abs(a.y + a.h - b.y) <= 1.5;
}

// Arvore da lista da edicao, achatada em linhas { ...peca, depth }: topo na
// ordem do tipo; cada mesinha/mousepad traz logo abaixo (depth 1) o que esta
// nela ou em cima dela; o resto segue solto.
function treePieces(pieces) {
    const ordered = orderPieces(pieces);
    const parents = ordered.filter(p => !p.device);
    const taken = new Set();
    const children = new Map();
    for (const q of parents) {
        const kids = ordered.filter(p => !taken.has(p.key) && childOf(p, q));
        for (const k of kids)
            taken.add(k.key);
        children.set(q.key, kids);
    }
    const rows = [];
    for (const p of ordered) {
        if (taken.has(p.key))
            continue;
        rows.push(Object.assign({ depth: 0 }, p));
        for (const k of children.get(p.key) ?? [])
            rows.push(Object.assign({ depth: 1 }, k));
    }
    return rows;
}

// Reparte as linhas em `n` colunas de tamanho parecido sem separar um grupo
// (linha de depth 0 + as de depth 1 logo abaixo).
function splitColumns(rows, n) {
    const groups = [];
    for (const r of rows) {
        if (r.depth === 0 || groups.length === 0)
            groups.push([r]);
        else
            groups[groups.length - 1].push(r);
    }
    const cols = Array.from({ length: Math.max(1, n) }, () => []);
    const target = Math.ceil(rows.length / cols.length);
    let c = 0;
    for (const g of groups) {
        if (c < cols.length - 1 && cols[c].length > 0 && cols[c].length + g.length > target)
            c++;
        cols[c].push(...g);
    }
    return cols;
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
