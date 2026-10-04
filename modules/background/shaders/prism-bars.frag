#version 440
// Luz do wallpaper Prism, toda na GPU: feixe branco com gradiente, brilho no
// impacto, reflexo, e 6 cordas (ondas estacionarias) com antialias por
// distancia ate a curva. O QML so atualiza os uniforms por quadro -- antes as
// cordas eram polylines refeitas em JS a cada quadro e travavam o shell.
// Recompilar: qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o prism-bars.frag.qsb prism-bars.frag
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
};

const int MODES[6] = int[6](4, 6, 9, 13, 18, 24);
const float HZ[6] = float[6](1.7, 2.4, 3.3, 4.6, 6.2, 8.0);
const vec3 COL[6] = vec3[6](
    vec3(0.847, 0.271, 0.184), vec3(0.933, 0.541, 0.200), vec3(0.902, 0.804, 0.333),
    vec3(0.475, 0.678, 0.380), vec3(0.357, 0.576, 0.839), vec3(0.604, 0.447, 0.839));
const float PI = 3.14159265;

float envAt(int i) { return i < 4 ? env0[i] : env1[i - 4]; }
float xAt(int i) { return i < 4 ? xs0[i] : xs1[i - 4]; }

// cobertura antialiasada de uma faixa de meia-largura hw a distancia d
float band(float d, float hw) { return clamp(hw + 0.5 - d, 0.0, 1.0); }

void main() {
    vec2 p = qt_TexCoord0 * res;
    vec3 rgb = vec3(0.0);     // premultiplicado
    float a = 0.0;

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
        if (db > hb + 1.0) continue;
        float e = envAt(i);
        float inBar = band(db, hb);

        // barra: a cor cheia do arco-iris, espessura fixa; acende com a batida
        vec3 base = COL[i] * (0.80 + 0.20 * e);
        float fill = inBar;

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
        float halo = exp(-pow(d / (hw * 2.5 + 1.0), 2.0)) * 0.30 * e * inBar;
        // corda: linha clara dentro da barra (quase branca no pico)
        vec3 bright = mix(COL[i], vec3(1.0), 0.55 + 0.3 * e);

        vec3 c = base * fill;
        c = mix(c, bright, clamp(core * (0.65 + 0.35 * e) + halo, 0.0, 1.0));
        rgb += c; a += max(fill, core);
    }

    a = clamp(a, 0.0, 1.0);
    fragColor = vec4(min(rgb, vec3(1.0)), a) * qt_Opacity;
}
