pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Services
import qs.components
import qs.services

// Wallpaper "Prism" (capa do Dark Side of the Moon com o logo do Arch no lugar
// do prisma), ativo quando o wallpaper e o caelestia-prism.png gerado pelo
// setup. O logo fica sempre; o feixe branco que entra pela esquerda e o
// arco-iris que sai pela direita SO existem com audio tocando:
//   feixe    -> forca geral do som (espessura e brilho)
//   6 linhas -> uma faixa de frequencia cada, como a luz: vermelho = graves
//               (menor frequencia) ... violeta = agudos (maior frequencia)
// Silencio por ~0,4 s: feixe e arco-iris somem com fade, fica so o logo.
// Medidas copiadas do wallpaper anterior (pink-floyd-...-arch-linux.jpg, 4K):
// logo com 18,6% da altura da tela, centrado, creme #eadbb2; fundo #282828;
// faixa das linhas um pouco abaixo do meio.
Item {
    id: root

    // Le o audio e anima o feixe (o visualizer ligado e a tela visivel).
    property bool reactive

    readonly property real logoH: height * 0.1856
    readonly property real bandY: height / 2 + height * 0.0123
    readonly property real maxT: height * 0.0105
    readonly property real step: height * 0.0165
    readonly property color background: "#282828"
    readonly property list<color> spectrum: ["#cf3a2c", "#e97d2b", "#e2c64c", "#6c9f58", "#4e86c8", "#8b63c8"]

    property list<real> bands: [0, 0, 0, 0, 0, 0]
    property real level
    property real presence
    property real silentFor: 1

    // Um quadro de audio -> alvos suavizados (sobe rapido, desce devagar).
    function advance(dt: real): void {
        const v = Audio.cava.values;
        const n = v.length;
        let peak = 0;
        let sum = 0;
        const next = [];
        for (let b = 0; b < 6; b++) {
            const from = Math.floor(b * n / 6);
            const to = Math.max(from + 1, Math.floor((b + 1) * n / 6));
            let s = 0;
            let m = 0;
            for (let i = from; i < to && i < n; i++) {
                s += v[i];
                m = Math.max(m, v[i]);
            }
            const target = Math.min(1, (s / Math.max(1, to - from)) * 0.6 + m * 0.4);
            const cur = root.bands[b] ?? 0;
            next.push(cur + (target - cur) * (target > cur ? 0.5 : 0.12));
            peak = Math.max(peak, m);
            sum += s;
        }
        root.bands = next;
        const lt = Math.min(1, n ? sum / n * 1.6 : 0);
        root.level += (lt - root.level) * (lt > root.level ? 0.45 : 0.1);
        root.silentFor = peak < 0.015 ? root.silentFor + dt : 0;
        const pt = root.silentFor > 0.4 ? 0 : 1;
        root.presence += (pt - root.presence) * (pt > root.presence ? 0.18 : 0.06);
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

    // Visualizer desligado/escondido: some o feixe junto.
    onReactiveChanged: {
        if (!reactive) {
            root.presence = 0;
            root.silentFor = 1;
        }
    }

    // Feixe branco: da borda esquerda ate o centro (o logo cobre o resto).
    Rectangle {
        x: 0
        width: root.width / 2
        height: Math.max(1, root.maxT * (0.35 + 0.65 * root.level))
        y: root.bandY - height / 2
        color: "#d9d9d6"
        opacity: root.presence * (0.35 + 0.65 * root.level)
        visible: opacity > 0.01
    }

    // Arco-iris: do centro ate a borda direita, uma linha por faixa.
    Repeater {
        model: 6

        Rectangle {
            required property int index

            readonly property real v: root.bands[index] ?? 0

            x: root.width / 2
            width: root.width / 2
            height: Math.max(1, root.maxT * (0.3 + 0.7 * v))
            y: root.bandY + (index - 2.5) * root.step - height / 2
            color: root.spectrum[index]
            opacity: root.presence * (0.2 + 0.8 * v)
            visible: opacity > 0.01
        }
    }

    // Logo do Arch (caminho do archlinux-logo.svg oficial; caixa 12,1..243,8).
    // O contorno na cor do fundo abre o respiro entre o logo e as linhas.
    Item {
        id: logoBox

        readonly property real unit: root.logoH / 231.7

        x: root.width / 2 - root.logoH / 2
        y: root.height / 2 - root.logoH / 2
        width: root.logoH
        height: root.logoH

        Shape {
            x: -12.1 * logoBox.unit
            y: -12.1 * logoBox.unit
            preferredRendererType: Shape.CurveRenderer
            transform: Scale {
                xScale: logoBox.unit
                yScale: logoBox.unit
            }

            ShapePath {
                fillColor: "#eadbb2"
                strokeColor: root.background
                strokeWidth: 5
                joinStyle: ShapePath.RoundJoin
                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: "m127.98 12.07c-10.316 25.309-16.543 41.855-28.031 66.41 7.043 7.4609 15.691 16.156 29.734 25.977-15.098-6.207-25.395-12.445-33.094-18.918-14.703 30.68-37.742 74.391-84.492 158.39 36.746-21.219 65.23-34.293 91.773-39.289-1.1406-4.8945-1.7852-10.195-1.7422-15.734l0.042969-1.1719c0.58203-23.551 12.828-41.645 27.336-40.418 14.508 1.2266 25.781 21.316 25.199 44.867-0.10938 4.4219-0.60938 8.6914-1.4805 12.641 26.258 5.1328 54.438 18.18 90.684 39.105-7.1484-13.156-13.527-25.016-19.621-36.316-9.5938-7.4336-19.605-17.117-40.023-27.594 14.035 3.6406 24.082 7.8516 31.914 12.555-61.941-115.32-66.957-130.66-88.199-180.5z"
                }
            }
        }
    }
}
