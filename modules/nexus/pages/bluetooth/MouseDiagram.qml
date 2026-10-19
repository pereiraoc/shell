pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

// Silhueta do mouse com cada botao clicavel em cima dele (Mouse > <mouse> >
// Buttons). O desenho e um SVG de traco preto (assets/mice/<modelo>.svg,
// vetorizado e afinado a partir do PNG em projects-assets/caelestia-assets,
// sem os numeros de dentro das teclas laterais); e rasterizado no tamanho
// real e o Colouriser pinta com a cor do tema (claro no escuro, escuro no
// claro). Cada area e o CONTORNO REAL da peca no desenho (regiao fechada
// extraida do SVG), em unidades da imagem original: escala junto com ela, o
// clique so vale dentro do contorno e o fundo do card aparece por dentro.
Item {
    id: root

    required property string model
    required property var buttons
    // O que o botao faz, dentro da area (laterais); "" = sem texto
    property var labeler: b => ""
    property string selected
    property string hovered

    signal picked(id: string)

    // Por modelo: arquivo, tamanho original e areas (contorno em SVG, centro
    // do texto e, nas laterais, onde vai o numero)
    readonly property var diagrams: ({
            "razer-naga-v2-hyperspeed": {
                source: "assets/mice/razer-naga-v2-hyperspeed.svg",
                w: 356,
                h: 356,
                spots: [
                    // Frente = DPI aumenta (conferido no mouse). Roda = corpo dos
                    // sulcos; topo segue o arco escuro (extraido do desenho); inclinar a roda: faixas fora do canal.
                    // Laterais: contorno = a tecla irregular do desenho. O rotulo
                    // (rx/ry/rw/rh/ra) segue uma grade regular ajustada as 12
                    // teclas (minimos quadrados, erro max 1,1 un.): textos em
                    // linhas paralelas, mesma inclinacao, caixa que cabe na menor.
                    { id: "dpi-up", path: "M33.5 26.6 L32.8 39.8 L31.9 55.4 L31.0 56.5 L29.4 57.4 L23.6 58.2 L21.0 58.2 L18.4 56.5 L17.2 54.1 L17.4 47.9 L19.8 36.9 L21.9 32.9 L23.4 31.0 L32.4 25.5 L33.2 25.4 Z" },
                    { id: "dpi-down", path: "M32.2 63.0 L33.1 74.2 L33.6 87.1 L33.5 88.5 L32.0 90.0 L28.6 91.2 L18.8 91.9 L18.2 91.0 L17.4 84.8 L17.0 76.4 L17.2 67.1 L18.8 65.2 L20.6 64.2 L29.9 62.1 L31.5 62.4 Z" },
                    { id: "middle", path: "M106.9 54.6 L99.2 54.6 L96.0 55.0 L94.8 55.5 L93.8 56.4 L93.0 58.8 L92.9 69.6 L92.1 74.1 L92.5 109.6 L93.8 113.1 L95.4 115.1 L97.5 116.5 L100.8 117.4 L105.2 117.2 L108.0 116.4 L109.6 115.4 L111.5 113.4 L112.5 111.5 L113.1 108.2 L113.1 74.4 L112.0 69.4 L112.0 58.8 L111.6 57.1 L110.5 55.8 L108.9 55.0 Z" },
                    { id: "tilt-left", path: "M 79.5 60.0 L 79.5 60.0 A 3.5 3.5 0 0 1 83.0 63.5 L 83.0 106.5 A 3.5 3.5 0 0 1 79.5 110.0 L 79.5 110.0 A 3.5 3.5 0 0 1 76.0 106.5 L 76.0 63.5 A 3.5 3.5 0 0 1 79.5 60.0 Z" },
                    { id: "tilt-right", path: "M 123.5 60.0 L 123.5 60.0 A 3.5 3.5 0 0 1 127.0 63.5 L 127.0 106.5 A 3.5 3.5 0 0 1 123.5 110.0 L 123.5 110.0 A 3.5 3.5 0 0 1 120.0 106.5 L 120.0 63.5 A 3.5 3.5 0 0 1 123.5 60.0 Z" },
                    { id: "side-1", rx: 257.9, ry: 162.5, rw: 21.0, rh: 15.0, ra: -13.6, path: "M266.0 151.6 L263.0 151.6 L253.9 154.5 L249.0 156.5 L248.8 159.8 L248.0 160.9 L248.2 168.6 L248.6 170.2 L249.9 172.1 L251.6 172.5 L259.4 171.4 L261.8 170.6 L264.9 170.2 L268.2 168.8 L268.8 167.4 L268.6 164.2 L267.4 160.0 L267.1 153.9 Z" },
                    { id: "side-2", rx: 281.6, ry: 156.8, rw: 21.0, rh: 15.0, ra: -13.6, path: "M291.0 146.6 L290.0 146.2 L288.4 146.4 L279.5 148.5 L273.1 150.5 L270.5 152.0 L270.2 157.1 L270.6 161.6 L271.5 165.6 L273.0 167.8 L274.1 167.8 L277.2 166.5 L288.8 164.4 L292.0 163.1 L293.4 161.8 L293.4 159.2 L292.5 156.4 L292.4 149.8 Z" },
                    { id: "side-3", rx: 305.3, ry: 151.1, rw: 21.0, rh: 15.0, ra: -13.6, path: "M311.6 141.5 L307.4 141.2 L299.9 142.2 L296.6 143.4 L294.8 144.9 L294.6 145.9 L295.4 147.2 L295.8 149.9 L295.5 158.4 L296.5 160.9 L297.8 161.5 L299.0 161.5 L304.5 160.4 L310.4 158.4 L314.9 155.9 L315.5 153.4 Z" },
                    { id: "side-4", rx: 261.0, ry: 186.7, rw: 21.0, rh: 15.0, ra: -13.6, path: "M268.8 178.8 L267.1 178.5 L262.1 179.5 L255.6 181.5 L253.1 182.6 L251.9 183.6 L251.6 188.2 L252.9 189.9 L253.2 193.5 L254.4 194.6 L255.8 195.4 L258.6 195.4 L264.1 193.5 L268.2 193.0 L270.2 191.8 L270.2 186.1 L269.5 179.9 Z" },
                    { id: "side-5", rx: 284.7, ry: 181.0, rw: 21.0, rh: 15.0, ra: -13.6, path: "M294.2 173.0 L293.1 172.2 L289.5 172.5 L279.4 174.5 L274.0 176.5 L273.2 177.6 L273.4 182.9 L274.2 186.6 L275.6 188.9 L278.4 188.9 L280.5 187.9 L282.8 187.8 L288.1 186.0 L290.6 185.9 L292.5 185.0 L295.1 184.8 L295.5 184.0 L295.4 178.2 Z" },
                    { id: "side-6", rx: 308.4, ry: 175.2, rw: 21.0, rh: 15.0, ra: -13.6, path: "M318.1 166.4 L316.2 166.4 L306.5 168.4 L299.2 170.4 L298.5 171.0 L298.1 171.9 L298.1 174.2 L299.2 177.9 L299.1 183.4 L299.4 184.5 L300.1 185.2 L301.9 185.4 L318.2 180.2 L320.1 179.2 L320.2 175.0 L319.9 174.2 L319.6 171.0 Z" },
                    { id: "side-7", rx: 264.1, ry: 210.8, rw: 21.0, rh: 15.0, ra: -13.6, path: "M271.9 202.6 L269.9 202.2 L265.9 203.4 L262.2 205.0 L257.5 206.5 L255.0 208.0 L254.9 211.2 L254.4 212.6 L254.9 214.1 L255.9 215.5 L256.0 218.9 L256.4 219.2 L259.9 219.4 L268.0 218.4 L272.2 217.4 L273.4 216.6 L274.0 215.1 L274.0 212.9 L273.5 210.8 L273.5 206.0 L273.1 204.5 Z" },
                    { id: "side-8", rx: 287.8, ry: 205.1, rw: 21.0, rh: 15.0, ra: -13.6, path: "M297.4 198.2 L296.0 197.2 L294.1 197.4 L284.4 199.4 L276.9 201.6 L276.2 202.8 L276.4 208.0 L277.4 212.0 L278.2 213.5 L279.1 214.2 L281.1 214.4 L292.8 211.2 L297.6 209.4 L298.5 208.4 L298.6 206.2 L297.5 203.5 Z" },
                    { id: "side-9", rx: 311.5, ry: 199.4, rw: 21.0, rh: 15.0, ra: -13.6, path: "M322.4 191.6 L320.6 190.2 L306.5 192.4 L301.9 193.6 L301.2 194.8 L301.2 198.5 L301.8 205.1 L302.5 208.6 L303.5 209.4 L305.4 209.4 L316.6 206.2 L323.1 203.6 L323.6 203.1 L323.2 193.5 Z" },
                    { id: "side-10", rx: 267.2, ry: 235.0, rw: 21.0, rh: 15.0, ra: -13.6, path: "M275.4 226.1 L274.1 225.2 L272.6 225.4 L261.8 228.5 L256.8 230.8 L256.2 231.6 L256.2 235.2 L257.4 236.8 L257.5 242.0 L259.8 243.2 L263.9 243.2 L269.1 242.2 L274.8 240.4 L276.6 239.4 L277.2 238.0 L276.4 236.0 L276.4 229.1 Z" },
                    { id: "side-11", rx: 290.9, ry: 229.2, rw: 21.0, rh: 15.0, ra: -13.6, path: "M299.9 219.6 L298.6 219.2 L288.0 221.5 L281.8 223.5 L280.4 225.8 L280.2 229.8 L281.2 234.9 L282.1 236.5 L283.5 237.5 L285.5 237.4 L300.5 233.2 L301.5 231.9 L301.8 228.6 L301.2 222.9 Z" },
                    { id: "side-12", rx: 314.6, ry: 223.5, rw: 21.0, rh: 15.0, ra: -13.6, path: "M321.8 215.2 L311.4 216.4 L306.1 217.5 L303.5 218.9 L303.1 221.2 L304.2 223.9 L304.5 228.8 L305.2 231.2 L306.1 232.2 L307.8 232.4 L314.9 230.1 L316.5 228.6 L319.2 228.1 L321.8 226.2 L322.6 223.5 L323.1 220.0 L323.0 217.5 Z" }
                ]
            }
            ,
            // Razer Atheris: desenho do guia (vista de cima, vetorizado de
            // images/Atheris-00000097-en.pdf); so o que o mouse reporta ao
            // Linux e clicavel: roda (middle) e os dois botoes laterais
            // (forward em cima, back embaixo). O botao de DPI abaixo da roda
            // troca o estagio dentro do mouse e nao chega ao sistema.
            "razer-atheris": {
                source: "assets/mice/razer-atheris.svg",
                w: 215,
                h: 304,
                shownW: 260,
                spots: [
                    { id: "middle", path: "M102.0 45.0 L117.0 45.0 A8 8 0 0 1 125.0 53.0 L125.0 91.0 A8 8 0 0 1 117.0 99.0 L102.0 99.0 A8 8 0 0 1 94.0 91.0 L94.0 53.0 A8 8 0 0 1 102.0 45.0 Z" },
                    { id: "forward", path: "M22.0 106.0 L29.0 106.0 A4 4 0 0 1 33.0 110.0 L33.0 125.0 A4 4 0 0 1 29.0 129.0 L22.0 129.0 A4 4 0 0 1 18.0 125.0 L18.0 110.0 A4 4 0 0 1 22.0 106.0 Z" },
                    { id: "back", path: "M22.0 131.0 L29.0 131.0 A4 4 0 0 1 33.0 135.0 L33.0 150.0 A4 4 0 0 1 29.0 154.0 L22.0 154.0 A4 4 0 0 1 18.0 150.0 L18.0 135.0 A4 4 0 0 1 22.0 131.0 Z" }
                ]
            }
        })

    readonly property var diagram: root.diagrams[root.model] ?? null
    readonly property bool available: root.diagram !== null
    // So as areas de botoes que o mouse reporta agora (travados ficam de fora)
    readonly property var spots: root.available ? root.diagram.spots.filter(s => root.buttons.some(b => b.id === s.id && !b.locked)) : []
    readonly property real k: root.available ? art.width / root.diagram.w : 1

    // Largura em que o desenho fica no tamanho "real" dos outros (um mouse
    // alto como o Atheris pede menos que o Naga, que e quadrado)
    implicitWidth: root.diagram?.shownW ?? 460
    implicitHeight: root.available ? Math.min(root.width, root.implicitWidth) * root.diagram.h / root.diagram.w : 0
    visible: root.available

    Image {
        id: art

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(root.width, root.implicitWidth)
        height: root.implicitHeight
        source: root.available ? Quickshell.shellPath(root.diagram.source) : ""
        fillMode: Image.PreserveAspectFit
        // SVG renderizado no tamanho exibido (x escala da tela): traco nitido
        sourceSize.width: art.width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
        smooth: true
        asynchronous: true

        layer.enabled: true
        layer.effect: Colouriser {
            colorizationColor: Colours.palette.m3onSurfaceVariant
            brightness: 1
        }
    }

    // Areas no mesmo sistema de coordenadas da imagem original
    Item {
        x: art.x
        y: art.y
        width: root.available ? root.diagram.w : 0
        height: root.available ? root.diagram.h : 0
        scale: root.k
        transformOrigin: Item.TopLeft

        Repeater {
            model: root.spots.length

            Item {
                id: spot

                required property int index
                readonly property var spec: root.spots[index] ?? ({})
                readonly property var button: root.buttons.find(b => b.id === spot.spec.id) ?? null
                readonly property bool isSelected: root.selected === spot.spec.id
                readonly property bool remapped: (spot.button?.action ?? "default") !== "default"
                readonly property bool isHovered: hit.containsMouse
                readonly property string label: spot.button ? root.labeler(spot.button) : ""
                readonly property string number: spot.spec.id.startsWith("side-") ? spot.spec.id.split("-")[1] : ""

                anchors.fill: parent

                Shape {
                    id: shape

                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    containsMode: Shape.FillContains

                    // Escolhido: amarelo cheio + halo em volta + halo em volta. Remapeado:
                    // fundo bem leve; mouse em cima: um toque de cor.
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: spot.isSelected ? Qt.alpha(Colours.palette.m3tertiary, 0.45) : "transparent"
                        strokeWidth: 4 / root.k
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: spot.spec.path ?? ""
                        }
                    }

                    ShapePath {
                        // Escolhido: amarelo translucido (numero amarelo e texto
                        // branco continuam legiveis) + halo + borda grossa
                        fillColor: spot.isSelected ? Qt.alpha(Colours.palette.m3tertiary, 0.38) : spot.isHovered ? Qt.alpha(Colours.palette.m3tertiary, 0.16) : spot.remapped ? Qt.alpha(Colours.palette.m3tertiary, 0.14) : "transparent"
                        strokeColor: Colours.palette.m3tertiary
                        strokeWidth: (spot.isSelected ? 2.4 : 1.4) / root.k
                        joinStyle: ShapePath.RoundJoin

                        PathSvg {
                            path: spot.spec.path ?? ""
                        }
                    }
                }

                MouseArea {
                    id: hit

                    anchors.fill: parent
                    containmentMask: shape
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(spot.spec.id)
                    onContainsMouseChanged: {
                        if (hit.containsMouse)
                            root.hovered = spot.spec.id;
                        else if (root.hovered === spot.spec.id)
                            root.hovered = "";
                    }
                }
            }
        }
    }

    // Rotulos no frame de cada tecla lateral (centro, tamanho e inclinacao
    // dela), fora do item escalado: numero no canto superior esquerdo, texto
    // no resto, encolhendo ate caber. Texto em CurveRendering (letras como
    // curvas): nitido inclinado; o nativo ganha franja colorida e girar uma
    // layer pronta serrilha.
    Repeater {
        model: root.spots.length

        Item {
            id: tag

            required property int index
            readonly property var spec: root.spots[index] ?? ({})
            readonly property var button: root.buttons.find(b => b.id === tag.spec.id) ?? null
            readonly property bool isSelected: root.selected === tag.spec.id
            readonly property string label: tag.button ? root.labeler(tag.button) : ""
            readonly property string number: tag.spec.id.startsWith("side-") ? tag.spec.id.split("-")[1] : ""
            readonly property real pad: 2

            visible: tag.label !== "" && tag.spec.rw !== undefined
            x: art.x + ((tag.spec.rx ?? 0) - (tag.spec.rw ?? 0) / 2) * root.k
            y: art.y + ((tag.spec.ry ?? 0) - (tag.spec.rh ?? 0) / 2) * root.k
            width: (tag.spec.rw ?? 0) * root.k
            height: (tag.spec.rh ?? 0) * root.k
            rotation: tag.spec.ra ?? 0

            // Acao com nome comprido: icone no lugar do texto
            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 2
                visible: !tag.isSelected && tag.label.startsWith("icon:")
                text: tag.label.slice(5)
                color: Colours.palette.m3onSurface
                // fontStyle (nao font): mexer em font troca o icone por texto
                fontStyle: Tokens.font.icon.builders.small.scale(0.85).build()
            }

            StyledText {
                id: num

                // Numero pequeno, colado no canto superior esquerdo da tecla
                x: tag.pad + 2
                y: tag.pad - 1
                text: tag.number
                renderType: Text.CurveRendering
                font.pixelSize: 6
                font.weight: Font.Bold
                color: Colours.palette.m3tertiary
            }

            // Texto centrado na caixa (simetrico), um pouco abaixo do numero
            StyledText {
                anchors.fill: parent
                anchors.leftMargin: tag.pad + 3
                anchors.rightMargin: tag.pad + 3
                // Numero em cima no canto, texto na parte de baixo: nao se cruzam
                // "..." do escolhido sobe um pouco (senao vaza por baixo)
                anchors.topMargin: tag.isSelected ? tag.pad : tag.pad + 3
                anchors.bottomMargin: tag.isSelected ? tag.pad + 3 : 0
                // Escolhido: so o numero fica; o texto vira "…" (vai mudar).
                // "icon:<nome>" = icone (camada abaixo), sem texto
                visible: tag.isSelected || !tag.label.startsWith("icon:")
                text: tag.isSelected ? "..." : tag.label
                renderType: Text.CurveRendering
                color: Colours.palette.m3onSurface
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Mesmo tamanho em todas (cabe na tecla mais estreita); so
                // encolhe texto longo de acao do desktop
                fontSizeMode: Text.Fit
                minimumPixelSize: 5
                font.pixelSize: tag.isSelected ? 13 : 9
                font.weight: tag.isSelected ? Font.Black : Font.DemiBold
            }
        }
    }
}
