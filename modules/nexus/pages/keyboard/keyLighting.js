.pragma library

// Previa da iluminacao de um teclado: cor e intensidade de cada tecla no
// instante t (0..1 = uma volta) para o rascunho da RgbLightingView
// ({ off, mode, colors, random, brightness, speed, direction }). Mesma familia
// de desenhos do Armoury Crate / asusd, so para dar a ideia -- nao e a
// simulacao do firmware. Sem Qt alem de Qt.hsva/Qt.rgba/Qt.color.

// Pseudo-aleatorio estavel por tecla (0..1)
function noise(i) {
    let h = Math.imul(i + 1, 2654435761) >>> 0;
    h = Math.imul(h ^ (h >>> 15), 2246822519) >>> 0;
    return (h % 10007) / 10007;
}

// Cor na posicao t (ciclica) de uma lista de hex, interpolando entre
// vizinhas; lista vazia = roda de cores.
function colorAt(cols, t) {
    const u = ((t % 1) + 1) % 1;
    if (cols.length === 0)
        return Qt.hsva(u, 0.85, 1, 1);
    if (cols.length === 1)
        return Qt.color(`#${cols[0]}`);
    const p = u * cols.length;
    const i = Math.floor(p) % cols.length;
    const f = p - Math.floor(p);
    const a = Qt.color(`#${cols[i]}`);
    const b = Qt.color(`#${cols[(i + 1) % cols.length]}`);
    return Qt.rgba(a.r + (b.r - a.r) * f, a.g + (b.g - a.g) * f, a.b + (b.b - a.b) * f, 1);
}

function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
}

// Cores do rascunho como lista de hex; vazia = roda de cores (random, arco-iris)
function colors(L) {
    return L.random ? [] : (L.colors ?? []);
}

// { c: color, k: 0..1 } da tecla de centro normalizado (nx, ny), indice i, no instante t
function sample(L, cols, nx, ny, i, t) {
    const dir = L.direction || "right";
    const along = dir === "up" || dir === "down" ? ny : nx;
    const sign = dir === "left" || dir === "up" ? 1 : -1;
    let c = colorAt(cols, 0);
    let lv = 1;
    switch (L.mode) {
    case "Breathing":
        lv = 0.08 + 0.92 * (0.5 - 0.5 * Math.cos(2 * Math.PI * t * 2));
        c = cols.length > 1 ? Qt.color(`#${cols[Math.floor(t * 2) % cols.length]}`) : colorAt(cols, Math.floor(t * 2) * 0.37);
        break;
    case "Pulse":
        lv = 0.08 + 0.92 * Math.pow(0.5 - 0.5 * Math.cos(2 * Math.PI * t * 2), 3);
        break;
    case "Spectrum Cycle":
        c = Qt.hsva(t, 0.85, 1, 1);
        break;
    case "Rainbow Wave":
        c = colorAt(cols.length > 1 ? cols : [], along + sign * t);
        break;
    case "Quicksand":
        c = colorAt(cols, (dir === "up" ? -ny : ny) + t);
        break;
    case "Current":
        c = colorAt(cols, nx * 0.5 + t);
        lv = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(2 * Math.PI * (nx * 2 - t * 2)));
        break;
    case "Reactive": {
        const step = Math.floor(t * 10);
        const hit = noise(i * 7 + step) > 0.9;
        const prev = noise(i * 7 + step - 1) > 0.9;
        lv = hit ? 1 : prev ? 0.45 : 0.04;
        c = colorAt(cols, noise(i + step));
        break;
    }
    case "Ripple": {
        const dist = Math.hypot(nx - 0.5, (ny - 0.5) * 0.4);
        lv = Math.max(0.04, 1 - Math.abs(dist - t * 0.8) * 7);
        c = colorAt(cols, t);
        break;
    }
    case "Rain Drop": {
        const col = Math.floor(nx * 16);
        const y = ((t * 2 + noise(col * 13)) % 1) * 1.6 - 0.3;
        lv = Math.max(0.04, 1 - Math.abs(ny - y) * 3.5);
        c = colorAt(cols, noise(col * 13 + 1));
        break;
    }
    case "Starry Night":
        lv = 0.04 + 0.96 * Math.pow(Math.max(0, Math.sin(2 * Math.PI * (t * 2 + noise(i)))), 6);
        c = colorAt(cols, noise(i * 3 + 2));
        break;
    }
    const level = Math.max(0.15, (L.brightness ?? 100) / 100);
    return { c: c, k: lv * level };
}
