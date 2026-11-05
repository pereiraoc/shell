pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

// Aparelhos aprovados (05/11, setup CF-38): pedidos de "Approve from my phone" que chegam ao nas-approve do NAS
// aparecem aqui para o dono aprovar no proprio PC (apelido, 30 dias ou para sempre, ou negar), e a lista dos
// aparelhos aprovados com revogar (dois cliques). Dados e acoes: caelestia-approve (ToolBridge "approve").
ColumnLayout {
    id: root

    required property ToolBridge bridge
    readonly property var pending: root.bridge.info.pending ?? []
    readonly property var devices: root.bridge.info.devices ?? []
    property string armed: ""

    function deviceIcon(kind: string): string {
        if (/Android|iPhone/.test(kind))
            return "smartphone";
        if (/iPad|tablet/i.test(kind))
            return "tablet_android";
        if (/TV/.test(kind))
            return "tv";
        if (/app/.test(kind))
            return "apps";
        return "laptop";
    }

    function press(id: string, medium: bool): void {
        if (medium && root.armed !== id) {
            root.armed = id;
            disarm.restart();
            return;
        }
        root.armed = "";
        root.bridge.run({ id: id });
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    Timer {
        id: disarm

        interval: 4000
        onTriggered: root.armed = ""
    }

    SectionHeader {
        first: true
        text: root.pending.length > 0 ? Tr.tr("Sign-in requests") : Tr.tr("Approved devices")
    }

    InfoRow {
        visible: (root.bridge.info.error ?? "") !== ""
        first: true
        last: true
        icon: "error"
        label: Tr.tr("Could not read the approvals")
        subtext: root.bridge.info.error ?? ""
    }

    // ---- pedidos esperando ----------------------------------------------------
    Repeater {
        model: root.pending.length

        ConnectedRect {
            id: req

            required property int index
            readonly property var r: root.pending[req.index] ?? ({})
            property string nick: req.r.kind ?? ""

            Layout.fillWidth: true
            first: req.index === 0
            last: req.index === root.pending.length - 1
            implicitHeight: reqCol.implicitHeight + Tokens.padding.large * 2

            ColumnLayout {
                id: reqCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.large

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: root.deviceIcon(req.r.kind ?? "")
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.large
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: req.r.kind ?? ""
                            font: Tokens.font.title.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Tr.tr("Wants %1 · %2 · %3 s left").arg(req.r.site ?? "").arg(req.r.where ?? "").arg(req.r.expires_in ?? 0)
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    // o codigo que aparece na tela do aparelho: conferir antes de aprovar
                    StyledText {
                        text: req.r.code ?? ""
                        font.family: "monospace"
                        font.pointSize: Tokens.font.title.medium.pointSize
                        font.letterSpacing: 3
                        color: Colours.palette.m3onSurface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        Layout.fillWidth: true
                        text: req.r.kind ?? ""
                        leadingIcon: "badge"
                        onTextChanged: req.nick = text
                    }

                    TextButton {
                        type: TextButton.Filled
                        text: Tr.tr("30 days")
                        enabled: root.bridge.busyAction === ""
                        onClicked: root.press(`approve~${req.r.id}~30d~${req.nick.replace(/~/g, " ").trim()}`, false)
                    }

                    TextButton {
                        text: root.armed === `always~${req.r.id}` ? Tr.tr("Click again") : Tr.tr("Always")
                        enabled: root.bridge.busyAction === ""
                        onClicked: {
                            if (root.armed !== `always~${req.r.id}`) {
                                root.armed = `always~${req.r.id}`;
                                disarm.restart();
                                return;
                            }
                            root.armed = "";
                            root.bridge.run({ id: `approve~${req.r.id}~always~${req.nick.replace(/~/g, " ").trim()}` });
                        }
                    }

                    TextButton {
                        type: TextButton.Text
                        text: Tr.tr("Deny")
                        enabled: root.bridge.busyAction === ""
                        onClicked: root.press(`deny~${req.r.id}`, false)
                    }
                }
            }
        }
    }

    SectionHeader {
        visible: root.pending.length > 0
        text: Tr.tr("Approved devices")
    }

    // ---- aparelhos aprovados ---------------------------------------------------
    InfoRow {
        visible: root.devices.length === 0 && (root.bridge.info.error ?? "") === ""
        first: true
        last: true
        icon: "verified_user"
        label: Tr.tr("No approved devices yet")
        subtext: Tr.tr("On a new device, open a private site and pick 'Approve from my phone'")
    }

    Repeater {
        model: root.devices.length

        RowButton {
            id: dev

            required property int index
            readonly property var d: root.devices[dev.index] ?? ({})

            Layout.fillWidth: true
            first: dev.index === 0
            last: dev.index === root.devices.length - 1
            icon: root.deviceIcon(dev.d.kind ?? "")
            text: dev.d.nickname ?? ""
            subtext: root.armed === `revoke~${dev.d.id}` ? Tr.tr("Click again to revoke: it will need a new approval")
                : Tr.tr("%1 · %2 · last seen %3").arg(dev.d.kind ?? "").arg(dev.d.forever ? Tr.tr("always") : (dev.d.until ?? "")).arg(dev.d.where ?? "")
            trailingIcon: "delete"
            onClicked: root.press(`revoke~${dev.d.id}`, true)
        }
    }

    ActionErrorRow {
        bridge: root.bridge
    }
}
