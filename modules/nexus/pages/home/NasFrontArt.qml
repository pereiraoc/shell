pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import "../server/server.js" as S

// A frente do UGREEN DXP4800 Plus em miniatura, para o setup do Home (a versao
// grande, com legendas e pecas clicaveis, e o ServerDiagram da pagina Server):
// so linhas, como os outros diagramas -- moldura com a face recuada, gaveteiro
// com a barra de cima, quatro gavetas com a tampa e a trava, painel de baixo
// com botao, LEDs LAN e DISK1-4, SD e USBs, e a barra do nome. Mesmas
// coordenadas do ServerDiagram (360 x 360 un), sem texto: a 17,8 cm de mesa a
// peca tem uns 80 px e letra nenhuma se le. Gaveta com disco e LED ganham o
// tom primario quando o NAS responde.
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

    // Moldura e a face recuada
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

    // Gaveteiro (com a barra grossa em cima)
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

    // As 4 gavetas: contorno, linha da tampa, tom de estado so com disco, divisa, trava
    Repeater {
        model: 4

        Item {
            id: bay

            required property int index
            readonly property var disk: root.bays[bay.index + 1] ?? null
            readonly property bool on: root.online && !!bay.disk

            x: (44 + bay.index * 72) * root.k
            y: 44 * root.k
            width: 60 * root.k
            height: 216 * root.k

            Rectangle {
                anchors.fill: bay
                radius: 7 * root.k
                color: "transparent"
                border.width: 1
                border.color: bay.on ? root.lit : root.faint
            }

            Rectangle {
                x: 1
                y: 7 * root.k
                width: bay.width - 2
                height: 155 * root.k
                radius: 4 * root.k
                visible: bay.on
                color: Qt.alpha(root.lit, 0.16)
            }

            Rectangle {
                x: 0
                y: 7 * root.k
                width: bay.width
                height: 1
                color: root.faint
            }

            Rectangle {
                x: 0
                y: 162 * root.k
                width: bay.width
                height: 1
                color: root.faint
            }

            Rectangle {
                anchors.horizontalCenter: bay.horizontalCenter
                y: 178 * root.k
                width: Math.max(3, 20 * root.k)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: bay.on ? root.lit : root.faint
            }
        }
    }

    // Painel de baixo e a barra do nome: duas linhas na largura da face
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

    // Botao de energia (pilula)
    Rectangle {
        x: 49 * root.k
        y: 301 * root.k
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

            x: (98 + led.index * 12.2) * root.k - width / 2
            y: 304 * root.k
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
        y: 303 * root.k
        width: 50 * root.k
        height: Math.max(2, 7 * root.k)
        radius: 2 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 255 * root.k
        y: 303 * root.k
        width: Math.max(3, 15 * root.k)
        height: Math.max(2, 7 * root.k)
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    Rectangle {
        x: 288 * root.k
        y: 301 * root.k
        width: Math.max(4, 23 * root.k)
        height: Math.max(2, 11 * root.k)
        radius: 1 * root.k
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }
}
