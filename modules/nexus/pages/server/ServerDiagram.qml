pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "server.js" as S

// O UGREEN DXP4800 Plus no traco dos outros diagramas (LaptopLidDiagram,
// SetupDiagram), 760 x 720 unidades, desenhado pelas fotos e pelo manual
// guardados em caelestia-assets ("UGREEN DXP4800 Plus Front/Rear/Bottom*.png"):
//   frente  (0..360 x 0..360)   quatro gavetas numeradas 01-04 com a trava embaixo;
//                               faixa inferior: botao, LEDs LAN + DISK1-4, SD, USB-C, USB3.2
//   tras    (400..760 x 0..360) grade quadrada da ventoinha; fileira HDMI, USB3.2, 2x USB2.0,
//                               LAN 2, LAN 1, RESET, DC 19V; quatro parafusos
//   fundo   (0..360 x 384..903)  so com `bottomExpanded`: a placa de baixo NA MESMA LARGURA da frente
//                               (178 x 257 mm reais, desenho do manual 555x800 -> 360x519), como desenho
//                               tecnico: pes, tampa de servico com 2x M.2 (vertical, esquerda) e os 2
//                               slots de memoria empilhados (direita, modulo instalado no slot 1), etiqueta
// Pecas que o NAS reporta sao clicaveis e pintam o estado:
//   bay-1..4   gavetas (porta SATA n = baia n)      -> disco, SMART, temperatura
//   power      botao; led-net LED "LAN"
//   fan        ventoinha (rpm); lan-10g = LAN 2 (atlantic), lan-2g5 = LAN 1 (igc) -- ordem fisica
//              das duas portas a confirmar com o cabo em casa (nas-status diz qual tem link)
//   m2-1/m2-2  slots NVMe (sistema; Lexar quando chegar); ram-1/ram-2 memoria (8 GB; ADATA pendente)
// `picked(id)` e `hovered` (a pagina mostra a legenda embaixo).
Item {
    id: root

    // data do caelestia-nas status (online, disks, net, fans, mem, uptime_s)
    required property var info
    property string selected
    property string hovered
    // Mostra a vista de baixo (M.2 e memoria) embaixo da frente, em escala real
    property bool bottomExpanded: false

    readonly property bool online: root.info.online === true
    readonly property var bays: S.bayMap(root.info.disks)
    readonly property var m2: S.m2Slots(root.info.disks)
    readonly property var lan10: S.lanPort(root.info.net, "atlantic")
    readonly property var lan25: S.lanPort(root.info.net, "igc")
    readonly property var fans: root.info.fans ?? null
    readonly property var mem: root.info.mem ?? null

    readonly property real k: root.width / 760
    // Rotulos miudos das portas (LAN, DISK1.., HDMI..) so quando o desenho e grande o bastante
    // para serem legiveis; antes disso a legenda por hover faz o papel.
    readonly property bool labels: root.k >= 1.1
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property string family: Tokens.font.label.small.family
    // Numeros das gavetas: condensada alta e pesada, como a serigrafia
    readonly property string numFamily: "Nimbus Sans Narrow"

    signal picked(id: string)

    function stateColor(id: string, on: bool, bad: bool): color {
        if (root.selected === id)
            return Colours.palette.m3tertiary;
        if (bad)
            return Colours.palette.m3error;
        if (root.hovered === id)
            return Colours.palette.m3tertiary;
        return on ? Colours.palette.m3primary : root.faint;
    }

    function fill(id: string, on: bool, bad: bool): color {
        if (root.selected === id)
            return Qt.alpha(Colours.palette.m3tertiary, 0.22);
        if (root.hovered === id)
            return Qt.alpha(Colours.palette.m3tertiary, 0.12);
        if (bad)
            return Qt.alpha(Colours.palette.m3error, 0.18);
        return on ? Qt.alpha(Colours.palette.m3primary, 0.14) : "transparent";
    }

    function diskOn(d: var): bool {
        return root.online && !!d;
    }

    function diskBad(d: var): bool {
        return !!d && d.smart === "FAILED";
    }

    function small(px: real): real {
        return Math.max(5, px * root.k);
    }

    implicitHeight: (root.bottomExpanded ? 384 + 519 : 360) * root.k

    // ================================================================ FRENTE
    // Carcaca: moldura externa e a face recuada (a faixa entre as duas e o que
    // se ve nos cantos da foto); so linhas, como os outros diagramas
    Chassis {
        x: 0
    }

    // Gaveteiro: caixa recuada com a barra grossa em cima (as gavetas comecam
    // 16 un abaixo do topo dela)
    Rectangle {
        x: 36 * root.k
        y: 28 * root.k
        width: 288 * root.k
        height: 240 * root.k
        radius: 12 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // As 4 gavetas: tampa em cima (linha), face com o numero e a capacidade,
    // divisa e a base com a trava redonda; so a gaveta com disco/escolhida tem
    // tom (cor de estado)
    Repeater {
        model: 4

        Item {
            id: bay

            required property int index
            readonly property int n: bay.index + 1
            readonly property string spotId: `bay-${bay.n}`
            readonly property var disk: root.bays[bay.n] ?? null
            readonly property bool on: root.diskOn(bay.disk)
            readonly property bool bad: root.diskBad(bay.disk)
            readonly property bool lit: root.selected === bay.spotId || root.hovered === bay.spotId

            x: (44 + bay.index * 72) * root.k
            y: 44 * root.k
            width: 60 * root.k
            height: 216 * root.k

            // Contorno da gaveta inteira
            Rectangle {
                anchors.fill: bay
                radius: 7 * root.k
                color: "transparent"
                border.width: root.selected === bay.spotId ? Math.max(1, 1.6 * root.k) : 1
                border.color: root.stateColor(bay.spotId, bay.on, bay.bad)
            }

            // Tom de estado (disco presente, escolhida, falha) na face da gaveta
            Rectangle {
                x: 1
                y: 7 * root.k
                width: bay.width - 2
                height: 155 * root.k
                radius: 4 * root.k
                visible: bay.lit || bay.on || bay.bad
                color: root.fill(bay.spotId, bay.on, bay.bad)
            }

            // Tampa: a linha onde a face comeca
            Rectangle {
                x: 0
                y: 7 * root.k
                width: bay.width
                height: 1
                color: root.faint
            }

            // Numero, em condensada alta como a impressa
            Text {
                anchors.horizontalCenter: bay.horizontalCenter
                y: 59 * root.k - height / 2
                text: `0${bay.n}`
                color: bay.on ? root.stateColor(bay.spotId, bay.on, bay.bad) : root.ink
                font.family: root.numFamily
                font.pixelSize: root.small(38)
                font.weight: Font.Bold
                renderType: Text.NativeRendering
            }

            Text {
                anchors.horizontalCenter: bay.horizontalCenter
                y: 136 * root.k
                visible: !!bay.disk
                text: bay.disk ? `${Math.round((bay.disk.size ?? 0) / 1e12)} TB` : ""
                color: root.stateColor(bay.spotId, bay.on, bay.bad)
                font.family: root.family
                font.pixelSize: root.small(8)
                renderType: Text.NativeRendering
            }

            // Divisa entre a face clara e a base preta
            Rectangle {
                x: 0
                y: 162 * root.k
                width: bay.width
                height: 1
                color: root.faint
            }

            // Trava (disco com fenda) na base
            Rectangle {
                id: lock

                anchors.horizontalCenter: bay.horizontalCenter
                y: 178 * root.k
                width: 20 * root.k
                height: 20 * root.k
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: bay.on ? root.stateColor(bay.spotId, bay.on, bay.bad) : root.faint

                Rectangle {
                    anchors.centerIn: lock
                    width: 2 * root.k
                    height: 10 * root.k
                    color: bay.on ? root.stateColor(bay.spotId, bay.on, bay.bad) : root.faint
                }
            }

            Spot {
                anchors.fill: bay
                spotId: bay.spotId
            }
        }
    }

    // Painel inferior e, abaixo dele, a barra com o nome: duas linhas na
    // largura da face
    Repeater {
        model: [272, 326]

        Rectangle {
            required property int modelData

            x: 8 * root.k
            y: modelData * root.k
            width: 344 * root.k
            height: 1
            color: root.faint
        }
    }

    Text {
        x: 0
        y: 335 * root.k - height / 2
        width: 360 * root.k
        horizontalAlignment: Text.AlignHCenter
        text: "DXP4800 Plus"
        color: root.faint
        font.family: root.family
        font.pixelSize: root.small(8)
        font.letterSpacing: 0.5 * root.k
        renderType: Text.NativeRendering
    }

    // Botao de energia (pilula com o traco)
    Rectangle {
        id: power

        x: 49 * root.k
        y: 301 * root.k
        width: 28 * root.k
        height: 11 * root.k
        radius: height / 2
        color: root.fill("power", root.online, false)
        border.width: 1
        border.color: root.stateColor("power", root.online, false)

        Rectangle {
            anchors.centerIn: power
            width: 8 * root.k
            height: 2 * root.k
            color: root.stateColor("power", root.online, false)
        }

        Spot {
            anchors.fill: power
            anchors.margins: -5
            spotId: "power"
        }
    }

    // LEDs: LAN, DISK1..DISK4 (passo de 12 un como na foto), rotulo sob cada um
    Repeater {
        model: 5

        Item {
            id: led

            required property int index
            readonly property var disk: led.index >= 1 ? (root.bays[led.index] ?? null) : null
            readonly property bool on: led.index === 0 ? root.online && !!(root.lan10?.up || root.lan25?.up) : root.diskOn(led.disk)
            readonly property bool bad: led.index >= 1 && root.diskBad(led.disk)
            readonly property string spotId: led.index === 0 ? "led-net" : `bay-${led.index}`

            x: (92 + led.index * 12.2) * root.k
            y: 300 * root.k
            width: 12.2 * root.k
            height: 20 * root.k

            Rectangle {
                anchors.horizontalCenter: led.horizontalCenter
                y: 4 * root.k
                width: 5 * root.k
                height: 5 * root.k
                radius: width / 2
                color: led.on || led.bad ? root.stateColor(led.spotId, led.on, led.bad) : "transparent"
                border.width: 1
                border.color: root.stateColor(led.spotId, led.on, led.bad)
            }

            Text {
                anchors.horizontalCenter: led.horizontalCenter
                y: 12 * root.k
                visible: root.labels
                text: led.index === 0 ? "LAN" : `DISK${led.index}`
                color: root.faint
                font.family: root.family
                font.pixelSize: root.small(3.2)
                renderType: Text.NativeRendering
            }

            Spot {
                anchors.fill: led
                spotId: led.spotId
            }
        }
    }

    // SD, USB-C, USB3.2 (so desenho) com os rotulos
    Rectangle {
        id: sd

        x: 188 * root.k
        y: 303 * root.k
        width: 50 * root.k
        height: 7 * root.k
        radius: 2 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint

        Repeater {
            model: 9

            Rectangle {
                required property int index

                x: (4 + index * 5.2) * root.k
                y: 2 * root.k
                width: 2 * root.k
                height: 3 * root.k
                color: root.faint
            }
        }
    }

    Rectangle {
        x: 255 * root.k
        y: 303 * root.k
        width: 15 * root.k
        height: 7 * root.k
        radius: 3.5 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        id: usba

        x: 288 * root.k
        y: 301 * root.k
        width: 23 * root.k
        height: 11 * root.k
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint

        Rectangle {
            x: 4 * root.k
            y: 3 * root.k
            width: 15 * root.k
            height: 4 * root.k
            color: root.faint
            opacity: 0.6
        }
    }

    Repeater {
        model: [{ x: 188, w: 50, t: "SD" }, { x: 255, w: 15, t: "USB-C" }, { x: 288, w: 23, t: "USB3.2" }]

        Text {
            required property var modelData

            visible: root.labels
            x: modelData.x * root.k
            y: 313 * root.k
            width: modelData.w * root.k
            horizontalAlignment: Text.AlignHCenter
            text: modelData.t
            color: root.faint
            font.family: root.family
            font.pixelSize: root.small(3.2)
            renderType: Text.NativeRendering
        }
    }

    // ================================================================= TRAS
    Chassis {
        x: 400 * root.k
    }

    // Parafusos dos cantos da face
    Repeater {
        model: [{ x: 424, y: 24 }, { x: 736, y: 24 }, { x: 424, y: 336 }, { x: 736, y: 336 }]

        Rectangle {
            required property var modelData

            x: (modelData.x - 4) * root.k
            y: (modelData.y - 4) * root.k
            width: 8 * root.k
            height: 8 * root.k
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    // Grade quadrada da ventoinha: aneis concentricos e o UGREEN grande no meio
    Item {
        id: fan

        readonly property bool on: root.online && !!(root.fans?.case_rpm)

        x: 448 * root.k
        y: 32 * root.k
        width: 264 * root.k
        height: 250 * root.k

        Rectangle {
            anchors.fill: fan
            radius: 22 * root.k
            color: root.fill("fan", fan.on, false)
            border.width: Math.max(1, 1.4 * root.k)
            border.color: root.stateColor("fan", fan.on, false)
        }

        Repeater {
            model: 9

            Rectangle {
                required property int index

                readonly property real d: (40 + index * 25) * root.k

                x: (fan.width - d) / 2
                y: (fan.height - d) / 2
                width: d
                height: d
                radius: d / 2
                color: "transparent"
                border.width: 1
                border.color: root.faint
                opacity: 0.6
            }
        }

        Text {
            anchors.centerIn: fan
            text: "UGREEN"
            color: root.ink
            font.family: root.family
            font.pixelSize: root.small(24)
            font.weight: Font.Bold
            font.letterSpacing: 3 * root.k
            renderType: Text.NativeRendering
        }

        Text {
            anchors.horizontalCenter: fan.horizontalCenter
            y: fan.height - 22 * root.k
            text: fan.on ? `${Math.round(root.fans.case_rpm)} rpm` : ""
            color: root.stateColor("fan", fan.on, false)
            font.family: root.family
            font.pixelSize: root.small(8)
            renderType: Text.NativeRendering
        }

        Spot {
            anchors.fill: fan
            spotId: "fan"
        }
    }

    // Fileira de portas: HDMI, USB3.2, USB2.0 x2, LAN 2, LAN 1, RESET, DC 19V
    Rectangle {
        x: 451 * root.k
        y: 303 * root.k
        width: 26 * root.k
        height: 10 * root.k
        radius: 3 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 498 * root.k
        y: 302 * root.k
        width: 18 * root.k
        height: 12 * root.k
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint

        Rectangle {
            x: 3 * root.k
            y: 3 * root.k
            width: 12 * root.k
            height: 4 * root.k
            color: root.faint
            opacity: 0.6
        }
    }

    Repeater {
        model: [292, 307]

        Rectangle {
            required property int modelData

            x: 547 * root.k
            y: modelData * root.k
            width: 20 * root.k
            height: 10 * root.k
            radius: 1 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    // LAN 2 (10 GbE, atlantic) e LAN 1 (2,5 GbE, igc): ordem fisica a confirmar com o cabo
    Repeater {
        model: [{ id: "lan-10g", x: 588, port: root.lan10 }, { id: "lan-2g5", x: 632, port: root.lan25 }]

        Item {
            id: rj

            required property var modelData
            readonly property bool on: root.online && !!(rj.modelData.port?.up)

            x: rj.modelData.x * root.k
            y: 298 * root.k
            width: 30 * root.k
            height: 23 * root.k

            Rectangle {
                anchors.fill: rj
                radius: 2 * root.k
                color: root.fill(rj.modelData.id, rj.on, false)
                border.width: 1
                border.color: root.stateColor(rj.modelData.id, rj.on, false)
            }

            // Trava do RJ45 e o LED de link
            Rectangle {
                x: 10 * root.k
                y: 16 * root.k
                width: 10 * root.k
                height: 6 * root.k
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }

            Rectangle {
                x: 3 * root.k
                y: 3 * root.k
                width: 3 * root.k
                height: 3 * root.k
                radius: width / 2
                color: rj.on ? root.stateColor(rj.modelData.id, rj.on, false) : "transparent"
                border.width: 1
                border.color: root.faint
            }

            Spot {
                anchors.fill: rj
                anchors.margins: -3
                spotId: rj.modelData.id
            }
        }
    }

    Rectangle {
        x: 676 * root.k
        y: 308 * root.k
        width: 4 * root.k
        height: 4 * root.k
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        id: dc

        x: 696 * root.k
        y: 301 * root.k
        width: 18 * root.k
        height: 18 * root.k
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.faint

        Rectangle {
            anchors.centerIn: dc
            width: 5 * root.k
            height: 5 * root.k
            radius: width / 2
            color: root.faint
        }
    }

    Repeater {
        model: [{ x: 451, w: 26, t: "HDMI" }, { x: 498, w: 18, t: "USB3.2" }, { x: 547, w: 20, t: "USB2.0" }, { x: 588, w: 30, t: "LAN 2" }, { x: 632, w: 30, t: "LAN 1" }, { x: 668, w: 20, t: "RESET" }, { x: 696, w: 18, t: "DC 19V" }]

        Text {
            required property var modelData

            visible: root.labels
            x: modelData.x * root.k
            y: 325 * root.k
            width: modelData.w * root.k
            horizontalAlignment: Text.AlignHCenter
            text: modelData.t
            color: root.faint
            font.family: root.family
            font.pixelSize: root.small(3.2)
            renderType: Text.NativeRendering
        }
    }

    // Velocidade da porta com cabo (vem do nas-status)
    Repeater {
        model: [{ x: 588, port: root.lan10, id: "lan-10g" }, { x: 632, port: root.lan25, id: "lan-2g5" }]

        Text {
            required property var modelData

            visible: root.online && !!(modelData.port?.up)
            x: (modelData.x - 2) * root.k
            y: 288 * root.k
            width: 34 * root.k
            horizontalAlignment: Text.AlignHCenter
            text: modelData.port?.speed_mbps ? (modelData.port.speed_mbps >= 1000 ? `${modelData.port.speed_mbps / 1000}G` : `${modelData.port.speed_mbps}M`) : ""
            color: root.stateColor(modelData.id, true, false)
            font.family: root.family
            font.pixelSize: root.small(5)
            renderType: Text.NativeRendering
        }
    }

    // ================================================================ FUNDO
    Item {
        id: bottom

        // 555 x 800 do desenho do manual -> 360 x 519 unidades (mesma largura da frente)
        readonly property real s: 360 / 555
        readonly property real u: bottom.s * root.k

        visible: root.bottomExpanded
        x: 0
        y: 384 * root.k
        width: 360 * root.k
        height: 519 * root.k

        Rectangle {
            anchors.fill: bottom
            radius: 6 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }

        Text {
            x: 0
            y: -14 * root.k
            width: bottom.width
            horizontalAlignment: Text.AlignHCenter
            text: "UNDERSIDE · 178 × 257 mm · M.2 × 2 · RAM × 2"
            color: root.faint
            font.family: root.family
            font.pixelSize: root.small(7)
            font.letterSpacing: 1 * root.k
            renderType: Text.NativeRendering
        }

        // Pes (ovais) nos quatro cantos
        Repeater {
            model: [{ x: 65, y: 115 }, { x: 490, y: 115 }, { x: 65, y: 685 }, { x: 490, y: 685 }]

            Rectangle {
                required property var modelData

                x: (modelData.x - 7) * bottom.u
                y: (modelData.y - 22) * bottom.u
                width: 14 * bottom.u
                height: 44 * bottom.u
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }
        }

        // Tampa de servico (com os 4 parafusos)
        Rectangle {
            x: 70 * bottom.u
            y: 205 * bottom.u
            width: 415 * bottom.u
            height: 285 * bottom.u
            radius: 8 * bottom.u
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }

        Repeater {
            model: [{ x: 82, y: 217 }, { x: 473, y: 217 }, { x: 82, y: 478 }, { x: 473, y: 478 }]

            Rectangle {
                required property var modelData

                x: (modelData.x - 6) * bottom.u
                y: (modelData.y - 6) * bottom.u
                width: 12 * bottom.u
                height: 12 * bottom.u
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }
        }

        // 2x M.2 na vertical (esquerda): M.2 1 = sistema, M.2 2 = Lexar quando chegar
        Repeater {
            model: 2

            Item {
                id: slot

                required property int index
                readonly property string spotId: `m2-${slot.index + 1}`
                readonly property var disk: root.m2[slot.index] ?? null
                readonly property bool on: root.diskOn(slot.disk)
                readonly property bool bad: root.diskBad(slot.disk)

                x: (85 + slot.index * 80) * bottom.u
                y: 225 * bottom.u
                width: 75 * bottom.u
                height: 245 * bottom.u

                Rectangle {
                    anchors.fill: slot
                    radius: 3 * root.k
                    color: root.fill(slot.spotId, slot.on, slot.bad)
                    border.width: 1
                    border.color: root.stateColor(slot.spotId, slot.on, slot.bad)
                }

                // Conector em cima, parafuso no meio
                Rectangle {
                    x: 6 * bottom.u
                    y: 0
                    width: slot.width - 12 * bottom.u
                    height: 10 * bottom.u
                    color: slot.on ? root.stateColor(slot.spotId, slot.on, slot.bad) : root.faint
                    opacity: 0.6
                }

                Rectangle {
                    anchors.horizontalCenter: slot.horizontalCenter
                    y: 115 * bottom.u
                    width: 12 * bottom.u
                    height: 12 * bottom.u
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: root.faint
                }

                Text {
                    x: 0
                    y: 150 * bottom.u
                    width: slot.width
                    horizontalAlignment: Text.AlignHCenter
                    text: `M.2 ${slot.index + 1}`
                    color: slot.on ? root.stateColor(slot.spotId, slot.on, slot.bad) : root.ink
                    font.family: root.family
                    font.pixelSize: root.small(8)
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }

                Text {
                    x: 0
                    y: 175 * bottom.u
                    width: slot.width
                    horizontalAlignment: Text.AlignHCenter
                    text: slot.disk ? `${Math.round((slot.disk.size ?? 0) / 1e9)} GB` : (slot.index === 1 ? "empty · Lexar" : "empty")
                    color: slot.on ? root.stateColor(slot.spotId, slot.on, slot.bad) : root.faint
                    font.family: root.family
                    font.pixelSize: root.small(6)
                    renderType: Text.NativeRendering
                }

                Spot {
                    anchors.fill: slot
                    spotId: slot.spotId
                }
            }
        }

        // Memoria: dois conectores empilhados (RAM 1 embaixo, com o modulo instalado; RAM 2 em cima, vazio)
        Item {
            id: ram2

            readonly property string spotId: "ram-2"

            x: 250 * bottom.u
            y: 235 * bottom.u
            width: 210 * bottom.u
            height: 22 * bottom.u

            Rectangle {
                anchors.fill: ram2
                radius: 2 * root.k
                color: root.fill(ram2.spotId, false, false)
                border.width: 1
                border.color: root.stateColor(ram2.spotId, false, false)
            }

            Text {
                anchors.centerIn: ram2
                text: "RAM 2 · empty"
                color: root.stateColor(ram2.spotId, false, false)
                font.family: root.family
                font.pixelSize: root.small(6)
                renderType: Text.NativeRendering
            }

            Spot {
                anchors.fill: ram2
                anchors.margins: -2
                spotId: ram2.spotId
            }
        }

        Item {
            id: ram1

            readonly property string spotId: "ram-1"
            readonly property bool on: root.online

            x: 250 * bottom.u
            y: 265 * bottom.u
            width: 210 * bottom.u
            height: 92 * bottom.u

            // Conector
            Rectangle {
                x: 0
                y: 0
                width: ram1.width
                height: 22 * bottom.u
                radius: 2 * root.k
                color: root.fill(ram1.spotId, ram1.on, false)
                border.width: 1
                border.color: root.stateColor(ram1.spotId, ram1.on, false)
            }

            // Modulo instalado
            Rectangle {
                id: module

                x: 5 * bottom.u
                y: 22 * bottom.u
                width: ram1.width - 10 * bottom.u
                height: 70 * bottom.u
                radius: 2 * root.k
                color: root.fill(ram1.spotId, ram1.on, false)
                border.width: 1
                border.color: root.stateColor(ram1.spotId, ram1.on, false)

                Text {
                    anchors.centerIn: module
                    text: root.mem && root.mem.total ? `RAM 1 · ${Math.round(root.mem.total / 1024)} GB` : "RAM 1 · installed"
                    color: root.stateColor(ram1.spotId, ram1.on, false)
                    font.family: root.family
                    font.pixelSize: root.small(7)
                    font.weight: Font.DemiBold
                    renderType: Text.NativeRendering
                }
            }

            Spot {
                anchors.fill: ram1
                spotId: ram1.spotId
            }
        }

        Repeater {
            model: [{ x: 275, y: 375 }, { x: 450, y: 375 }]

            Rectangle {
                required property var modelData

                x: (modelData.x - 6) * bottom.u
                y: (modelData.y - 6) * bottom.u
                width: 12 * bottom.u
                height: 12 * bottom.u
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }
        }

        // Etiqueta
        Rectangle {
            id: label

            x: 125 * bottom.u
            y: 615 * bottom.u
            width: 300 * bottom.u
            height: 105 * bottom.u
            radius: 6 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.faint

            Text {
                anchors.centerIn: label
                text: "DXP4800 Plus · SN EC752JJ042613F7C"
                color: root.faint
                font.family: root.family
                font.pixelSize: root.small(6)
                renderType: Text.NativeRendering
            }
        }
    }

    // Carcaca de 360 x 360: moldura externa e a face recuada 8 un, com raio
    // menor -- a faixa entre as duas e o que se ve nos cantos da foto
    component Chassis: Item {
        width: 360 * root.k
        height: 360 * root.k

        Rectangle {
            anchors.fill: parent
            radius: 24 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 8 * root.k
            radius: 18 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    component Spot: MouseArea {
        id: spot

        required property string spotId

        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked(spot.spotId)
        onContainsMouseChanged: {
            if (spot.containsMouse)
                root.hovered = spot.spotId;
            else if (root.hovered === spot.spotId)
                root.hovered = "";
        }
    }
}
