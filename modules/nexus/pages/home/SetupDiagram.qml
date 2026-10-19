pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.nexus.pages.display

// O setup visto de frente, no traco dos outros diagramas: os monitores
// externos atras (na ordem do arranjo do Hyprland), a mesa, e sobre ela --
// da esquerda para a direita -- os controles, o notebook aberto no suporte,
// o mousepad grande com o Azoth e os mouses, os fones nas caixinhas e o
// headphone no suporte. Tamanhos proporcionais (cm reais, 1 cm = width/190).
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
    readonly property real deskY: 42 * root.cm
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant

    // Monitores externos, da esquerda para a direita como no Hyprland
    readonly property var externals: root.monitors.filter(m => !m.internal && m.enabled).sort((a, b) => Number(a.position.split("x")[0]) - Number(b.position.split("x")[0]))

    signal open(page: string, tab: string)

    function visibleFor(on: bool): bool {
        return on || root.showOffline;
    }

    implicitHeight: 92 * root.cm

    // ------------------------------------------------------------ monitores
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2 * root.cm
        spacing: 6 * root.cm

        Repeater {
            model: root.externals.length

            MonitorOutline {
                required property int index
                // 2560 px logicos ~ 80 cm (34" ultrawide); outros tamanhos na proporcao
                readonly property real pxCm: 80 / 2560

                mon: root.externals[index] ?? ({})
                label: (mon.description ?? mon.name ?? "").replace(/^LG Electronics\s+/i, "").replace(/\s+0x[0-9A-Fa-f]+$/, "")
                sublabel: ""
                width: Number((mon.logical ?? "2560x1080").split("x")[0]) * pxCm * root.cm
                height: Number((mon.logical ?? "2560x1080").split("x")[1]) * pxCm * root.cm

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.open("display", parent.mon.name)
                }
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

    // Mousepad grande (90 x 40 cm), visto de cima inclinado: um retangulo baixo
    Rectangle {
        x: 58 * root.cm
        y: root.deskY + 4 * root.cm
        width: 90 * root.cm
        height: 20 * root.cm
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
            x: (2 + pad.index * 17) * root.cm
            y: root.deskY + 8 * root.cm
            width: 15 * root.cm
            height: 10 * root.cm

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
    // Aberto a ~150 graus num suporte de 45 graus: a tela quase de frente, a
    // base inclinada por baixo, o suporte em cunha
    Item {
        id: laptop

        readonly property var mon: root.monitors.find(m => m.internal) ?? null

        x: 20 * root.cm
        y: root.deskY - 26 * root.cm
        width: 35 * root.cm
        height: 36 * root.cm

        // suporte (cunha)
        Canvas {
            anchors.fill: parent
            onPaint: {
                const c = getContext("2d");
                c.clearRect(0, 0, width, height);
                c.strokeStyle = root.faint;
                c.lineWidth = 1;
                // cunha do suporte (45 graus), apoiada na mesa
                c.beginPath();
                c.moveTo(width * 0.22, height);
                c.lineTo(width * 0.82, height);
                c.lineTo(width * 0.82, height * 0.8);
                c.closePath();
                c.stroke();
                // base do notebook deitada na cunha (vista de frente, inclinada)
                c.strokeStyle = root.ink;
                c.beginPath();
                c.moveTo(width * 0.04, height * 0.8);
                c.lineTo(width * 0.96, height * 0.8);
                c.lineTo(width * 0.99, height * 0.66);
                c.lineTo(width * 0.01, height * 0.66);
                c.closePath();
                c.stroke();
            }

            Connections {
                function onInkChanged(): void {
                    requestPaint();
                }

                target: root
            }
        }

        // tela (16", 34.5 x 21.5 cm) um pouco inclinada para tras
        MonitorOutline {
            x: 0
            y: 0
            width: parent.width
            height: 21.5 * root.cm
            mon: laptop.mon ?? ({ internal: true })
            label: qsTr("Laptop")
            sublabel: ""
            dim: !laptop.mon?.enabled
            transform: Rotation {
                origin.x: laptop.width / 2
                origin.y: 21.5 * root.cm
                axis.x: 1
                axis.y: 0
                axis.z: 0
                angle: -20
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open("display", laptop.mon?.name ?? "")
            }
        }
    }

    // --------------------------------------------------------------- teclado
    // Azoth (32.5 x 13.5 cm) no mousepad: contorno com a grade de teclas
    Item {
        id: kbd

        visible: !!root.keyboard && root.visibleFor(!!root.keyboard.online)
        opacity: root.keyboard?.online ? 1 : 0.4
        x: 64 * root.cm
        y: root.deskY + 7 * root.cm
        width: 32.5 * root.cm
        height: 13.5 * root.cm

        Rectangle {
            anchors.fill: parent
            radius: 1 * root.cm
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }

        // fileiras de teclas sugeridas
        Column {
            anchors.fill: parent
            anchors.margins: 1.2 * root.cm
            spacing: 0.5 * root.cm

            Repeater {
                model: 6

                Row {
                    required property int index

                    spacing: 0.4 * root.cm

                    Repeater {
                        model: parent.index === 0 ? 14 : parent.index === 5 ? 8 : 15

                        Rectangle {
                            required property int index

                            width: 1.55 * root.cm
                            height: 1.55 * root.cm
                            radius: 0.2 * root.cm
                            color: "transparent"
                            border.width: 1
                            border.color: root.faint
                        }
                    }
                }
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1.4 * root.cm
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
    // Naga (12 x 7.5 cm) e Atheris (10 x 6.3 cm), a direita do teclado
    Repeater {
        model: root.mice.length

        Item {
            id: mouse

            required property int index
            readonly property var dev: root.mice[index] ?? ({})
            readonly property bool naga: (mouse.dev.model ?? "").includes("naga")
            readonly property real wCm: mouse.naga ? 7.5 : 6.3
            readonly property real hCm: mouse.naga ? 12 : 10

            visible: root.visibleFor(!!mouse.dev.online)
            opacity: mouse.dev.online ? 1 : 0.4
            x: (100 + mouse.index * 10) * root.cm
            y: root.deskY + 5 * root.cm
            width: mouse.wCm * root.cm
            height: mouse.hCm * root.cm

            Image {
                id: art

                anchors.fill: parent
                source: Quickshell.shellPath(`assets/mice/${mouse.dev.model}.svg`)
                fillMode: Image.PreserveAspectFit
                sourceSize.width: art.width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
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
    // Caixinhas lado a lado (WF-1000XM5 6.5 x 4 cm, FreeClip 2 6 x 6 cm) e o
    // WH-1000XM5 no suporte (20 x 25 cm), na ponta direita
    Repeater {
        model: root.headphones.length

        Item {
            id: hp

            required property int index
            readonly property var dev: root.headphones[index] ?? ({})
            readonly property string file: ({ "WH-1000XM5": "sony-wh-1000xm5", "WF-1000XM5": "sony-wf-1000xm5", "HUAWEI FreeClip 2": "huawei-freeclip-2" })[hp.dev.model] ?? ""
            readonly property bool big: hp.dev.model === "WH-1000XM5"
            // caixinhas: uma ao lado da outra; o headphone no suporte, atras
            readonly property int budIndex: root.headphones.filter((h, i) => i < hp.index && h.model !== "WH-1000XM5").length

            visible: hp.file !== "" && root.visibleFor(!!hp.dev.connected)
            opacity: hp.dev.connected ? 1 : 0.4
            x: hp.big ? 168 * root.cm : (152 + hp.budIndex * 8) * root.cm
            y: hp.big ? root.deskY - 26 * root.cm : root.deskY + 4 * root.cm
            width: (hp.big ? 20 : 7) * root.cm
            height: (hp.big ? 22 : 7) * root.cm

            // suporte do headphone: haste e base
            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.5
                width: 1
                height: 26 * root.cm - parent.height * 0.5
                color: root.faint
            }

            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: 26 * root.cm - 1
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
                sourceSize.width: hpArt.width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)
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
