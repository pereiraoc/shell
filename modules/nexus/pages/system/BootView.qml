pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Aba Boot de System: o que rodou ate o fim do boot e quanto demorou
// (caelestia-boot = systemd-analyze), do mais lento para o mais rapido, e a
// cadeia critica -- o caminho que de fato segurou o boot. So nasce quando a
// aba abre (o systemd-analyze leva ~1 s).
ColumnLayout {
    id: root

    readonly property var info: bridge.info
    readonly property var times: root.info.times ?? ({})
    readonly property var units: (root.info.units ?? []).filter(u => root.scope === "all" || u.scope === root.scope)
    readonly property real slowest: root.units.length > 0 ? Math.max(0.001, root.units[0].s) : 1
    property string scope: "all"

    function secs(v: var): string {
        if (v === null || v === undefined)
            return "–";
        return v >= 10 ? `${Math.round(v)} s` : `${Number(v).toFixed(1)} s`;
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    ToolBridge {
        id: bridge

        tool: "boot"
    }

    InfoRow {
        first: true
        last: true
        visible: bridge.error !== "" || bridge.level === "error"
        icon: "error"
        iconColour: Colours.palette.m3error
        label: Tr.tr("Could not measure the boot")
        subtext: bridge.error || bridge.summary
    }

    SectionHeader {
        first: true
        text: Tr.tr("Last boot")
    }

    InfoRow {
        first: true
        icon: "timer"
        label: Tr.tr("Total")
        value: root.secs(root.times.total)
        subtext: root.times.target_s ? Tr.tr("Desktop ready %1 after the kernel started").arg(root.secs(root.times.target_s)) : ""
    }

    InfoRow {
        icon: "memory"
        label: Tr.tr("Firmware + boot loader")
        value: `${root.secs(root.times.firmware)} + ${root.secs(root.times.loader)}`
        subtext: Tr.tr("Before Linux: UEFI, Fast Boot and the boot menu")
    }

    InfoRow {
        icon: "terminal"
        label: Tr.tr("Kernel")
        value: root.secs(root.times.kernel)
        subtext: Tr.tr("Drivers, initramfs and the root file system")
    }

    InfoRow {
        last: true
        icon: "rocket_launch"
        label: Tr.tr("Services (userspace)")
        value: root.secs(root.times.userspace)
        subtext: Tr.tr("systemd units until the desktop — the list below")
    }

    // Unidades mais lentas primeiro: barra proporcional a mais lenta
    SectionHeader {
        text: Tr.tr("Slowest first")
    }

    ChipSelectRow {
        first: true
        label: Tr.tr("Show")
        options: [
            { value: "all", label: Tr.tr("Everything") },
            { value: "system", label: Tr.tr("System") },
            { value: "user", label: Tr.tr("Your session") }
        ]
        current: root.scope
        onPicked: v => root.scope = v
    }

    Repeater {
        model: Math.min(20, root.units.length)

        MeterRow {
            // Modelo = quantidade: atualizar o status nao recria a linha
            // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
            // que vai sumir guarda o ultimo item ate ser destruida.
            required property int index
            property var modelData: root.units[index] ?? ({})
            readonly property var liveItem: root.units[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            last: index === Math.min(20, root.units.length) - 1
            icon: modelData.scope === "user" ? "person" : "settings"
            label: modelData.unit ?? ""
            valueText: root.secs(modelData.s)
            value: (modelData.s ?? 0) / root.slowest
            subtext: modelData.scope === "user" ? Tr.tr("your session") : Tr.tr("system")
        }
    }

    InfoRow {
        first: true
        last: true
        visible: root.units.length === 0 && bridge.error === ""
        icon: "hourglass_empty"
        label: Tr.tr("Measuring…")
    }

    // Cadeia critica: cada nivel depende do de cima; "+" = quanto a unidade levou
    SectionHeader {
        visible: (root.info.chain ?? []).length > 0
        text: Tr.tr("Critical chain")
    }

    StyledText {
        Layout.fillWidth: true
        visible: (root.info.chain ?? []).length > 0
        text: Tr.tr("Each line waited for the one above it. “+” is how long the unit itself took.")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: (root.info.chain ?? []).length

        InfoRow {
            required property int index
            property var modelData: (root.info.chain ?? [])[index] ?? ({})
            readonly property var liveItem: (root.info.chain ?? [])[index]

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: index === 0
            last: index === (root.info.chain ?? []).length - 1
            icon: index === 0 ? "flag" : "subdirectory_arrow_right"
            label: "    ".repeat(Math.min(6, modelData.depth ?? 0)) + (modelData.unit ?? "")
            value: `@${root.secs(modelData.at_s)}` + ((modelData.took_s ?? 0) > 0 ? `  +${root.secs(modelData.took_s)}` : "")
        }
    }

    ActionErrorRow {
        bridge: bridge
    }
}
