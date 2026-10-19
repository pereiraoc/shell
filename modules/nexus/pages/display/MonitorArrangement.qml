pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Arranjo dos monitores (Display > General): cada tela ligada desenhada na
// posicao e no tamanho logicos do Hyprland, arrastavel. Ao soltar, a posicao
// nova (em px logicos, inteira) e encostada no monitor mais perto -- sem
// sobrepor nem deixar vao -- e sai em `moved(name, x, y)`; a pagina manda
// try-pos e o banner de 15 s pede para manter. Clique escolhe o monitor
// (`picked`). Mesmo papel do nwg-displays, sem sair do Nexus.
Item {
    id: root

    // [{ name, internal, enabled, position: "XxY", logical: "WxH", mode }]
    required property var monitors
    property string selected
    // Rotulos por monitor (nome curto)
    property var labels: ({})
    readonly property var shown: root.monitors.filter(m => m.enabled)
    // Caixa que contem todos (px logicos) e a escala para caber na largura
    readonly property var box: {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        for (const m of root.shown) {
            const r = root.rect(m);
            x0 = Math.min(x0, r.x); y0 = Math.min(y0, r.y);
            x1 = Math.max(x1, r.x + r.w); y1 = Math.max(y1, r.y + r.h);
        }
        return root.shown.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 };
    }
    readonly property real pad: Tokens.padding.large
    readonly property real maxH: 240
    readonly property real k: Math.min((root.width - root.pad * 2) / root.box.w, (root.maxH - root.pad * 2) / Math.max(1, root.box.h))
    // Centrado na largura
    readonly property real ox: (root.width - root.box.w * root.k) / 2 - root.box.x * root.k
    readonly property real oy: root.pad - root.box.y * root.k

    signal picked(name: string)
    signal moved(name: string, x: int, y: int)

    function rect(m: var): var {
        const [x, y] = (m.position ?? "0x0").split("x").map(Number);
        const [w, h] = (m.logical ?? "1x1").split("x").map(Number);
        return { x: x, y: y, w: w || 1, h: h || 1 };
    }

    // Encosta o retangulo movido nos outros: se sobrepoe algum, vai para o
    // lado dele que pede o menor deslocamento; depois, se ficou com vao ate o
    // vizinho mais proximo (ate 1/4 da largura), cola nele.
    function settle(name: string, x: real, y: real): var {
        const me = root.rect(root.shown.find(m => m.name === name));
        const others = root.shown.filter(m => m.name !== name).map(m => root.rect(m));
        let nx = Math.round(x), ny = Math.round(y);
        for (const o of others) {
            const overlap = nx < o.x + o.w && o.x < nx + me.w && ny < o.y + o.h && o.y < ny + me.h;
            if (!overlap)
                continue;
            const cands = [
                { x: o.x - me.w, y: ny, d: Math.abs(o.x - me.w - nx) },
                { x: o.x + o.w, y: ny, d: Math.abs(o.x + o.w - nx) },
                { x: nx, y: o.y - me.h, d: Math.abs(o.y - me.h - ny) },
                { x: nx, y: o.y + o.h, d: Math.abs(o.y + o.h - ny) }
            ].sort((a, b) => a.d - b.d);
            nx = cands[0].x;
            ny = cands[0].y;
        }
        // cola no vizinho mais proximo quando sobrou um vao pequeno
        let best = null;
        for (const o of others) {
            const gaps = [
                { dx: o.x - (nx + me.w), dy: 0 },
                { dx: o.x + o.w - nx, dy: 0 },
                { dx: 0, dy: o.y - (ny + me.h) },
                { dx: 0, dy: o.y + o.h - ny }
            ];
            for (const g of gaps) {
                const d = Math.abs(g.dx) + Math.abs(g.dy);
                if (d > 0 && d < me.w / 4 && (!best || d < best.d))
                    best = { dx: g.dx, dy: g.dy, d: d };
            }
        }
        if (best) {
            nx += best.dx;
            ny += best.dy;
        }
        return { x: nx, y: ny };
    }

    implicitHeight: root.box.h * root.k + root.pad * 2

    Repeater {
        model: root.shown.length

        MonitorOutline {
            id: tile

            required property int index
            readonly property var r: root.rect(root.shown[index] ?? ({}))
            property bool held

            mon: root.shown[index] ?? ({})
            label: root.labels[mon.name] ?? mon.name
            sublabel: (mon.logical ?? "").replace("x", " × ")
            selected: root.selected === mon.name
            dragging: tile.held
            x: root.ox + tile.r.x * root.k
            y: root.oy + tile.r.y * root.k
            width: Math.max(24, tile.r.w * root.k)
            height: Math.max(16, tile.r.h * root.k)
            z: tile.held ? 2 : tile.selected ? 1 : 0

            Behavior on x {
                enabled: !tile.held

                Anim {}
            }

            Behavior on y {
                enabled: !tile.held

                Anim {}
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: tile.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                drag.target: root.shown.length > 1 ? tile : null
                drag.threshold: 4
                onPressed: tile.held = true
                onReleased: {
                    tile.held = false;
                    if (!drag.active) {
                        root.picked(tile.mon.name);
                        return;
                    }
                    const lx = (tile.x - root.ox) / root.k;
                    const ly = (tile.y - root.oy) / root.k;
                    const p = root.settle(tile.mon.name, lx, ly);
                    root.picked(tile.mon.name);
                    if (p.x !== tile.r.x || p.y !== tile.r.y)
                        root.moved(tile.mon.name, p.x, p.y);
                    // volta ao binding ate o status vir com a posicao nova
                    tile.x = Qt.binding(() => root.ox + tile.r.x * root.k);
                    tile.y = Qt.binding(() => root.oy + tile.r.y * root.k);
                }
                onClicked: {}
            }
        }
    }
}
