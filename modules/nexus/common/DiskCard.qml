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
// caelestia-storage (lsblk + df + /proc/swaps) ou do caelestia-nas disks (o mesmo
// formato, discos do NAS). Clicar numa particao montada abre a arvore de pastas nela.
// Mora em common porque serve as duas abas (Partitions e NAS) do Storage.
ColumnLayout {
    id: root

    required property var disk
    required property var fmt          // funcao de formatar bytes da pagina
    property bool firstCard
    // Linha extra na legenda (ex.: SMART e temperatura dos discos do NAS)
    property string extra

    readonly property var segs: root.disk.segments ?? []
    // fracoes da barra: proporcional, minimo de 3% por pedaco, renormalizado
    readonly property var fracs: {
        const total = root.disk.size || 1;
        const raw = root.segs.map(s => Math.max(s.size / total, 0.03));
        const sum = raw.reduce((a, b) => a + b, 0) || 1;
        return raw.map(f => f / sum);
    }

    signal browse(string path)

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
        case "apps":
            return Colours.palette.m3secondary;
        case "cache":
            return Colours.palette.m3inversePrimary;
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
        case "apps":
            return "deployed_code";
        case "cache":
            return "cached";
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
        case "apps":
            return qsTr("App data");
        case "cache":
            return qsTr("Cache");
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
        if (seg.note)
            parts.push(seg.note);
        return parts.join("  ·  ");
    }

    spacing: Tokens.spacing.extraSmall / 2

    SectionHeader {
        first: root.firstCard
        text: `${(root.disk.model || root.disk.name).toUpperCase()}  ·  ${root.fmt(root.disk.size)}${root.disk.system ? qsTr("  ·  SYSTEM") : ""}`
    }

    // ----------------------------------------------------------- barra GParted
    ConnectedRect {
        id: barCard

        // A barra fica abaixo da curva do canto grande (o raio extraLarge escala com
        // rounding.scale: com 2x sao ~56 px e, colada no topo, a barra vazava pra fora
        // da borda arredondada). inset = quanto a curva entra na altura em que a lateral
        // da barra encosta nela.
        readonly property real side: Tokens.padding.largeIncreased
        readonly property real r: Tokens.rounding.extraLarge
        readonly property real cornerInset: barCard.r > barCard.side ? barCard.r - Math.sqrt(barCard.r * barCard.r - (barCard.r - barCard.side) * (barCard.r - barCard.side)) : 0
        readonly property real topPad: Math.max(Tokens.padding.medium, Math.ceil(barCard.cornerInset) + Tokens.padding.small / 2)
        readonly property real bottomPad: barCard.last ? barCard.topPad : Tokens.padding.medium

        Layout.fillWidth: true
        Layout.preferredHeight: barCard.implicitHeight
        implicitHeight: barCard.topPad + bar.height + Tokens.spacing.small + legend.implicitHeight + barCard.bottomPad
        first: true
        last: root.segs.length === 0

        Row {
            id: bar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: barCard.topPad
            anchors.leftMargin: barCard.side
            anchors.rightMargin: barCard.side
            height: 22
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

                    // A particao inteira (tom claro); livre = so a borda. Sem texto: quem
                    // diz o que e cada pedaco e a lista embaixo, na mesma cor. O usado e
                    // recortado DENTRO do pedaco (clip + mesmo raio): nunca vaza nem vira bolinha.
                    StyledRect {
                        anchors.fill: parent
                        radius: 4
                        clip: true
                        color: seg.data_.kind === "free" ? "transparent" : Qt.alpha(seg.tone, 0.3)
                        border.width: seg.data_.kind === "free" ? 1 : 0
                        border.color: seg.tone

                        Rectangle {
                            visible: seg.usedFrac > 0
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(seg.usedFrac, 0)
                            radius: 4
                            color: seg.tone
                        }
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
            text: qsTr("%1  ·  %2%3  ·  solid = used, light = free, outline = unallocated").arg(root.disk.path).arg(root.segs.filter(s => s.kind === "part").length === 1 ? qsTr("1 partition") : qsTr("%1 partitions").arg(root.segs.filter(s => s.kind === "part").length)).arg(root.extra ? `  ·  ${root.extra}` : "")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
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
