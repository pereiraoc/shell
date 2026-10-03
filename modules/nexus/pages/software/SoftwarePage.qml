pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Arvore aninhada: REQUISITO > DESIGN > IMPLEMENTACAO > itens (configuracao,
// scripts/pastas, pacotes, bibliotecas). A implementacao e um capitulo do
// design com "#### Implementação" -- e ali que o repositorio declara o que
// resolve aquele software (docs/advanced/software-inventory.md).
//
// A versao anterior filtrava tres secoes irmas: escolher um requisito trocava
// o conteudo das listas abaixo, e a hierarquia ficava so implicita -- nao dava
// pra ver ONDE cada coisa estava. Aninhado, a posicao na tela e a propria
// resposta, e da pra ter dois requisitos abertos ao mesmo tempo.
//
PageBase {
    id: root

    // Conjuntos de nos abertos, por id. Objeto em vez de string unica para que
    // varios ramos fiquem abertos ao mesmo tempo -- comparar dois requisitos
    // e' metade do uso desta tela.
    property var openReq: ({})
    property var openDesign: ({})
    property var openImpl: ({})

    function fmtSize(bytes: int): string {
        if (!bytes)
            return "";
        if (bytes >= 1048576)
            return `${(bytes / 1048576).toFixed(1)} MiB`;
        return `${Math.round(bytes / 1024)} KiB`;
    }

    function statusLabel(s: string): string {
        if (s === "parcial")
            return qsTr("Partial");
        if (s === "pendente")
            return qsTr("Pending");
        return qsTr("Not assessed");
    }

    function toggle(set: var, key: string): var {
        const next = Object.assign({}, set);
        if (next[key])
            delete next[key];
        else
            next[key] = true;
        return next;
    }

    // Abre a nota no editor configurado (open_command em
    // software-inventory.json). Caminho absoluto montado a partir de
    // trace.repo, porque o CLI devolve caminhos relativos ao repositorio.
    function openNote(rel: string): void {
        const repo = SoftwareInventory.trace.repo ?? "";
        const cmd = SoftwareInventory.trace.open_command ?? ["code"];
        if (repo && rel)
            Quickshell.execDetached([...cmd, `${repo}/${rel}`]);
    }

    title: qsTr("Software")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Required software traces back to a requirement. Derived software does not — it is the list of things to formalise or remove. Click any row to open its note.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        InfoRow {
            first: true
            icon: "verified"
            label: qsTr("Required")
            subtext: qsTr("Reaches a requirement, directly or through a dependency")
            value: SoftwareInventory.counts.required ?? "—"
        }

        InfoRow {
            last: true
            icon: "help"
            iconColour: Colours.palette.m3error
            label: qsTr("Derived")
            subtext: qsTr("Nothing in the repository explains it")
            value: SoftwareInventory.counts.derived ?? "—"
        }

        SectionHeader {
            text: qsTr("UPDATES")
        }

        // Le o cache (sem rede). Contagem parcial ganha o aviso na propria
        // linha: um "0" sem os repositorios oficiais nao e' "em dia".
        NavRow {
            first: true
            last: true
            icon: SoftwareInventory.updateCount > 0 ? "system_update_alt" : "update"
            iconLabel.color: SoftwareInventory.updateCount > 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            text: SoftwareInventory.updateCount > 0 ? qsTr("%n update(s) available", "", SoftwareInventory.updateCount) : qsTr("Updates")
            subtext: !SoftwareInventory.updatesFetched ? qsTr("Not checked yet") : (SoftwareInventory.updatesComplete ? qsTr("%1 official · %2 AUR · %3 Flatpak").arg((SoftwareInventory.updates.repo ?? []).length).arg((SoftwareInventory.updates.aur ?? []).length).arg((SoftwareInventory.updates.flatpak ?? []).length) : qsTr("Partial check — some sources were not asked"))
            onClicked: root.nState.openSubPage(4)
        }

        SectionHeader {
            text: qsTr("REQUIREMENT  ›  DESIGN  ›  IMPLEMENTATION  ›  CONFIG · SCRIPTS · PACKAGES")
        }

        Repeater {
            model: SoftwareInventory.requirements

            ColumnLayout {
                id: reqBranch

                required property var modelData
                required property int index

                readonly property bool expanded: !!root.openReq[reqBranch.modelData.id]
                readonly property var designs: SoftwareInventory.designFor(reqBranch.modelData)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                TreeRow {
                    first: reqBranch.index === 0
                    last: !reqBranch.expanded && reqBranch.index === SoftwareInventory.requirements.length - 1
                    color: reqBranch.expanded ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    icon: reqBranch.expanded ? "expand_more" : "chevron_right"
                    text: `${reqBranch.modelData.id}  ${reqBranch.modelData.title}`
                    subtext: qsTr("%1 · %2 design · %3 implementation · %4 packages").arg(root.statusLabel(reqBranch.modelData.status)).arg(reqBranch.modelData.design.length).arg((reqBranch.modelData.implementations ?? []).length).arg((reqBranch.modelData.packages_all ?? []).length)
                    value: reqBranch.modelData.packages_size > 0 ? `${root.fmtSize(reqBranch.modelData.files_size)}  ·  ${root.fmtSize(reqBranch.modelData.packages_size)}` : root.fmtSize(reqBranch.modelData.files_size)
                    onClicked: root.openReq = root.toggle(root.openReq, reqBranch.modelData.id)
                }

                // --- DESIGN
                Repeater {
                    model: reqBranch.expanded ? reqBranch.designs : []

                    ColumnLayout {
                        id: designBranch

                        required property var modelData

                        // O mesmo design serve varios requisitos: a chave leva o
                        // requisito, senao abrir num ramo abriria em todos.
                        readonly property string key: `${reqBranch.modelData.id}/${designBranch.modelData.id}`
                        readonly property bool expanded: !!root.openDesign[designBranch.key]
                        readonly property var impls: SoftwareInventory.implsFor(designBranch.modelData)

                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.extraSmall / 2

                        TreeRow {
                            icon: designBranch.impls.length > 0 ? (designBranch.expanded ? "expand_more" : "chevron_right") : "description"
                            text: `${designBranch.modelData.id}  ${designBranch.modelData.title}`
                            subtext: designBranch.impls.length > 0 ? qsTr("%1 implementation · %2").arg(designBranch.impls.length).arg(designBranch.modelData.file) : qsTr("No implementation declared · %1").arg(designBranch.modelData.file)
                            value: root.fmtSize(designBranch.modelData.size)
                            trailingIcon: designBranch.impls.length > 0 ? "" : "open_in_new"
                            onClicked: {
                                if (designBranch.impls.length > 0)
                                    root.openDesign = root.toggle(root.openDesign, designBranch.key);
                                else
                                    root.openNote(designBranch.modelData.file);
                            }
                        }

                        // --- IMPLEMENTACAO (capitulo do design)
                        Repeater {
                            model: designBranch.expanded ? designBranch.impls : []

                            ColumnLayout {
                                id: implBranch

                                required property var modelData

                                readonly property string key: `${designBranch.key}/${implBranch.modelData.id}`
                                readonly property bool expanded: !!root.openImpl[implBranch.key]
                                readonly property var items: SoftwareInventory.itemsFor(implBranch.modelData)
                                readonly property bool hasStub: implBranch.items.some(i => i.stub)

                                Layout.fillWidth: true
                                Layout.leftMargin: Tokens.padding.largeIncreased
                                spacing: Tokens.spacing.extraSmall / 2

                                TreeRow {
                                    color: implBranch.expanded ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer
                                    icon: implBranch.expanded ? "expand_more" : "chevron_right"
                                    iconColour: implBranch.hasStub ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                    text: implBranch.modelData.title
                                    subtext: qsTr("%1 config · %2 scripts/folders · %3 packages · %4 libraries%5").arg(implBranch.modelData.configurations.length).arg(implBranch.modelData.items.length).arg(implBranch.modelData.packages.length + implBranch.modelData.flatpaks.length).arg(implBranch.modelData.libraries.length).arg(implBranch.hasStub ? qsTr(" · has a stub") : "")
                                    value: implBranch.modelData.packages_size > 0 ? `${root.fmtSize(implBranch.modelData.files_size)}  ·  ${root.fmtSize(implBranch.modelData.packages_size)}` : root.fmtSize(implBranch.modelData.files_size)
                                    onClicked: root.openImpl = root.toggle(root.openImpl, implBranch.key)
                                }

                                // --- itens: configuracao
                                Repeater {
                                    model: implBranch.expanded ? implBranch.modelData.configurations : []

                                    TreeRow {
                                        id: cfgRow

                                        required property string modelData
                                        readonly property var cfg: SoftwareInventory.configFor(cfgRow.modelData)

                                        Layout.leftMargin: Tokens.padding.largeIncreased
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        icon: "tune"
                                        text: `${cfgRow.modelData}  ${cfgRow.cfg?.title ?? ""}`
                                        subtext: qsTr("Configuration · %1").arg(cfgRow.cfg?.file ?? "")
                                        value: root.fmtSize(cfgRow.cfg?.size ?? 0)
                                        trailingIcon: "open_in_new"
                                        onClicked: root.openNote(cfgRow.cfg?.file ?? "")
                                    }
                                }

                                // --- itens: scripts e pastas
                                Repeater {
                                    model: implBranch.expanded ? implBranch.items : []

                                    TreeRow {
                                        id: itemRow

                                        required property var modelData

                                        Layout.leftMargin: Tokens.padding.largeIncreased
                                        color: Colours.tPalette.m3surfaceContainerHigh
                                        icon: itemRow.modelData.stub ? "warning" : (itemRow.modelData.kind === "dir" ? "folder" : "terminal")
                                        iconColour: itemRow.modelData.stub ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                                        text: itemRow.modelData.path
                                        subtext: itemRow.modelData.stub ? qsTr("Stub — listed but does nothing") : (itemRow.modelData.kind === "dir" ? qsTr("Folder") : (itemRow.modelData.packages.length > 0 ? qsTr("Script · installs %1").arg(itemRow.modelData.packages.join(" ")) : qsTr("Script · configures, installs nothing")))
                                        value: root.fmtSize(itemRow.modelData.size)
                                        trailingIcon: itemRow.modelData.kind === "dir" ? "" : "open_in_new"
                                        onClicked: {
                                            if (itemRow.modelData.kind !== "dir")
                                                root.openNote(itemRow.modelData.path);
                                        }
                                    }
                                }

                                // --- itens: pacotes (programas + flatpak) e bibliotecas
                                TreeRow {
                                    visible: implBranch.expanded && (implBranch.modelData.packages.length + implBranch.modelData.flatpaks.length) > 0
                                    Layout.leftMargin: Tokens.padding.largeIncreased
                                    color: Colours.tPalette.m3surfaceContainerHigh
                                    icon: "deployed_code"
                                    text: qsTr("Packages  ·  %1").arg(implBranch.modelData.packages.length + implBranch.modelData.flatpaks.length)
                                    subtext: [...implBranch.modelData.packages, ...implBranch.modelData.flatpaks].join("  ")
                                }

                                TreeRow {
                                    visible: implBranch.expanded && implBranch.modelData.libraries.length > 0
                                    Layout.leftMargin: Tokens.padding.largeIncreased
                                    color: Colours.tPalette.m3surfaceContainerHigh
                                    icon: "library_books"
                                    text: qsTr("Libraries  ·  %1").arg(implBranch.modelData.libraries.length)
                                    subtext: implBranch.modelData.libraries.join("  ")
                                }
                            }
                        }
                    }
                }
            }
        }

        SectionHeader {
            text: qsTr("LOOSE ENDS")
        }

        NavRow {
            first: true
            icon: "help"
            text: qsTr("Derived software")
            subtext: qsTr("%1 explicit · %2 orphaned · %3 dependencies").arg(SoftwareInventory.counts.derived_explicit ?? 0).arg(SoftwareInventory.counts.derived_orphan ?? 0).arg(SoftwareInventory.counts.derived_dependency ?? 0)
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "unknown_document"
            text: qsTr("Untracked files")
            subtext: qsTr("No package claims them")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            last: true
            icon: "link_off"
            text: qsTr("Repository issues")
            subtext: qsTr("%1 outside any implementation · %2 broken · %3 stubs · %4 design unused").arg(SoftwareInventory.counts.unplaced ?? 0).arg(SoftwareInventory.broken.length).arg(SoftwareInventory.stubs.length).arg(SoftwareInventory.unusedDesign.length)
            onClicked: root.nState.openSubPage(3)
        }
    }
}
