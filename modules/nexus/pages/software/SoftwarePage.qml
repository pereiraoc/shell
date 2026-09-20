pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Arvore aninhada: REQUIREMENT > DESIGN > CONFIGURATION, com IMPLEMENTATION
// ao lado do design dentro do mesmo requisito.
//
// A versao anterior filtrava tres secoes irmas: escolher um requisito trocava
// o conteudo das listas abaixo, e a hierarquia ficava so implicita -- nao dava
// pra ver ONDE cada coisa estava. Aninhado, a posicao na tela e a propria
// resposta, e da pra ter dois requisitos abertos ao mesmo tempo.
//
// Configuracao pendura no DESIGN, nao no requisito: em docs/configuracao cada
// arquivo declara a que design pertence.
PageBase {
    id: root

    // Conjuntos de nos abertos, por id. Objeto em vez de string unica para que
    // varios ramos fiquem abertos ao mesmo tempo -- comparar dois requisitos
    // e' metade do uso desta tela.
    property var openReq: ({})
    property var openDesign: ({})

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
            text: qsTr("REQUIREMENT  ·  DESIGN  ·  CONFIGURATION  ·  IMPLEMENTATION")
        }

        Repeater {
            model: SoftwareInventory.requirements

            ColumnLayout {
                id: reqBranch

                required property var modelData
                required property int index

                readonly property bool expanded: !!root.openReq[reqBranch.modelData.id]
                readonly property var designs: SoftwareInventory.designFor(reqBranch.modelData)
                readonly property var impls: SoftwareInventory.implFor(reqBranch.modelData)

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                TreeRow {
                    first: reqBranch.index === 0
                    last: !reqBranch.expanded && reqBranch.index === SoftwareInventory.requirements.length - 1
                    color: reqBranch.expanded ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                    icon: reqBranch.expanded ? "expand_more" : "chevron_right"
                    text: `${reqBranch.modelData.id}  ${reqBranch.modelData.title}`
                    subtext: qsTr("%1 · %2 design · %3 config · %4 impl · %5 pkg").arg(root.statusLabel(reqBranch.modelData.status)).arg(reqBranch.modelData.design.length).arg(reqBranch.modelData.configurations.length).arg(reqBranch.modelData.implementation.length).arg(reqBranch.modelData.packages.length)
                    value: reqBranch.modelData.packages_size > 0 ? `${root.fmtSize(reqBranch.modelData.files_size)}  ·  ${root.fmtSize(reqBranch.modelData.packages_size)}` : root.fmtSize(reqBranch.modelData.files_size)
                    onClicked: root.openReq = root.toggle(root.openReq, reqBranch.modelData.id)
                }

                // --- DESIGN, um nivel abaixo
                Repeater {
                    model: reqBranch.expanded ? reqBranch.designs : []

                    ColumnLayout {
                        id: designBranch

                        required property var modelData

                        // A chave junta requisito e design: o mesmo documento
                        // serve mais de um requisito (DS-12 serve tres), e sem
                        // o prefixo abrir num ramo abriria em todos.
                        readonly property string key: `${reqBranch.modelData.id}/${designBranch.modelData.id}`
                        readonly property bool expanded: !!root.openDesign[designBranch.key]
                        readonly property var configs: (designBranch.modelData.configurations ?? []).map(id => (SoftwareInventory.trace.configurations ?? []).find(c => c.id === id)).filter(c => c)

                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.extraSmall / 2

                        TreeRow {
                            icon: designBranch.configs.length > 0 ? (designBranch.expanded ? "expand_more" : "chevron_right") : "description"
                            text: `${designBranch.modelData.id}  ${designBranch.modelData.title}`
                            subtext: designBranch.modelData.file
                            value: designBranch.configs.length > 0 ? qsTr("%1 config  ·  %2").arg(designBranch.configs.length).arg(root.fmtSize(designBranch.modelData.size)) : root.fmtSize(designBranch.modelData.size)
                            trailingIcon: designBranch.configs.length > 0 ? "" : "open_in_new"
                            onClicked: {
                                if (designBranch.configs.length > 0)
                                    root.openDesign = root.toggle(root.openDesign, designBranch.key);
                                else
                                    root.openNote(designBranch.modelData.file);
                            }
                        }

                        // --- CONFIGURATION, dois niveis abaixo
                        Repeater {
                            model: designBranch.expanded ? designBranch.configs : []

                            TreeRow {
                                id: cfgRow

                                required property var modelData

                                Layout.leftMargin: Tokens.padding.largeIncreased
                                color: Colours.tPalette.m3surfaceContainerHigh
                                icon: "tune"
                                text: `${cfgRow.modelData.id}  ${cfgRow.modelData.title}`
                                subtext: cfgRow.modelData.file
                                value: root.fmtSize(cfgRow.modelData.size)
                                trailingIcon: "open_in_new"
                                onClicked: root.openNote(cfgRow.modelData.file)
                            }
                        }
                    }
                }

                // --- IMPLEMENTATION, irma do design dentro do requisito
                Repeater {
                    model: reqBranch.expanded ? reqBranch.impls : []

                    TreeRow {
                        id: implRow

                        required property var modelData
                        required property int index

                        Layout.leftMargin: Tokens.padding.largeIncreased
                        last: implRow.index === reqBranch.impls.length - 1 && reqBranch.index === SoftwareInventory.requirements.length - 1
                        icon: implRow.modelData.stub ? "warning" : (implRow.modelData.kind === "dir" ? "folder" : "terminal")
                        iconColour: implRow.modelData.stub ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                        text: implRow.modelData.path
                        subtext: implRow.modelData.stub ? qsTr("Stub — declared but does nothing") : (implRow.modelData.packages.length > 0 ? implRow.modelData.packages.join(" ") : qsTr("Configures, installs nothing"))
                        value: root.fmtSize(implRow.modelData.size)
                        trailingIcon: implRow.modelData.kind === "dir" ? "" : "open_in_new"
                        onClicked: {
                            if (implRow.modelData.kind !== "dir")
                                root.openNote(implRow.modelData.path);
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
            subtext: qsTr("%1 broken · %2 stubs · %3 design unused · %4 config unlinked").arg(SoftwareInventory.broken.length).arg(SoftwareInventory.stubs.length).arg(SoftwareInventory.unusedDesign.length).arg(SoftwareInventory.counts.configurations_unlinked ?? 0)
            onClicked: root.nState.openSubPage(3)
        }
    }
}
