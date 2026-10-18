pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "azothLayout.js" as Az

// Aba do ROG Azoth em Keyboard, parte do teclado em si: a silhueta (75 %,
// OLED + knob no canto) com as teclas da camada Fn clicaveis, o cartao da
// tecla escolhida, e o OLED -- qual animacao esta no visor (lida do teclado;
// nada muda sozinho), brilho e liga/desliga. Tudo pelo caelestia-peripherals
// (canal vendor, mesmos pacotes do g-helper).
ColumnLayout {
    id: root

    // Entrada rgb do caelestia-peripherals para este teclado ({ id, name, oled: { animation, count } })
    required property var device
    // bridge.run({ id }) e bridge.busyAction do caelestia-peripherals
    required property var bridge

    readonly property var oled: root.device.oled ?? null
    readonly property var keyInfo: Az.keys().find(k => k.id === root.selected) ?? null
    property string selected

    Layout.fillWidth: true
    spacing: Tokens.spacing.medium

    StyledText {
        Layout.fillWidth: true
        text: Tr.tr("Tap a highlighted key to see what Fn does with it. Profiles, macros and the knob modes live in the keyboard itself.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    KeyboardDiagram {
        Layout.fillWidth: true
        keys: Az.keys()
        size: Az.size()
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

    SubsectionHeader {
        icon: "screenshot_monitor"
        text: Tr.tr("OLED display")
        status: root.oled ? (root.oled.animation !== null ? Tr.tr("Animation %1 of %2").arg(root.oled.animation + 1).arg(root.oled.count) : Tr.tr("Custom")) : Tr.tr("Asleep")
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
        label: Tr.tr("Animation on the display")
        subtext: Tr.tr("Read from the keyboard; it only changes if you pick another one here")
        options: Array.from({ length: root.oled?.count ?? 0 }, (_, i) => ({ value: String(i + 1), label: String(i + 1) }))
        current: root.oled && root.oled.animation !== null ? String(root.oled.animation + 1) : ""
        busy: root.bridge.busyAction.startsWith(`oled-${root.device.id}-anim-`)
        onPicked: v => root.bridge.run({ id: `oled-${root.device.id}-anim-${v}` })
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
