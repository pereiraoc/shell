# Pipeline da arte dos teclados: python3 scripts/art/gen_keyboard_art.py (le /data/images/projects-assets/caelestia-assets, escreve modules/nexus/pages/keyboard/*Art.js). trace.py vetoriza os PNGs de traco (silhuetas) em SVG evenodd.
"""azoth.json / g16kbd.json -> .js (pragma library) com id por tecla, caixa do
topo do keycap (f) e o chassis."""
import json, sys, cv2, numpy as np
sys.path.insert(0, ".")
from trace import load, contours, path

def keys2(src, hmin, hmax, wmin, wmax, extra=None, K=3, crop=(0, 0, 0, 0)):
    bw, w, h, K = load(src, K, crop)
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
        # topo = maior contorno de dentro que ocupa mais da metade da tecla
        tops = [c for c in inner if c["box"][2] > bw_ * 0.5 and c["box"][3] > bh * 0.5]
        tops.sort(key=lambda c: -c["box"][2] * c["box"][3])
        f = tops[0]["box"] if tops else (x, y, bw_, bh)
        ks.append({"x": round(x, 1), "y": round(y, 1), "w": round(bw_, 1), "h": round(bh, 1),
                   "f": [round(f[0] - x, 1), round(f[1] - y, 1), round(f[2], 1), round(f[3], 1)],
                   "d": path([c["pts"] for c in groups[i]], x, y)})
    return {"w": w, "h": h, "chassis": path([c["pts"] for c in rest]), "keys": ks}

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
          "var KEYS = [", ]
    for k in keys:
        js.append("    " + json.dumps({"id": k["id"], "x": k["x"], "y": k["y"], "w": k["w"], "h": k["h"], "f": k["f"], "d": k["d"]}, separators=(",", ":")) + ",")
    js[-1] = js[-1].rstrip(",")
    js += ["];", "", "function keys() {", "    return KEYS;", "}", "", "function size() {", "    return { w: W, h: H };", "}", ""]
    open(out, "w").write("\n".join(js))
    print(out, len(keys), "teclas,", round(sum(len(l) for l in js) / 1024), "KB")

A = "/data/images/projects-assets/caelestia-assets"
I = A
F = "/data/projects/caelestia-shell-pereiraoc-patch/modules/nexus/pages/keyboard"
az = keys2(f"{A}/ROG Azoth QSG Keyboard.png", 60, 120, 40, 700, crop=(6, 6, 6, 6),
           extra=lambda b: (b[0] > 1300 and 250 < b[2] < 350 and 60 <= b[3] <= 120))
AZ = [
    ["esc", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "oled"],
    ["grave", "k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8", "k9", "k0", "minus", "equal", "bksp", "ins"],
    ["tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "lbr", "rbr", "bslash", "del"],
    ["caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", "semi", "quote", "enter", "pgup"],
    ["lshift", "z", "x", "c", "v", "b", "n", "m", "comma", "period", "slash", "rshift", "up", "pgdn"],
    ["lctrl", "win", "lalt", "space", "ralt", "fn", "rctrl", "left", "down", "right"],
]
knob = {"id": "knob", "x": 1630.0, "y": 49.0, "w": 46.0, "h": 70.0, "f": [0, 0, 46, 70], "d": ""}
emit(az, AZ, 30, f"{F}/azothArt.js", "ROG Azoth QSG (Q20535_M701)", [knob])
g = keys2(f"{A}/ROG G16 Keyboard Silhouette.png", 11, 60, 20, 400)
G = [
    ["m1", "m2", "m3", "m4", "power"],
    ["esc", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "delete"],
    ["grave", "k1", "k2", "k3", "k4", "k5", "k6", "k7", "k8", "k9", "k0", "minus", "equal", "bksp"],
    ["tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "lbr", "rbr", "bslash"],
    ["caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", "semi", "quote", "enter"],
    ["lshift", "z", "x", "c", "v", "b", "n", "m", "comma", "period", "slash", "rshift"],
    ["lctrl", "fn", "win", "lalt", "space", "ralt", "rctrl", "home", "pgupdn", "end"],
]
emit(g, G, 15, f"{F}/g16Art.js", "ROG G16 Keyboard Silhouette.png (caelestia-assets)")
