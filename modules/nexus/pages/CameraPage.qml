pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Cameras (Nexus > Camera): quem esta usando, previa ao vivo (so quando
// pedida: acende a luz da camera) e os ajustes de imagem que o driver expoe
// (V4L2) -- caelestia-camera. Os ajustes ficam salvos e voltam no login.
PageBase {
    id: root

    readonly property var cams: bridge.info.cameras ?? []
    property string previewNode

    // Sliders: o valor vai ~0,3 s depois de parar de arrastar, um por vez.
    property var pending: ({})

    function setCtrl(node: string, name: string, value: int): void {
        const p = Object.assign({}, root.pending);
        p[`${node}|${name}`] = value;
        root.pending = p;
        flushTimer.restart();
    }

    function flush(): void {
        if (bridge.busyAction !== "")
            return;
        const keys = Object.keys(root.pending);
        if (keys.length === 0)
            return;
        const [node, name] = keys[0].split("|");
        const v = root.pending[keys[0]];
        const p = Object.assign({}, root.pending);
        delete p[keys[0]];
        root.pending = p;
        bridge.run({ id: `set-${node}-${name}-${v}` });
    }

    readonly property var labels: ({
            "brightness": qsTr("Brightness"),
            "contrast": qsTr("Contrast"),
            "saturation": qsTr("Saturation"),
            "hue": qsTr("Hue"),
            "gamma": qsTr("Gamma"),
            "sharpness": qsTr("Sharpness"),
            "gain": qsTr("Gain"),
            "white_balance_automatic": qsTr("Automatic white balance"),
            "white_balance_temperature": qsTr("Colour temperature"),
            "power_line_frequency": qsTr("Anti-flicker"),
            "backlight_compensation": qsTr("Backlight compensation"),
            "auto_exposure": qsTr("Exposure"),
            "exposure_time_absolute": qsTr("Exposure time"),
            "exposure_dynamic_framerate": qsTr("Lower frame rate in dim light"),
            "focus_automatic_continuous": qsTr("Autofocus"),
            "focus_absolute": qsTr("Focus"),
            "zoom_absolute": qsTr("Zoom")
        })

    readonly property var hints: ({
            "white_balance_temperature": qsTr("Turn off automatic white balance to set this"),
            "exposure_time_absolute": qsTr("Set exposure to manual to change this"),
            "power_line_frequency": qsTr("Match your mains frequency so lamps don't flicker on camera (60 Hz in Brazil)"),
            "gain": qsTr("Brighter in the dark, with more noise"),
            "exposure_dynamic_framerate": qsTr("Brighter image in the dark, but less smooth")
        })

    readonly property var menuLabels: ({
            "Manual Mode": qsTr("Manual"),
            "Aperture Priority Mode": qsTr("Automatic"),
            "Disabled": qsTr("Off")
        })

    // Grupos, na ordem em que aparecem; o que nao estiver aqui vai em "More"
    readonly property var groups: [
        { title: qsTr("Picture"), names: ["brightness", "contrast", "saturation", "hue", "gamma", "sharpness"] },
        { title: qsTr("Light"), names: ["auto_exposure", "exposure_time_absolute", "gain", "backlight_compensation", "exposure_dynamic_framerate", "power_line_frequency"] },
        { title: qsTr("Colour"), names: ["white_balance_automatic", "white_balance_temperature"] }
    ]

    function grouped(ctrls: var): var {
        const known = Array.from(root.groups).reduce((a, g) => a.concat(g.names), []);
        const out = Array.from(root.groups).map(g => ({ title: g.title, ctrls: g.names.map(n => ctrls.find(c => c.name === n)).filter(c => !!c) }));
        out.push({ title: qsTr("More"), ctrls: ctrls.filter(c => !known.includes(c.name)) });
        return out.filter(g => g.ctrls.length > 0);
    }

    function pretty(name: string): string {
        return root.labels[name] ?? (name.charAt(0).toUpperCase() + name.slice(1).replace(/_/g, " "));
    }

    title: qsTr("Camera")
    description: qsTr("Preview, privacy and picture settings")

    onVisibleChanged: {
        if (!visible)
            root.previewNode = "";
        else
            bridge.refresh();
    }

    ToolBridge {
        id: bridge

        tool: "camera"
        onBusyActionChanged: root.flush()
    }

    // PageBase so aceita Item como filho direto.
    Item {
        Timer {
            id: flushTimer

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
            visible: root.cams.length === 0
            icon: "videocam_off"
            label: bridge.loading ? qsTr("Looking for cameras…") : qsTr("No cameras found")
            subtext: bridge.info.errors?.camera ?? ""
        }

        ActionErrorRow {
            bridge: bridge
        }

        Repeater {
            model: root.cams.length

            ColumnLayout {
                id: cam

                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.cams[index] ?? ({})
                readonly property var liveItem: root.cams[index]
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                required property int index

                readonly property bool previewing: root.previewNode === cam.modelData.node
                readonly property bool changed: (cam.modelData.controls ?? []).some(c => c.value !== c.default)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: cam.index === 0
                    text: cam.modelData.ir ? qsTr("Infrared camera") : qsTr("Webcam")
                }

                // Estado + previa
                ConnectedRect {
                    Layout.fillWidth: true
                    first: true
                    last: !cam.previewing && (cam.modelData.controls ?? []).length === 0 && !cam.modelData.face_unlock
                    implicitHeight: camHead.implicitHeight + Tokens.padding.large * 2

                    RowLayout {
                        id: camHead

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: cam.modelData.in_use_by?.length ? "radio_button_checked" : cam.modelData.ir ? "face" : "videocam"
                            color: cam.modelData.in_use_by?.length ? Colours.palette.m3error : Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                            fill: 1
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: cam.modelData.in_use_by?.length ? qsTr("In use by %1").arg(cam.modelData.in_use_by.join(", ")) : cam.previewing ? qsTr("Previewing") : qsTr("Not in use")
                                font: Tokens.font.title.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: [cam.modelData.device, cam.modelData.sizes?.[0] ? qsTr("up to %1").arg(cam.modelData.sizes[0]) : "", cam.modelData.name].filter(x => x).join(" · ")
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        TextButton {
                            visible: !cam.modelData.in_use_by?.length || cam.previewing
                            text: cam.previewing ? qsTr("Stop") : qsTr("Preview")
                            type: cam.previewing ? TextButton.Filled : TextButton.Text
                            onClicked: root.previewNode = cam.previewing ? "" : cam.modelData.node
                        }
                    }
                }

                // Previa ao vivo: so existe enquanto pedida (a camera liga)
                ConnectedRect {
                    Layout.fillWidth: true
                    visible: cam.previewing
                    implicitHeight: previewLoader.item ? width * 9 / 16 : 0
                    clip: true

                    Loader {
                        id: previewLoader

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        active: cam.previewing
                        sourceComponent: Item {
                            id: pv

                            readonly property var device: mediaDevices.videoInputs.find(d => String(d.id).includes(cam.modelData.node)) ?? mediaDevices.defaultVideoInput

                            MediaDevices {
                                id: mediaDevices
                            }

                            CaptureSession {
                                camera: Camera {
                                    cameraDevice: pv.device
                                    active: true
                                }
                                videoOutput: output
                            }

                            VideoOutput {
                                id: output

                                anchors.fill: parent
                                fillMode: VideoOutput.PreserveAspectFit
                            }
                        }
                    }
                }

                RowButton {
                    last: (cam.modelData.controls ?? []).length === 0
                    visible: !!cam.modelData.face_unlock
                    icon: "face"
                    text: qsTr("Used by face unlock")
                    subtext: qsTr("Models and unlock methods are in Security")
                    trailingIcon: "chevron_right"
                    onClicked: root.nState.openPage("security", 0)
                }

                InfoRow {
                    last: true
                    visible: (cam.modelData.controls ?? []).length === 0 && !cam.modelData.face_unlock
                    icon: "tune"
                    label: qsTr("This camera has no picture settings")
                }

                // Ajustes, por grupo
                Repeater {
                    model: (root.grouped(cam.modelData.controls ?? [])).length

                    ColumnLayout {
                        id: grp

                        // Modelo = quantidade: atualizar o status nao recria a linha
                        // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                        // que vai sumir guarda o ultimo item ate ser destruida.
                        property var modelData: (root.grouped(cam.modelData.controls ?? []))[index] ?? ({})
                        readonly property var liveItem: (root.grouped(cam.modelData.controls ?? []))[index]
                        onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                        required property int index

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall / 2

                        SubsectionHeader {
                            text: grp.modelData.title
                        }

                        Repeater {
                            model: grp.modelData.ctrls.length

                            Loader {
                                id: ctl

                                // Modelo = quantidade: atualizar o status nao recria a linha
                                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                                // que vai sumir guarda o ultimo item ate ser destruida.
                                property var modelData: grp.modelData.ctrls[index] ?? ({})
                                readonly property var liveItem: grp.modelData.ctrls[index]
                                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                                required property int index

                                readonly property bool isFirst: ctl.index === 0
                                readonly property bool isLast: ctl.index === grp.modelData.ctrls.length - 1

                                Layout.fillWidth: true
                                sourceComponent: ctl.modelData.type === "bool" ? boolComp : ctl.modelData.type === "menu" ? menuComp : intComp

                                Component {
                                    id: boolComp

                                    ToggleRow {
                                        first: ctl.isFirst
                                        last: ctl.isLast
                                        text: root.pretty(ctl.modelData.name)
                                        subtext: root.hints[ctl.modelData.name] ?? ""
                                        checked: ctl.modelData.value === 1
                                        disabled: ctl.modelData.inactive
                                        onToggled: root.setCtrl(cam.modelData.node, ctl.modelData.name, checked ? 1 : 0)
                                    }
                                }

                                Component {
                                    id: menuComp

                                    ChipSelectRow {
                                        first: ctl.isFirst
                                        last: ctl.isLast
                                        label: root.pretty(ctl.modelData.name)
                                        subtext: root.hints[ctl.modelData.name] ?? ""
                                        options: (ctl.modelData.options ?? []).map(o => ({ value: String(o.value), label: root.menuLabels[o.label] ?? o.label }))
                                        current: String(ctl.modelData.value)
                                        disabled: ctl.modelData.inactive
                                        onPicked: v => root.setCtrl(cam.modelData.node, ctl.modelData.name, Number(v))
                                    }
                                }

                                Component {
                                    id: intComp

                                    ColumnLayout {
                                        id: intRow

                                        readonly property int range: Math.max(1, ctl.modelData.max - ctl.modelData.min)
                                        property int shown: ctl.modelData.value

                                        spacing: 0
                                        opacity: ctl.modelData.inactive ? 0.5 : 1

                                        Connections {
                                            target: ctl
                                            function onModelDataChanged(): void {
                                                // valor pendente (arrastando) manda: o refresh
                                                // do anterior nao puxa o slider de volta
                                                if (root.pending[`${cam.modelData.node}|${ctl.modelData.name}`] === undefined)
                                                    intRow.shown = ctl.modelData.value;
                                            }
                                        }

                                        SliderRow {
                                            Layout.fillWidth: true
                                            first: ctl.isFirst
                                            last: ctl.isLast && !root.hints[ctl.modelData.name]
                                            enabled: !ctl.modelData.inactive
                                            icon: "tune"
                                            label: root.pretty(ctl.modelData.name)
                                            valueLabel: intRow.shown === ctl.modelData.default ? qsTr("%1 (default)").arg(intRow.shown) : String(intRow.shown) + (ctl.modelData.name === "white_balance_temperature" ? " K" : "")
                                            value: (intRow.shown - ctl.modelData.min) / intRow.range
                                            onMoved: v => {
                                                const step = ctl.modelData.step || 1;
                                                const raw = ctl.modelData.min + Math.round(v * intRow.range / step) * step;
                                                intRow.shown = Math.max(ctl.modelData.min, Math.min(ctl.modelData.max, raw));
                                                root.setCtrl(cam.modelData.node, ctl.modelData.name, intRow.shown);
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            Layout.leftMargin: Tokens.padding.largeIncreased
                                            Layout.bottomMargin: Tokens.spacing.small
                                            visible: !!root.hints[ctl.modelData.name] && (ctl.modelData.inactive || ctl.modelData.name !== "white_balance_temperature" && ctl.modelData.name !== "exposure_time_absolute")
                                            text: root.hints[ctl.modelData.name] ?? ""
                                            color: Colours.palette.m3outline
                                            font: Tokens.font.label.small
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                RowButton {
                    Layout.topMargin: Tokens.spacing.medium
                    first: true
                    last: true
                    visible: (cam.modelData.controls ?? []).length > 0
                    icon: "restart_alt"
                    text: qsTr("Reset picture settings")
                    subtext: cam.changed ? qsTr("Back to the camera's defaults") : qsTr("Everything is at the default")
                    disabled: !cam.changed || bridge.busyAction !== ""
                    onClicked: bridge.run({ id: `reset-${cam.modelData.node}` })
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large
            Layout.leftMargin: Tokens.padding.small
            visible: root.cams.length > 0
            text: qsTr("Settings apply to every app and come back after a restart.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }
    }
}
