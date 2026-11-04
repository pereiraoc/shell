pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Caminho do trafego em linha (pedido de 04/11: Internet, Network > Services).
// Mesmo desenho dos nos de Network > This network (icone grande so com contorno).
//
//     PathDiagram {
//         nodes: [{ icon: "laptop_mac", label: "This PC", sub: "...", port: "", state: "on" }, ...]
//         links: [{ label: "WireGuard", detail: "UDP 51820", tunnel: true }, ...]   // nodes.length - 1
//     }
//
// - port: onde aquele no ESCUTA (etiqueta sob o icone), nunca solto no caminho;
// - tunnel: linha dupla com cadeado = trafego dentro de um tunel cifrado; o
//   label diz QUAL servico faz o tunel; detail diz protocolo/porta;
// - encrypted (sem tunel): linha simples com cadeado (TLS/HTTPS/DoH);
// - state: "on" (primary), "off" (apagado), "error".
// So linha, sem preenchimento; cor so para estado.
RowLayout {
    id: root

    property var nodes: []
    property var links: []

    readonly property real box: Tokens.padding.extraExtraLarge * 2

    function stateColour(state: string): color {
        if (state === "error")
            return Colours.palette.m3error;
        if (state === "off")
            return Colours.palette.m3outline;
        return Colours.palette.m3primary;
    }

    Layout.fillWidth: true
    spacing: 0

    Repeater {
        model: root.nodes

        RowLayout {
            id: seg

            required property var modelData
            required property int index
            readonly property bool hasLink: seg.index < root.nodes.length - 1
            readonly property var link: root.links[seg.index] ?? ({})

            Layout.fillWidth: true
            Layout.preferredWidth: seg.hasLink ? 2.2 : 1
            Layout.alignment: Qt.AlignTop
            spacing: 0

            // ---- no -------------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: Tokens.spacing.extraSmall / 2

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: root.box
                    implicitHeight: root.box
                    radius: Tokens.rounding.medium
                    color: "transparent"
                    border.width: 1
                    border.color: seg.modelData.state === "off" ? Colours.palette.m3outlineVariant : seg.modelData.state === "error" ? Colours.palette.m3error : Colours.palette.m3outline

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: seg.modelData.icon
                        color: root.stateColour(seg.modelData.state ?? "on")
                        fontStyle: Tokens.font.icon.size(Tokens.padding.extraExtraLarge).build()
                    }
                }

                // porta em que este no escuta
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    visible: (seg.modelData.port ?? "") !== ""
                    implicitWidth: portText.implicitWidth + Tokens.padding.medium * 2
                    implicitHeight: portText.implicitHeight + Tokens.padding.small
                    radius: Tokens.rounding.full
                    color: "transparent"
                    border.width: 1
                    border.color: Colours.palette.m3outline

                    Text {
                        id: portText

                        anchors.centerIn: parent
                        text: `port ${seg.modelData.port ?? ""}`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: seg.modelData.label ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    color: seg.modelData.state === "off" ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: (seg.modelData.sub ?? "") !== ""
                    text: seg.modelData.sub ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            // ---- ligacao ----------------------------------------------------
            Item {
                id: lk

                readonly property bool tunnel: seg.link.tunnel === true
                readonly property bool locked: lk.tunnel || seg.link.encrypted === true

                visible: seg.hasLink
                Layout.fillWidth: true
                Layout.preferredWidth: 1.2
                Layout.alignment: Qt.AlignTop
                implicitHeight: root.box

                // nome do servico / do enlace, em cima da linha (cadeado acima se cifrado)
                Column {
                    anchors.bottom: line.top
                    anchors.bottomMargin: Tokens.spacing.extraSmall
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0

                    MaterialIcon {
                        visible: lk.locked
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "lock"
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.size(Tokens.font.label.small.pointSize * 1.3).build()
                    }

                    Text {
                        width: parent.width
                        text: seg.link.label ?? ""
                        horizontalAlignment: Text.AlignHCenter
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                // a linha: dupla = tunel; simples = conexao comum
                Item {
                    id: line

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.spacing.small
                    anchors.rightMargin: Tokens.spacing.small
                    height: lk.tunnel ? 5 : 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: chev.width / 2
                        anchors.top: parent.top
                        height: 1
                        color: lk.locked ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    Rectangle {
                        visible: lk.tunnel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: chev.width / 2
                        anchors.bottom: parent.bottom
                        height: 1
                        color: Colours.palette.m3primary
                    }

                    MaterialIcon {
                        id: chev

                        anchors.right: parent.right
                        anchors.rightMargin: -width / 3
                        anchors.verticalCenter: parent.verticalCenter
                        text: "chevron_right"
                        color: lk.locked ? Colours.palette.m3primary : Colours.palette.m3outline
                    }
                }

                // protocolo / porta de destino, embaixo
                Text {
                    anchors.top: line.bottom
                    anchors.topMargin: Tokens.spacing.extraSmall
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: seg.link.detail ?? ""
                    horizontalAlignment: Text.AlignHCenter
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }
    }
}
