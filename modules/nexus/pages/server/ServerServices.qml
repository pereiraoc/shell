pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus.common
import "server.js" as S

// Aba Services: cada stack Docker (Immich, Nextcloud, Jellyfin, Navidrome) com
// estado, containers e os botoes start/stop/restart (parar e reiniciar pedem
// dois cliques). Embaixo, as unidades nativas do NixOS, so leitura.
ColumnLayout {
    id: root

    required property var page
    required property var bridge

    readonly property var info: root.bridge.info
    readonly property bool online: root.info.online === true
    readonly property var stacks: root.info.stacks ?? []
    readonly property var services: root.info.services ?? []

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

    function stateColour(key: string): color {
        if (key === "failed")
            return Colours.palette.m3error;
        if (key === "on")
            return Colours.palette.m3primary;
        return Colours.palette.m3outline;
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

    Repeater {
        model: root.online ? root.stacks.length : 0

        ColumnLayout {
            id: stack

            required property int index
            readonly property var s: root.stacks[index] ?? ({})
            readonly property string key: S.stateKey(stack.s.active)
            readonly property var acts: S.stackActions(root.bridge.actions, stack.s.name ?? "")
            readonly property var containers: stack.s.containers ?? []

            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: stack.index === 0
                text: String(stack.s.name ?? "").toUpperCase()
            }

            InfoRow {
                first: true
                icon: S.stateIcon(stack.key)
                iconColour: root.stateColour(stack.key)
                label: root.stateText(stack.key) + (stack.s.since ? Tr.tr(" since %1").arg(String(stack.s.since).replace("T", " ")) : "")
                subtext: stack.containers.length === 0 ? Tr.tr("No containers") : stack.containers.map(c => `${c.name}: ${c.status ?? c.state}`).join(" · ")
            }

            Repeater {
                model: stack.acts.length

                RowButton {
                    id: act

                    required property int index
                    property var modelData: stack.acts[index] ?? ({})
                    readonly property var liveItem: stack.acts[index]
                    readonly property bool isArmed: root.page.armed === act.modelData.id
                    readonly property bool isBusy: root.bridge.busyAction === act.modelData.id

                    onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

                    color: act.isArmed ? Colours.palette.m3errorContainer : Colours.tPalette.m3surfaceContainer
                    icon: act.isBusy ? "hourglass_top" : String(act.modelData.id ?? "").startsWith("start:") ? "play_arrow" : String(act.modelData.id ?? "").startsWith("stop:") ? "stop" : "restart_alt"
                    text: root.page.actionText(act.modelData)
                    subtext: act.modelData.detail ?? ""
                    disabled: root.bridge.busyAction !== "" && !act.isBusy
                    onClicked: {
                        if (!act.isBusy)
                            root.page.press(act.modelData);
                    }
                }
            }

            RowButton {
                last: true
                icon: "subject"
                text: Tr.tr("Show log")
                subtext: Tr.tr("journal of %1 plus the container logs").arg(stack.s.unit ?? "")
                onClicked: root.page.showLogs(stack.s.unit ?? "")
            }
        }
    }

    SectionHeader {
        visible: root.online && root.services.length > 0
        text: Tr.tr("SYSTEM UNITS")
    }

    Repeater {
        model: root.online ? root.services.length : 0

        InfoRow {
            id: unit

            required property int index
            property var modelData: root.services[index] ?? ({})
            readonly property var liveItem: root.services[index]
            readonly property string key: S.stateKey(unit.modelData.active)

            onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem

            first: unit.index === 0
            last: unit.index === root.services.length - 1
            icon: S.stateIcon(unit.key)
            iconColour: root.stateColour(unit.key)
            label: unit.modelData.unit ?? ""
            subtext: [root.stateText(unit.key), unit.modelData.sub ?? "", unit.modelData.enabled ?? ""].filter(x => x).join(" · ")
        }
    }
}
