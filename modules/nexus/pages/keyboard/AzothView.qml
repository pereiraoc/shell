pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.bluetooth
import "azothLayout.js" as Az
import "azothArt.js" as AzArt

// Aba do ROG Azoth em Keyboard, de cima para baixo: bateria e como esta ligado,
// a silhueta (75 %, OLED + knob no canto) com a previa da luz e as teclas da
// camada Fn clicaveis, o cartao da tecla escolhida, a iluminacao (efeito,
// cores, brilho, velocidade -- o que se escolhe aparece na silhueta) e o OLED:
// qual animacao esta no visor (lida do teclado; nada muda sozinho), a imagem
// que o usuario subiu pelo Armoury Crate (fica guardada no teclado e da para
// voltar a ela), brilho e liga/desliga. Tudo pelo caelestia-peripherals
// (canal vendor, mesmos pacotes do g-helper).
ColumnLayout {
    id: root

    // Entrada rgb do caelestia-peripherals para este teclado ({ id, name, node, oled: { animation, raw, count, custom } })
    required property var device
    // ToolBridge do caelestia-peripherals (bridge.run({ id }), bridge.busyAction)
    required property var bridge
    // Entrada do caelestia-peripheral-battery ({ pct, charging, stale }) ou null
    property var battery: null

    readonly property var oled: root.device.oled ?? null
    readonly property bool hasCustom: (root.oled?.custom ?? null) !== null
    readonly property var keyInfo: Az.keys().find(k => k.id === root.selected) ?? null
    readonly property string name: (root.device.name ?? "").replace(/\s*(2\.4GHz|USB)$/, "")
    readonly property bool wireless: /2\.4GHz$/.test(root.device.name ?? "")
    property string selected

    function batteryText(b: var): string {
        return b.charging ? Tr.tr("Charging") : b.stale ? Tr.tr("Last known level — the keyboard is asleep") : "";
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    SubsectionHeader {
        icon: "keyboard"
        text: root.name
        status: root.battery ? (root.battery.stale ? Tr.tr("Asleep · %1%") : "%1%").arg(Math.round(root.battery.pct * 100)) : ""
        warn: !!root.battery && root.battery.pct < 0.2
    }

    MeterRow {
        first: true
        visible: !!root.battery
        icon: "battery_full"
        label: Tr.tr("Battery")
        valueText: root.battery ? `${Math.round(root.battery.pct * 100)}%` : ""
        value: root.battery?.pct ?? 0
        warnAt: 0.2
        warnBelow: true
        subtext: root.battery ? root.batteryText(root.battery) : ""
    }

    InfoRow {
        first: !root.battery
        last: true
        icon: root.wireless ? "settings_remote" : "usb"
        label: Tr.tr("Connection")
        value: root.wireless ? Tr.tr("2.4 GHz receiver") : Tr.tr("USB cable")
        subtext: Tr.tr("Lighting, display and Fn layer are read from the keyboard")
    }

    // Silhueta: previa da luz + teclas da camada Fn
    ArtKeyboardDiagram {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        Layout.bottomMargin: Tokens.spacing.small
        art: ({ W: AzArt.W, H: AzArt.H, CHASSIS: AzArt.CHASSIS, RECTS: AzArt.RECTS, LINE: AzArt.LINE, SPLIT: AzArt.SPLIT, KEYS: AzArt.KEYS })
        special: Az.SPECIAL
        selected: root.selected
        lighting: lights.preview
        onPicked: id => root.selected = root.selected === id ? "" : id
    }

    StyledText {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.small
        visible: root.selected === ""
        text: Tr.tr("Tap a highlighted key to see what Fn does with it. Profiles, macros and the knob modes live in the keyboard.")
        color: Colours.palette.m3outline
        font: Tokens.font.label.small
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    // Cartao da tecla selecionada
    StyledRect {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.small
        visible: root.selected !== ""
        implicitHeight: card.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: card

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.small

            RowLayout {
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: root.keyInfo?.icon || "keyboard"
                    color: Colours.palette.m3tertiary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Az.comboLabel(root.selected)
                    font: Tokens.font.title.small
                    color: Colours.palette.m3primary
                    elide: Text.ElideRight
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.keyInfo?.fn ?? ""
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Handled by the keyboard firmware — nothing reaches the computer")
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }
    }

    // Iluminacao (o rascunho anima a silhueta acima): comeca direto na grade de efeitos
    RgbLightingView {
        id: lights

        embedded: true
        deviceId: root.device.id
        bridge: root.bridge
    }

    SubsectionHeader {
        icon: "screenshot_monitor"
        text: Tr.tr("OLED display")
        status: root.oled ? (root.oled.animation !== null ? Tr.tr("Animation %1 of %2").arg(root.oled.animation + 1).arg(root.oled.count) : Tr.tr("Your GIF")) : Tr.tr("Asleep")
    }

    InfoRow {
        first: true
        last: true
        visible: !root.oled
        icon: "bedtime"
        label: Tr.tr("The keyboard is asleep")
        subtext: Tr.tr("Press a key on it and come back — the display state is read from the keyboard")
    }

    ChipSelectRow {
        first: true
        visible: !!root.oled
        label: Tr.tr("On the display")
        subtext: root.hasCustom ? Tr.tr("Read from the keyboard. Your GIF stays stored in it; only Armoury Crate can upload a new one") : Tr.tr("Read from the keyboard; it only changes if you pick another one here")
        options: {
            const o = Array.from({ length: root.oled?.count ?? 0 }, (_, i) => ({ value: String(i + 1), label: String(i + 1) }));
            if (root.hasCustom)
                o.push({ value: "custom", label: Tr.tr("Your GIF"), icon: "gif_box" });
            return o;
        }
        current: !root.oled ? "" : root.oled.animation !== null ? String(root.oled.animation + 1) : (root.oled.raw === root.oled.custom ? "custom" : "")
        busy: root.bridge.busyAction.startsWith(`oled-${root.device.id}-anim-`) || root.bridge.busyAction === `oled-${root.device.id}-custom`
        onPicked: v => root.bridge.run({ id: v === "custom" ? `oled-${root.device.id}-custom` : `oled-${root.device.id}-anim-${v}` })
    }

    ChipSelectRow {
        visible: !!root.oled
        label: Tr.tr("Brightness")
        subtext: Tr.tr("The keyboard does not report the current level")
        options: [
            { value: "25", label: "25%" },
            { value: "50", label: "50%" },
            { value: "75", label: "75%" },
            { value: "100", label: "100%" }
        ]
        current: ""
        busy: root.bridge.busyAction.startsWith(`oled-${root.device.id}-bri-`)
        onPicked: v => root.bridge.run({ id: `oled-${root.device.id}-bri-${v}` })
    }

    ChipSelectRow {
        last: true
        visible: !!root.oled
        label: Tr.tr("Display")
        options: [
            { value: "on", label: Tr.tr("On"), icon: "visibility" },
            { value: "off", label: Tr.tr("Off"), icon: "visibility_off" }
        ]
        current: ""
        busy: root.bridge.busyAction.startsWith(`oled-${root.device.id}-o`)
        onPicked: v => root.bridge.run({ id: `oled-${root.device.id}-${v}` })
    }
}
