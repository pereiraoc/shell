pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Modos de um fone Bluetooth (Sound > <fone>): cancelamento de ruido,
// som ambiente, equalizador, gestos... -- caelestia-headphones, que conversa
// com o fone pelo protocolo do fabricante (Sony MDR, Huawei SPP). O estado e
// lido do proprio fone ao abrir a pagina e depois de cada mudanca.
PageBase {
    id: root

    readonly property var hp: (bridge.info.headphones ?? []).find(h => h.id === root.nState.selectedHeadphone) ?? null
    readonly property var st: root.hp?.state ?? ({})
    readonly property var caps: root.hp?.caps ?? ({})
    readonly property bool sony: root.hp?.family === "sony"
    readonly property bool ready: !!root.hp?.connected && !!root.hp?.state
    readonly property string busy: bridge.busyAction
    readonly property var btDevice: Bluetooth.devices.values.find(d => d.address?.toLowerCase() === root.hp?.address?.toLowerCase()) ?? null // qmllint disable unresolved-type

    // nivel do ambiente: aplica ~0,4 s depois de soltar o slider
    property int pendingLevel: -1

    function run(id: string): void {
        bridge.run({ id: id });
    }

    function batteryText(b: var): string {
        if (!b)
            return "";
        const parts = [];
        if (b.level != null)
            parts.push(`${b.level}%`);
        if (b.left != null)
            parts.push(qsTr("L %1%").arg(b.left));
        if (b.right != null)
            parts.push(qsTr("R %1%").arg(b.right));
        if (b.case != null)
            parts.push(qsTr("case %1%").arg(b.case));
        if (b.charging)
            parts.push(qsTr("charging"));
        return parts.join(" · ");
    }

    readonly property var eqLabels: ({
            "off": qsTr("Off"),
            "bright": qsTr("Bright"),
            "excited": qsTr("Excited"),
            "mellow": qsTr("Mellow"),
            "relaxed": qsTr("Relaxed"),
            "vocal": qsTr("Vocal"),
            "treble": qsTr("Treble boost"),
            "bass": qsTr("Bass boost"),
            "speech": qsTr("Speech"),
            "default": qsTr("Default"),
            "voice": qsTr("Voice")
        })

    readonly property var tapLabels: ({
            "off": qsTr("Nothing"),
            "play-pause": qsTr("Play / pause"),
            "next": qsTr("Next track"),
            "previous": qsTr("Previous track"),
            "assistant": qsTr("Voice assistant")
        })

    readonly property var gestureRows: [
        { key: "double_tap", id: "tap2", side: "left", label: qsTr("Double tap, left") },
        { key: "double_tap", id: "tap2", side: "right", label: qsTr("Double tap, right") },
        { key: "triple_tap", id: "tap3", side: "left", label: qsTr("Triple tap, left") },
        { key: "triple_tap", id: "tap3", side: "right", label: qsTr("Triple tap, right") }
    ]

    title: root.hp?.name ?? qsTr("Headphones")
    description: root.hp?.model ?? ""
    isSubPage: true

    ToolBridge {
        id: bridge

        tool: "headphones"
    }

    // PageBase so aceita Item como filho direto.
    Item {
        Timer {
            id: levelTimer

            interval: 400
            onTriggered: {
                if (root.pendingLevel > 0 && root.busy === "") {
                    root.run(`ambient-${root.hp.id}-${root.pendingLevel}`);
                    root.pendingLevel = -1;
                } else if (root.pendingLevel > 0) {
                    restart();
                }
            }
        }

        // Ao (re)abrir a pagina e quando o fone conecta: le o estado dele
        Connections {
            target: root.btDevice

            function onConnectedChanged(): void {
                refreshTimer.restart();
            }
        }

        Timer {
            id: refreshTimer

            interval: 2500
            onTriggered: bridge.refresh()
        }
    }

    onVisibleChanged: {
        if (visible)
            bridge.refresh();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        InfoRow {
            first: true
            last: true
            visible: !root.hp
            icon: "headphones"
            label: qsTr("Headphones not found")
            subtext: qsTr("Pair them first in Bluetooth")
        }

        // Cabecalho: estado, bateria, codec
        ConnectedRect {
            Layout.fillWidth: true
            visible: !!root.hp
            first: true
            last: !root.ready
            implicitHeight: headRow.implicitHeight + Tokens.padding.large * 2

            RowLayout {
                id: headRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: root.hp?.buds ? "earbuds" : "headphones"
                    color: root.hp?.connected ? Colours.palette.m3primary : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                    fill: root.hp?.connected ? 1 : 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: !root.hp?.connected ? qsTr("Not connected") : root.busy !== "" ? qsTr("Applying…") : bridge.loading ? qsTr("Reading the headphones…") : root.ready ? qsTr("Connected") : qsTr("Connected — no answer from the headphones")
                        font: Tokens.font.title.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: !root.hp?.connected ? qsTr("Connect them to change their modes") : root.hp?.error ? root.hp.error : [root.batteryText(root.st.battery), root.st.codec ?? ""].filter(x => x).join(" · ")
                        color: root.hp?.error ? Colours.palette.m3tertiary : Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                TextButton {
                    visible: !!root.hp && !root.hp.connected && !!root.btDevice
                    text: qsTr("Connect")
                    type: TextButton.Filled
                    onClicked: root.btDevice.connected = true
                }

                IconButton {
                    visible: !!root.hp?.connected
                    icon: "refresh"
                    type: IconButton.Text
                    disabled: root.busy !== ""
                    onClicked: bridge.refresh()
                }
            }
        }

        ActionErrorRow {
            bridge: bridge
        }

        // ---------------------------------------------------- Sony: ruido
        SectionHeader {
            visible: root.ready && !!root.st.noise
            text: qsTr("Noise control")
        }

        ChipSelectRow {
            first: true
            last: root.st.noise?.mode !== "ambient"
            visible: root.ready && !!root.st.noise
            label: qsTr("Mode")
            options: [
                { value: "nc", label: qsTr("Cancel noise"), icon: "noise_control_off" },
                { value: "ambient", label: qsTr("Ambient"), icon: "hearing" },
                { value: "off", label: qsTr("Off") }
            ]
            current: root.st.noise?.mode ?? ""
            busy: root.busy.startsWith("anc-")
            onPicked: v => root.run(`anc-${root.hp.id}-${v}`)
        }

        SliderRow {
            visible: root.ready && root.st.noise?.mode === "ambient"
            icon: "hearing"
            label: qsTr("How much of the outside you hear")
            valueLabel: root.pendingLevel > 0 ? String(root.pendingLevel) : String(root.st.noise?.ambient_level ?? "")
            value: (root.pendingLevel > 0 ? root.pendingLevel : (root.st.noise?.ambient_level ?? 10)) / 20
            onMoved: v => {
                root.pendingLevel = Math.max(1, Math.min(20, Math.round(v * 20)));
                levelTimer.restart();
            }
        }

        ToggleRow {
            last: true
            visible: root.ready && root.st.noise?.mode === "ambient"
            text: qsTr("Focus on voices")
            subtext: qsTr("Lets voices through and keeps the rest of the noise down")
            checked: !!root.st.noise?.voice
            disabled: root.busy !== ""
            onToggled: root.run(`voice-${root.hp.id}-${checked ? "on" : "off"}`)
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: true
            visible: root.ready && root.st.speak_to_chat != null
            text: qsTr("Speak-to-chat")
            subtext: qsTr("Pauses the music and lets the outside in when you start talking")
            checked: !!root.st.speak_to_chat
            disabled: root.busy !== ""
            onToggled: root.run(`stc-${root.hp.id}-${checked ? "on" : "off"}`)
        }

        // ------------------------------------------------- Som (os dois)
        SectionHeader {
            visible: root.ready && root.st.eq != null
            text: qsTr("Sound")
        }

        ExpandSelectRow {
            first: true
            last: root.st.quality == null && root.st.low_latency == null
            visible: root.ready && root.st.eq != null
            icon: "equalizer"
            label: qsTr("Equalizer")
            options: (root.caps.eq ?? []).map(e => ({ value: e, label: root.eqLabels[e] ?? e }))
            current: root.st.eq ?? ""
            busy: root.busy.startsWith("eq-")
            onPicked: v => root.run(`eq-${root.hp.id}-${v}`)
        }

        ChipSelectRow {
            visible: root.ready && root.st.quality != null
            label: qsTr("Prefer")
            subtext: qsTr("Better sound, or a connection that drops less in crowded places")
            options: [
                { value: "quality", label: qsTr("Sound quality") },
                { value: "connectivity", label: qsTr("Stable connection") }
            ]
            current: root.st.quality ?? ""
            busy: root.busy.startsWith("quality-")
            onPicked: v => root.run(`quality-${root.hp.id}-${v}`)
        }

        ToggleRow {
            visible: root.ready && root.st.low_latency != null
            text: qsTr("Low latency")
            subtext: qsTr("Less delay for games and video, at some cost in sound quality")
            checked: !!root.st.low_latency
            disabled: root.busy !== ""
            onToggled: root.run(`lowlatency-${root.hp.id}-${checked ? "on" : "off"}`)
        }

        ToggleRow {
            last: true
            visible: root.ready && root.st.auto_pause != null
            text: qsTr("Pause when taken off")
            checked: !!root.st.auto_pause
            disabled: root.busy !== ""
            onToggled: root.run(`autopause-${root.hp.id}-${checked ? "on" : "off"}`)
        }

        // ---------------------------------------------- Huawei: gestos
        SectionHeader {
            visible: root.ready && (!!root.st.double_tap || !!root.st.triple_tap)
            text: qsTr("Gestures")
        }

        Repeater {
            // Lista fixa (cada linha some sozinha): uma lista recalculada a
            // cada leitura do fone recriaria as linhas.
            model: root.gestureRows

            ExpandSelectRow {
                required property var modelData
                required property int index

                visible: root.ready && (root.st[modelData.key] ?? {})[modelData.side] !== undefined

                first: index === 0
                last: index === 3
                icon: "touch_app"
                label: modelData.label
                options: (root.caps.taps ?? []).map(t => ({ value: t, label: root.tapLabels[t] ?? t }))
                current: (root.st[modelData.key] ?? {})[modelData.side] ?? ""
                busy: root.busy.startsWith(`${modelData.id}-`)
                onPicked: v => root.run(`${modelData.id}-${root.hp.id}-${modelData.side === "left" ? "l" : "r"}-${v}`)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            Layout.leftMargin: Tokens.padding.small
            visible: !!root.hp
            text: qsTr("The headphones answer one app at a time: if the phone app is open on them, a change here may not go through.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
