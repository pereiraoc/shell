"""Vetoriza desenho de traco preto (PNG) -> SVG evenodd; e, para teclados, separa
as teclas: caixa externa de cada keycap + todos os contornos dentro dela (path proprio)."""
import sys, json, cv2, numpy as np

def load(src, K=3, crop=(0, 0, 0, 0)):
    im = cv2.imread(src, cv2.IMREAD_UNCHANGED)
    if im.ndim == 3 and im.shape[2] == 4:
        # transparente vira branco (senao o fundo vazio vira tinta)
        a = im[:, :, 3:4].astype(np.float32) / 255.0
        im = (im[:, :, :3].astype(np.float32) * a + 255.0 * (1 - a)).astype(np.uint8)
    h, w = im.shape[:2]
    t, b, l, r = crop
    im = im[t:h - b, l:w - r]; h, w = im.shape[:2]
    gray = cv2.cvtColor(im, cv2.COLOR_BGR2GRAY) if im.ndim == 3 else im
    big = cv2.resize(gray, (w * K, h * K), interpolation=cv2.INTER_CUBIC)
    big = cv2.GaussianBlur(big, (3, 3), 0)
    _, bw = cv2.threshold(big, 160, 255, cv2.THRESH_BINARY_INV)
    bw[:2, :] = 0; bw[-2:, :] = 0; bw[:, :2] = 0; bw[:, -2:] = 0
    return bw, w, h, K

def contours(bw, K):
    cs, hier = cv2.findContours(bw, cv2.RETR_TREE, cv2.CHAIN_APPROX_NONE)
    hier = hier[0] if hier is not None else []
    out = []
    for i, c in enumerate(cs):
        if cv2.contourArea(c) < 3 * K * K and len(c) < 8:
            out.append(None); continue
        ap = cv2.approxPolyDP(c, 0.9 * K / 2, True)
        pts = [(p[0][0] / K, p[0][1] / K) for p in ap]
        x, y, bw_, bh = cv2.boundingRect(c)
        out.append({"pts": pts, "box": (x / K, y / K, bw_ / K, bh / K), "parent": int(hier[i][3])})
    return out

def path(pts_list, ox=0, oy=0):
    return " ".join("M" + " L".join(f"{x - ox:.1f} {y - oy:.1f}" for x, y in pts) + " Z" for pts in pts_list if len(pts) >= 3)

def svg(w, h, d):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}"><path fill="#000" fill-rule="evenodd" d="{d}"/></svg>'

def whole(src, out, K=3, crop=(0, 0, 0, 0)):
    bw, w, h, K = load(src, K, crop)
    cs = [c for c in contours(bw, K) if c]
    open(out, "w").write(svg(w, h, path([c["pts"] for c in cs])))
    print(out, w, h, "contornos", len(cs))

def keys(src, out_json, kmin, kmax, K=3, crop=(0, 0, 0, 0)):
    """kmin/kmax: faixa de altura (px da imagem) de uma tecla; chaves = contornos
    nessa faixa cujo pai NAO e tecla (as caixas externas)."""
    bw, w, h, K = load(src, K, crop)
    cs = contours(bw, K)
    def is_key(i):
        c = cs[i]
        if not c: return False
        x, y, bw_, bh = c["box"]
        return kmin <= bh <= kmax and bw_ >= kmin * 0.6
    keyish = {i for i in range(len(cs)) if is_key(i)}
    outer = [i for i in keyish if cs[i]["parent"] not in keyish]
    def ancestors(i):
        a = []
        p = cs[i]["parent"]
        while p >= 0:
            a.append(p); p = cs[p]["parent"]
        return a
    keyset = set(outer)
    groups = {i: [] for i in outer}
    rest = []
    for i, c in enumerate(cs):
        if not c: continue
        own = [a for a in ancestors(i) if a in keyset]
        k = own[0] if own else (i if i in keyset else None)
        if k is None: rest.append(c["pts"])
        else: groups[k].append(c["pts"])
    keys_ = []
    for i in outer:
        x, y, bw_, bh = cs[i]["box"]
        keys_.append({"x": round(x, 1), "y": round(y, 1), "w": round(bw_, 1), "h": round(bh, 1), "d": path(groups[i], x, y)})
    doc = {"w": w, "h": h, "chassis": path(rest), "keys": keys_}
    json.dump(doc, open(out_json, "w"))
    print(out_json, w, h, "teclas", len(keys_), "chassis contornos", len(rest))
    return doc

if __name__ == "__main__":
    pass
