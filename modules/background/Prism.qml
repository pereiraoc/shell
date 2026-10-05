pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia.Services
import qs.components
import qs.services

// Wallpaper "Prism" (capa do Dark Side of the Moon com o logo do Arch no lugar
// do prisma), ativo quando o wallpaper e o caelestia-prism.png gerado pelo
// setup. O logo fica sempre; o resto so existe com audio tocando:
//
//   feixe branco  entra pela esquerda ate a FACE esquerda do logo; gradiente
//                 que acende perto do logo, brilho no ponto de impacto e um
//                 reflexo curto -- tudo pela forca geral do som.
//   6 cordas      saem da FACE direita (nunca do meio do logo), uma por faixa
//                 de frequencia como a luz: vermelho = graves ... violeta =
//                 agudos. Cada uma e uma corda de violao presa no logo e na
//                 borda da tela: onda estacionaria com comprimento de onda
//                 ligado a faixa (grave = onda longa, agudo = curta).
//                 "Dedilhar": quando a faixa bate, amplitude E brilho saltam
//                 para o valor NOVO (nao somam com o que sobrava) e decaem
//                 com o tempo; grave sustenta mais, como corda grossa.
//
// A luz VIAJA da esquerda para a direita: quando o som comeca, a frente entra
// pela borda esquerda, chega no logo e so entao o arco-iris se espalha ate a
// direita. Parou de tocar (player pausado, ou ~2,5 s sem som): a "fonte"
// sai -- o fim do feixe anda ate o logo e depois o fim do arco-iris anda ate
// a borda direita. Fica so o logo.
// Medidas do wallpaper anterior (pink-floyd-...-arch-linux.jpg, 4K): logo
// com 18,6% da altura da tela, centrado, creme #eadbb2; fundo #282828.
Item {
    id: root

    // Le o audio e anima (visualizer ligado e a tela visivel).
    property bool reactive
    // Espelha so a luz (feixe, cordas, aura): a luz entra pela direita e o
    // arco-iris sai pela esquerda. O logo fica como e (nao e simetrico); o
    // contorno externo e simetrico a ~1 px, entao a luz continua colada nele.
    property bool mirrored

    readonly property real logoH: height * 0.1856
    readonly property real logoX: width / 2 - logoH / 2
    readonly property real logoY: height / 2 - logoH / 2
    readonly property real bandY: height / 2 + height * 0.0123
    readonly property real maxT: height * 0.0085
    readonly property real step: height * 0.0195
    readonly property color background: "#282828"
    readonly property list<color> spectrum: ["#d8452f", "#ee8a33", "#e6cd55", "#79ad61", "#5b93d6", "#9a72d6"]

    // Contorno externo do logo medido no archlinux-logo.svg (101 linhas, 0 =
    // topo, x em fracao da caixa do logo); entalhes alisados.
    readonly property list<real> edgeL: [0.4998, 0.4959, 0.4916, 0.4877, 0.4838, 0.4799, 0.4756, 0.4717, 0.4674, 0.4635, 0.4596, 0.4553, 0.4514, 0.4471, 0.4432, 0.4389, 0.4350, 0.4307, 0.4264, 0.4221, 0.4178, 0.4135, 0.4091, 0.4048, 0.4001, 0.3958, 0.3910, 0.3867, 0.3820, 0.3772, 0.3725, 0.3678, 0.3630, 0.3582, 0.3530, 0.3483, 0.3435, 0.3384, 0.3336, 0.3284, 0.3233, 0.3185, 0.3133, 0.3086, 0.3034, 0.2978, 0.2931, 0.2879, 0.2827, 0.2775, 0.2719, 0.2667, 0.2615, 0.2564, 0.2512, 0.2460, 0.2404, 0.2352, 0.2300, 0.2244, 0.2192, 0.2141, 0.2085, 0.2028, 0.1977, 0.1925, 0.1869, 0.1813, 0.1761, 0.1705, 0.1653, 0.1597, 0.1545, 0.1489, 0.1433, 0.1381, 0.1325, 0.1273, 0.1213, 0.1161, 0.1105, 0.1053, 0.0997, 0.0941, 0.0885, 0.0829, 0.0777, 0.0721, 0.0665, 0.0609, 0.0552, 0.0496, 0.0445, 0.0388, 0.0332, 0.0276, 0.0220, 0.0164, 0.0112, 0.0056, 0.0000]
    readonly property list<real> edgeR: [0.4998, 0.5041, 0.5084, 0.5127, 0.5170, 0.5209, 0.5252, 0.5296, 0.5339, 0.5382, 0.5421, 0.5464, 0.5507, 0.5550, 0.5593, 0.5637, 0.5680, 0.5727, 0.5770, 0.5814, 0.5857, 0.5904, 0.5947, 0.5995, 0.6042, 0.6085, 0.6133, 0.6180, 0.6228, 0.6275, 0.6323, 0.6370, 0.6418, 0.6470, 0.6517, 0.6569, 0.6616, 0.6664, 0.6716, 0.6767, 0.6819, 0.6867, 0.6918, 0.6970, 0.7018, 0.7074, 0.7121, 0.7173, 0.7225, 0.7277, 0.7328, 0.7380, 0.7432, 0.7484, 0.7536, 0.7587, 0.7644, 0.7695, 0.7747, 0.7799, 0.7851, 0.7907, 0.7959, 0.8010, 0.8066, 0.8118, 0.8170, 0.8226, 0.8278, 0.8330, 0.8386, 0.8438, 0.8489, 0.8546, 0.8597, 0.8653, 0.8705, 0.8757, 0.8811, 0.8866, 0.8921, 0.8975, 0.9030, 0.9084, 0.9139, 0.9193, 0.9245, 0.9297, 0.9353, 0.9409, 0.9461, 0.9512, 0.9568, 0.9620, 0.9676, 0.9732, 0.9784, 0.9840, 0.9892, 0.9948, 1.0000]

    // Por corda: meias-ondas na corda (comprimento de onda ~ faixa), vibracao
    // em Hz (visual) e quanto tempo o "som" sustenta.
    readonly property list<int> modes: [4, 6, 9, 13, 18, 24]
    readonly property list<real> hz: [1.7, 2.4, 3.3, 4.6, 6.2, 8.0]
    readonly property list<real> sustain: [1.25, 1.0, 0.8, 0.62, 0.48, 0.36]

    property list<real> env: [0, 0, 0, 0, 0, 0]
    property list<real> raw: [0, 0, 0, 0, 0, 0]
    property real level
    property real presence
    // Aura do logo: intensidade propria, suavizada (acende ~0,25 s, apaga
    // ~1,4 s) -- presence vai a zero de uma vez no fim da saida da luz.
    property real aura
    property real silentFor: 99
    readonly property bool mprisPlaying: Players.list.some(p => p.playbackState === MprisPlaybackState.Playing)
    // Frente (head) e cauda (tail) da luz no caminho desdobrado 0..1:
    // 0..beamPart = feixe (borda esquerda -> logo), resto = arco-iris
    // (face do logo -> borda direita).
    property real head
    property real tail
    readonly property real beamPart: 0.42
    readonly property real arriveSecs: 0.75
    readonly property real leaveSecs: 1.1
    property real time

    function edgeAt(table: list<real>, y: real): real {
        const t = Math.max(0, Math.min(1, (y - root.logoY) / root.logoH)) * 100;
        const i = Math.floor(t);
        const f = t - i;
        const a = table[Math.min(100, i)];
        const b = table[Math.min(100, i + 1)];
        return root.logoX + (a + (b - a) * f) * root.logoH;
    }

    function lineY(i: int): real {
        return root.bandY + (i - 2.5) * root.step;
    }

    // Um quadro: bandas do cava -> envelope de corda dedilhada.
    function advance(dt: real): void {
        root.time += dt;
        const v = Audio.cava.values;
        const n = v.length;
        let peak = 0;
        let sum = 0;
        const nextEnv = [];
        const nextRaw = [];
        for (let b = 0; b < 6; b++) {
            const from = Math.floor(b * n / 6);
            const to = Math.max(from + 1, Math.floor((b + 1) * n / 6));
            let s = 0;
            let m = 0;
            for (let i = from; i < to && i < n; i++) {
                s += v[i];
                m = Math.max(m, v[i]);
            }
            const val = Math.min(1, (s / Math.max(1, to - from)) * 0.5 + m * 0.5);
            // decai como corda; uma batida nova SUBSTITUI (max), nao soma
            const decayed = (root.env[b] ?? 0) * Math.exp(-dt / root.sustain[b]);
            nextEnv.push(Math.max(decayed, val));
            nextRaw.push(val);
            peak = Math.max(peak, m);
            sum += s;
        }
        root.env = nextEnv;
        root.raw = nextRaw;
        const lt = Math.min(1, n ? sum / n * 1.6 : 0);
        root.level += (lt - root.level) * (lt > root.level ? 0.5 : 0.08);
        // Tocando = um player MPRIS em Playing (volume baixo ou trecho calmo
        // nao apagam) OU som no cava, com folga de 2,5 s entre batidas para
        // audio sem player (jogo, Discord) nao piscar em trechos baixos.
        root.silentFor = peak < 0.008 ? root.silentFor + dt : 0;
        const playing = root.mprisPlaying || root.silentFor <= 2.5;
        if (playing) {
            if (root.tail > 0) {
                // a fonte voltou no meio da saida: luz nova entrando da esquerda
                root.tail = 0;
                root.head = 0;
            }
            root.head = Math.min(1, root.head + dt / root.arriveSecs);
        } else if (root.head > 0) {
            root.tail = Math.min(1, root.tail + dt / root.leaveSecs);
            if (root.tail >= 1) {
                root.head = 0;
                root.tail = 0;
            }
        }
        root.presence = root.head > 0 ? 1 : 0;
        const at = playing ? 0.35 + 0.65 * root.level : 0;
        root.aura += (at - root.aura) * (1 - Math.exp(-dt / (at > root.aura ? 0.25 : 1.4)));
        if (root.aura < 0.002)
            root.aura = 0;
    }

    function beamFrac(f: real): real {
        return Math.max(0, Math.min(1, f / root.beamPart));
    }

    function rainFrac(f: real): real {
        return Math.max(0, Math.min(1, (f - root.beamPart) / (1 - root.beamPart)));
    }

    Loader {
        active: root.reactive

        sourceComponent: Item {
            ServiceRef {
                service: Audio.cava
            }

            FrameAnimation {
                running: true
                onTriggered: root.advance(frameTime)
            }
        }
    }

    onReactiveChanged: {
        if (!reactive) {
            root.presence = 0;
            root.silentFor = 99;
            root.head = 0;
            root.tail = 0;
            root.aura = 0;
        }
    }

    // ------------------------------------------------------------ luz
    // Feixe, brilho, reflexo e cordas num shader (shaders/prism-v7.frag): por
    // quadro so mudam os uniforms. As cordas em JS/Shape refaziam ~2000
    // pontos por quadro na thread da interface e travavam a barra/popouts.
    ShaderEffect {
        transform: Scale {
            origin.x: root.width / 2
            xScale: root.mirrored ? -1 : 1
        }

        readonly property real hitXv: root.edgeAt(root.edgeL, root.bandY)
        readonly property real beamEnd: hitXv + root.logoH * 0.04

        // luz comeca um pouco POR BAIXO do logo: a face corta no angulo dela
        function startX(i: int): real {
            return root.edgeAt(root.edgeR, root.lineY(i)) - root.logoH * 0.06;
        }

        anchors.fill: parent
        visible: root.presence > 0 || root.aura > 0
        fragmentShader: Qt.resolvedUrl("shaders/prism-v7.frag.qsb")

        property vector2d res: Qt.vector2d(width, height)
        property real time: root.time
        property real level: root.level
        property real beamK: root.presence * (0.35 + 0.65 * root.level)
        property real beamFrom: beamEnd * root.beamFrac(root.tail)
        property real beamTo: beamEnd * root.beamFrac(root.head)
        property real hitX: hitXv
        property real bandY: root.bandY
        property real maxT: root.maxT
        property real stepY: root.step
        property real hitting: root.beamFrac(root.head) >= 1 && root.beamFrac(root.tail) < 1 ? 1 : 0
        property real uA: root.rainFrac(root.tail)
        property real uB: root.rainFrac(root.head)
        property vector4d env0: Qt.vector4d(root.env[0], root.env[1], root.env[2], root.env[3])
        property vector4d env1: Qt.vector4d(root.env[4], root.env[5], 0, 0)
        property vector4d xs0: Qt.vector4d(startX(0), startX(1), startX(2), startX(3))
        property vector4d xs1: Qt.vector4d(startX(4), startX(5), 0, 0)
        property real auraK: root.aura
    }

    // ------------------------------------------------------------ boot
    // Fim do boot (configs/plymouth/caelestia-prism + caelestia-boot-bridge):
    // o Plymouth e a ponte deixam um ponto de luz no feixe; na PRIMEIRA carga
    // da sessao o ponto explode no logo (mesma matematica do tema) -- o logo
    // sozinho no centro = ligou. No fim cria $XDG_RUNTIME_DIR/
    // caelestia-desktop-ready: a ponte sai e o Plymouth e encerrado. Reload do
    // shell: o arquivo existe, o logo so aparece suave.
    readonly property string readyPath: `${Quickshell.env("XDG_RUNTIME_DIR")}/caelestia-desktop-ready`
    property bool booting
    property real burstP        // explosao 0..1 (0,35 s)
    property real settleP       // logo esfriando 0..1 (1 s)

    function easeOut(p: real): real {
        const q = 1 - p;
        return 1 - q * q * q;
    }
    function easeBack(p: real): real {
        const q = p - 1;
        return 1 + q * q * (2.6 * q + 1.6);
    }

    FileView {
        path: root.readyPath
        printErrors: false
        // So na primeira carga: depois o arquivo existe e nada mais acontece.
        onLoadFailed: if (!root.booting && root.burstP === 0) {
            root.booting = true;
            bootAnim.start();
        }
        onLoaded: if (!root.booting)
            root.burstP = root.settleP = 1
    }

    SequentialAnimation {
        id: bootAnim

        NumberAnimation {
            target: root
            property: "burstP"
            from: 0
            to: 1
            duration: 350
        }
        NumberAnimation {
            target: root
            property: "settleP"
            from: 0
            to: 1
            duration: 1000
        }
        ScriptAction {
            script: {
                root.booting = false;
                Quickshell.execDetached(["touch", root.readyPath]);
            }
        }
    }

    // Ponto de luz (o mesmo da ponte), clarao e anel -- abaixo do logo
    Image {
        readonly property real size: root.logoH * 0.08 * 1.3 / 0.225
        visible: root.booting && root.burstP < 1
        source: Quickshell.shellPath("assets/boot/dot.png")
        x: root.width / 2 - size / 2
        y: root.bandY - size / 2
        width: size
        height: size
        opacity: 1 - root.burstP
        smooth: true
    }

    Image {
        readonly property real r: root.logoH * (0.12 + 1.2 * root.easeOut(root.burstP))
        readonly property real size: Math.min(r / 0.20, root.logoH * 3)
        readonly property real q: 1 - root.burstP
        visible: root.booting
        source: Quickshell.shellPath("assets/boot/glow.png")
        x: root.width / 2 - size / 2
        y: root.bandY - size / 2
        width: size
        height: size
        opacity: root.burstP < 1 ? Math.min(1, 3 * q * Math.sqrt(q)) : 0.55 * (1 - root.settleP) * (1 - root.settleP)
        smooth: true
    }

    Image {
        readonly property real size: Math.min(root.logoH * (0.1 + 1.9 * root.easeOut(root.burstP)) / 0.40, root.logoH * 3)
        visible: root.booting && root.burstP < 1
        source: Quickshell.shellPath("assets/boot/ring.png")
        x: root.width / 2 - size / 2
        y: root.bandY - size / 2
        width: size
        height: size
        opacity: 0.9 * (1 - root.burstP) * (1 - root.burstP)
        smooth: true
    }

    // ------------------------------------------------------------ logo
    // Caminho do archlinux-logo.svg oficial (caixa 12,1..243,8). O contorno
    // na cor do fundo abre o respiro entre o logo e a luz.
    Item {
        id: logoBox

        readonly property real unit: root.logoH / 231.7

        x: root.logoX
        y: root.logoY
        width: root.logoH
        height: root.logoH
        // Boot: nasce da explosao (0,7 -> 1 com overshoot, quente -> creme).
        // Reload do shell: so aparece suave.
        opacity: root.booting ? Math.min(1, root.burstP * 1.6) : (root.burstP === 1 ? 1 : 0)
        scale: root.booting ? 0.7 + 0.3 * root.easeBack(root.burstP) : 1
        transformOrigin: Item.Center

        Behavior on opacity {
            enabled: !root.booting
            NumberAnimation {
                duration: 600
                easing.type: Easing.OutCubic
            }
        }

        Shape {
            x: -12.1 * logoBox.unit
            y: -12.1 * logoBox.unit
            preferredRendererType: Shape.CurveRenderer
            transform: Scale {
                xScale: logoBox.unit
                yScale: logoBox.unit
            }

            ShapePath {
                // quente (quase branco) na explosao, esfria ate o creme
                fillColor: root.booting ? Qt.tint("#eadbb2", Qt.rgba(1, 0.98, 0.94, 1 - root.easeOut(root.settleP))) : "#eadbb2"
                strokeColor: root.background
                strokeWidth: 3
                joinStyle: ShapePath.RoundJoin
                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: "m127.98 12.07c-10.316 25.309-16.543 41.855-28.031 66.41 7.043 7.4609 15.691 16.156 29.734 25.977-15.098-6.207-25.395-12.445-33.094-18.918-14.703 30.68-37.742 74.391-84.492 158.39 36.746-21.219 65.23-34.293 91.773-39.289-1.1406-4.8945-1.7852-10.195-1.7422-15.734l0.042969-1.1719c0.58203-23.551 12.828-41.645 27.336-40.418 14.508 1.2266 25.781 21.316 25.199 44.867-0.10938 4.4219-0.60938 8.6914-1.4805 12.641 26.258 5.1328 54.438 18.18 90.684 39.105-7.1484-13.156-13.527-25.016-19.621-36.316-9.5938-7.4336-19.605-17.117-40.023-27.594 14.035 3.6406 24.082 7.8516 31.914 12.555-61.941-115.32-66.957-130.66-88.199-180.5z"
                }
            }
        }
    }
}
