pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// O que esta desatualizado, por fonte, e o botao do aplicador, que roda aqui
// mesmo (progresso abaixo do botao; a senha vem pela caixa do Caelestia). A
// pagina so le: a lista vem de ~/.cache/caelestia/updates.json, gravado pelo
// timer, pelo "Check now" ou pelo proprio caelestia-update ao terminar; o
// progresso, de update-state.json.
PageBase {
    id: root

    readonly property var sources: [
        {
            key: "repo",
            label: qsTr("OFFICIAL REPOSITORIES"),
            icon: "deployed_code"
        },
        {
            key: "aur",
            label: qsTr("AUR"),
            icon: "construction"
        },
        {
            key: "flatpak",
            label: qsTr("FLATPAK"),
            icon: "package_2"
        },
        // Forks so por seguranca (caelestia-forks, politica auto): o "Update
        // everything" avanca ate a release nova e recompila.
        {
            key: "forks",
            label: qsTr("CRAFTING APPS"),
            icon: "fork_right"
        },
        // Segurados de proposito no caelestia-update (--print-hold): nao contam
        // como pendentes e o "Update everything" nao os toca.
        {
            key: "held",
            label: qsTr("HELD ON PURPOSE"),
            icon: "pause_circle"
        },
        // Forks com alteracoes nossas (politica manual: caelestia, Odysseus):
        // so avisa; a atualizacao e feita a mao, avaliando o impacto.
        {
            key: "review",
            label: qsTr("FORKS TO REVIEW"),
            icon: "rate_review"
        }
    ]

    readonly property var runSteps: [
        {
            key: "repo",
            label: qsTr("Official repositories")
        },
        {
            key: "aur",
            label: qsTr("AUR")
        },
        {
            key: "flatpak",
            label: qsTr("Flatpak")
        },
        {
            key: "forks",
            label: qsTr("Crafting Apps")
        },
        // TV da sala (caelestia-sala-jogos sync --scrape): pulado com o Pi desligado; nao muda o resultado
        {
            key: "tv",
            label: qsTr("Living-room TV")
        },
        {
            key: "checks",
            label: qsTr("Checks before restarting")
        }
    ]

    readonly property var run: SoftwareInventory.updateRun
    readonly property bool runKnown: root.run.started_at !== undefined
    readonly property bool runFailed: !SoftwareInventory.updating && root.runKnown && (root.run.rc !== 0 || SoftwareInventory.updateRunDead)

    function currentStep(): string {
        const s = root.runSteps.find(s => root.run.steps?.[s.key] === "running");
        return s ? s.label : qsTr("Starting");
    }

    function runTitle(): string {
        if (SoftwareInventory.updating)
            return qsTr("Updating: %1").arg(root.currentStep());
        if (SoftwareInventory.updateRunDead)
            return qsTr("The last update was interrupted");
        if (root.run.cancelled)
            return qsTr("Update cancelled");
        return root.run.rc === 0 ? qsTr("Updates installed") : qsTr("Update finished with errors");
    }

    function runSubtext(): string {
        if (SoftwareInventory.updating)
            return qsTr("You can close this window; the update keeps going");
        if (root.run.block_reboot)
            return qsTr("Do not restart yet: see the problems below");
        if (root.run.reboot)
            return qsTr("Restart to use the new kernel or driver");
        if (root.run.relogin)
            return qsTr("Log out and back in to load the new compositor");
        return Qt.formatDateTime(new Date((root.run.finished_at || root.run.started_at) * 1000), "dd/MM hh:mm");
    }

    function stepIcon(state: string): string {
        return ({ pending: "schedule", running: "pending", done: "check_circle", failed: "error", skipped: "remove_circle_outline" })[state] ?? "schedule";
    }

    function stepColour(state: string): color {
        if (state === "failed")
            return Colours.palette.m3error;
        return state === "running" || state === "done" ? Colours.palette.m3primary : Colours.palette.m3outline;
    }

    function stepText(state: string): string {
        return ({ pending: qsTr("Waiting"), running: qsTr("Running"), done: qsTr("Done"), failed: qsTr("Failed"), skipped: qsTr("Skipped") })[state] ?? "";
    }

    // Secoes que so aparecem quando tem algo (as outras mostram "Up to date").
    readonly property var onlyWhenPending: ["held", "review"]

    function sourceState(key: string): string {
        if (key === "repo" && SoftwareInventory.updates.checkupdates_missing)
            return qsTr("not checked — install pacman-contrib");
        if ((SoftwareInventory.updates.errors ?? []).includes(key))
            return qsTr("did not respond");
        return "";
    }

    function checkedText(): string {
        if (SoftwareInventory.loadingUpdates)
            return qsTr("Checking…");
        const at = SoftwareInventory.updatesCheckedAt;
        if (!at)
            return qsTr("Never checked");
        return qsTr("Checked %1").arg(Qt.formatDateTime(at, "dd/MM hh:mm"));
    }

    title: qsTr("Updates")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Checked every 6 hours in the background; a notification appears only when the pending list changes. Updating runs here and asks for your password once: official repositories first, then AUR, then Flatpak, then the Crafting Apps forks, then the living-room TV catalogue (Steam games and ROM box art), and it tells you afterwards whether a reboot or a plugin rebuild is needed. Forks with our own changes are only listed for review.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        InfoRow {
            first: true
            icon: SoftwareInventory.updateCount > 0 ? "system_update_alt" : (SoftwareInventory.updatesComplete ? "check_circle" : "help")
            iconColour: SoftwareInventory.updateCount > 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            label: SoftwareInventory.updateCount > 0 ? qsTr("%n update(s) available", "", SoftwareInventory.updateCount) : (SoftwareInventory.updatesComplete ? qsTr("Up to date") : qsTr("No updates found"))
            subtext: SoftwareInventory.updatesFetched && !SoftwareInventory.updatesComplete ? qsTr("%1 · partial: some sources were not checked").arg(root.checkedText()) : root.checkedText()
            value: SoftwareInventory.updatesFetched ? qsTr("%1 · %2 · %3 · %4").arg((SoftwareInventory.updates.repo ?? []).length).arg((SoftwareInventory.updates.aur ?? []).length).arg((SoftwareInventory.updates.flatpak ?? []).length).arg((SoftwareInventory.updates.forks ?? []).length) : ""
        }

        RowButton {
            icon: "refresh"
            text: qsTr("Check now")
            subtext: qsTr("Asks the repositories, AUR, Flathub and the forks' upstreams — takes a few seconds")
            disabled: SoftwareInventory.loadingUpdates
            onClicked: SoftwareInventory.fetchUpdates()
        }

        RowButton {
            last: !root.runFailed
            icon: "system_update_alt"
            text: qsTr("Update everything")
            subtext: SoftwareInventory.updating ? qsTr("Running, progress below") : qsTr("Installs everything listed here, except what is held or needs review")
            disabled: SoftwareInventory.updating
            onClicked: SoftwareInventory.runUpdate()
        }

        // Reserva: sem terminal o pacman nao faz perguntas, entao o que precisa
        // de uma decisao (conflito, troca de pacote) falha e cai aqui.
        RowButton {
            last: true
            visible: root.runFailed
            icon: "terminal"
            text: qsTr("Open in a terminal")
            subtext: qsTr("If the package manager needs a decision from you")
            trailingIcon: "open_in_new"
            onClicked: SoftwareInventory.runUpdateInTerminal()
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.runKnown
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                text: SoftwareInventory.updating ? qsTr("UPDATE IN PROGRESS") : qsTr("LAST UPDATE")
            }

            InfoRow {
                first: true
                icon: SoftwareInventory.updating ? "pending" : (root.runFailed ? (root.run.cancelled ? "cancel" : "error") : "check_circle")
                iconColour: root.runFailed && !root.run.cancelled ? Colours.palette.m3error : Colours.palette.m3primary
                label: root.runTitle()
                subtext: root.runKnown ? root.runSubtext() : ""
            }

            Repeater {
                model: root.runSteps.length

                InfoRow {
                    id: stepRow

                    required property int index
                    readonly property string state_: root.run.steps?.[root.runSteps[stepRow.index].key] ?? "pending"

                    icon: root.stepIcon(stepRow.state_)
                    iconColour: root.stepColour(stepRow.state_)
                    label: root.runSteps[stepRow.index].label
                    value: root.stepText(stepRow.state_)
                }
            }

            Repeater {
                model: (root.run.notes ?? []).length

                // Sem elide: e o erro do pacman, tem de dar para ler inteiro.
                ConnectedRect {
                    id: noteRow

                    required property int index

                    Layout.fillWidth: true
                    implicitHeight: noteLayout.implicitHeight + Tokens.padding.medium * 2

                    RowLayout {
                        id: noteLayout

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Tokens.padding.largeIncreased
                        anchors.rightMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "warning"
                            color: Colours.palette.m3tertiary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: (root.run.notes ?? [])[noteRow.index] ?? ""
                            font: Tokens.font.body.small
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            ConnectedRect {
                last: true
                Layout.fillWidth: true
                implicitHeight: 340
                visible: SoftwareInventory.updateLog !== ""

                // Log inteiro na pagina. Segue o fim enquanto ele cresce; rolar para
                // cima solta, e voltar ao fim prende de novo.
                StyledFlickable {
                    id: logFlick

                    property bool follow: true

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    contentWidth: width
                    contentHeight: logText.implicitHeight
                    flickableDirection: Flickable.VerticalFlick
                    clip: true

                    function toEnd(): void {
                        contentY = Math.max(0, contentHeight - height);
                    }

                    onContentHeightChanged: if (follow) toEnd()
                    onHeightChanged: if (follow) toEnd()
                    onContentYChanged: follow = contentY >= contentHeight - height - 4

                    StyledScrollBar.vertical: StyledScrollBar {
                        flickable: logFlick
                    }

                    // Text puro: StyledText animaria a cor a cada linha nova.
                    Text {
                        id: logText

                        width: logFlick.width - Tokens.padding.large
                        text: SoftwareInventory.updateLog
                        textFormat: Text.PlainText
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.mono.small
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }
            }
        }

        Repeater {
            model: root.sources.length

            ColumnLayout {
                id: section

                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.sources[index] ?? ({})
                readonly property var liveItem: root.sources[index]
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                required property int index

                readonly property var items: SoftwareInventory.updates[section.modelData.key] ?? []
                readonly property string problem: root.sourceState(section.modelData.key)

                Layout.fillWidth: true
                visible: !root.onlyWhenPending.includes(section.modelData.key) || section.items.length > 0
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    text: section.problem ? `${section.modelData.label}  ·  ${section.problem}` : `${section.modelData.label}  ·  ${section.items.length}`
                }

                ItemList {
                    id: pkgList

                    showList: true
                    placeholderIcon: section.problem ? "warning" : "check_circle"
                    placeholderText: section.problem ? qsTr("Not checked") : qsTr("Up to date")
                    list.spacing: Tokens.spacing.extraSmall / 2

                    model: ScriptModel {
                        values: [...section.items]
                    }

                    delegate: InfoRow {
                        id: row

                        required property var modelData
                        required property int index

                        anchors.left: pkgList.list.contentItem.left
                        anchors.right: pkgList.list.contentItem.right
                        first: row.index === 0
                        last: row.index === section.items.length - 1
                        icon: section.modelData.icon
                        label: row.modelData.name
                        subtext: {
                            const v = row.modelData.from ? `${row.modelData.from}  →  ${row.modelData.to}` : row.modelData.to;
                            if (section.modelData.key === "held")
                                return qsTr("%1  ·  kept back on purpose, not installed by Update everything").arg(v);
                            if (section.modelData.key === "review")
                                return qsTr("%1  ·  has our own changes, update by hand").arg(v);
                            return v;
                        }
                    }
                }
            }
        }
    }
}
