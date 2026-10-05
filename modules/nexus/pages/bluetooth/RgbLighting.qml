pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Iluminacao de um teclado/periferico RGB (Devices > <device> > Lighting):
// efeito, cores, brilho e velocidade -- caelestia-peripherals
// `rgb-<dev>-apply-...`, validado pelas capacidades de cada modo (`caps`).
// Cada mudanca aplica na hora (agrupada em ~0,3 s); com uma aplicacao em
// curso, a ultima pedida espera e vai em seguida. O OpenRGB nao le cor/brilho
// do teclado: o que aparece aqui e o ultimo efeito aplicado (`settings`).
PageBase {
    id: root

    readonly property var dev: (bridge.info.rgb ?? []).find(d => d.id === root.nState.selectedRgbDevice) ?? null
    readonly property var caps: root.dev?.caps ?? ({})
    readonly property var modeCaps: root.caps[root.mode] ?? ({ colors: [0, 0], random: false, brightness: false, speed: false })
    readonly property string theme: bridge.info.theme_colour ?? "ffffff"

    // Rascunho (o que o usuario escolheu), iniciado do ultimo efeito salvo.
    property bool inited
    property bool off
    property string mode: "Static"
    property var colors: []
    property bool random
    property int brightness: 100
    property int speed: 50
    property string direction
    readonly property bool pending: !!root.dev?.settings?.pending
    readonly property var dirs: root.modeCaps.directions ?? []
    // Velocidades que o aparelho tem (o do notebook: 3; o Azoth: 4)
    readonly property var speeds: root.modeCaps.speeds ?? [25, 50, 75, 100]
    readonly property bool laptop: root.dev?.backend === "asusd"
    readonly property var power: root.dev?.power ?? ({})
    property int slot: 0

    property string wanted
    property string sent

    readonly property var effects: [
        { mode: "Static", label: qsTr("Solid"), icon: "circle" },
        { mode: "Breathing", label: qsTr("Breathing"), icon: "air" },
        { mode: "Reactive", label: qsTr("Key press"), icon: "touch_app" },
        { mode: "Ripple", label: qsTr("Ripple"), icon: "radio_button_checked" },
        { mode: "Rain Drop", label: qsTr("Rain"), icon: "water_drop" },
        { mode: "Starry Night", label: qsTr("Starry night"), icon: "star" },
        { mode: "Current", label: qsTr("Current"), icon: "bolt" },
        { mode: "Quicksand", label: qsTr("Quicksand"), icon: "hourglass_bottom" },
        { mode: "Pulse", label: qsTr("Pulse"), icon: "favorite" },
        { mode: "Rainbow Wave", label: qsTr("Wave"), icon: "waves" },
        { mode: "Spectrum Cycle", label: qsTr("Cycle"), icon: "autorenew" }
    ].filter(e => !!root.caps[e.mode])

    // Paleta: cor do tema primeiro, depois um circulo cromatico.
    readonly property var palette: [root.theme, "ffffff", "ff3b30", "ff8c1a", "ffcc00", "a6e22e", "34c759", "1ec8a5", "32d2f5", "2f7bff", "5856d6", "a64dff", "ff2dc8", "ff6b9a"]
    readonly property var rainbow: ["ff3b30", "ff8c1a", "ffcc00", "34c759", "2f7bff", "a64dff", "ff2dc8", "32d2f5"]

    function slug(m: string): string {
        return m.toLowerCase().replace(/[^a-z0-9]+/g, "-");
    }

    // Ajusta o numero de cores ao modo: completa com a paleta, corta o excesso.
    function fitColors(list: var, m: string): var {
        // dev.caps, nao root.caps: no onDevChanged o binding de caps ainda nao
        // foi reavaliado.
        const [lo, hi] = ((root.dev?.caps ?? {})[m] ?? { colors: [0, 0] }).colors;
        let out = (list ?? []).slice(0, hi);
        const fill = lo > 1 ? root.rainbow : [root.theme];
        let i = 0;
        while (out.length < Math.max(lo, hi > 0 ? 1 : 0))
            out.push(fill[i++ % fill.length]);
        return out;
    }

    function actionId(): string {
        if (!root.dev)
            return "";
        if (root.off)
            return `rgb-${root.dev.id}-off`;
        const c = root.modeCaps;
        let id = `rgb-${root.dev.id}-apply-${root.slug(root.mode)}`;
        if (c.colors[1] > 0)
            id += root.random && c.random ? "-c-random" : `-c-${root.colors.join(".")}`;
        if (c.brightness)
            id += `-b-${root.brightness}`;
        if (c.speed)
            id += `-s-${root.speed}`;
        if ((c.directions ?? []).length > 0)
            id += `-d-${(c.directions.includes(root.direction) ? root.direction : c.directions[0])}`;
        return id;
    }

    function changed(): void {
        root.wanted = root.actionId();
        applyTimer.restart();
    }

    function flush(): void {
        if (!root.wanted || root.wanted === root.sent || bridge.busyAction !== "")
            return;
        root.sent = root.wanted;
        bridge.run({ id: root.wanted });
    }

    function init(): void {
        if (root.inited || !root.dev)
            return;
        root.inited = true;
        const s = root.dev.settings;
        const caps = root.dev.caps ?? {};
        if (s && caps[s.mode]) {
            root.off = s.mode === "Static" && (s.colors ?? [])[0] === "000000";
            root.mode = root.off ? "Static" : s.mode;
            root.colors = root.fitColors(root.off ? [root.theme] : s.colors, root.mode);
            root.random = !!s.random;
            root.brightness = s.brightness ?? 100;
            root.speed = s.speed ?? 50;
            const speeds = caps[root.mode]?.speeds ?? [25, 50, 75, 100];
            if (!speeds.includes(root.speed))
                root.speed = speeds.reduce((a, b) => Math.abs(b - root.speed) < Math.abs(a - root.speed) ? b : a, speeds[0]);
            root.direction = s.direction ?? "";
        } else {
            root.mode = caps["Static"] ? "Static" : (Object.keys(caps)[0] ?? "Static");
            root.colors = root.fitColors([root.theme], root.mode);
        }
        root.sent = root.actionId();
    }

    title: root.dev ? root.dev.name.replace(/\s*2\.4GHz$/, "") : qsTr("Lighting")
    description: qsTr("Lighting effect, colours, brightness and speed")
    isSubPage: true

    onDevChanged: Qt.callLater(root.init)
    Component.onCompleted: root.init()

    ToolBridge {
        id: bridge

        tool: "peripherals"
        onBusyActionChanged: root.flush()
    }

    // Efeito pedido com o teclado dormindo fica pendente: tenta de novo
    // enquanto a pagina estiver aberta (aperte uma tecla e ele entra).
    Item {
        Timer {
            interval: 4000
            repeat: true
            running: root.pending && root.visible
            onTriggered: {
                if (bridge.busyAction === "")
                    bridge.run({ id: "rgb-restore" });
            }
        }
    }

    // PageBase so aceita Item como filho direto.
    Item {
        Timer {
            id: applyTimer

            interval: 300
            onTriggered: root.flush()
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: !root.dev
            icon: "keyboard_off"
            label: qsTr("Device not found")
            subtext: qsTr("It may be off or disconnected. Wake it up and come back.")
        }

        // Previa: faixa com as cores escolhidas (como a luz do teclado vai ficar)
        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.dev
            first: true
            last: true
            implicitHeight: previewCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: previewCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.small

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: "keyboard"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                        fill: 1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: root.off ? qsTr("Lights off") : (root.effects.find(e => e.mode === root.mode)?.label ?? root.mode)
                            font: Tokens.font.title.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: bridge.busyAction.startsWith("rgb-") ? qsTr("Applying…") : root.pending ? qsTr("The keyboard is asleep — press any key on it and this applies by itself") : root.dev?.backend === "hid" ? qsTr("Changes apply right away and are saved in the keyboard") : root.laptop ? qsTr("Changes apply right away and the laptop keeps them") : qsTr("Changes apply right away and come back when you log in")
                            color: root.pending ? Colours.palette.m3tertiary : Colours.palette.m3outline
                            font: Tokens.font.label.small
                            wrapMode: Text.WordWrap
                        }
                    }

                    CircularIndicator {
                        visible: bridge.busyAction.startsWith("rgb-")
                        running: visible
                        implicitSize: Tokens.font.icon.large.pointSize * 1.4
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Tokens.padding.large * 1.6
                    radius: Tokens.rounding.small
                    opacity: root.off ? 0.15 : 0.35 + 0.65 * root.brightness / 100
                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: root.previewAt(0)
                        }
                        GradientStop {
                            position: 0.5
                            color: root.previewAt(0.5)
                        }
                        GradientStop {
                            position: 1
                            color: root.previewAt(1)
                        }
                    }
                }
            }
        }

        ActionErrorRow {
            bridge: bridge
        }

        // Efeito
        SectionHeader {
            visible: !!root.dev
            text: qsTr("Effect")
        }

        GridLayout {
            Layout.fillWidth: true
            visible: !!root.dev
            columns: Math.max(3, Math.floor(width / 130))
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            EffectTile {
                label: qsTr("Off")
                icon: "light_off"
                selected: root.off
                onPicked: {
                    root.off = true;
                    root.changed();
                }
            }

            Repeater {
                model: root.effects

                EffectTile {
                    required property var modelData

                    label: modelData.label
                    icon: modelData.icon
                    selected: !root.off && root.mode === modelData.mode
                    onPicked: {
                        root.off = false;
                        root.mode = modelData.mode;
                        root.colors = root.fitColors(root.colors, root.mode);
                        root.slot = Math.min(root.slot, Math.max(0, root.colors.length - 1));
                        root.changed();
                    }
                }
            }
        }

        // Cores
        SectionHeader {
            visible: !!root.dev && !root.off && root.modeCaps.colors[1] > 0
            text: root.modeCaps.colors[1] > 1 ? qsTr("Colours") : qsTr("Colour")
        }

        ToggleRow {
            first: true
            visible: !!root.dev && !root.off && root.modeCaps.random
            text: qsTr("Random colours")
            subtext: qsTr("The keyboard picks the colours itself")
            checked: root.random
            onToggled: {
                root.random = checked;
                root.changed();
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.dev && !root.off && root.modeCaps.colors[1] > 0 && !(root.random && root.modeCaps.random)
            first: !root.modeCaps.random
            last: true
            implicitHeight: colourCol.implicitHeight + Tokens.padding.medium * 2

            ColumnLayout {
                id: colourCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                // Cores do efeito: escolha uma e pinte pela paleta
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: root.modeCaps.colors[1] > 1 ? qsTr("Effect colours") : qsTr("Colour")
                        font: Tokens.font.body.small
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: root.colors

                        Swatch {
                            required property string modelData
                            required property int index

                            hex: modelData
                            big: true
                            selected: root.colors.length > 1 && root.slot === index
                            onPicked: root.slot = index
                        }
                    }

                    IconButton {
                        visible: root.modeCaps.colors[1] > root.modeCaps.colors[0]
                        icon: "remove"
                        type: IconButton.Tonal
                        isRound: true
                        disabled: root.colors.length <= Math.max(1, root.modeCaps.colors[0])
                        onClicked: {
                            const c = root.colors.slice();
                            c.splice(root.slot, 1);
                            root.colors = c;
                            root.slot = Math.min(root.slot, c.length - 1);
                            root.changed();
                        }
                    }

                    IconButton {
                        visible: root.modeCaps.colors[1] > root.modeCaps.colors[0]
                        icon: "add"
                        type: IconButton.Tonal
                        isRound: true
                        disabled: root.colors.length >= root.modeCaps.colors[1]
                        onClicked: {
                            const c = root.colors.slice();
                            c.push(root.rainbow[c.length % root.rainbow.length]);
                            root.colors = c;
                            root.slot = c.length - 1;
                            root.changed();
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.modeCaps.colors[0] > 1
                    text: qsTr("This effect always uses %1 colours").arg(root.modeCaps.colors[0])
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    Repeater {
                        model: root.palette

                        Swatch {
                            required property string modelData
                            required property int index

                            hex: modelData
                            selected: (root.colors[root.slot] ?? "") === modelData
                            badge: index === 0 ? "palette" : ""
                            onPicked: root.setSlot(modelData)
                        }
                    }
                }

                TextFieldRow {
                    Layout.fillWidth: true
                    label: qsTr("Custom colour")
                    placeholderText: "RRGGBB"
                    value: root.colors[root.slot] ?? ""
                    maximumLength: 7
                    smallField: true
                    onEditingFinished: v => {
                        const h = v.replace(/^#/, "").toLowerCase();
                        if (/^[0-9a-f]{6}$/.test(h))
                            root.setSlot(h);
                    }
                }
            }
        }

        // Brilho e velocidade
        SectionHeader {
            visible: !!root.dev && !root.off && (root.modeCaps.brightness || root.modeCaps.speed || root.dirs.length > 0)
            text: qsTr("Look")
        }

        ChipSelectRow {
            first: true
            last: !root.modeCaps.speed
            visible: !!root.dev && !root.off && root.modeCaps.brightness
            label: qsTr("Brightness")
            options: [
                { value: "25", label: qsTr("Low") },
                { value: "50", label: qsTr("Medium") },
                { value: "75", label: qsTr("High") },
                { value: "100", label: qsTr("Max") }
            ]
            current: String(root.brightness)
            onPicked: v => {
                root.brightness = Number(v);
                root.changed();
            }
        }

        ChipSelectRow {
            first: !root.modeCaps.brightness
            last: root.dirs.length === 0
            visible: !!root.dev && !root.off && root.modeCaps.speed
            label: qsTr("Speed")
            options: root.speeds.map(v => ({
                        value: String(v),
                        label: ({ 25: qsTr("Slow"), 50: qsTr("Normal"), 75: qsTr("Fast"), 100: qsTr("Fastest") })[v] ?? `${v}%`
                    }))
            current: String(root.speed)
            onPicked: v => {
                root.speed = Number(v);
                root.changed();
            }
        }

        ChipSelectRow {
            first: !root.modeCaps.brightness && !root.modeCaps.speed
            last: true
            visible: !!root.dev && !root.off && root.dirs.length > 0
            label: qsTr("Direction")
            options: root.dirs.map(d => ({
                        value: d,
                        label: ({ left: qsTr("Left"), right: qsTr("Right"), up: qsTr("Up"), down: qsTr("Down") })[d],
                        icon: ({ left: "arrow_back", right: "arrow_forward", up: "arrow_upward", down: "arrow_downward" })[d]
                    }))
            current: root.dirs.includes(root.direction) ? root.direction : (root.dirs[0] ?? "")
            onPicked: v => {
                root.direction = v;
                root.changed();
            }
        }

        // Teclado do notebook: em que fases a luz acende (asusd LedPower)
        SectionHeader {
            visible: root.laptop && Object.keys(root.power).length > 0
            text: qsTr("Light also")
        }

        Repeater {
            model: root.laptop && Object.keys(root.power).length > 0 ? [
                { phase: "boot", label: qsTr("While starting up"), sub: qsTr("From power-on until the login screen") },
                { phase: "sleep", label: qsTr("While asleep"), sub: qsTr("With the laptop suspended") },
                { phase: "shutdown", label: qsTr("While shutting down"), sub: "" }
            ] : []

            ToggleRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === 2
                text: modelData.label
                subtext: modelData.sub
                checked: !!root.power[modelData.phase]
                disabled: bridge.busyAction !== ""
                onToggled: bridge.run({ id: `kbd-power-${modelData.phase}-${checked ? "on" : "off"}` })
            }
        }
    }

    function setSlot(hex: string): void {
        const c = root.colors.slice();
        if (c.length === 0)
            return;
        c[Math.min(root.slot, c.length - 1)] = hex;
        root.colors = c;
        root.changed();
    }

    // Cor da previa no ponto t (0..1): efeitos do arco-iris mostram o
    // espectro; os demais, as cores escolhidas espalhadas.
    function previewAt(t: real): color {
        if (root.off)
            return "#000000";
        if (root.mode === "Spectrum Cycle" || (root.random && root.modeCaps.random))
            return Qt.hsva(t * 0.83, 0.8, 1, 1);
        const c = root.colors;
        if (c.length === 0)
            return Qt.hsva(t * 0.83, 0.8, 1, 1);
        return `#${c[Math.min(c.length - 1, Math.round(t * (c.length - 1)))]}`;
    }

    component EffectTile: StyledRect {
        id: tile

        property string label
        property string icon
        property bool selected

        signal picked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: tileCol.implicitHeight + Tokens.padding.medium * 2
        radius: Tokens.rounding.large
        color: tile.selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: tile.radius
            color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
            disabled: tile.selected
            onClicked: tile.picked()
        }

        ColumnLayout {
            id: tileCol

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: tile.icon
                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
                fill: tile.selected ? 1 : 0
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: tile.label
                color: tile.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                font: Tokens.font.label.medium
            }
        }
    }

    component Swatch: Item {
        id: sw

        property string hex
        property bool selected
        property bool big
        property string badge

        signal picked

        implicitWidth: Tokens.font.icon.medium.pointSize * (sw.big ? 2.2 : 1.8)
        implicitHeight: implicitWidth

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: sw.selected ? 2 : 0
            border.color: Colours.palette.m3primary
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: width / 2
            color: `#${sw.hex}`
            border.width: 1
            border.color: Qt.alpha(Colours.palette.m3onSurface, 0.2)

            MaterialIcon {
                anchors.centerIn: parent
                visible: sw.badge !== ""
                text: sw.badge
                color: Qt.hsva(0, 0, 0, 0.6)
                fontStyle: Tokens.font.icon.small
            }
        }

        StateLayer {
            radius: width / 2
            onClicked: sw.picked()
        }
    }
}
