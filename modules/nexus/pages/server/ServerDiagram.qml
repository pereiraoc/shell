pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "server.js" as S

// O UGREEN DXP4800 Plus no traco dos outros diagramas (LaptopLidDiagram,
// SetupDiagram): frente, traseira e a tampa de baixo com os M.2, 760 x 440
// unidades. Desenhado a mao a partir do aparelho (sem silhueta do usuario em
// caelestia-assets ainda; se uma "UGREEN DXP4800 Plus Silhouette.png" aparecer
// la, scripts/art/trace.py troca o traco mantendo estes ids). Cada peca que o
// NAS reporta e clicavel e pinta o estado:
//   bay-1..4  baias da frente (porta SATA n = baia n)  -> disco, SMART, temperatura
//   m2-1/m2-2 slots NVMe de baixo (sistema; Lexar quando chegar)
//   power     botao + LED de energia (ligado/fora do alcance)
//   led-net   LED de rede; lan-10g / lan-2g5 as portas de tras (link, velocidade, IP)
//   fan       ventoinha traseira (rpm)
// `picked(id)` e `hovered` (a pagina mostra a legenda embaixo).
Item {
    id: root

    // data do caelestia-nas status (online, disks, net, fans, uptime_s)
    required property var info
    property string selected
    property string hovered

    readonly property bool online: root.info.online === true
    readonly property var bays: S.bayMap(root.info.disks)
    readonly property var m2: S.m2Slots(root.info.disks)
    readonly property var lan10: S.lanPort(root.info.net, "atlantic")
    readonly property var lan25: S.lanPort(root.info.net, "igc")
    readonly property var fans: root.info.fans ?? null

    readonly property real k: root.width / 760
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property color face: Colours.palette.m3surfaceContainerLow
    readonly property string family: Tokens.font.label.small.family

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

    implicitHeight: 440 * root.k


    // ------------------------------------------------------------------ frente
    Rectangle {
        x: 0
        y: 0
        width: 360 * root.k
        height: 360 * root.k
        radius: 10 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.ink
    }

    // Coluna da esquerda: botao, LEDs, USB-C, USB-A, SD
    Rectangle {
        x: 12 * root.k
        y: 12 * root.k
        width: 72 * root.k
        height: 336 * root.k
        radius: 6 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        id: power

        x: 34 * root.k
        y: 26 * root.k
        width: 28 * root.k
        height: 28 * root.k
        radius: width / 2
        color: root.fill("power", root.online, false)
        border.width: Math.max(1, 1.5 * root.k)
        border.color: root.stateColor("power", root.online, false)

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.32
            height: width
            radius: width / 2
            color: root.stateColor("power", root.online, false)
        }

        Spot {
            anchors.fill: parent
            anchors.margins: -6
            spotId: "power"
        }
    }

    // LEDs: energia, rede, discos 1-4
    Repeater {
        model: 6

        Rectangle {
            id: led

            required property int index
            readonly property var disk: led.index >= 2 ? (root.bays[led.index - 1] ?? null) : null
            readonly property bool on: led.index === 0 ? root.online : led.index === 1 ? !!(root.lan10?.up || root.lan25?.up) : root.diskOn(led.disk)
            readonly property bool bad: led.index >= 2 && root.diskBad(led.disk)
            readonly property string spotId: led.index === 0 ? "power" : led.index === 1 ? "led-net" : `bay-${led.index - 1}`

            x: 44 * root.k
            y: (76 + led.index * 22) * root.k
            width: 8 * root.k
            height: 8 * root.k
            radius: width / 2
            color: led.on || led.bad ? root.stateColor(led.spotId, led.on, led.bad) : "transparent"
            border.width: 1
            border.color: root.stateColor(led.spotId, led.on, led.bad)

            Spot {
                anchors.fill: parent
                anchors.margins: -6
                spotId: led.spotId
            }
        }
    }

    Repeater {
        model: [{ y: 76, t: "PWR" }, { y: 98, t: "NET" }, { y: 120, t: "1" }, { y: 142, t: "2" }, { y: 164, t: "3" }, { y: 186, t: "4" }]

        Text {
            required property var modelData

            x: 58 * root.k
            y: (modelData.y - 2) * root.k
            text: modelData.t
            color: root.faint
            font.family: root.family
            font.pixelSize: Math.max(5, 7 * root.k)
            renderType: Text.NativeRendering
        }
    }

    // USB-C, USB-A e SD (so desenho)
    Rectangle {
        x: 40 * root.k
        y: 236 * root.k
        width: 16 * root.k
        height: 6 * root.k
        radius: 3 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 38 * root.k
        y: 262 * root.k
        width: 20 * root.k
        height: 9 * root.k
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 34 * root.k
        y: 318 * root.k
        width: 28 * root.k
        height: 4 * root.k
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // As 4 baias
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

            x: (96 + bay.index * 65) * root.k
            y: 18 * root.k
            width: 57 * root.k
            height: 324 * root.k

            Rectangle {
                anchors.fill: parent
                radius: 4 * root.k
                color: root.fill(bay.spotId, bay.on, bay.bad)
                border.width: root.selected === bay.spotId ? Math.max(1, 1.6 * root.k) : 1
                border.color: root.stateColor(bay.spotId, bay.on, bay.bad)
            }

            // Alca da gaveta com a trava
            Rectangle {
                x: 8 * root.k
                y: 12 * root.k
                width: 41 * root.k
                height: 14 * root.k
                radius: 3 * root.k
                color: "transparent"
                border.width: 1
                border.color: bay.on || bay.bad ? root.stateColor(bay.spotId, bay.on, bay.bad) : root.faint
            }

            Rectangle {
                x: 38 * root.k
                y: 16 * root.k
                width: 7 * root.k
                height: 6 * root.k
                radius: 1 * root.k
                color: bay.on ? root.stateColor(bay.spotId, bay.on, bay.bad) : "transparent"
                border.width: 1
                border.color: root.faint
            }

            // Fendas de ventilacao
            Repeater {
                model: 6

                Rectangle {
                    required property int index

                    x: 10 * root.k
                    y: (90 + index * 36) * root.k
                    width: 37 * root.k
                    height: 5 * root.k
                    radius: 2.5 * root.k
                    color: "transparent"
                    border.width: 1
                    border.color: root.faint
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 300 * root.k
                text: bay.disk ? `${bay.n} · ${Math.round((bay.disk.size ?? 0) / 1e12)} TB` : String(bay.n)
                color: bay.on ? root.stateColor(bay.spotId, bay.on, bay.bad) : root.faint
                font.family: root.family
                font.pixelSize: Math.max(6, 9 * root.k)
                renderType: Text.NativeRendering
            }

            Spot {
                anchors.fill: parent
                spotId: bay.spotId
            }
        }
    }

    // ---------------------------------------------------------------- traseira
    Rectangle {
        x: 400 * root.k
        y: 0
        width: 360 * root.k
        height: 360 * root.k
        radius: 10 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.ink
    }

    // Ventoinha de 120 mm: anel, aro interno, cubo e 4 pas
    Item {
        id: fan

        readonly property bool on: root.online && !!(root.fans?.case_rpm)

        x: 430 * root.k
        y: 70 * root.k
        width: 180 * root.k
        height: 180 * root.k

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: root.fill("fan", fan.on, false)
            border.width: Math.max(1, 1.4 * root.k)
            border.color: root.stateColor("fan", fan.on, false)
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.66
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.22
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: root.stateColor("fan", fan.on, false)
        }

        Repeater {
            model: 4

            Rectangle {
                required property int index

                anchors.centerIn: parent
                width: parent.width * 0.92
                height: 1
                color: root.faint
                rotation: index * 45
            }
        }

        Spot {
            anchors.fill: parent
            spotId: "fan"
        }
    }

    Text {
        x: 430 * root.k
        y: 262 * root.k
        width: 180 * root.k
        horizontalAlignment: Text.AlignHCenter
        text: fan.on ? `${Math.round(root.fans.case_rpm)} rpm` : ""
        color: root.stateColor("fan", fan.on, false)
        font.family: root.family
        font.pixelSize: Math.max(6, 8 * root.k)
        renderType: Text.NativeRendering
    }

    // Coluna de portas: DC, 2x USB-A, HDMI, 2,5 GbE, 10 GbE, Kensington
    Rectangle {
        x: 690 * root.k
        y: 40 * root.k
        width: 20 * root.k
        height: 20 * root.k
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Repeater {
        model: [84, 106]

        Rectangle {
            required property int modelData

            x: 688 * root.k
            y: modelData * root.k
            width: 24 * root.k
            height: 10 * root.k
            radius: 1 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    Rectangle {
        x: 686 * root.k
        y: 136 * root.k
        width: 28 * root.k
        height: 10 * root.k
        radius: 3 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // Portas de rede: 2,5 GbE (igc) em cima, 10 GbE (atlantic) embaixo
    Repeater {
        model: [{ id: "lan-2g5", y: 176, label: "2.5G", port: root.lan25 }, { id: "lan-10g", y: 226, label: "10G", port: root.lan10 }]

        Item {
            id: rj

            required property var modelData
            readonly property bool on: root.online && !!(rj.modelData.port?.up)

            x: 684 * root.k
            y: rj.modelData.y * root.k
            width: 32 * root.k
            height: 26 * root.k

            Rectangle {
                anchors.fill: parent
                radius: 2 * root.k
                color: root.fill(rj.modelData.id, rj.on, false)
                border.width: 1
                border.color: root.stateColor(rj.modelData.id, rj.on, false)
            }

            // Trava do RJ45 e os LEDs de link
            Rectangle {
                x: 10 * root.k
                y: 20 * root.k
                width: 12 * root.k
                height: 6 * root.k
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }

            Rectangle {
                x: 3 * root.k
                y: 3 * root.k
                width: 4 * root.k
                height: 4 * root.k
                radius: width / 2
                color: rj.on ? root.stateColor(rj.modelData.id, rj.on, false) : "transparent"
                border.width: 1
                border.color: root.faint
            }

            Text {
                x: 36 * root.k
                y: 6 * root.k
                text: rj.modelData.label
                color: rj.on ? root.stateColor(rj.modelData.id, rj.on, false) : root.faint
                font.family: root.family
                font.pixelSize: Math.max(5, 8 * root.k)
                renderType: Text.NativeRendering
            }

            Spot {
                anchors.fill: parent
                anchors.margins: -4
                spotId: rj.modelData.id
            }
        }
    }

    Rectangle {
        x: 696 * root.k
        y: 300 * root.k
        width: 8 * root.k
        height: 14 * root.k
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // Fendas de ventilacao na base da traseira
    Repeater {
        model: 8

        Rectangle {
            required property int index

            x: (430 + index * 22) * root.k
            y: 318 * root.k
            width: 14 * root.k
            height: 5 * root.k
            radius: 2.5 * root.k
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    // ------------------------------------------------- tampa de baixo: M.2 x2
    Rectangle {
        x: 0
        y: 380 * root.k
        width: 360 * root.k
        height: 60 * root.k
        radius: 6 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Text {
        x: 12 * root.k
        y: 385 * root.k
        text: "M.2 NVMe"
        color: root.faint
        font.family: root.family
        font.pixelSize: Math.max(5, 7 * root.k)
        font.letterSpacing: 1 * root.k
        renderType: Text.NativeRendering
    }

    Repeater {
        model: 2

        Item {
            id: slot

            required property int index
            readonly property string spotId: `m2-${slot.index + 1}`
            readonly property var disk: root.m2[slot.index] ?? null
            readonly property bool on: root.diskOn(slot.disk)
            readonly property bool bad: root.diskBad(slot.disk)

            x: (40 + slot.index * 160) * root.k
            y: 404 * root.k
            width: 140 * root.k
            height: 22 * root.k

            Rectangle {
                anchors.fill: parent
                radius: 3 * root.k
                color: root.fill(slot.spotId, slot.on, slot.bad)
                border.width: 1
                border.color: root.stateColor(slot.spotId, slot.on, slot.bad)
            }

            // Conector na ponta esquerda
            Rectangle {
                x: 0
                y: 4 * root.k
                width: 8 * root.k
                height: 14 * root.k
                color: slot.on ? root.stateColor(slot.spotId, slot.on, slot.bad) : root.faint
                opacity: 0.6
            }

            Text {
                anchors.centerIn: parent
                text: slot.disk ? `${Math.round((slot.disk.size ?? 0) / 1e9)} GB${slot.index === 0 ? " · system" : ""}` : (slot.index === 1 ? "empty · Lexar" : "empty")
                color: slot.on ? root.stateColor(slot.spotId, slot.on, slot.bad) : root.faint
                font.family: root.family
                font.pixelSize: Math.max(5, 8 * root.k)
                renderType: Text.NativeRendering
            }

            Spot {
                anchors.fill: parent
                spotId: slot.spotId
            }
        }
    }

    // Nome do modelo na traseira, no traco fraco (como o "ROG ZEPHYRUS" da tampa)
    Text {
        x: 400 * root.k
        y: 412 * root.k
        width: 360 * root.k
        horizontalAlignment: Text.AlignHCenter
        text: "DXP4800 PLUS"
        color: root.faint
        font.family: root.family
        font.pixelSize: Math.max(6, 9 * root.k)
        font.letterSpacing: 2 * root.k
        renderType: Text.NativeRendering
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
