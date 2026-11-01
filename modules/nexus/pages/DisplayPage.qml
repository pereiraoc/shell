pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.display

// Telas, em abas: General (o arranjo dos monitores -- arrastar para mover,
// clicar para escolher -- e, embaixo, o monitor escolhido: resolucao/taxa,
// escala, brilho, lado da barra, liga/desliga; depois os monitores conhecidos
// e o tamanho de texto dos apps X11, o tablet no cabo). Logica no caelestia-display
// (repositorio de setup): toda mudanca e aplicada SO ao vivo (try-*) e o
// banner de 15 s pergunta se mantem -- sem resposta, volta ao monitors.conf.
// O banner fica acima das abas, para aparecer em qualquer uma.
PageBase {
    id: root

    readonly property var monitors: (bridge.info.monitors ?? []).filter(m => m.connected)
    readonly property int enabledCount: root.monitors.filter(m => m.enabled).length
    readonly property bool pending: !!bridge.info.pending
    // Monitor escolhido no arranjo (nome do Hyprland); vazio = o primeiro
    property string selected
    readonly property var selectedMon: root.monitors.find(m => m.name === root.selected) ?? root.monitors[0] ?? null
    readonly property var monLabels: {
        const o = {};
        for (const m of root.monitors)
            o[m.name] = root.tabLabel(m);
        return o;
    }

    function tryChange(id: string): void {
        bridge.run({ id: id });
    }

    function scaleLabel(m: var, s: real): string {
        const [w, h] = (m.mode.split("@")[0] ?? "").split("x").map(Number);
        const pct = `${Math.round(s * 100)}%`;
        return w ? `${pct} · ${Math.round(w / s)}×${Math.round(h / s)}` : pct;
    }

    function modeLabel(mode: string): string {
        const [res, hz] = mode.split("@");
        return `${res.replace("x", " × ")} · ${hz} Hz`;
    }

    function friendlyName(m: var): string {
        if (m.internal)
            return qsTr("Built-in display");
        // "LG Electronics LG ULTRAWIDE 0x01010101" -> sem o serial no fim
        const d = (m.description ?? "").replace(/\s*\(.*\)$/, "").replace(/\s+(0x)?[0-9A-Fa-f]{6,}$/, "");
        return d || m.name;
    }

    // Rotulo curto da aba: "Laptop screen" / "LG ULTRAWIDE" (sem a marca repetida)
    function tabLabel(m: var): string {
        if (m.internal)
            return qsTr("Laptop screen");
        const d = root.friendlyName(m);
        const words = d.split(/\s+/);
        return words.length > 2 ? words.slice(-2).join(" ") : d;
    }

    function pickRequested(): void {
        const want = root.nState.requestedTab;
        if (want && root.monitors.some(m => m.name === want)) {
            root.selected = want;
            root.tab = "general";
            root.nState.requestedTab = "";
        }
    }

    title: qsTr("Display")
    description: qsTr("Resolution, refresh rate, scale and brightness for each screen")
    tabs: [
        { id: "general", label: qsTr("General") }
    ]

    // Deep link com o nome do monitor (busca, Home, IPC): escolhe-o no
    // arranjo. PageBase so aceita Item como filho direto.
    // O pedido costuma chegar ANTES da pagina existir e antes da lista de
    // monitores: confere tambem ao nascer e quando a lista chega.
    Item {
        Component.onCompleted: root.pickRequested()

        Connections {
            function onRequestedTabChanged(): void {
                root.pickRequested();
            }

            target: root.nState
        }

        Connections {
            function onMonitorsChanged(): void {
                root.pickRequested();
            }

            target: root
        }
    }

    // Monitores conhecidos (caelestia-app-monitor), base do App placement
    ToolBridge {
        id: appmon

        tool: "app-monitor"
    }

    ToolBridge {
        id: bridge

        tool: "display"

        // Com mudanca pendente, acompanha o prazo: a reversao automatica
        // acontece fora do shell e so aparece aqui no proximo refresh.
        Timer {
            interval: 2000
            repeat: true
            running: root.pending && root.visible
            onTriggered: bridge.refresh()
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
            visible: bridge.error !== ""
            icon: "error"
            iconColour: Colours.palette.m3error
            label: qsTr("Could not read display settings")
            subtext: bridge.error
        }

        RevertBanner {
            id: banner

            first: true
            last: true
            visible: root.pending
            deadline: bridge.info.pending?.deadline ?? 0
            text: bridge.busyAction ? qsTr("Applying…") : qsTr("Keep these display settings?")
            onKeep: bridge.run({ id: "keep" })
            onRevert: bridge.run({ id: "revert" })
        }

        ActionErrorRow {
            bridge: bridge
        }

        // ----------------------------------------------------------- General
        TabPane {
            active: root.tab === "general"

            // Arranjo: arrastar move (try-pos, com o banner de 15 s), clicar escolhe
            MonitorArrangement {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                monitors: root.monitors
                selected: root.selectedMon?.name ?? ""
                labels: root.monLabels
                onPicked: name => root.selected = name
                onMoved: (name, x, y) => root.tryChange(`try-pos-${name}-${x}x${y}`)
            }

            StyledText {
                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.spacing.medium
                text: root.monitors.length > 1 ? qsTr("Drag a screen to move it next to another; tap one to change its settings below") : qsTr("Tap the screen to change its settings below")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            // O monitor escolhido
            ColumnLayout {
                id: mon

                readonly property var modelData: root.selectedMon ?? ({})
                readonly property var brightness: Brightness.getMonitor(mon.modelData.name ?? "")
                // `-<nome>` no fim ou `-<nome>-` no meio: so endsWith(nome) fazia
                // try-off-eDP-1 marcar o DP-1 como ocupado
                readonly property bool busy: bridge.busyAction.endsWith(`-${mon.modelData.name ?? "§"}`) || bridge.busyAction.includes(`-${mon.modelData.name}-`)

                Layout.fillWidth: true
                visible: !!root.selectedMon
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: root.selectedMon ? root.friendlyName(root.selectedMon) : ""
                }

                InfoRow {
                    first: true
                    icon: mon.modelData.internal ? "laptop" : "desktop_windows"
                    label: mon.modelData.enabled ? qsTr("%1 · %2 workspace area").arg(mon.modelData.name).arg((mon.modelData.logical ?? "").replace("x", " × ")) : qsTr("%1 · off").arg(mon.modelData.name)
                    subtext: [mon.modelData.description, mon.modelData.enabled ? qsTr("at %1").arg(mon.modelData.position) : ""].filter(x => x).join(" · ")
                }

                // Agora (so esta sessao) x ao ligar (monitors.conf): 240 Hz
                // para jogar sem mudar o padrao. O keep nao grava resolucao/taxa.
                ExpandSelectRow {
                    visible: mon.modelData.enabled
                    icon: "aspect_ratio"
                    label: qsTr("Resolution & refresh rate")
                    subtext: qsTr("For this session. Higher refresh rate means smoother motion")
                    options: (mon.modelData.modes ?? []).map(m => ({ value: m, label: root.modeLabel(m) }))
                    current: mon.modelData.mode ?? ""
                    busy: mon.busy && bridge.busyAction.startsWith("try-mode")
                    onPicked: v => root.tryChange(`try-mode-${mon.modelData.name}-${v}`)
                }

                ExpandSelectRow {
                    visible: mon.modelData.enabled && !!mon.modelData.saved_mode
                    icon: "power_settings_new"
                    label: qsTr("At startup")
                    subtext: qsTr("Used every time the computer starts. Also applies now")
                    options: (mon.modelData.modes ?? []).map(m => ({ value: m, label: root.modeLabel(m) }))
                    current: mon.modelData.saved_mode ?? ""
                    busy: bridge.busyAction.startsWith(`default-mode-${mon.modelData.name}-`)
                    onPicked: v => bridge.run({ id: `default-mode-${mon.modelData.name}-${v}` })
                }

                ChipSelectRow {
                    visible: mon.modelData.enabled
                    label: qsTr("Scale")
                    subtext: qsTr("Makes text, apps and the shell bigger. Whole numbers are always sharp.")
                    options: (mon.modelData.valid_scales ?? []).map(s => ({ value: String(s), label: `${Math.round(s * 100)}%` }))
                    current: String((mon.modelData.valid_scales ?? []).find(s => Math.abs(s - mon.modelData.scale) < 0.01) ?? mon.modelData.scale)
                    busy: mon.busy && bridge.busyAction.startsWith("try-scale")
                    onPicked: v => root.tryChange(`try-scale-${mon.modelData.name}-${v}`)
                }

                SliderRow {
                    visible: mon.modelData.enabled && !!mon.brightness
                    icon: "brightness_6"
                    label: qsTr("Brightness")
                    valueLabel: `${Math.round((mon.brightness?.brightness ?? 0) * 100)}%`
                    value: mon.brightness?.brightness ?? 0
                    onMoved: v => mon.brightness?.setBrightness(v)
                }

                // Lado da barra neste monitor (Screens.barSides). Na
                // direita o shell espelha: barra e menus dela na direita,
                // notificacoes/sidebar/OSD na esquerda. Aplica na hora.
                ChipSelectRow {
                    visible: mon.modelData.enabled
                    label: qsTr("Bar position")
                    subtext: Screens.barRight(mon.modelData.name ?? "") ? qsTr("Notifications, sidebar and volume pop-up move to the left edge") : ""
                    options: [
                        { value: "left", label: qsTr("Left"), icon: "align_horizontal_left" },
                        { value: "right", label: qsTr("Right"), icon: "align_horizontal_right" }
                    ]
                    current: Screens.barRight(mon.modelData.name ?? "") ? "right" : "left"
                    onPicked: v => Screens.setBarOption(mon.modelData.name, "side", v)
                }

                ToggleRow {
                    visible: mon.modelData.enabled && Screens.barRight(mon.modelData.name ?? "")
                    text: qsTr("Mirror the wallpaper visualiser")
                    subtext: qsTr("Light and music bars flow from the bar side")
                    checked: Screens.mirrorVisualiser(mon.modelData.name ?? "")
                    onToggled: Screens.setBarOption(mon.modelData.name, "mirrorVisualiser", checked)
                }

                ToggleRow {
                    last: true
                    text: qsTr("Use this display")
                    subtext: mon.modelData.enabled && root.enabledCount <= 1 ? qsTr("This is the only screen on") : qsTr("Windows move to the other screen when it turns off")
                    checked: !!mon.modelData.enabled
                    disabled: mon.busy || (mon.modelData.enabled && root.enabledCount <= 1)
                    onToggled: root.tryChange(`${checked ? "try-on" : "try-off"}-${mon.modelData.name}`)
                }
            }

            // Monitores ja conectados alguma vez (caelestia-app-monitor): e deles que
            // sai a escolha de monitor por app em Apps > App placement.
            SectionHeader {
                text: qsTr("Known monitors")
            }

            Repeater {
                model: (appmon.info.monitors ?? []).length

                ColumnLayout {
                    id: known

                    required property int index
                    readonly property var mon: appmon.info.monitors[index] ?? ({})
                    readonly property int count: (appmon.info.monitors ?? []).length
                    property bool confirmForget

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall / 2

                    InfoRow {
                        first: known.index === 0
                        icon: known.mon.internal ? "laptop" : "desktop_windows"
                        iconColour: known.mon.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                        label: known.mon.label ?? ""
                        subtext: `${known.mon.connected ? qsTr("Connected · %1").arg(known.mon.connector) : qsTr("Not connected")} · ${known.mon.width}×${known.mon.height}`
                    }

                    TextFieldRow {
                        label: qsTr("Nickname")
                        subtext: qsTr("Shown when picking where an app opens")
                        value: known.mon.alias ?? ""
                        placeholderText: known.mon.label ?? ""
                        maximumLength: 40
                        smallField: true
                        onEditingFinished: v => {
                            if (v !== (known.mon.alias ?? ""))
                                appmon.run({ id: `alias~${known.mon.id}~${v}` });
                        }
                    }

                    RowButton {
                        last: known.index === known.count - 1
                        visible: !known.mon.connected
                        icon: "delete"
                        text: known.confirmForget ? qsTr("Click again to forget") : qsTr("Forget this monitor")
                        onClicked: {
                            if (!known.confirmForget) {
                                known.confirmForget = true;
                                return;
                            }
                            appmon.run({ id: `forget~${known.mon.id}` });
                            known.confirmForget = false;
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Text size for X11 apps")
            }

            ChipSelectRow {
                first: true
                last: true
                label: qsTr("Steam, games and other X11 apps")
                subtext: qsTr("These apps ignore the per-screen scale. Restart them after changing.")
                options: [
                    { value: "96", label: "100%" },
                    { value: "120", label: "125%" },
                    { value: "144", label: "150%" },
                    { value: "192", label: "200%" }
                ]
                current: String(bridge.info.xft_dpi ?? "")
                busy: bridge.busyAction.startsWith("dpi-")
                onPicked: v => bridge.run({ id: `dpi-${v}` })
            }

            // Tablet Android como monitor pelo cabo USB. Logica no caelestia-tablet
            // (repositorio de setup, CF-28): ao conectar o tablet pareado, saida virtual
            // do Hyprland + wayvnc + porta pelo cabo (adb reverse) + AVNC aberto no
            // tablet. Aqui so pareamento e liga/desliga; a saida "tablet" entra no
            // arranjo acima como qualquer monitor.
            ToolSection {
                Layout.topMargin: Tokens.spacing.large
                tool: "tablet"
                title: qsTr("Tablet as a monitor")
                icon: "tablet_android"
                hint: qsTr("An Android tablet with USB debugging on becomes an extra display over the cable (AVNC app on the tablet). Pair it once; it connects on its own after that.")
            }

            AdvancedGroup {
                Layout.topMargin: Tokens.spacing.large
                apps: [
                    { id: "nwg-displays", text: qsTr("Arrange displays"), subtext: qsTr("Position screens side by side, mirror (nwg-displays)") }
                ]
            }
        }
    }
}
