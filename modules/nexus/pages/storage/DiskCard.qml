pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Um disco fisico como no GParted: em cima, a barra com as particoes lado a lado
// na ordem do disco (largura proporcional ao tamanho, com um minimo para a EFI de
// 0,5 GB nao sumir; a parte cheia de cada pedaco = usado); embaixo, as particoes na
// mesma ordem, com a mesma cor. Livre = pedaco tracejado/vazio. Dados: data.disks do
// caelestia-storage (lsblk + df + /proc/swaps). Clicar numa particao montada abre a
// arvore de pastas nela.
ColumnLayout {
    id: root

    required property var disk
    required property var fmt          // funcao de formatar bytes da pagina
    property bool firstCard

    signal browse(string path)

    readonly property var segs: root.disk.segments ?? []
    // fracoes da barra: proporcional, minimo de 3% por pedaco, renormalizado
    readonly property var fracs: {
        const total = root.disk.size || 1;
        const raw = root.segs.map(s => Math.max(s.size / total, 0.03));
        const sum = raw.reduce((a, b) => a + b, 0) || 1;
        return raw.map(f => f / sum);
    }

    function roleColour(seg: var): color {
        if (seg.kind === "free")
            return Colours.palette.m3outlineVariant;
        switch (seg.role) {
        case "system":
            return Colours.palette.m3primary;
        case "home":
            return Colours.palette.m3secondary;
        case "data":
            return Colours.palette.m3tertiary;
        case "swap":
            return Colours.palette.m3inversePrimary;
        case "boot":
            return Colours.palette.m3outline;
        default:
            return Colours.palette.m3onSurfaceVariant;
        }
    }

    function roleIcon(seg: var): string {
        if (seg.kind === "free")
            return "crop_free";
        switch (seg.role) {
        case "system":
            return "settings";
        case "home":
            return "home";
        case "data":
            return "folder";
        case "swap":
            return "swap_horiz";
        case "boot":
            return "power_settings_new";
        default:
            return "hard_drive";
        }
    }

    function roleName(seg: var): string {
        if (seg.kind === "free")
            return qsTr("Unallocated");
        switch (seg.role) {
        case "system":
            return qsTr("System");
        case "home":
            return qsTr("Home");
        case "data":
            return qsTr("Data");
        case "swap":
            return qsTr("Swap");
        case "boot":
            return qsTr("Boot");
        default:
            return seg.mount ? qsTr("Other") : qsTr("Not mounted");
        }
    }

    function segTitle(seg: var): string {
        if (seg.kind === "free")
            return qsTr("Unallocated space");
        const where = seg.mount ? seg.mount : (seg.role === "swap" ? "swap" : qsTr("not mounted"));
        return `${seg.label || seg.name}  ·  ${where}`;
    }

    function segSub(seg: var): string {
        if (seg.kind === "free")
            return qsTr("%1 with no partition").arg(root.fmt(seg.size));
        const parts = [seg.name, seg.fstype || "?", root.fmt(seg.size)];
        if (seg.used !== null && seg.used !== undefined)
            parts.push(seg.role === "swap" ? qsTr("%1 in use").arg(root.fmt(seg.used)) : qsTr("%1 free  ·  %2%").arg(root.fmt(seg.avail)).arg(seg.pct));
        else if (seg.role === "swap")
            parts.push(qsTr("inactive"));
        return parts.join("  ·  ");
    }

    spacing: Tokens.spacing.extraSmall / 2

    SectionHeader {
        first: root.firstCard
        text: `${(root.disk.model || root.disk.name).toUpperCase()}  ·  ${root.fmt(root.disk.size)}${root.disk.system ? qsTr("  ·  SYSTEM") : ""}`
    }

    // ----------------------------------------------------------- barra GParted
    ConnectedRect {
        Layout.fillWidth: true
        implicitHeight: bar.height + legend.implicitHeight + Tokens.padding.medium * 2 + Tokens.spacing.small
        first: true
        last: root.segs.length === 0

        Row {
            id: bar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium
            anchors.leftMargin: Tokens.padding.largeIncreased
            anchors.rightMargin: Tokens.padding.largeIncreased
            height: 34
            spacing: 3

            Repeater {
                model: root.segs.length

                Item {
                    id: seg

                    required property int index
                    readonly property var data_: root.segs[index] ?? ({})
                    readonly property color tone: root.roleColour(seg.data_)
                    readonly property real usedFrac: seg.data_.kind === "part" && seg.data_.used !== null && seg.data_.used !== undefined && seg.data_.size > 0 ? Math.min(seg.data_.used / Math.max(seg.data_.used + (seg.data_.avail ?? 0), 1), 1) : -1

                    width: Math.max((bar.width - bar.spacing * (root.segs.length - 1)) * (root.fracs[index] ?? 0), 4)
                    height: bar.height

                    // fundo: a particao inteira (tom claro); livre = so a borda
                    StyledRect {
                        anchors.fill: parent
                        radius: Tokens.rounding.small
                        color: seg.data_.kind === "free" ? "transparent" : Qt.alpha(seg.tone, 0.28)
                        border.width: seg.data_.kind === "free" ? 1 : 0
                        border.color: seg.tone
                    }

                    // usado: preenche da esquerda, no tom cheio
                    StyledRect {
                        visible: seg.usedFrac >= 0
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(seg.usedFrac, 0)
                        radius: Tokens.rounding.small
                        color: seg.tone
                    }

                    // nome dentro do pedaco, so se couber
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        visible: parent.width > 64
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: seg.data_.kind === "free" ? qsTr("free") : (seg.data_.mount || seg.data_.label || seg.data_.name)
                        color: seg.data_.kind === "free" ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                        font: Tokens.font.label.small
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !!seg.data_.mount
                        cursorShape: seg.data_.mount ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.browse(seg.data_.mount)
                    }
                }
            }
        }

        // legenda curta: tamanho total e o que e cheio x claro
        StyledText {
            id: legend

            anchors.left: bar.left
            anchors.right: bar.right
            anchors.top: bar.bottom
            anchors.topMargin: Tokens.spacing.small
            text: qsTr("%1  ·  %2 partitions  ·  solid = used, light = free, outline = unallocated").arg(root.disk.path).arg(root.segs.filter(s => s.kind === "part").length)
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }
    }

    // --------------------------------------------- particoes, na ordem do disco
    Repeater {
        model: root.segs.length

        RowButton {
            id: row

            required property int index
            readonly property var seg: root.segs[index] ?? ({})

            last: row.index === root.segs.length - 1
            icon: root.roleIcon(row.seg)
            iconLabel.color: root.roleColour(row.seg)
            text: `${root.roleName(row.seg)}  ·  ${root.segTitle(row.seg)}`
            subtext: root.segSub(row.seg)
            trailingIcon: row.seg.mount ? "chevron_right" : ""
            disabled: !row.seg.mount
            onClicked: if (row.seg.mount) root.browse(row.seg.mount)
        }
    }
}
