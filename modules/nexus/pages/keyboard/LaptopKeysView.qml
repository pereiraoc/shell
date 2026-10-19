pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages.bluetooth
import "laptopLayout.js" as Lk
import "g16Art.js" as G16Art

// Aba Laptop de Keyboard, de cima para baixo: o que o teclado controla agora
// (touchpad, monitores), a silhueta do GU603 com a previa da luz e as teclas
// especiais clicaveis (M1-M4 e a fila Fn: o que cada uma faz e qual o
// feedback, lido do caelestia-laptop-keys; so o Fn + F11 e escolhivel), e a
// iluminacao: brilho (asusctl) e efeito/cores (asusd), que aparecem na
// silhueta conforme se escolhe.
ColumnLayout {
    id: root

    // ToolBridge do caelestia-peripherals da pagina (brilho asusctl + luz asusd)
    required property var peripherals

    readonly property var periph: root.peripherals.info
    readonly property var laptopRgb: (root.periph.rgb ?? []).find(d => d.backend === "asusd") ?? null
    readonly property bool backlightAvailable: root.periph.laptop_keyboard?.available === true
    readonly property var info: bridge.info
    readonly property var keyInfo: (root.info.keys ?? []).find(k => k.id === root.selected) ?? null
    // Nada selecionado de inicio; clicar na tecla marcada desmarca (como no Naga)
    property string selected

    function byText(by: string): string {
        switch (by) {
        case "kernel":
            return Tr.tr("the kernel");
        case "shell":
            return Tr.tr("the shell");
        case "tool":
            return Tr.tr("caelestia-laptop-keys");
        default:
            return Tr.tr("Hyprland");
        }
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    ToolBridge {
        id: bridge

        tool: "laptop-keys"
    }

    InfoRow {
        first: true
        last: true
        visible: root.info.nkey_present === false
        icon: "error"
        iconColour: Colours.palette.m3error
        label: Tr.tr("The laptop keyboard (ASUS N-KEY device) was not found")
        subtext: Tr.tr("The special keys do nothing on this machine")
    }

    SubsectionHeader {
        icon: "laptop"
        text: Tr.tr("Laptop keyboard")
        status: root.backlightAvailable ? Tr.tr("Backlight %1").arg(({ off: Tr.tr("off"), low: Tr.tr("low"), med: Tr.tr("medium"), high: Tr.tr("high") })[root.periph.laptop_keyboard?.brightness] ?? "") : ""
    }

    InfoRow {
        first: true
        icon: "touchpad_mouse"
        label: Tr.tr("Touchpad")
        value: root.info.touchpad_enabled === false ? Tr.tr("Off") : Tr.tr("On")
        subtext: Tr.tr("Fn + F10 toggles it")
    }

    InfoRow {
        last: true
        icon: "screenshot_monitor"
        label: Tr.tr("Monitors")
        value: root.info.mirror_active ? Tr.tr("Mirrored on the laptop screen") : Tr.tr("Normal layout")
        subtext: Tr.tr("Fn + F9 mirrors everything on the laptop screen and back")
    }

    // Silhueta: previa da luz + teclas especiais
    ArtKeyboardDiagram {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.medium
        Layout.bottomMargin: Tokens.spacing.small
        art: ({ W: G16Art.W, H: G16Art.H, CHASSIS: G16Art.CHASSIS, RECTS: G16Art.RECTS, KEYS: G16Art.KEYS })
        special: Lk.SPECIAL
        selected: root.selected
        lighting: root.laptopRgb ? lights.preview : null
        onPicked: id => root.selected = root.selected === id ? "" : id
    }

    StyledText {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.small
        visible: root.selected === ""
        text: Tr.tr("Tap a highlighted key to see what it does")
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
                    text: Lk.ICONS[root.selected] ?? "keyboard"
                    color: Colours.palette.m3tertiary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.keyInfo ? `${Lk.comboLabel(root.selected)} · ${root.keyInfo.printed}` : Lk.comboLabel(root.selected)
                    font: Tokens.font.title.small
                    color: Colours.palette.m3primary
                    elide: Text.ElideRight
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.keyInfo?.does ?? ""
                font: Tokens.font.body.medium
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: !!root.keyInfo
                text: Tr.tr("Feedback: %1 · handled by %2").arg(root.keyInfo?.feedback ?? "").arg(root.byText(root.keyInfo?.by ?? ""))
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }

            // M1-M4: o Fn nao chega ao sistema, entao Fn + M1 e a propria M1
            StyledText {
                Layout.fillWidth: true
                visible: root.selected.startsWith("m")
                text: Tr.tr("Fn + %1 sends the same key as %1, so it does the same thing").arg(root.keyInfo?.printed ?? root.selected.toUpperCase())
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }
    }

    ChipSelectRow {
        first: true
        last: true
        visible: root.selected === "f11"
        label: Tr.tr("Fn + F11 does")
        subtext: root.info.hibernate_available ? "" : Tr.tr("Hibernate needs the resume= kernel parameter — not set up yet")
        options: (root.info.sleep_choices ?? []).filter(c => c.id !== "hibernate" || root.info.hibernate_available).map(c => ({ value: c.id, label: c.label }))
        current: root.info.sleep_key ?? ""
        busy: bridge.busyAction.startsWith("sleep-")
        onPicked: v => bridge.run({ id: `sleep-${v}` })
    }

    // Brilho (asusctl); o efeito (asusd) vem logo abaixo com o proprio "Effect"
    SectionHeader {
        text: Tr.tr("Backlight")
    }

    ChipSelectRow {
        first: true
        last: true
        visible: root.backlightAvailable
        label: Tr.tr("Level")
        subtext: Tr.tr("Fn + F2 / F3 on the laptop change this too")
        options: [
            { value: "off", label: Tr.tr("Off"), icon: "light_off" },
            { value: "low", label: Tr.tr("Low") },
            { value: "med", label: Tr.tr("Medium") },
            { value: "high", label: Tr.tr("High") }
        ]
        current: root.periph.laptop_keyboard?.brightness ?? ""
        busy: root.peripherals.busyAction.startsWith("kbd-")
        onPicked: v => root.peripherals.run({ id: `kbd-${v}` })
    }

    RgbLightingView {
        id: lights

        visible: !!root.laptopRgb
        embedded: true
        deviceId: root.laptopRgb?.id ?? ""
        bridge: root.peripherals
    }

    ActionErrorRow {
        bridge: bridge
    }
}
