pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.effects
import qs.services
import qs.utils
import "setup.js" as L

// O setup visto de frente, no traco dos outros diagramas, com cada peca onde
// o usuario a deixou: monitores (silhueta do LG com o pe, numa mesinha da
// largura dele e da altura do touchpad, com os estojos dos fones ao lado do
// pe), notebook (G16 aberto, com tela, camera, teclado, touchpad e
// alto-falantes clicaveis -- cada area abre a sua pagina), NAS (frente do
// DXP4800 Plus, a esquerda do monitor, so quando responde), mousepad de
// 90 x 25, Azoth, mouses, headphone no suporte e controles. Silhuetas em
// assets/devices com o traco normalizado para o tamanho em que aparecem
// (scripts/art/trace.py, `stroke`). Tamanhos reais em cm (1 cm = width/190):
//   LG 25" 58 x 24 cm de tela (EDID), ~59 cm com a moldura; G16 35,5 x 24,3;
//   NAS 17,8 x 17,8 de frente; Azoth 32,6 x 13,6; Naga 12 x 7,5; Atheris
//   10 x 6,3; WH-1000XM5 21,7 de largura; WF-1000XM5 (estojo) 6,5 x 4;
//   FreeClip 2 (estojo) 5 x 5; controle Xbox 15,3 x 10,2.
// `editing` mostra a grade (2,5 cm, 10 cm mais forte) e deixa arrastar; a
// posicao (cm, encaixada na grade) fica em ~/.config/caelestia/setup-layout.json
// por peca; `reset()` apaga tudo e volta ao padrao. Na edicao as pecas nao tem
// nome escrito: `pieces` (com a geometria) alimenta a lista embaixo
// (PieceList), e `hoverKey` (mouse na peca) / `highlightKey` (mouse na lista) /
// `selectedKey` (clique) acendem peca e linha juntas. Clique fora da edicao
// abre a pagina da peca (`open(page, tab)`); o que esta desligado (mouse fora,
// NAS sem resposta, tela conhecida mas nao ligada) so aparece com `showOffline`.
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
    // { online, lastSeen, info } do caelestia-nas, ou null
    property var nas: null
    // { label, online, output } do caelestia-tablet (tablet pareado), ou null
    property var tablet: null
    property bool showOffline
    property bool editing
    // Posicoes salvas: { key: { x, y } } em cm
    property var layout: ({})
    readonly property bool customized: Object.keys(root.layout).length > 0
    // Nome da peca sob o mouse fora da edicao (a pagina mostra na legenda)
    property string hoverLabel
    // Edicao: peca sob o mouse, peca sob o mouse na lista, peca escolhida
    property string hoverKey
    property string highlightKey
    property string selectedKey
    // Pecas visiveis: [{ key, label, kind, online, device, x, y, w, h }] (cm)
    property var pieces: []
    readonly property string legend: root.editing ? root.pieceLabel(root.hoverKey || root.highlightKey || root.selectedKey) : root.hoverLabel
    // So aparece (e so anima) depois do layout salvo carregar e do encaixe:
    // senao a pagina abria no mundo inteiro e "dava zoom" ate o conteudo
    property bool ready

    // Mundo em cm, sem borda fixa: a linha da mesa (deskY) e a borda de tras do
    // tampo -- monitor, suporte do fone, NAS e notebook apoiam nela, e o
    // mousepad fica a frente (abaixo da linha); x = 0 e a esquerda do arranjo
    // padrao e o NAS nasce em worldX0 + 1, antes de tudo. Nos dois modos o
    // conteudo (caixa de todas as pecas visiveis) e encaixado na largura e
    // centrado: fora da edicao com 2 cm de folga; na edicao com folga maior
    // (editPad) para haver mesa livre onde soltar, e a caixa recalcula a cada
    // peca solta (um mundo de 210 cm fixo deixava tudo pequeno demais).
    readonly property real worldX0: -20
    readonly property real worldW: 190
    readonly property real deskY: 50
    readonly property real shelfH: 8.3
    readonly property real pad: 2
    readonly property real editPadX: 12
    readonly property real editPadY: 8
    readonly property real snapCm: 2.5
    property rect fit: Qt.rect(0, 0, 190, 90)
    readonly property real padX: root.editing ? root.editPadX : root.pad
    readonly property real padY: root.editing ? root.editPadY : root.pad
    readonly property real cm: root.width / Math.max(40, root.fit.width + root.padX * 2)
    readonly property real ox: root.padX - root.fit.x
    readonly property real oy: root.padY - root.fit.y
    readonly property color ink: Colours.palette.m3onSurfaceVariant
    readonly property color faint: Colours.palette.m3outlineVariant
    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1

    // Monitores externos conhecidos (ligados ou nao), da esquerda para a direita
    // como no Hyprland; `monitorOn` = ligado e conectado
    // (a saida virtual do tablet nao e um monitor de verdade: tem peca propria)
    readonly property var externals: root.monitors.filter(m => !m.internal && !root.isVirtual(m)).sort((a, b) => root.posX(a) - root.posX(b))
    readonly property var laptop: root.monitors.find(m => m.internal) ?? null
    // Padrao: o notebook fica do lado em que esta no arranjo (a direita do LG, hoje)
    readonly property bool laptopRight: !root.laptop || root.externals.length === 0 || root.posX(root.laptop) >= Math.max(...root.externals.map(m => root.posX(m)))
    // Arranjo automatico (setup.js autoLayout): so entra o que vai aparecer, com
    // os tamanhos das pecas; posicoes salvas (layout) sobrepoem por peca
    readonly property var auto: L.autoLayout({
        deskY: root.deskY, shelfH: root.shelfH, laptopRight: root.laptopRight,
        nas: root.nas && (root.nas.online || root.showOffline) ? { w: 17.8, h: 17.8 } : null,
        stand: root.headphones.some(h => h.model === "WH-1000XM5" && (h.connected || root.showOffline)) ? { w: 21.7, h: 28 } : null,
        buds: root.headphones.filter(h => h.model !== "WH-1000XM5" && (h.connected || root.showOffline)).map(h => ({ key: `headphones:${h.model}`, w: root.budW(h.model), h: root.budH(h.model) })),
        monitors: root.externals.filter(m => root.monitorOn(m) || root.showOffline).map(m => ({ key: `monitor:${m.name}`, w: 59, h: root.monitorH(m) })),
        tablet: root.tablet && (root.tablet.online || root.showOffline) ? { w: 28.5, h: 28.5 * 1900 / 2850 } : null,
        laptop: root.laptop ? { w: 35.5, h: 35.5 * 1243 / 918 } : null,
        mousepad: { w: 90, h: 25 },
        keyboard: root.keyboard && (root.keyboard.online || root.showOffline) ? { w: 32.6, h: 32.6 * 793 / 1867 } : null,
        mice: root.mice.filter(m => m.online || root.showOffline).map(m => ({ key: `mouse:${m.model}`, w: (m.model ?? "").includes("naga") ? 7.5 : 7.1, h: (m.model ?? "").includes("naga") ? 12 : 10 })),
        controllers: root.controllers.map((c, i) => ({ key: `controller:${i}`, w: 15.3, h: 10.2, on: !!c.connected })).filter(c => c.on || root.showOffline)
    })
    // Areas clicaveis do notebook (setup.js), com o nome traduzido
    readonly property var laptopParts: L.laptopParts().map(p => ({ id: p.id, label: root.partLabel(p.id), x: p.x, y: p.y, w: p.w, h: p.h }))

    signal open(page: string, tab: string)

    function posX(m: var): real {
        return Number((m.position ?? "0x0").split("x")[0]);
    }

    // Saida virtual (tablet pelo cabo: `tablet`, ou HEADLESS-N numa versao do
    // Hyprland sem nome)
    function isVirtual(m: var): bool {
        const n = m?.name ?? "";
        return n === "tablet" || n.startsWith("HEADLESS-");
    }

    function monitorOn(m: var): bool {
        return !!m && !!m.enabled && m.connected !== false;
    }

    function monitorH(m: var): real {
        return /LG ULTRAWIDE/i.test(m?.description ?? "") ? 59 * 754 / 1285 : 33;
    }

    // Estojos abertos, como nos guias (assets/devices/*.svg): WF-1000XM5 6,5 x 6,1 cm;
    // FreeClip 2 6 x 7 cm
    function budW(model: string): real {
        return model === "WF-1000XM5" ? 6.5 : 6;
    }

    function budH(model: string): real {
        return model === "WF-1000XM5" ? 6.1 : 7;
    }

    function autoX(key: string): real {
        return root.auto.pos[key]?.x ?? 0;
    }

    function autoY(key: string): real {
        return root.auto.pos[key]?.y ?? 0;
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

    function setHover(label: string, on: bool): void {
        if (on)
            root.hoverLabel = label;
        else if (root.hoverLabel === label)
            root.hoverLabel = "";
    }

    function setHoverKey(key: string, on: bool): void {
        if (on)
            root.hoverKey = key;
        else if (root.hoverKey === key)
            root.hoverKey = "";
    }

    function pieceLabel(key: string): string {
        return root.pieces.find(p => p.key === key)?.label ?? "";
    }

    function partLabel(id: string): string {
        switch (id) {
        case "screen":
            return Tr.tr("Screen");
        case "camera":
            return Tr.tr("Camera");
        case "speakers":
            return Tr.tr("Speakers");
        case "keyboard":
            return Tr.tr("Keyboard");
        case "touchpad":
            return Tr.tr("Touchpad");
        }
        return id;
    }

    // Clique numa area do notebook: a tela abre o Display com a tela do
    // notebook escolhida; as outras abrem a aba "laptop"/"touchpad"/"output"
    function openPart(id: string): void {
        const p = L.laptopParts().find(h => h.id === id);
        if (p)
            root.open(p.page, p.tab || (root.laptop?.name ?? ""));
    }

    // Caixa (cm) das pecas visiveis + a mesa: e o que aparece fora da edicao.
    // De quebra recolhe a lista das pecas visiveis para a edicao.
    function refit(): void {
        let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
        const list = [];
        for (const c of root.children) {
            if (c.key === undefined || !c.visible)
                continue;
            list.push({ key: c.key, label: c.label, kind: c.kind, online: c.online, device: c.device, x: c.xCm, y: c.yCm, w: c.wCm, h: c.hCm });
            x0 = Math.min(x0, c.xCm);
            y0 = Math.min(y0, c.yCm);
            x1 = Math.max(x1, c.xCm + c.wCm);
            y1 = Math.max(y1, c.yCm + c.hCm);
        }
        root.pieces = L.orderPieces(list);
        if (x0 === Infinity) {
            root.fit = Qt.rect(0, 0, root.worldW, root.deskY + 40);
            return;
        }
        root.fit = Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    implicitHeight: (root.fit.height + root.padY * 2) * root.cm
    opacity: root.ready ? 1 : 0

    onLayoutChanged: Qt.callLater(root.refit)
    onShowOfflineChanged: Qt.callLater(root.refit)
    onEditingChanged: {
        if (!root.editing) {
            root.selectedKey = "";
            root.highlightKey = "";
        }
        Qt.callLater(root.refit);
    }
    onMonitorsChanged: Qt.callLater(root.refit)
    onMiceChanged: Qt.callLater(root.refit)
    onKeyboardChanged: Qt.callLater(root.refit)
    onHeadphonesChanged: Qt.callLater(root.refit)
    onControllersChanged: Qt.callLater(root.refit)
    onNasChanged: Qt.callLater(root.refit)
    Component.onCompleted: Qt.callLater(root.refit)

    Behavior on opacity {
        Anim {}
    }

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
            root.refit();
            root.ready = true;
        }
        onLoadFailed: {
            root.layout = {};
            root.refit();
            root.ready = true;
        }
    }

    // Grade da edicao: linhas finas a cada 2,5 cm (5 quando nao cabem) e
    // fortes a cada 10 cm; e nela que as pecas encaixam ao soltar
    Canvas {
        id: grid

        readonly property color minor: Qt.alpha(root.faint, 0.25)
        readonly property color major: Qt.alpha(root.faint, 0.7)

        anchors.fill: parent
        visible: root.editing
        onVisibleChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onMinorChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!root.editing || root.cm <= 0)
                return;
            const steps = L.gridSteps(root.cm);
            const isMajor = v => Math.abs(v / steps.major - Math.round(v / steps.major)) < 1e-6;
            // so as linhas que caem no trecho visivel do mundo (multiplos do passo)
            const x0 = Math.floor(-root.ox / steps.minor) * steps.minor;
            const x1 = grid.width / root.cm - root.ox;
            const y0 = Math.floor(-root.oy / steps.minor) * steps.minor;
            const y1 = grid.height / root.cm - root.oy;
            ctx.lineWidth = 1;
            for (let x = x0; x <= x1 + 1e-6; x += steps.minor) {
                const px = Math.round((x + root.ox) * root.cm) + 0.5;
                ctx.strokeStyle = isMajor(x) ? grid.major : grid.minor;
                ctx.beginPath();
                ctx.moveTo(px, 0);
                ctx.lineTo(px, grid.height);
                ctx.stroke();
            }
            for (let y = y0; y <= y1 + 1e-6; y += steps.minor) {
                const py = Math.round((y + root.oy) * root.cm) + 0.5;
                ctx.strokeStyle = isMajor(y) ? grid.major : grid.minor;
                ctx.beginPath();
                ctx.moveTo(0, py);
                ctx.lineTo(grid.width, py);
                ctx.stroke();
            }
        }

        Connections {
            function onOxChanged(): void {
                grid.requestPaint();
            }

            function onOyChanged(): void {
                grid.requestPaint();
            }

            target: root
        }
    }

    // Linha da mesa (borda de tras do tampo)
    Rectangle {
        x: 0
        y: (root.deskY + root.oy) * root.cm
        width: root.width
        height: 1
        color: root.ink
    }

    // ------------------------------------------------------------ monitores
    Repeater {
        model: root.externals.length

        Piece {
            id: ext

            required property int index
            readonly property var mon: root.externals[index] ?? ({})
            readonly property bool lg: /LG ULTRAWIDE/i.test(ext.mon.description ?? "")

            key: `monitor:${ext.mon.name}`
            kind: "monitor"
            defX: root.autoX(`monitor:${ext.mon.name}`)
            defY: root.autoY(`monitor:${ext.mon.name}`)
            wCm: 59
            hCm: root.monitorH(ext.mon)
            label: ((ext.mon.description || ext.mon.name) ?? "").replace(/^LG Electronics\s+/i, "").replace(/\s+0x[0-9A-Fa-f]+$/, "")
            online: root.monitorOn(ext.mon)
            showOffline: root.showOffline
            onClicked: root.open("display", ext.mon.name)

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
    // Areas clicaveis (setup.js): tela -> Display (tela do notebook), camera
    // -> Camera > Laptop, teclado -> Keyboard > Laptop, touchpad -> Mouse >
    // Touchpad, grades laterais -> Sound > Output; o resto do chassi -> Display
    Piece {
        id: lap

        key: "laptop"
        kind: "laptop"
        defX: root.autoX("laptop")
        defY: root.autoY("laptop")
        wCm: 35.5
        hCm: 35.5 * 1243 / 918
        label: Tr.tr("Laptop")
        visible: !!root.laptop
        online: !!root.laptop?.enabled
        showOffline: true
        hotspots: root.laptopParts
        onClicked: root.open("display", root.laptop?.name ?? "")
        onPartClicked: id => root.openPart(id)

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

    // --------------------------------------------------------------- tablet
    // Galaxy Tab S8+ de frente (assets/devices/galaxy-tab-s8-plus.svg, pelas
    // fotos: corpo 28,5 x 18,5 cm, moldura uniforme, camera no centro da borda
    // de cima, S Pen encostada nela), em pe na mesinha ao lado dos monitores ou,
    // sem monitor externo, na mesa ao lado do notebook. Existe
    // quando ha um tablet pareado no caelestia-tablet e so e "ligado" enquanto e
    // a saida virtual `tablet`; clicar abre o Display nessa saida.
    Piece {
        id: tab

        key: "tablet"
        kind: "tablet"
        defX: root.autoX("tablet")
        defY: root.autoY("tablet")
        wCm: 28.5
        hCm: 28.5 * 1900 / 2850
        label: root.tablet?.label || Tr.tr("Tablet")
        visible: !!root.tablet && (tab.online || root.showOffline)
        online: !!root.tablet?.online
        showOffline: root.showOffline
        onClicked: root.open("display", root.tablet?.output ?? "")

        Image {
            id: tabArt

            anchors.fill: parent
            source: Quickshell.shellPath("assets/devices/galaxy-tab-s8-plus.svg")
            fillMode: Image.PreserveAspectFit
            sourceSize.width: tabArt.width * root.dpr
            smooth: true
            asynchronous: true

            layer.enabled: true
            layer.effect: Colouriser {
                colorizationColor: root.ink
                brightness: 1
            }
        }
    }

    // ------------------------------------------------------------------ NAS
    // Frente do DXP4800 Plus apoiada na mesa, no comeco do grupo de cima (antes
    // do suporte do fone e da mesinha); existe sempre que ha um NAS
    // configurado, mas so e "ligado" quando responde
    Piece {
        id: nasPiece

        key: "nas"
        kind: "nas"
        defX: root.autoX("nas")
        defY: root.autoY("nas")
        wCm: 17.8
        hCm: 17.8
        label: !root.nas ? "" : root.nas.online ? Tr.tr("NAS · DXP4800 Plus") : root.nas.lastSeen ? Tr.tr("NAS · last seen %1").arg(root.nas.lastSeen) : Tr.tr("NAS · out of reach")
        visible: !!root.nas && (nasPiece.online || root.showOffline)
        online: !!root.nas?.online
        showOffline: root.showOffline
        onClicked: root.open("server", "overview")

        NasFrontArt {
            anchors.fill: parent
            info: root.nas?.info ?? ({})
            online: nasPiece.online
            ink: root.ink
            faint: root.faint
        }
    }

    // ------------------------------------------------------------- mesinha
    // Apoio horizontal das telas: tao larga quanto os monitores externos (e o
    // tablet) em cima dela, do pe deles ate a linha da mesa; sem monitor
    // externo nao existe
    Piece {
        id: shelf

        // o topo fica onde foi posto (sob o pe do monitor); a base desce ate a
        // linha da mesa
        readonly property real topCm: root.layout["shelf"]?.y ?? (root.auto.shelf?.y ?? root.deskY - root.shelfH)

        key: "shelf"
        kind: "shelf"
        defX: root.auto.shelf?.x ?? 0
        defY: root.auto.shelf?.y ?? root.deskY - root.shelfH
        wCm: root.auto.shelf?.w ?? 59
        hCm: Math.max(2, root.deskY - shelf.topCm)
        label: Tr.tr("Monitor riser")
        device: false
        visible: !!root.auto.shelf

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
    Piece {
        key: "mousepad"
        kind: "mousepad"
        defX: root.autoX("mousepad")
        defY: root.autoY("mousepad")
        wCm: 90
        hCm: 25
        label: Tr.tr("Mousepad · 90 × 25 cm")
        device: false

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

        Piece {
            id: pad

            required property int index
            readonly property var dev: root.controllers[index] ?? ({})

            key: `controller:${pad.index}`
            kind: "controller"
            defX: root.autoX(`controller:${pad.index}`)
            defY: root.autoY(`controller:${pad.index}`)
            wCm: 15.3
            hCm: 10.2
            label: pad.dev.name ?? Tr.tr("Controller")
            online: !!pad.dev.connected
            showOffline: root.showOffline
            onClicked: root.open("bluetooth", "")

            MaterialIcon {
                anchors.centerIn: parent
                text: "stadia_controller"
                color: root.ink
                fontStyle: Tokens.font.icon.size(Math.max(8, pad.width * 0.95)).build()
            }
        }
    }

    // --------------------------------------------------------------- teclado
    Piece {
        id: kbd

        key: "keyboard"
        kind: "keyboard"
        defX: root.autoX("keyboard")
        defY: root.autoY("keyboard")
        wCm: 32.6
        hCm: 32.6 * 793 / 1867
        label: root.keyboard ? [(root.keyboard.name ?? "").replace(/\s*2\.4GHz$/, ""), root.keyboard.battery !== null && root.keyboard.battery !== undefined ? `${Math.round(root.keyboard.battery * 100)}%` : ""].filter(x => x).join(" · ") : ""
        visible: !!root.keyboard && (kbd.online || root.showOffline)
        online: !!root.keyboard?.online
        showOffline: root.showOffline
        onClicked: root.open("keyboard", root.keyboard?.id ?? "")

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

        Piece {
            id: mouse

            required property int index
            readonly property var dev: root.mice[index] ?? ({})
            readonly property bool naga: (mouse.dev.model ?? "").includes("naga")

            key: `mouse:${mouse.dev.model}`
            kind: "mouse"
            defX: root.autoX(`mouse:${mouse.dev.model}`)
            defY: root.autoY(`mouse:${mouse.dev.model}`)
            wCm: mouse.naga ? 7.5 : 7.1
            hCm: mouse.naga ? 12 : 10
            label: (mouse.dev.name ?? "").replace(/\s*\(.*?\)\s*$/, "")
            online: !!mouse.dev.online
            showOffline: root.showOffline
            onClicked: root.open("mouse", mouse.dev.model ?? "")

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

        Piece {
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
            kind: "headphones"
            defX: root.autoX(`headphones:${hp.dev.model}`)
            defY: root.autoY(`headphones:${hp.dev.model}`)
            wCm: hp.big ? 21.7 : root.budW(hp.dev.model)
            hCm: hp.big ? hp.standH : root.budH(hp.dev.model)
            label: [hp.dev.name, hp.dev.model].filter(x => x).join(" · ")
            visible: (hp.file !== "" || !hp.big) && (hp.online || root.showOffline)
            online: !!hp.dev.connected
            showOffline: root.showOffline
            onClicked: root.open("sound", "output")

            // Suporte: base oval na mesa, haste e o gancho -- por baixo da
            // banda, dentro do arco, segurando-a (a banda tem ~1,5 cm)
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
                y: 3.4 * root.cm
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
                y: 3.0 * root.cm
                width: 5 * root.cm
                height: 1.4 * root.cm
                radius: height / 2
                color: "transparent"
                border.width: 1
                border.color: root.ink
            }

            // Estojos abertos, como nos guias (so linhas; o SVG de cada modelo):
            // ao pe do suporte, lado a lado, na mesa
            Image {
                id: hpArt

                visible: hp.file !== ""
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

    // Uma peca com tudo o que e igual para todas: mundo (cm, deslocamento,
    // mesa, grade), edicao e os sinais que o diagrama trata
    component Piece: SetupPiece {
        layout: root.layout
        cm: root.cm
        ox: root.ox
        oy: root.oy
        animate: root.ready
        deskCm: root.deskY
        snapCm: root.snapCm
        editing: root.editing
        highlighted: root.highlightKey === key
        selected: root.selectedKey === key
        onHover: (l, on) => root.setHover(l, on)
        onHoverKey: (k, on) => root.setHoverKey(k, on)
        onPressedPiece: k => root.selectedKey = k
        onMoved: (k, x, y) => root.place(k, x, y)
    }
}
