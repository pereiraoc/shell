pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import "../server/server.js" as S

// A frente do UGREEN DXP4800 Plus em miniatura, para o setup do Home (a versao
// grande, com legendas e pecas clicaveis, e o ServerDiagram da pagina Server):
// quatro gavetas com a trava e a faixa de baixo com o botao e os LEDs LAN e
// DISK1-4. Mesmas coordenadas do ServerDiagram (360 x 360 un), sem texto: a
// 17,8 cm de mesa a peca tem uns 80 px e letra nenhuma se le. Gaveta com disco
// e LED ganham o tom primario quando o NAS responde.
Item {
    id: root

    // data do caelestia-nas status (online, disks, net)
    property var info: ({})
    property bool online
    property color ink: Colours.palette.m3onSurfaceVariant
    property color faint: Colours.palette.m3outlineVariant

    readonly property real k: root.width / 360
    readonly property var bays: S.bayMap(root.info?.disks)
    readonly property bool linkUp: root.online && Array.isArray(root.info?.net) && root.info.net.some(n => !!n.up)
    readonly property color lit: Colours.palette.m3primary

    // Caixa
    Rectangle {
        anchors.fill: parent
        radius: 18 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.ink
    }

    // Moldura das gavetas
    Rectangle {
        x: 30 * root.k
        y: 30 * root.k
        width: 300 * root.k
        height: 240 * root.k
        radius: 10 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // As 4 gavetas: face, divisa e a trava redonda na base
    Repeater {
        model: 4

        Item {
            id: bay

            required property int index
            readonly property var disk: root.bays[bay.index + 1] ?? null
            readonly property bool on: root.online && !!bay.disk

            x: (44 + bay.index * 72) * root.k
            y: 44 * root.k
            width: 64 * root.k
            height: 213 * root.k

            Rectangle {
                anchors.fill: bay
                radius: 7 * root.k
                color: bay.on ? Qt.alpha(root.lit, 0.14) : "transparent"
                border.width: 1
                border.color: bay.on ? root.lit : root.faint
            }

            Rectangle {
                x: 0
                y: 160 * root.k
                width: bay.width
                height: 1
                color: root.faint
            }

            Rectangle {
                anchors.horizontalCenter: bay.horizontalCenter
                y: 176 * root.k
                width: Math.max(3, 20 * root.k)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: bay.on ? root.lit : root.faint
            }
        }
    }

    // Botao de energia (pilula)
    Rectangle {
        x: 49 * root.k
        y: 300 * root.k
        width: Math.max(4, 28 * root.k)
        height: Math.max(2, 11 * root.k)
        radius: height / 2
        color: root.online ? Qt.alpha(root.lit, 0.3) : "transparent"
        border.width: 1
        border.color: root.online ? root.lit : root.faint
    }

    // LEDs: LAN, DISK1..DISK4
    Repeater {
        model: 5

        Rectangle {
            id: led

            required property int index
            readonly property bool on: led.index === 0 ? root.linkUp : root.online && !!root.bays[led.index]

            x: (96 + led.index * 11) * root.k
            y: 302 * root.k
            width: Math.max(2, 5 * root.k)
            height: width
            radius: width / 2
            color: led.on ? root.lit : "transparent"
            border.width: 1
            border.color: led.on ? root.lit : root.faint
        }
    }

    // Leitor SD e as duas USB (so desenho)
    Rectangle {
        x: 188 * root.k
        y: 302 * root.k
        width: 51 * root.k
        height: Math.max(2, 7 * root.k)
        radius: 2 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 255 * root.k
        y: 303 * root.k
        width: Math.max(3, 12 * root.k)
        height: Math.max(2, 5 * root.k)
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 288 * root.k
        y: 301 * root.k
        width: Math.max(4, 19 * root.k)
        height: Math.max(2, 9 * root.k)
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }
}
