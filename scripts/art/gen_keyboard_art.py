# Pipeline da arte dos teclados: python3 scripts/art/gen_keyboard_art.py (le /data/images/projects-assets/caelestia-assets, escreve modules/nexus/pages/keyboard/*Art.js). trace.py vetoriza os PNGs de traco (silhuetas) em SVG evenodd.
"""azoth.json / g16kbd.json -> .js (pragma library) com id por tecla, caixa do
topo do keycap (f) e o chassis."""
import json, sys, cv2, numpy as np
sys.path.insert(0, ".")
from trace import load, contours, path

def rrect_pts(x, y, w, h, r, n=6):
    """Retangulo arredondado como poligono (cantos com n passos)."""
    import math
    pts = []
    for cx, cy, a0 in ((x + w - r, y + r, -90), (x + w - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts

def ring_pts(x, y, w, h, lw, r):
    """Anel (contorno) de espessura lw: dois poligonos, evenodd."""
    return [rrect_pts(x, y, w, h, r), rrect_pts(x + lw, y + lw, w - 2 * lw, h - 2 * lw, max(1, r - lw))]

def keys2(src, hmin, hmax, wmin, wmax, extra=None, K=3, crop=(0, 0, 0, 0), edge=2, split=False):
    """split: separa em cada tecla o que acende (contorno externo, relevo e a
    legenda principal, `d`) do que fica branco (`u`: legendas Shift na parte de
    baixo do topo e as legendas frontais no relevo) -- como no Azoth, em que so
    a serigrafia principal e translucida."""
    from trace import line_width
    bw, w, h, K = load(src, K, crop, edge)
    line_w = max(1.5, line_width(bw, K))
    cs = contours(bw, K)
    def is_key(i):
        c = cs[i]
        if not c: return False
        x, y, bw_, bh = c["box"]
        return hmin <= bh <= hmax and wmin <= bw_ <= wmax
    keyish = {i for i in range(len(cs)) if is_key(i)}
    if extra:
        for i, c in enumerate(cs):
            if c and extra(c["box"]): keyish.add(i)
    outer = [i for i in keyish if cs[i]["parent"] not in keyish]
    def ancestors(i):
        a = []; p = cs[i]["parent"]
        while p >= 0: a.append(p); p = cs[p]["parent"]
        return a
    keyset = set(outer); groups = {i: [] for i in outer}; rest = []
    for i, c in enumerate(cs):
        if not c: continue
        own = [a for a in ancestors(i) if a in keyset]
        k = own[0] if own else (i if i in keyset else None)
        (rest if k is None else groups[k]).append(c)
    ks = []
    for i in outer:
        x, y, bw_, bh = cs[i]["box"]
        inner = [c for c in groups[i] if c is not cs[i]]
        # topo do keycap = maior contorno de dentro cujo pai e a propria tecla
        # topo = contorno(s) de dentro que ocupam mais da metade da largura
        # (duas metades, como PgUp/PgDn empilhados, viram a uniao)
        tops = [c for c in inner if c["box"][2] > bw_ * 0.5 and c["box"][3] > bh * 0.35]
        tops.sort(key=lambda c: -c["box"][2] * c["box"][3])
        parts = groups[i]
        outline_only = not tops
        if outline_only:
            # o contorno da tecla e um anel grosso de destaque do desenho (vai
            # para fora com o chassis): fica a serigrafia e um anel sintetico
            # da mesma espessura das outras teclas, para nao destoar
            parts = [c for c in parts if c is not cs[i]]
            ring = ring_pts(x, y, bw_, bh, line_w, min(bw_, bh) * 0.12)
            parts = [{"pts": p} for p in ring] + parts
            ins = min(bw_, bh) * 0.1
            f = (x + ins, y + ins, bw_ - 2 * ins, bh - 2 * ins)
            outline_only = False
        else:
            x0 = min(c["box"][0] for c in tops); y0 = min(c["box"][1] for c in tops)
            x1 = max(c["box"][0] + c["box"][2] for c in tops); y1 = max(c["box"][1] + c["box"][3] for c in tops)
            f = (x0, y0, x1 - x0, y1 - y0)
        k = {"x": round(x, 1), "y": round(y, 1), "w": round(bw_, 1), "h": round(bh, 1),
             "f": [round(f[0] - x, 1), round(f[1] - y, 1), round(f[2], 1), round(f[3], 1)]}
        if split and tops and parts and parts[0] is cs[i]:
            # profundidade dentro da tecla: 0 = contorno externo, 1 = faces
            # (topo e relevos), 2 = glifos, 3+ = buracos dos glifos
            idx = {id(c): n for n, c in enumerate(cs) if c}
            def depth(c):
                dpt = 0; p = c["parent"]
                while p >= 0 and p != i:
                    dpt += 1; p = cs[p]["parent"]
                return dpt + 1
            top = tops[0]
            unlit_roots = []
            for c in parts:
                if c is cs[i] or depth(c) != 2:
                    continue
                par = cs[c["parent"]]
                cx, cy = c["box"][0] + c["box"][2] / 2, c["box"][1] + c["box"][3] / 2
                if par is top:
                    if cy > top["box"][1] + top["box"][3] * 0.5:
                        unlit_roots.append(c)          # simbolo Shift, embaixo da legenda
                else:
                    unlit_roots.append(c)              # legenda frontal, no relevo
            def under(c, roots):
                p = c["parent"]
                while p >= 0 and p != i:
                    if any(cs[p] is r for r in roots):
                        return True
                    p = cs[p]["parent"]
                return any(c is r for r in roots)
            unlit = [c for c in parts if under(c, unlit_roots)]
            lit = [c for c in parts if not under(c, unlit_roots)]
            k["d"] = path([c["pts"] for c in lit], x, y)
            if unlit:
                k["u"] = path([c["pts"] for c in unlit], x, y)
        else:
            k["d"] = path([c["pts"] for c in parts], x, y)
        if outline_only:
            k["o"] = True
        ks.append(k)
    # aneis de destaque do desenho em volta de teclas (o \ e o Enter do G16)
    # nao sao chassis: fora
    def frames_key(c):
        x0, y0, w0, h0 = c["box"]
        return any(x0 - 14 <= k["x"] and y0 - 14 <= k["y"] and k["x"] + k["w"] <= x0 + w0 + 14 and k["y"] + k["h"] <= y0 + h0 + 14
                   and w0 < 3.2 * k["w"] and h0 < 3.2 * k["h"] for k in ks)
    rest = [c for c in rest if not frames_key(c)]
    # chassis tambem como caixas (contornos sem tecla), para quem prefere
    # contornos finos em vez da arte (o QSG do Azoth tem bordas grossas)
    rects = []
    for c in sorted(rest, key=lambda c: -c["box"][2] * c["box"][3]):
        x, y, bw_, bh = c["box"]
        if bw_ < 20 or bh < 20:
            continue
        # caixa encaixada numa ja listada (linha dupla): ignora
        if any(abs(x - r[0]) < 14 and abs(y - r[1]) < 14 and abs(bw_ - r[2]) < 28 and abs(bh - r[3]) < 28 for r in rects):
            continue
        rects.append([round(x, 1), round(y, 1), round(bw_, 1), round(bh, 1)])
    return {"w": w, "h": h, "chassis": path([c["pts"] for c in rest]), "rects": rects, "keys": ks, "line": round(line_w, 1), "split": split}

def rows(doc, tol):
    ks = sorted(doc["keys"], key=lambda k: k["y"] + k["h"] / 2)
    out = []
    for k in ks:
        cy = k["y"] + k["h"] / 2
        if out and abs(cy - out[-1][0]) <= tol:
            out[-1][1].append(k); out[-1][0] = sum(q["y"] + q["h"] / 2 for q in out[-1][1]) / len(out[-1][1])
        else:
            out.append([cy, [k]])
    for cy, lst in out:
        lst.sort(key=lambda k: (k["x"], k["y"]))
    return [lst for cy, lst in out]

def emit(doc, seqs, tol, out, src_note, extra_keys=()):
    rs = rows(doc, tol)
    assert len(rs) == len(seqs), (len(rs), len(seqs), [len(r) for r in rs])
    keys = []
    for lst, seq in zip(rs, seqs):
        assert len(lst) == len(seq), (seq, len(lst), [round(k['x']) for k in lst])
        for k, kid in zip(lst, seq):
            keys.append(dict(id=kid, **k))
    keys += list(extra_keys)
    js = [".pragma library", "", f"// GERADO por scratchpad/art/gen.py de {src_note}: nao editar a mao.",
          "// Unidades do desenho; cada tecla = caixa externa do keycap (x, y, w, h), topo do",
          "// keycap (f = [x, y, w, h] relativo) e a arte dela (d = SVG evenodd, relativo).",
          f"var W = {doc['w']};", f"var H = {doc['h']};", f"var CHASSIS = {json.dumps(doc['chassis'])};",
          f"var RECTS = {json.dumps(doc['rects'])};",
          f"var LINE = {doc['line']};", f"var SPLIT = {'true' if doc['split'] else 'false'};",
          "var KEYS = [", ]
    for k in keys:
        rec = {"id": k["id"], "x": k["x"], "y": k["y"], "w": k["w"], "h": k["h"], "f": k["f"], "d": k["d"]}
        if k.get("u"):
            rec["u"] = k["u"]
        if k.get("o"):
            rec["o"] = True
        js.append("    " + json.dumps(rec, separators=(",", ":")) + ",")
    js[-1] = js[-1].rstrip(",")
    js += ["];", "", "function keys() {", "    return KEYS;", "}", "", "function size() {", "    return { w: W, h: H };", "}", ""]
    open(out, "w").write("\n".join(js))
    print(out, len(keys), "teclas,", round(sum(len(l) for l in js) / 1024), "KB")

A = "/data/images/projects-assets/caelestia-assets"
I = A
F = "/data/projects/caelestia-shell-pereiraoc-patch/modules/nexus/pages/keyboard"
# Silhueta mono do usuario (uma cor, fundo transparente): 1u = 106 px;
# OLED = caixa larga no canto; knob = caixa estreita colada na borda direita
az = keys2(f"{A}/ROG Azoth Keyboard Silhouette (mono).png", 60, 130, 40, 800, edge=0, split=True,
           extra=lambda b: (b[0] > 1400 and 250 < b[2] < 420 and 60 <= b[3] <= 140) or (b[0] > 1790 and 12 <= b[2] <= 60 and 40 <= b[3] <= 110))
AZ = [
    ["esc", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "oled"],
    ["grave", "k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8", "k9", "k0", "minus", "equal", "bksp", "ins"],
    ["tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "lbr", "rbr", "bslash", "del"],
    ["caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", "semi", "quote", "enter", "pgup"],
    ["lshift", "z", "x", "c", "v", "b", "n", "m", "comma", "period", "slash", "rshift", "up", "pgdn"],
    ["lctrl", "win", "lalt", "space", "ralt", "fn", "rctrl", "left", "down", "right"],
]
knob = {"id": "knob", "x": 1820.0, "y": 60.0, "w": 34.0, "h": 72.0, "f": [0, 0, 34, 72], "d": ""}
emit(az, AZ, 34, f"{F}/azothArt.js", "ROG Azoth Keyboard Silhouette (mono).png (caelestia-assets)", [knob] if not any(k["w"] < 60 and k["x"] > 1790 for k in az["keys"]) else [])
g = keys2(f"{A}/ROG G16 Keyboard Silhouette (no speaker or power).png", 11, 60, 20, 400, edge=0)
G = [
    ["m1", "m2", "m3", "m4"],
    ["esc", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "delete"],
    ["grave", "k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8", "k9", "k0", "minus", "equal", "bksp"],
    ["tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "lbr", "rbr", "bslash"],
    ["caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", "semi", "quote", "enter"],
    ["lshift", "z", "x", "c", "v", "b", "n", "m", "comma", "period", "slash", "rshift"],
    ["lctrl", "fn", "win", "lalt", "space", "ralt", "rctrl", "home", "pgupdn", "end"],
]
emit(g, G, 15, f"{F}/g16Art.js", "ROG G16 Keyboard Silhouette (no speaker or power).png (caelestia-assets)")
