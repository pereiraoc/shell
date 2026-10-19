pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Diagrama de um teclado (laptopLayout.js / azothLayout.js) no traco do manual:
// teclas so de contorno, cantos pouco arredondados, respiros reais e o que
// esta impresso em cada uma (simbolo com Shift no canto, glifo sob o rotulo,
// logo do Windows, traco da barra de espaco). As teclas especiais (com `id`)
// sao clicaveis: as do notebook (icone impresso) levam o icone da funcao no
// centro e o nome pequeno no canto (`corner`: "tr" ou "br"); as do Azoth
// (`legend`: a segunda funcao impressa, como RESET ou MODE>) mostram o rotulo
// normal e a legenda pequena embaixo (no meio, na fila dos numeros, onde os
// cantos ja estao ocupados); `kind` "oled" e "knob" desenham o visor e o botao
// do Azoth. Com `lighting` (o rascunho da RgbLightingView) as teclas acendem
// como o efeito escolhido -- a legenda brilha na cor, como num teclado
// retroiluminado -- e os efeitos animados correm na silhueta (respiracao,
// onda, chuva...). E uma ideia do efeito, nao a simulacao do firmware.
// Mesmo papel do MouseDiagram do Naga, mas sem SVG.
Item {
    id: root

    property string selected
    // keys()/size() do layout: [{ id, label, icon, kind, top, glyph, micon, bar, corner, x, y, w, h }], { w, h }
    required property var keys
    required property var size
    // Previa da iluminacao ({ off, mode, colors, random, brightness, speed, direction }); null = so o contorno
    property var lighting: null
    readonly property bool lit: !!root.lighting && !root.lighting.off
    readonly property bool animated: root.lit && root.lighting.mode !== "Static"
    // Cores do rascunho (hex); vazia = roda de cores (random, arco-iris)
    readonly property var litColors: root.lit && !root.lighting.random ? (root.lighting.colors ?? []) : []
    readonly property real litLevel: root.lit ? Math.max(0.15, (root.lighting.brightness ?? 100) / 100) : 0
    // 0..1 = uma volta do efeito; a velocidade do aparelho encurta a volta
    property real phase: 0
    readonly property real unit: root.width > 0 ? root.width / root.size.w : 0
    // metade do respiro entre teclas (0.16u no manual) e raio dos cantos (~0.1u)
    readonly property real gap: root.unit * 0.08
    readonly property real corner: root.unit * 0.1
    readonly property string family: Tokens.font.label.small.family

    signal picked(id: string)

    // Pseudo-aleatorio estavel por tecla (0..1)
    function noise(i: int): real {
        let h = Math.imul(i + 1, 2654435761) >>> 0;
        h = Math.imul(h ^ (h >>> 15), 2246822519) >>> 0;
        return (h % 10007) / 10007;
    }

    // Cor na posicao t (ciclica) de uma lista de hex, interpolando entre
    // vizinhas; lista vazia = roda de cores.
    function colorAt(cols: var, t: real): color {
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

    // Cor e intensidade (0..1) da tecla k (indice i) no instante t do efeito.
    function sample(k: var, i: int, t: real): var {
        const L = root.lighting;
        const cols = root.litColors;
        const nx = (k.x + k.w / 2) / root.size.w;
        const ny = (k.y + k.h / 2) / root.size.h;
        const dir = L.direction || "right";
        const along = dir === "up" || dir === "down" ? ny : nx;
        const sign = dir === "left" || dir === "up" ? 1 : -1;
        let c = root.colorAt(cols, 0);
        let lv = 1;
        switch (L.mode) {
        case "Breathing":
            // duas respiracoes por volta, alternando as cores
            lv = 0.08 + 0.92 * (0.5 - 0.5 * Math.cos(2 * Math.PI * t * 2));
            c = cols.length > 1 ? Qt.color(`#${cols[Math.floor(t * 2) % cols.length]}`) : root.colorAt(cols, Math.floor(t * 2) * 0.37);
            break;
        case "Pulse":
            lv = 0.08 + 0.92 * Math.pow(0.5 - 0.5 * Math.cos(2 * Math.PI * t * 2), 3);
            break;
        case "Spectrum Cycle":
            c = Qt.hsva(t, 0.85, 1, 1);
            break;
        case "Rainbow Wave":
            c = root.colorAt(cols.length > 1 ? cols : [], along + sign * t);
            break;
        case "Quicksand":
            c = root.colorAt(cols, (dir === "up" ? -ny : ny) + t);
            break;
        case "Current":
            c = root.colorAt(cols, nx * 0.5 + t);
            lv = 0.3 + 0.7 * (0.5 + 0.5 * Math.sin(2 * Math.PI * (nx * 2 - t * 2)));
            break;
        case "Reactive": {
            // teclas "apertadas" ao acaso, apagando no passo seguinte
            const step = Math.floor(t * 10);
            const hit = root.noise(i * 7 + step) > 0.9;
            const prev = root.noise(i * 7 + step - 1) > 0.9;
            lv = hit ? 1 : prev ? 0.45 : 0.04;
            c = root.colorAt(cols, root.noise(i + step));
            break;
        }
        case "Ripple": {
            // anel saindo do centro (achatado: o teclado e largo)
            const dist = Math.hypot(nx - 0.5, (ny - 0.5) * 0.4);
            lv = Math.max(0.04, 1 - Math.abs(dist - t * 0.8) * 7);
            c = root.colorAt(cols, t);
            break;
        }
        case "Rain Drop": {
            // uma gota por coluna, cada uma no seu tempo
            const col = Math.floor(nx * 16);
            const y = ((t * 2 + root.noise(col * 13)) % 1) * 1.6 - 0.3;
            lv = Math.max(0.04, 1 - Math.abs(ny - y) * 3.5);
            c = root.colorAt(cols, root.noise(col * 13 + 1));
            break;
        }
        case "Starry Night":
            lv = 0.04 + 0.96 * Math.pow(Math.max(0, Math.sin(2 * Math.PI * (t * 2 + root.noise(i)))), 6);
            c = root.colorAt(cols, root.noise(i * 3 + 2));
            break;
        }
        return { c: c, k: lv * root.litLevel };
    }

    implicitHeight: root.size.h * root.unit

    NumberAnimation on phase {
        from: 0
        to: 1
        loops: Animation.Infinite
        duration: Math.round(8000 * 50 / Math.max(10, root.lighting?.speed ?? 50))
        running: root.animated && root.visible
    }

    Repeater {
        model: root.keys

        Rectangle {
            id: key

            required property var modelData
            required property int index

            readonly property bool special: key.modelData.id !== ""
            readonly property string kind: key.modelData.kind ?? ""
            // Legenda impressa (Azoth): a tecla se desenha como as outras, mais a legenda
            readonly property string legend: key.modelData.legend ?? ""
            readonly property bool iconKey: key.special && key.legend === "" && key.kind !== "oled" && key.kind !== "knob"
            readonly property bool active: key.special && key.modelData.id === root.selected
            // Luz da previa nesta tecla ({ c, k }); o visor e o knob nao acendem
            readonly property var glow: root.lit && key.kind === "" ? root.sample(key.modelData, key.index, root.phase) : null
            readonly property color ink: key.active ? Colours.palette.m3onTertiary : key.glow ? Qt.alpha(Qt.lighter(key.glow.c, 1.2), 0.3 + 0.7 * key.glow.k) : key.special ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            readonly property real inset: root.gap * 1.5

            x: key.modelData.x * root.unit + root.gap
            y: key.modelData.y * root.unit + root.gap
            width: key.modelData.w * root.unit - root.gap * 2
            height: key.modelData.h * root.unit - root.gap * 2
            radius: key.kind === "knob" ? height / 2 : root.corner
            // OLED: um visor preenchido (fica escuro, com o nome); knob: redondo
            color: key.active ? Colours.palette.m3tertiary : key.kind === "oled" ? Colours.palette.m3surfaceContainerHighest : key.glow ? Qt.alpha(key.glow.c, 0.06 + 0.3 * key.glow.k) : "transparent"
            border.width: key.active ? 0 : key.special ? 2 : 1
            border.color: key.glow && !key.active ? Qt.alpha(key.glow.c, 0.25 + 0.75 * key.glow.k) : key.special ? Colours.palette.m3tertiary : Colours.palette.m3outline

            // Tecla comum: rotulo no centro (ou em cima, quando ha glifo ou legenda embaixo)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: key.modelData.glyph || key.legend ? undefined : parent.verticalCenter
                anchors.top: key.modelData.glyph || key.legend ? parent.top : undefined
                anchors.topMargin: key.inset
                visible: !key.iconKey && key.kind === "" && key.modelData.label !== "" && key.modelData.top === ""
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * (key.modelData.label.length > 2 ? 0.17 : 0.3))
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
            }

            // Simbolo com Shift no canto superior esquerdo + rotulo no inferior direito
            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: key.inset
                visible: key.modelData.top !== ""
                text: key.modelData.top
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.22)
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: key.inset
                visible: key.modelData.top !== ""
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.28)
                renderType: Text.NativeRendering
            }

            // Glifo (⇤⇥, ↵, ⇧, ☰, ⟵): embaixo do rotulo, ou no centro se nao ha rotulo
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: key.modelData.label ? parent.bottom : undefined
                anchors.bottomMargin: key.inset
                anchors.verticalCenter: key.modelData.label ? undefined : parent.verticalCenter
                visible: key.modelData.glyph !== ""
                text: key.modelData.glyph
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * (key.modelData.label ? 0.26 : 0.36))
                renderType: Text.NativeRendering
            }

            // Logo do Windows. Text puro (nao MaterialIcon): o StyledText anima a
            // cor, e com a previa mudando a cor a cada quadro ele nunca chegaria la.
            Text {
                anchors.centerIn: parent
                visible: key.modelData.micon !== ""
                text: key.modelData.micon
                color: key.ink
                font: Tokens.font.icon.size(Math.max(6, root.unit * 0.3)).build()
                renderType: Text.NativeRendering
            }

            // Traco da barra de espaco
            Rectangle {
                anchors.centerIn: parent
                visible: key.modelData.bar
                width: root.unit * 0.8
                height: Math.max(1, root.unit * 0.03)
                color: key.ink
            }

            // Tecla especial com icone impresso (notebook): icone da funcao no
            // centro, nome pequeno no canto; o knob so o icone
            Text {
                anchors.centerIn: parent
                visible: key.iconKey || key.kind === "knob"
                text: key.modelData.icon
                color: key.ink
                font: Tokens.font.icon.size(Math.max(6, root.unit * 0.3)).build()
                renderType: Text.NativeRendering
            }

            Text {
                anchors.right: key.kind === "oled" ? undefined : parent.right
                anchors.horizontalCenter: key.kind === "oled" ? parent.horizontalCenter : undefined
                anchors.verticalCenter: key.kind === "oled" ? parent.verticalCenter : undefined
                anchors.top: key.modelData.corner === "tr" && key.kind !== "oled" ? parent.top : undefined
                anchors.bottom: key.modelData.corner === "br" && key.kind !== "oled" ? parent.bottom : undefined
                anchors.margins: root.gap
                visible: key.iconKey || key.kind === "oled"
                text: key.modelData.label
                color: key.ink
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.15)
                renderType: Text.NativeRendering
            }

            // Segunda funcao impressa (Azoth): embaixo no centro, ou no meio
            // quando os cantos ja tem o simbolo com Shift e o rotulo (fila dos numeros)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: key.modelData.top === "" ? parent.bottom : undefined
                anchors.verticalCenter: key.modelData.top !== "" ? parent.verticalCenter : undefined
                anchors.margins: root.gap
                visible: key.legend !== ""
                text: key.legend
                color: key.active ? key.ink : key.glow ? key.ink : Colours.palette.m3tertiary
                font.family: root.family
                font.pixelSize: Math.max(6, root.unit * 0.15)
                renderType: Text.NativeRendering
            }

            MouseArea {
                anchors.fill: parent
                enabled: key.special
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(key.modelData.id)
            }
        }
    }
}
