#version 440
// Luz do wallpaper Prism, toda na GPU: feixe branco com gradiente, brilho no
// impacto, reflexo, e 6 cordas (ondas estacionarias) com antialias por
// distancia ate a curva. O QML so atualiza os uniforms por quadro -- antes as
// cordas eram polylines refeitas em JS a cada quadro e travavam o shell.
// Recompilar: qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o prism-v6.frag.qsb prism-v6.frag
// (nome novo a cada mudanca grande: o ShaderEffect guarda o shader em cache
// pela URL e o hot-reload continuaria com o antigo)

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;          // tamanho em px
    float time;
    float level;       // forca geral do som 0..1
    float beamK;       // brilho do feixe (presenca * nivel)
    float beamFrom;    // trecho iluminado do feixe (px)
    float beamTo;
    float hitX;        // face esquerda do logo na altura do feixe
    float bandY;       // altura do feixe / centro das cordas
    float maxT;        // espessura maxima
    float stepY;       // distancia entre cordas
    float hitting;     // 1 = luz batendo no logo (brilho + reflexo)
    float uA;          // trecho iluminado das cordas (fracao 0..1)
    float uB;
    vec4 env0;         // envelope das cordas 0..3
    vec4 env1;         // 4..5 (zw livres)
    vec4 xs0;          // x inicial de cada corda (px)
    vec4 xs1;
    float auraK;       // aura do logo, suavizada no tempo (apaga devagar)
};

const int MODES[6] = int[6](4, 6, 9, 13, 18, 24);
const float HZ[6] = float[6](1.7, 2.4, 3.3, 4.6, 6.2, 8.0);
const vec3 COL[6] = vec3[6](
    vec3(0.847, 0.271, 0.184), vec3(0.933, 0.541, 0.200), vec3(0.902, 0.804, 0.333),
    vec3(0.475, 0.678, 0.380), vec3(0.357, 0.576, 0.839), vec3(0.604, 0.447, 0.839));
const float PI = 3.14159265;

// distancia com sinal a um triangulo (Inigo Quilez) -- o contorno do logo
// do Arch e quase um triangulo; serve para a aura.
float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2) {
    vec2 e0 = p1 - p0, e1 = p2 - p1, e2 = p0 - p2;
    vec2 v0 = p - p0, v1 = p - p1, v2 = p - p2;
    vec2 pq0 = v0 - e0 * clamp(dot(v0, e0) / dot(e0, e0), 0.0, 1.0);
    vec2 pq1 = v1 - e1 * clamp(dot(v1, e1) / dot(e1, e1), 0.0, 1.0);
    vec2 pq2 = v2 - e2 * clamp(dot(v2, e2) / dot(e2, e2), 0.0, 1.0);
    float s = sign(e0.x * e2.y - e0.y * e2.x);
    vec2 d = min(min(vec2(dot(pq0, pq0), s * (v0.x * e0.y - v0.y * e0.x)),
                     vec2(dot(pq1, pq1), s * (v1.x * e1.y - v1.y * e1.x))),
                     vec2(dot(pq2, pq2), s * (v2.x * e2.y - v2.y * e2.x)));
    return -sqrt(d.x) * sign(d.y);
}

float envAt(int i) { return i < 4 ? env0[i] : env1[i - 4]; }
float xAt(int i) { return i < 4 ? xs0[i] : xs1[i - 4]; }

// cobertura antialiasada de uma faixa de meia-largura hw a distancia d
float band(float d, float hw) { return clamp(hw + 0.5 - d, 0.0, 1.0); }

