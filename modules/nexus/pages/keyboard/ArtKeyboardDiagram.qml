pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.services
import "keyLighting.js" as Lit

// Diagrama de um teclado a partir do desenho do fabricante (azothArt.js /
// g16Art.js, gerados do QSG / da silhueta): o chassis e cada keycap sao a
// arte original, vetorizada, pintada na cor do tema. A luz (`lighting`, o
// rascunho da RgbLightingView) aparece como num teclado de verdade: no vao
// entre os keycaps e no bisel de cada um (a celula atras da tecla acende) e
// na serigrafia (a arte do keycap toma a cor da luz); o topo do keycap fica
// opaco. Teclas em `special` sao clicaveis (`picked`); a escolhida ganha o
// topo em tertiary.
Item {
    id: root

    // Biblioteca da arte: { W, H, CHASSIS, RECTS, LINE, SPLIT, KEYS: [{ id, x, y,
    // w, h, f, d, u?, o? }]. Com SPLIT (Azoth) cada tecla tem a parte que
    // acende (`d`: contorno externo, relevo, legenda principal) e a que fica
    // branca (`u`: simbolos Shift e legendas frontais); o contorno do topo do
    // keycap tambem fica branco (desenhado por cima, com a espessura LINE).
    required property var art
    // Chassis como contornos finos (RECTS) em vez da arte (CHASSIS): o QSG do
    // Azoth desenha a carcaca com bordas grossas que viram faixas claras
    property bool thinChassis
    // ids clicaveis
    required property var special
    property string selected
    property var lighting: null
    // Luz atras das teclas: quanto a celula ultrapassa o keycap (fracao da
    // altura) e quanto ela acende -- o teclado do notebook e mais leve
    property real glowPad: 0.07
    property real glowAlpha: 0.5
    // Quanto da cor da luz vai para a serigrafia/contorno aceso (0..1)
    property real inkMix: 0.85
    readonly property bool lit: !!root.lighting && !root.lighting.off
    readonly property bool animated: root.lit && root.lighting.mode !== "Static"
    readonly property var litColors: root.lit ? Lit.colors(root.lighting) : []
    // 0..1 = uma volta do efeito; a velocidade do aparelho encurta a volta
    property real phase: 0
    readonly property real k: root.width > 0 ? root.width / root.art.W : 0
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    // Topo do keycap: um tom acima do fundo da pagina, para ler como peca
    readonly property color face: Colours.palette.m3surfaceContainerLow

    signal picked(id: string)

    // Visor, knob e botao de ligar: nao acendem, nao sao keycaps (sem o tom
    // de tecla clicavel; a arte deles fica na cor do chassis)
    function plain(key: var): bool {
        return key.id === "oled" || key.id === "knob" || key.id === "power";
    }

    function lightable(key: var): bool {
        return key.d !== "" && !root.plain(key);
    }

    implicitHeight: root.art.H * root.k

    NumberAnimation on phase {
        from: 0
        to: 1
        loops: Animation.Infinite
        duration: Math.round(8000 * 50 / Math.max(10, root.lighting?.speed ?? 50))
        running: root.animated && root.visible
    }

    // Tudo desenhado nas unidades da arte e escalado de uma vez
    Item {
        width: root.art.W
        height: root.art.H
        scale: root.k
        transformOrigin: Item.TopLeft

        // Luz atras de cada tecla: a celula um pouco maior que o keycap, para
        // o vao entre teclas acender
        Repeater {
            model: root.art.KEYS

            Rectangle {
                id: cell

                required property var modelData
                required property int index
                readonly property real pad: cell.modelData.h * root.glowPad
                readonly property var glow: root.lit && root.lightable(cell.modelData) ? Lit.sample(root.lighting, root.litColors, (cell.modelData.x + cell.modelData.w / 2) / root.art.W, (cell.modelData.y + cell.modelData.h / 2) / root.art.H, cell.index, root.phase) : null

                x: cell.modelData.x - cell.pad
                y: cell.modelData.y - cell.pad
                width: cell.modelData.w + cell.pad * 2
                height: cell.modelData.h + cell.pad * 2
                radius: cell.pad * 1.5
                antialiasing: true
                color: cell.glow ? Qt.alpha(cell.glow.c, 0.06 + root.glowAlpha * cell.glow.k) : "transparent"
            }
        }

        // Chassis mais discreto que as teclas (grelhas, dobradica, molduras)
        Shape {
            visible: !root.thinChassis
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Qt.alpha(root.ink, 0.55)
                strokeWidth: -1
                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: root.art.CHASSIS
                }
            }
        }

        Repeater {
            model: root.thinChassis ? root.art.RECTS : []

            Rectangle {
                required property var modelData

                x: modelData[0]
                y: modelData[1]
                width: modelData[2]
                height: modelData[3]
                radius: Math.min(width, height) * 0.08
                color: "transparent"
                border.width: 2
                border.color: Qt.alpha(root.ink, 0.7)
            }
        }

        Repeater {
            model: root.art.KEYS

            Item {
                id: key

                required property var modelData
                required property int index
                readonly property bool special: root.special.includes(key.modelData.id)
                readonly property bool plain: root.plain(key.modelData)
                readonly property bool active: key.special && key.modelData.id === root.selected
                readonly property var glow: root.lit && root.lightable(key.modelData) ? Lit.sample(root.lighting, root.litColors, (key.modelData.x + key.modelData.w / 2) / root.art.W, (key.modelData.y + key.modelData.h / 2) / root.art.H, key.index, root.phase) : null
                // Serigrafia: na cor da luz quando acesa; tertiary para a tecla escolhida
                readonly property color inkNow: key.active ? Colours.palette.m3onTertiary : key.glow ? Lit.mix(Colours.palette.m3surfaceContainerHighest, key.glow.c, 0.15 + root.inkMix * key.glow.k) : key.special && !key.plain ? Colours.palette.m3tertiary : key.plain ? Qt.alpha(root.ink, 0.55) : root.ink

                x: key.modelData.x
                y: key.modelData.y
                width: key.modelData.w
                height: key.modelData.h

                // Topo do keycap: opaco (a luz nao atravessa o plastico), com o
                // destaque das teclas clicaveis / da escolhida; visor, knob e
                // botao de ligar ficam no fundo da pagina
                Rectangle {
                    x: key.modelData.f[0]
                    y: key.modelData.f[1]
                    width: key.modelData.f[2]
                    height: key.modelData.f[3]
                    radius: Math.min(width, height) * 0.08
                    antialiasing: true
                    // O visor fica por cima da arte: a tela e escura, so a moldura aparece
                    z: key.modelData.id === "oled" ? 1 : 0
                    color: key.modelData.d === "" ? (key.active ? Qt.alpha(Colours.palette.m3tertiary, 0.25) : "transparent") : key.plain ? (key.active ? Qt.alpha(Colours.palette.m3tertiary, 0.25) : Colours.palette.m3surface) : key.active ? Colours.palette.m3tertiary : key.special ? Qt.tint(root.face, Qt.alpha(Colours.palette.m3tertiary, 0.14)) : root.face
                    border.width: key.modelData.d === "" ? 2 : 0
                    border.color: key.active ? Colours.palette.m3tertiary : Qt.alpha(root.ink, 0.55)
                }

                Shape {
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: key.inkNow
                        strokeWidth: -1
                        fillRule: ShapePath.OddEvenFill

                        PathSvg {
                            path: key.modelData.d
                        }
                    }
                }

                // Contorno do topo do keycap: nao acende (fica na cor do
                // traco). Linha fina, por fora da caixa do topo -- e onde a
                // linha do desenho esta; so recolore, nao engrossa
                Rectangle {
                    readonly property real lw: 1.8

                    visible: !!root.art.SPLIT && !key.plain && key.modelData.d !== ""
                    x: key.modelData.f[0] - lw
                    y: key.modelData.f[1] - lw
                    width: key.modelData.f[2] + lw * 2
                    height: key.modelData.f[3] + lw * 2
                    radius: Math.min(width, height) * 0.06
                    antialiasing: true
                    color: "transparent"
                    border.width: lw
                    border.color: key.active ? Colours.palette.m3onTertiary : root.ink
                }

                // Legendas que nao acendem (Shift e frontais)
                Shape {
                    visible: !!key.modelData.u
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        fillColor: key.active ? Colours.palette.m3onTertiary : root.ink
                        strokeWidth: -1
                        fillRule: ShapePath.OddEvenFill

                        PathSvg {
                            path: key.modelData.u ?? ""
                        }
                    }
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
}
