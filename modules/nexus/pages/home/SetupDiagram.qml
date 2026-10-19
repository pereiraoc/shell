pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

// O setup visto de frente, no traco dos outros diagramas: os monitores
// externos atras (silhueta do LG, sem o pe), a mesa, e sobre ela os controles,
// o mousepad com o Azoth e os mouses, as caixinhas dos fones, o headphone no
// suporte e o notebook aberto (silhueta do G16), do lado em que ele esta no
// arranjo do Hyprland. Tamanhos reais em cm (1 cm = width/190):
//   LG 25" ultrawide 58 x 24 cm de tela (EDID), ~59 cm com a moldura;
//   G16 35,5 x 24,3 cm (tela 35 x 22); Azoth 32,6 x 13,6; Naga 12 x 7,5;
//   Atheris 10 x 6,3; WH-1000XM5 21,7 cm de largura; WF-1000XM5 (estojo)
//   6,5 x 4; FreeClip 2 (estojo) 5 x 5; controle Xbox 15,3 x 10,2.
// Cada aparelho e clicavel (`open(page, tab)`); o que esta desligado so
// aparece com `showOffline`, apagado.
Item {
    id: root

    // [{ name, internal, enabled, position, logical }] do caelestia-display
    property var monitors: []
    // [{ model, name, online }] -- mice + mice_offline do caelestia-peripherals
    property var mice: []
    // { id, name, online, battery } do teclado externo (Azoth), ou null
    property var keyboard: null
    // [{ model, name, connected }] do caelestia-headphones
    property var headphones: []
    // [{ name, connected }] controles (Bluetooth)
    property var controllers: []
    property bool showOffline

    readonly property real cm: root.width / 190
    readonly property real deskY: 50 * root.cm
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1

    // Monitores externos ligados, da esquerda para a direita como no Hyprland
    readonly property var externals: root.monitors.filter(m => !m.internal && m.enabled).sort((a, b) => root.posX(a) - root.posX(b))
    readonly property var laptop: root.monitors.find(m => m.internal) ?? null
    // O notebook fica do lado em que esta no arranjo (a direita do LG, hoje)
    readonly property bool laptopRight: !root.laptop || root.externals.length === 0 || root.posX(root.laptop) >= Math.max(...root.externals.map(m => root.posX(m)))
    // Faixa da mesa que sobra para o resto (controles, mousepad, fones)
    readonly property real zoneX: root.laptopRight ? 0 : 40 * root.cm
    readonly property real zoneW: 150 * root.cm

    signal open(page: string, tab: string)

    function posX(m: var): real {
        return Number((m.position ?? "0x0").split("x")[0]);
    }

    function visibleFor(on: bool): bool {
        return on || root.showOffline;
    }

    implicitHeight: 76 * root.cm

    // ------------------------------------------------------------ monitores
    // LG com o pe apoiado na mesa, centrado sobre o mousepad
    Repeater {
        model: root.externals.length

        Item {
            id: ext

            required property int index
            readonly property var mon: root.externals[index] ?? ({})
            readonly property bool lg: /LG ULTRAWIDE/i.test(ext.mon.description ?? "")
            readonly property real wCm: 59
            readonly property real hCm: ext.lg ? 59 * 584 / 1285 : 59 * 0.56

            x: root.zoneX + (30 + ext.index * 62) * root.cm
            y: root.deskY - ext.hCm * root.cm + 1
            width: ext.wCm * root.cm
            height: ext.hCm * root.cm

            Image {
                id: lgArt

                anchors.fill: parent
                visible: ext.lg
                source: Quickshell.shellPath("assets/devices/lg-25-ultrawide.svg")
                fillMode: Image.PreserveAspectFit
                sourceSize.width: lgArt.width * root.dpr
                smooth: true
                asynchronous: true

                layer.enabled: true
                layer.effect: Colouriser {
                    colorizationColor: root.ink
                    brightness: 1
                }
            }

            // monitor sem silhueta propria: so o contorno
            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: parent.height * 0.2
                visible: !ext.lg
                radius: 2 * root.cm
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.36
                text: (ext.mon.description ?? ext.mon.name ?? "").replace(/^LG Electronics\s+/i, "").replace(/\s+0x[0-9A-Fa-f]+$/, "")
                color: root.ink
                font: Tokens.font.label.medium
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("display", ext.mon.name)
            }
        }
    }

    // ---------------------------------------------------------------- mesa
    Rectangle {
        x: 0
        y: root.deskY
        width: root.width
        height: 1
        color: root.ink
    }

    // Mousepad grande (80 x 30 cm) visto de cima, inclinado
    Rectangle {
        x: root.zoneX + 22 * root.cm
        y: root.deskY + 2 * root.cm
        width: 80 * root.cm
        height: 22 * root.cm
        radius: 2 * root.cm
        color: "transparent"
        border.width: 1
        border.color: root.faint
    }

    // ---------------------------------------------------------- controles
    Repeater {
        model: root.controllers.length

        Item {
            id: pad

            required property int index
            readonly property var dev: root.controllers[index] ?? ({})

            visible: root.visibleFor(!!pad.dev.connected)
            opacity: pad.dev.connected ? 1 : 0.4
            x: root.zoneX + (2 + pad.index * 17) * root.cm
            y: root.deskY + 6 * root.cm
            width: 15.3 * root.cm
            height: 10.2 * root.cm

            MaterialIcon {
                anchors.centerIn: parent
                text: "stadia_controller"
                color: root.ink
                fontStyle: Tokens.font.icon.size(pad.width * 0.95).build()
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("bluetooth", "")
            }
        }
    }

    // ----------------------------------------------------------- notebook
    // Silhueta do G16 aberto (35,5 cm de largura), apoiado na mesa
    Item {
        id: lap

        readonly property real wCm: 35.5
        readonly property real hCm: 35.5 * 1243 / 918

        visible: !!root.laptop
        opacity: root.laptop?.enabled ? 1 : 0.4
        x: root.laptopRight ? root.width - (lap.wCm + 2) * root.cm : 2 * root.cm
        y: root.deskY - lap.hCm * root.cm + 1
        width: lap.wCm * root.cm
        height: lap.hCm * root.cm

        Image {
            id: lapArt

            anchors.fill: parent
            source: Quickshell.shellPath("assets/devices/rog-g16-open.svg")
            fillMode: Image.PreserveAspectFit
            sourceSize.width: lapArt.width * root.dpr
            smooth: true
            asynchronous: true

            layer.enabled: true
            layer.effect: Colouriser {
                colorizationColor: root.ink
                brightness: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open("display", root.laptop?.name ?? "")
        }
    }

    // --------------------------------------------------------------- teclado
    // Azoth (32,6 x 13,6 cm) no mousepad: a arte do QSG (a mesma da aba dele)
    Item {
        id: kbd

        visible: !!root.keyboard && root.visibleFor(!!root.keyboard.online)
        opacity: root.keyboard?.online ? 1 : 0.4
        x: root.zoneX + 27 * root.cm
        y: root.deskY + 6 * root.cm
        width: 32.6 * root.cm
        height: 32.6 * 716 / 1689 * root.cm

        Image {
            id: kbdArt

            anchors.fill: parent
            source: Quickshell.shellPath("assets/devices/rog-azoth.svg")
            fillMode: Image.PreserveAspectFit
            sourceSize.width: kbdArt.width * root.dpr
            smooth: true
            asynchronous: true

            layer.enabled: true
            layer.effect: Colouriser {
                colorizationColor: root.ink
                brightness: 1
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.bottom: parent.top
            anchors.rightMargin: 0.5 * root.cm
            text: root.keyboard?.battery !== undefined && root.keyboard?.battery !== null ? `${Math.round(root.keyboard.battery * 100)}%` : ""
            color: root.ink
            font: Tokens.font.label.small
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open("keyboard", root.keyboard?.id ?? "")
        }
    }

    // ---------------------------------------------------------------- mouses
    // Naga (12 x 7,5 cm, so o corpo: o painel lateral do desenho fica de
    // fora) e Atheris (10 x 7,1 cm), a direita do teclado
    Repeater {
        model: root.mice.length

        Item {
            id: mouse

            required property int index
            readonly property var dev: root.mice[index] ?? ({})
            readonly property bool naga: (mouse.dev.model ?? "").includes("naga")
            readonly property real hCm: mouse.naga ? 12 : 10
            readonly property real wCm: mouse.naga ? 7.5 : 7.1

            visible: root.visibleFor(!!mouse.dev.online)
            opacity: mouse.dev.online ? 1 : 0.4
            x: root.zoneX + (63 + mouse.index * 10) * root.cm
            y: root.deskY + 5 * root.cm
            width: mouse.wCm * root.cm
            height: mouse.hCm * root.cm

            // Naga: a silhueta sem o painel lateral (…-body.svg); os outros, a do mouse
            Image {
                id: art

                anchors.fill: parent
                source: Quickshell.shellPath(`assets/mice/${mouse.dev.model}${mouse.naga ? "-body" : ""}.svg`)
                fillMode: Image.PreserveAspectFit
                sourceSize.width: art.width * root.dpr
                smooth: true
                asynchronous: true

                layer.enabled: true
                layer.effect: Colouriser {
                    colorizationColor: root.ink
                    brightness: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("mouse", mouse.dev.model ?? "")
            }
        }
    }

    // ---------------------------------------------------------------- fones
    // Caixinhas lado a lado (WF-1000XM5 6,5 x 4 cm; FreeClip 2 5 x 5 cm) e o
    // WH-1000XM5 (21,7 cm) no suporte, entre o mousepad e o notebook
    Repeater {
        model: root.headphones.length

        Item {
            id: hp

            required property int index
            readonly property var dev: root.headphones[index] ?? ({})
            readonly property string file: ({ "WH-1000XM5": "sony-wh-1000xm5", "WF-1000XM5": "sony-wf-1000xm5", "HUAWEI FreeClip 2": "huawei-freeclip-2" })[hp.dev.model] ?? ""
            readonly property bool big: hp.dev.model === "WH-1000XM5"
            readonly property int budIndex: root.headphones.filter((h, i) => i < hp.index && h.model !== "WH-1000XM5").length
            readonly property real wCm: hp.big ? 21.7 : hp.dev.model === "WF-1000XM5" ? 6.5 : 5
            readonly property real hCm: hp.big ? 21.7 * 214 / 189 : hp.dev.model === "WF-1000XM5" ? 6.5 * 308 / 331 : 5

            visible: hp.file !== "" && root.visibleFor(!!hp.dev.connected)
            opacity: hp.dev.connected ? 1 : 0.4
            x: hp.big ? root.zoneX + 126 * root.cm : root.zoneX + (106 + hp.budIndex * 8) * root.cm
            y: hp.big ? root.deskY - 27 * root.cm : root.deskY + 3 * root.cm
            width: hp.wCm * root.cm
            height: hp.hCm * root.cm

            // suporte do headphone: haste e base
            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.5
                width: 1
                height: 27 * root.cm - parent.height * 0.5
                color: root.faint
            }

            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: 27 * root.cm - 1
                width: 10 * root.cm
                height: 2 * root.cm
                radius: 1 * root.cm
                color: "transparent"
                border.width: 1
                border.color: root.faint
            }

            Image {
                id: hpArt

                anchors.fill: parent
                source: hp.file ? Quickshell.shellPath(`assets/devices/${hp.file}.svg`) : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: hpArt.width * root.dpr
                smooth: true
                asynchronous: true

                layer.enabled: true
                layer.effect: Colouriser {
                    colorizationColor: root.ink
                    brightness: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("sound", "output")
            }
        }
    }
}
