pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// O setup visto de frente, no traco dos outros diagramas, com cada peca onde
// o usuario a deixou: monitores (silhueta do LG com o pe, numa mesinha da
// largura dele e da altura do touchpad, com os estojos dos fones ao lado do
// pe), notebook (G16 aberto), mousepad de 90 x 50, Azoth, mouses, headphone
// no suporte e controles. Silhuetas em assets/devices com o traco normalizado
// para o tamanho em que aparecem (scripts/art/trace.py, `stroke`). Tamanhos reais em cm (1 cm = width/190):
//   LG 25" 58 x 24 cm de tela (EDID), ~59 cm com a moldura; G16 35,5 x 24,3;
//   Azoth 32,6 x 13,6; Naga 12 x 7,5; Atheris 10 x 6,3; WH-1000XM5 21,7 de
//   largura; WF-1000XM5 (estojo) 6,5 x 4; FreeClip 2 (estojo) 5 x 5; controle
//   Xbox 15,3 x 10,2. `editing` deixa arrastar; a posicao (cm, encaixada em
//   0,5) fica em ~/.config/caelestia/setup-layout.json por peca; `reset()`
//   apaga tudo e volta ao padrao. Clique fora da edicao abre a pagina da
//   peca (`open(page, tab)`); o que esta desligado so aparece com `showOffline`.
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
    property bool editing
    // Posicoes salvas: { key: { x, y } } em cm
    property var layout: ({})
    readonly property bool customized: Object.keys(root.layout).length > 0

    readonly property real cm: root.width / 190
    readonly property real deskY: 50
    readonly property real shelfH: 8.3
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1

    // Monitores externos ligados, da esquerda para a direita como no Hyprland
    readonly property var externals: root.monitors.filter(m => !m.internal && m.enabled).sort((a, b) => root.posX(a) - root.posX(b))
    readonly property var laptop: root.monitors.find(m => m.internal) ?? null
    // Padrao: o notebook fica do lado em que esta no arranjo (a direita do LG, hoje)
    readonly property bool laptopRight: !root.laptop || root.externals.length === 0 || root.posX(root.laptop) >= Math.max(...root.externals.map(m => root.posX(m)))
    readonly property real zoneX: root.laptopRight ? 0 : 40
    // Onde o LG esta (salvo ou padrao): a mesinha e os estojos acompanham
    readonly property var lgMon: root.externals.find(m => /LG ULTRAWIDE/i.test(m.description ?? "")) ?? root.externals[0] ?? null
    readonly property real lgX: root.lgMon ? (root.layout[`monitor:${root.lgMon.name}`]?.x ?? root.zoneX + 30) : root.zoneX + 30
    readonly property real lgBottom: root.lgMon ? (root.layout[`monitor:${root.lgMon.name}`]?.y ?? root.deskY - root.shelfH - 59 * 754 / 1285) + 59 * 754 / 1285 : root.deskY - root.shelfH

    signal open(page: string, tab: string)

    function posX(m: var): real {
        return Number((m.position ?? "0x0").split("x")[0]);
    }

    function place(key: string, x: real, y: real): void {
        const next = JSON.parse(JSON.stringify(root.layout));
        next[key] = { x: x, y: y };
        root.layout = next;
        layoutFile.setText(JSON.stringify(next, null, 4) + "\n");
    }

    function reset(): void {
        root.layout = {};
        layoutFile.setText("{}\n");
    }

    implicitHeight: 104 * root.cm

    FileView {
        id: layoutFile

        path: `${Paths.config}/setup-layout.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text());
                root.layout = d && typeof d === "object" ? d : {};
            } catch (e) {
                root.layout = {};
            }
        }
        onLoadFailed: root.layout = {}
    }

    // Mesa
    Rectangle {
        x: 0
        y: root.deskY * root.cm
        width: root.width
        height: 1
        color: root.ink
    }

    // ------------------------------------------------------------ monitores
    Repeater {
        model: root.externals.length

        SetupPiece {
            id: ext

            required property int index
            readonly property var mon: root.externals[index] ?? ({})
            readonly property bool lg: /LG ULTRAWIDE/i.test(ext.mon.description ?? "")

            key: `monitor:${ext.mon.name}`
            defX: root.zoneX + 30 + ext.index * 62
            defY: root.deskY - root.shelfH - (ext.lg ? 59 * 754 / 1285 : 33)
            wCm: 59
            hCm: ext.lg ? 59 * 754 / 1285 : 33
            layout: root.layout
            cm: root.cm
            editing: root.editing
            label: (ext.mon.description ?? ext.mon.name ?? "").replace(/^LG Electronics\s+/i, "").replace(/\s+0x[0-9A-Fa-f]+$/, "")
            onClicked: root.open("display", ext.mon.name)
            onMoved: (k, x, y) => root.place(k, x, y)

            Image {
                id: lgArt

                anchors.fill: parent
                visible: ext.lg
                source: Quickshell.shellPath("assets/devices/lg-25-ultrawide-stand.svg")
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

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: parent.height * 0.2
                visible: !ext.lg
                radius: 2 * root.cm
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }
        }
    }

    // ----------------------------------------------------------- notebook
    SetupPiece {
        id: lap

        key: "laptop"
        defX: root.laptopRight ? 190 - 37.5 : 2
        defY: root.deskY - 35.5 * 1243 / 918
        wCm: 35.5
        hCm: 35.5 * 1243 / 918
        layout: root.layout
        cm: root.cm
        editing: root.editing
        label: qsTr("Laptop")
        visible: !!root.laptop
        online: !!root.laptop?.enabled
        showOffline: true
        onClicked: root.open("display", root.laptop?.name ?? "")
        onMoved: (k, x, y) => root.place(k, x, y)

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
    }

    // ------------------------------------------------------------- mesinha
    // Apoio horizontal do monitor: a largura do LG e a altura do touchpad do
    // G16 (8,3 cm); o pe fica em cima e os estojos dos fones ao lado dele
    SetupPiece {
        key: "shelf"
        defX: root.lgX
        defY: root.lgBottom
        wCm: 59
        hCm: root.shelfH
        layout: root.layout
        cm: root.cm
        editing: root.editing
        label: qsTr("Monitor riser")
        onMoved: (k, x, y) => root.place(k, x, y)

        Rectangle {
            anchors.fill: parent
            radius: 0.6 * root.cm
            color: "transparent"
            border.width: 1
            border.color: root.ink
        }

        Rectangle {
            x: 0
            y: 1.2 * root.cm
            width: parent.width
            height: 1
            color: Qt.alpha(root.ink, 0.5)
        }
    }

    // ------------------------------------------------------------- mousepad
    SetupPiece {
        key: "mousepad"
        defX: root.zoneX + 22
        defY: root.deskY + 2
        wCm: 90
        hCm: 50
        layout: root.layout
        cm: root.cm
        editing: root.editing
        label: qsTr("Mousepad · 90 × 50 cm")
        onMoved: (k, x, y) => root.place(k, x, y)

        Rectangle {
            anchors.fill: parent
            radius: 2 * root.cm
            color: "transparent"
            border.width: 1
            border.color: root.faint
        }
    }

    // ------------------------------------------------------------ controles
    Repeater {
        model: root.controllers.length

        SetupPiece {
            id: pad

            required property int index
            readonly property var dev: root.controllers[index] ?? ({})

            key: `controller:${pad.index}`
            defX: root.zoneX + 2 + pad.index * 17
            defY: root.deskY + 6
            wCm: 15.3
            hCm: 10.2
            layout: root.layout
            cm: root.cm
            editing: root.editing
            label: pad.dev.name ?? qsTr("Controller")
            online: !!pad.dev.connected
            showOffline: root.showOffline
            onClicked: root.open("bluetooth", "")
            onMoved: (k, x, y) => root.place(k, x, y)

            MaterialIcon {
                anchors.centerIn: parent
                text: "stadia_controller"
                color: root.ink
                fontStyle: Tokens.font.icon.size(Math.max(8, pad.width * 0.95)).build()
            }
        }
    }

    // --------------------------------------------------------------- teclado
    SetupPiece {
        id: kbd

        key: "keyboard"
        defX: root.zoneX + 27
        defY: root.deskY + 6
        wCm: 32.6
        hCm: 32.6 * 793 / 1867
        layout: root.layout
        cm: root.cm
        editing: root.editing
        label: root.keyboard ? [(root.keyboard.name ?? "").replace(/\s*2\.4GHz$/, ""), root.keyboard.battery !== null && root.keyboard.battery !== undefined ? `${Math.round(root.keyboard.battery * 100)}%` : ""].filter(x => x).join(" · ") : ""
        visible: !!root.keyboard && (kbd.online || root.showOffline)
        online: !!root.keyboard?.online
        showOffline: root.showOffline
        onClicked: root.open("keyboard", root.keyboard?.id ?? "")
        onMoved: (k, x, y) => root.place(k, x, y)

        Image {
            id: kbdArt

            anchors.fill: parent
            source: Quickshell.shellPath("assets/devices/rog-azoth-home.svg")
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
    }

    // ---------------------------------------------------------------- mouses
    Repeater {
        model: root.mice.length

        SetupPiece {
            id: mouse

            required property int index
            readonly property var dev: root.mice[index] ?? ({})
            readonly property bool naga: (mouse.dev.model ?? "").includes("naga")

            key: `mouse:${mouse.dev.model}`
            defX: root.zoneX + 63 + mouse.index * 10
            defY: root.deskY + 5
            wCm: mouse.naga ? 7.5 : 7.1
            hCm: mouse.naga ? 12 : 10
            layout: root.layout
            cm: root.cm
            editing: root.editing
            label: (mouse.dev.name ?? "").replace(/\s*\(.*?\)\s*$/, "")
            online: !!mouse.dev.online
            showOffline: root.showOffline
            onClicked: root.open("mouse", mouse.dev.model ?? "")
            onMoved: (k, x, y) => root.place(k, x, y)

            // Silhuetas do Home (<modelo>-home.svg): Naga sem o painel lateral, traco
            // normalizado para o tamanho em que aparecem
            Image {
                id: art

                anchors.fill: parent
                source: Quickshell.shellPath(`assets/devices/${mouse.dev.model}-home.svg`)
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
        }
    }

    // ---------------------------------------------------------------- fones
    Repeater {
        model: root.headphones.length

        SetupPiece {
            id: hp

            required property int index
            readonly property var dev: root.headphones[index] ?? ({})
            readonly property string file: ({ "WH-1000XM5": "sony-wh-1000xm5", "WF-1000XM5": "sony-wf-1000xm5", "HUAWEI FreeClip 2": "huawei-freeclip-2" })[hp.dev.model] ?? ""
            readonly property bool big: hp.dev.model === "WH-1000XM5"
            readonly property int budIndex: root.headphones.filter((h, i) => i < hp.index && h.model !== "WH-1000XM5").length

            // o headphone pendurado no suporte: a peca inclui o suporte (28 cm
            // de altura, base na mesa) e o fone pendurado no gancho
            readonly property real standH: 28

            key: `headphones:${hp.dev.model}`
            defX: hp.big ? root.zoneX + 126 : root.lgX + (hp.budIndex === 0 ? 8 : 44)
            defY: hp.big ? root.deskY - hp.standH : root.lgBottom - hp.hCm + 0.5
            wCm: hp.big ? 21.7 : hp.dev.model === "WF-1000XM5" ? 6.5 : 5
            hCm: hp.big ? hp.standH : hp.dev.model === "WF-1000XM5" ? 6.5 * 308 / 331 : 5
            layout: root.layout
            cm: root.cm
            editing: root.editing
            label: [hp.dev.name, hp.dev.model].filter(x => x).join(" · ")
            visible: hp.file !== "" && (hp.online || root.showOffline)
            online: !!hp.dev.connected
            showOffline: root.showOffline
            onClicked: root.open("sound", "output")
            onMoved: (k, x, y) => root.place(k, x, y)

            // Suporte: base oval na mesa, haste e o gancho onde o arco apoia
            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 11 * root.cm
                height: 2.2 * root.cm
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }

            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: 1.2 * root.cm
                width: Math.max(2, 0.8 * root.cm)
                height: parent.height - 2.2 * root.cm - y
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }

            Rectangle {
                visible: hp.big
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0.6 * root.cm
                width: 6 * root.cm
                height: 1.6 * root.cm
                radius: height / 2
                color: Colours.palette.m3surface
                border.width: 1
                border.color: root.ink
            }

            Image {
                id: hpArt

                x: 0
                y: hp.big ? 1.4 * root.cm : 0
                width: parent.width
                height: hp.big ? 21.7 * 222 / 197 * root.cm : parent.height
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
        }
    }
}