void main() {
    vec2 p = qt_TexCoord0 * res;
    vec3 rgb = vec3(0.0);     // premultiplicado
    float a = 0.0;

    // ---- aura do logo: branco quente bem leve, so com musica, respira com
    // a intensidade (auraK: suavizada no QML, acende rapido e apaga devagar,
    // independente da saida da luz). O logo e desenhado por
    // cima, entao so a parte de fora aparece; mais fraca embaixo (a base do
    // logo e concava).
    if (auraK > 0.001) {
        float lh = res.y * 0.1856;
        vec2 c0 = vec2(res.x * 0.5, res.y * 0.5 - lh * 0.5);
        float dT = sdTriangle(p, c0, vec2(c0.x - lh * 0.5, c0.y + lh), vec2(c0.x + lh * 0.5, c0.y + lh));
        if (dT < lh * 0.35) {
            // some na base: ela e concava, e aura so "fora do triangulo"
            // desenharia uma sombra com o formato dele sob o arco
            float fadeBottom = 1.0 - smoothstep(c0.y + lh * 0.55, c0.y + lh * 0.92, p.y);
            float aura = exp(-pow(max(dT, 0.0) / (lh * 0.11), 2.0)) * 0.13 * auraK * fadeBottom;
            rgb += vec3(1.0, 0.97, 0.90) * aura; a += aura;
        }
    }

    // ---- feixe branco
    if (beamK > 0.001 && p.x >= beamFrom && p.x <= beamTo) {
        float hw = max(0.75, maxT * (0.55 + 0.45 * level)) * 0.5;
        float d = abs(p.y - bandY);
        float g = mix(0.12, 1.0, pow(clamp(p.x / hitX, 0.0, 1.0), 1.6));
        float core = band(d, hw) * g;
        float halo = exp(-pow(d / (hw * 4.0), 2.0)) * 0.18 * g;
        float c = (core + halo) * beamK;
        rgb += vec3(c); a += c;
    }

    // ---- brilho no impacto + reflexo
    if (hitting > 0.5 && beamK > 0.001) {
        vec2 q = p - vec2(hitX, bandY);
        float R = res.y * 0.1856 * (0.07 + 0.11 * level);
        float glow = exp(-dot(q, q) / (R * R) * 2.5) * 0.6 * beamK;
        vec2 dir = normalize(vec2(-0.603, -0.7975));
        float along = dot(q, dir);
        float len = res.y * 0.1856 * 0.38;
        float refl = 0.0;
        if (along > 0.0 && along < len) {
            float perp = abs(q.x * dir.y - q.y * dir.x);
            refl = band(perp, max(0.6, maxT * 0.22)) * (1.0 - along / len) * 0.55 * beamK;
        }
        rgb += vec3(glow + refl); a += glow + refl;
    }

    // ---- faixas: barra continua e estavel (como as faixas do wallpaper
    // original) com a corda vibrando DENTRO dela -- calmo de olhar, mas vivo.
    float w0 = 2.0 * PI * time;
    for (int i = 0; i < 6; i++) {
        float x0 = xAt(i);
        float L = res.x - x0;
        float u = (p.x - x0) / L;
        if (u < uA || u > uB || L <= 0.0) continue;
        float yi = bandY + (float(i) - 2.5) * stepY;
        float hb = stepY * 0.42;                 // meia altura da barra
        float db = abs(p.y - yi);
        // saida da luz: perto da face do logo a faixa e mais intensa e vaza
        // um brilho na propria cor, que assenta ao longo do caminho
        float logoH = res.y * 0.1856;
        float face = x0 + logoH * 0.06;
        float near = exp(-max(0.0, p.x - face) / (logoH * 0.16));
        if (db > hb * (2.0 + 1.5 * near) + 2.0) continue;
        float e = envAt(i);
        float inBar = band(db, hb);
        float exitK = near * (0.45 + 0.55 * e) * (0.5 + 0.5 * level) * 0.55;
        // brilho fora da barra so nasce A PARTIR da face, suave (sem borda
        // vertical onde o logo nao cobre)
        float fromFace = smoothstep(face - 1.0, face + logoH * 0.04, p.x);

        // barra: o BRILHO segue a forca da faixa -- apagada quando fraca,
        // cor cheia (e um halo leve em volta) quando bate forte
        vec3 base = min(COL[i] * (0.38 + 0.62 * e) * (1.0 + 0.6 * exitK) + vec3(0.05 * exitK), vec3(1.0));
        float fill = inBar;
        float outer = exp(-pow(max(0.0, db - hb) / (hb * 0.9 + 1.0), 2.0)) * (1.0 - inBar) * 0.28 * e * e * fromFace;

        // corda dentro da barra
        float hw = maxT * (0.22 + 0.16 * e);
        float A = e * max(0.0, hb - hw - 1.5);
        float k = float(MODES[i]) * PI;
        float w = w0 * HZ[i];
        float s1 = sin(w), s2 = sin(2.0 * w + 1.3);
        float yc = yi + A * (sin(k * u) * s1 + 0.22 * sin(2.0 * k * u) * s2) / 1.22;
        float dy = A / 1.22 * (k / L) * (cos(k * u) * s1 + 0.44 * cos(2.0 * k * u) * s2);
        float d = abs(p.y - yc) / sqrt(1.0 + dy * dy);
        float core = band(d, hw) * inBar;
        float halo = exp(-pow(d / (hw * 2.5 + 1.0), 2.0)) * 0.25 * e * inBar;
        // corda: a MESMA cor, so mais clara e viva que a barra (nada de branco)
        vec3 bright = min(mix(COL[i] * (1.0 + 0.35 * e), vec3(1.0), 0.12 + 0.12 * e), vec3(1.0));

        vec3 c = base * fill;
        c = mix(c, bright, clamp(core * (0.7 + 0.3 * e) + halo, 0.0, 1.0));
        c += COL[i] * outer;
        // brilho que vaza na saida (para cima e para baixo da faixa)
        float spill = exp(-pow(max(0.0, db - hb) / (hb * 1.3 + 1.0), 2.0)) * (1.0 - inBar) * 0.30 * exitK * fromFace;
        c += COL[i] * spill;
        rgb += c; a += max(max(fill, core), outer + spill);
    }

    a = clamp(a, 0.0, 1.0);
    fragColor = vec4(min(rgb, vec3(1.0)), a) * qt_Opacity;
}
