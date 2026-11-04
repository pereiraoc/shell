pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Services: cada stack Docker como card (ServiceCard: logo, bolinha de
// estado, resumo dos containers; no hover, start/stop/restart com dois cliques
// para parar/reiniciar, abrir o app e o log). Embaixo, as unidades nativas do
// NixOS em cards compactos (so leitura + log).
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var stacks: root.info.stacks ?? []
    readonly property var services: root.info.services ?? []
    // stacks + apps sem stack (Pleitost: site estatico no Caddy) + apps que o NAS
    // publica mas rodam no PC (Odysseus; pc_apps do caelestia-nas)
    readonly property var stackGroups: S.groupServices(root.stacks.concat(S.staticSites(root.bridge.actions, root.stacks, root.services), root.info.pc_apps ?? []), x => x.name)
    readonly property var unitGroups: S.groupServices(S.visibleUnits(root.services), x => x.unit)

    function stateText(key: string): string {
        switch (key) {
        case "on":
            return Tr.tr("Running");
        case "starting":
            return Tr.tr("Starting");
        case "stopping":
            return Tr.tr("Stopping");
        case "failed":
            return Tr.tr("Failed");
        default:
            return Tr.tr("Stopped");
        }
    }

    Layout.fillWidth: true
    spacing: Tokens.spacing.extraSmall / 2

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.small
        Layout.bottomMargin: Tokens.spacing.medium
        text: Tr.tr("Each service is a Docker Compose stack run by a systemd unit on the NAS (stack-<name>.service). Stopping keeps the data; it only turns the containers off.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    InfoRow {
        visible: !root.online || root.stacks.length === 0
        first: true
        last: true
        icon: root.online ? "deployed_code" : "cloud_off"
        iconColour: Colours.palette.m3tertiary
        label: root.online ? Tr.tr("No stacks on the NAS yet") : Tr.tr("NAS out of reach")
        subtext: root.online ? Tr.tr("They appear here after phase 2 (services.nix) is applied") : ""
    }

    // Um grupo por funcao (S.groupServices: Media, Photos & files, Smart home...),
    // cada um com titulo e a grade de cards (uma coluna a cada ~240 px).
    // Modelo = quantidade: o refresh de 30 s nao recria os cards (hover e o
    // "clique de novo" nao se perdem).
    Repeater {
        model: root.online ? root.stackGroups.length : 0

        ColumnLayout {
            id: grp

            required property int index
            readonly property var g: root.stackGroups[grp.index] ?? ({ items: [] })

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            SectionHeader {
                first: grp.index === 0
                text: String(grp.g.title ?? "").toUpperCase()
            }

            GridLayout {
                id: grid

                // largura de coluna fixa: grupo com 2 cards nao estica os dois
                readonly property real cellWidth: Math.floor((grp.width - grid.columnSpacing * (grid.columns - 1)) / grid.columns)

                Layout.fillWidth: true
                columns: Math.max(2, Math.floor(grp.width / 240))
                columnSpacing: Tokens.spacing.small
                rowSpacing: Tokens.spacing.small

                Repeater {
                    model: (grp.g.items ?? []).length

                    ServiceCard {
                        id: stack

                        required property int index
                        readonly property var s: grp.g.items[stack.index] ?? ({})

                        Layout.preferredWidth: grid.cellWidth
                        Layout.maximumWidth: grid.cellWidth
                        bridge: root.bridge
                        name: stack.s.name ?? ""
                        stateKey: S.stateKey(stack.s.active)
                        stateText: root.stateText(stack.stateKey) + (stack.stateKey !== "on" && stack.stateKey !== "failed" && (stack.s.auto_start === false || stack.s.condition_met === false) ? Tr.tr(" (on purpose)") : "")
                        since: stack.s.since ? String(stack.s.since).replace("T", " ").slice(5, 16) : ""
                        summary: S.stackSummary(stack.s)
                        // app do PC nao tem journal no NAS
                        logUnit: stack.s.where === "pc" ? "" : (stack.s.unit ?? "")
                        actions: stack.s.site || stack.s.where === "pc" ? [] : S.stackActions(root.bridge.actions, stack.s.name ?? "")
                        openAction: S.actionById(root.bridge.actions, "open:" + (stack.s.name ?? ""))
                        onShowLog: unit => root.page.showLogs(unit)
                    }
                }
            }
        }
    }

    // Unidades do NixOS: mesmos grupos por funcao, cards compactos, depois de
    // um separador "SYSTEM"
    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spacing.large
        Layout.leftMargin: Tokens.padding.small
        visible: root.online && root.services.length > 0
        text: Tr.tr("System services of the NAS (NixOS units): read-only here, with their logs.")
        color: Colours.palette.m3outline
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    Repeater {
        model: root.online ? root.unitGroups.length : 0

        ColumnLayout {
            id: ugrp

            required property int index
            readonly property var g: root.unitGroups[ugrp.index] ?? ({ items: [] })

            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            SectionHeader {
                text: Tr.tr("SYSTEM · %1").arg(String(ugrp.g.title ?? "").toUpperCase())
            }

            GridLayout {
                id: ugrid

                // largura de coluna fixa: grupo com 2 cards nao estica os dois
                readonly property real cellWidth: Math.floor((ugrp.width - ugrid.columnSpacing * (ugrid.columns - 1)) / ugrid.columns)

                Layout.fillWidth: true
                columns: Math.max(2, Math.floor(ugrp.width / 240))
                columnSpacing: Tokens.spacing.small
                rowSpacing: Tokens.spacing.small

                Repeater {
                    model: (ugrp.g.items ?? []).length

                    ServiceCard {
                        id: unit

                        required property int index
                        readonly property var u: ugrp.g.items[unit.index] ?? ({})

                        Layout.preferredWidth: ugrid.cellWidth
                        Layout.maximumWidth: ugrid.cellWidth
                        compact: true
                        bridge: root.bridge
                        name: unit.u.unit ?? ""
                        stateKey: S.unitStateKey(unit.u, root.services)
                        stateText: root.stateText(unit.stateKey)
                        // timer: proxima/ultima execucao; oneshot parado entre execucoes = "Idle", nao "dead"
                        summary: S.unitSummary(unit.u, root.services, root.info.backup)
                        logUnit: unit.u.unit ?? ""
                        onShowLog: name => root.page.showLogs(name)
                    }
                }
            }
        }
    }
}
