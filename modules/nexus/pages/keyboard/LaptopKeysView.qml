pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common
import "laptopLayout.js" as Lk

// Aba Laptop de Keyboard, parte das teclas especiais: o que cada tecla
// (M1-M4, fila Fn) faz e qual o feedback -- lido do caelestia-laptop-keys, com
// o diagrama. So o Fn+F11 e escolhivel (lock / suspend / screen off /
// hibernate); as outras fazem o impresso (o Fn nao chega ao sistema, entao M1 e
// Fn+M1 sao a mesma tecla).
ColumnLayout {
    id: root

    readonly property var info: bridge.info
    readonly property var keyInfo: (root.info.keys ?? []).find(k => k.id === root.selected) ?? null
    readonly property var backlight: root.info.kbd_backlight ?? null
    // Nada selecionado de inicio; clicar na tecla marcada desmarca (como no Naga)
    property string selected

    function backlightText(b: var): string {
        if (!b)
            return Tr.tr("Not available");
        if (b.max === 3)
            return [Tr.tr("Off"), Tr.tr("Low"), Tr.tr("Medium"), Tr.tr("High")][b.level] ?? `${b.level}/${b.max}`;
        return `${b.level}/${b.max}`;
    }

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
    spacing: Tokens.spacing.medium

    ToolBridge {
        id: bridge

        tool: "laptop-keys"
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.info.nkey_present === false
        text: Tr.tr("The laptop keyboard (ASUS N-KEY device) was not found — these keys do nothing on this machine")
        color: Colours.palette.m3error
        font: Tokens.font.body.medium
        wrapMode: Text.WordWrap
    }

    StyledText {
        Layout.fillWidth: true
        text: Tr.tr("Tap a highlighted key. Fn + M1…M4 send the same key as M1…M4, so they are not configurable; Fn + F5 is handled by the kernel.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    LaptopKeyboard {
        Layout.fillWidth: true
        selected: root.selected
        onPicked: id => root.selected = root.selected === id ? "" : id
    }

    // Cartao da tecla selecionada
    StyledRect {
        Layout.fillWidth: true
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

    SubsectionHeader {
        icon: "info"
        text: Tr.tr("Now")
    }

    InfoRow {
        first: true
        icon: "keyboard"
        label: Tr.tr("Keyboard backlight")
        value: root.backlightText(root.backlight)
    }

    InfoRow {
        icon: "touchpad_mouse"
        label: Tr.tr("Touchpad")
        value: root.info.touchpad_enabled === false ? Tr.tr("Off") : Tr.tr("On")
    }

    InfoRow {
        last: true
        icon: "screenshot_monitor"
        label: Tr.tr("Monitors")
        value: root.info.mirror_active ? Tr.tr("Mirrored on the laptop screen") : Tr.tr("Normal layout")
    }

    ActionErrorRow {
        bridge: bridge
    }
}
