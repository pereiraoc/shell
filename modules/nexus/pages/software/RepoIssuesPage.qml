pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Pontas soltas do lado do REPOSITORIO, simetricas as da maquina: aqui o grafo
// esta furado, nao o sistema. Aresta quebrada e rot silencioso -- um caminho
// renomeado some do rastreamento sem erro nenhum se ninguem olhar.
PageBase {
    id: root

    readonly property var cfgById: Object.fromEntries((SoftwareInventory.trace.configurations ?? []).map(c => [c.id, c]))

    function openNote(rel: string): void {
        const repo = SoftwareInventory.trace.repo ?? "";
        const cmd = SoftwareInventory.trace.open_command ?? ["code"];
        if (repo && rel)
            Quickshell.execDetached([...cmd, `${repo}/${rel}`]);
    }

    title: qsTr("Repository issues")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("BROKEN EDGES  ·  %1").arg(SoftwareInventory.broken.length)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("A design or requirement points at something that does not exist — a renamed script, a missing CF — or lists a configuration that belongs to another design. Renaming a file breaks the trace silently; this is the only place it shows.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: brokenList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("Every edge resolves")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...SoftwareInventory.broken]
            }

            delegate: InfoRow {
                id: brokenRow

                required property var modelData
                required property int index

                anchors.left: brokenList.list.contentItem.left
                anchors.right: brokenList.list.contentItem.right
                first: brokenRow.index === 0
                last: brokenRow.index === SoftwareInventory.broken.length - 1
                icon: "link_off"
                iconColour: Colours.palette.m3error
                label: brokenRow.modelData.path
                subtext: brokenRow.modelData.section
                value: brokenRow.modelData.requirement
            }
        }

        SectionHeader {
            text: qsTr("STUBS  ·  %1").arg(SoftwareInventory.stubs.length)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("An implementation lists this file, but the file is a placeholder. The requirement above it would not survive a clean install.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: stubList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("No stubs")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...SoftwareInventory.stubs]
            }

            delegate: InfoRow {
                id: stubRow

                required property var modelData
                required property int index

                anchors.left: stubList.list.contentItem.left
                anchors.right: stubList.list.contentItem.right
                first: stubRow.index === 0
                last: stubRow.index === SoftwareInventory.stubs.length - 1
                icon: "warning"
                iconColour: Colours.palette.m3error
                label: stubRow.modelData.path
                subtext: qsTr("Declared but does nothing")
                value: stubRow.modelData.requirements.join(" ")
            }
        }

        SectionHeader {
            text: qsTr("DESIGN WITHOUT A REQUIREMENT  ·  %1").arg(SoftwareInventory.unusedDesign.length)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("Design documents no requirement reaches. Either a requirement is missing, or the document describes something nobody asked for.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: unusedList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("Every design document serves a requirement")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...SoftwareInventory.unusedDesign]
            }

            delegate: InfoRow {
                id: unusedRow

                required property var modelData
                required property int index

                anchors.left: unusedList.list.contentItem.left
                anchors.right: unusedList.list.contentItem.right
                first: unusedRow.index === 0
                last: unusedRow.index === SoftwareInventory.unusedDesign.length - 1
                icon: "description"
                label: `${unusedRow.modelData.id}  ${unusedRow.modelData.title}`
                subtext: unusedRow.modelData.file
            }
        }

        IssueSection {
            title: qsTr("OUTSIDE ANY IMPLEMENTATION")
            help: qsTr("Scripts and config folders in the repository that no design lists under \"#### Implementação\". Nothing above reaches them: find the design that owns each one, or remove it.")
            values: SoftwareInventory.trace.unplaced ?? []
            icon: "unknown_document"
            okText: qsTr("Every script belongs to an implementation")
            openOf: v => v
            onOpen: rel => root.openNote(rel)
        }

        IssueSection {
            title: qsTr("CONFIGURATION WITHOUT AN IMPLEMENTATION")
            help: qsTr("Configuration notes that no implementation lists. List each one in a chapter of the design its header declares.")
            values: SoftwareInventory.trace.configurations_unplaced ?? []
            icon: "tune"
            okText: qsTr("Every configuration hangs off an implementation")
            labelOf: v => `${v}  ${root.cfgById[v]?.title ?? ""}`
            subOf: v => root.cfgById[v]?.file ?? ""
            openOf: v => root.cfgById[v]?.file ?? ""
            onOpen: rel => root.openNote(rel)
        }

        IssueSection {
            title: qsTr("EMPTY IMPLEMENTATIONS")
            help: qsTr("A design chapter declares \"#### Implementação\" but lists nothing under it.")
            values: SoftwareInventory.trace.implementations_empty ?? []
            icon: "inventory"
            okText: qsTr("No empty implementation")
        }

        IssueSection {
            title: qsTr("OLD-STYLE LINKS IN A REQUIREMENT")
            help: qsTr("\"## Implementação\" inside a requirement is the model before 03/10/2026. Move each item to the design chapter that implements it.")
            values: SoftwareInventory.trace.legacy ?? []
            icon: "history"
            okText: qsTr("No requirement links scripts directly")
            labelOf: v => v.path
            subOf: v => v.requirement
        }

        SectionHeader {
            text: qsTr("DECLARED BUT NOT INSTALLED  ·  %1").arg((SoftwareInventory.trace.declared_missing ?? []).length)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("A script installs these, the machine does not have them. Either the repository is ahead, or the package was swapped for another one by hand.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: missingList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("Repository and machine agree")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...(SoftwareInventory.trace.declared_missing ?? [])]
            }

            delegate: InfoRow {
                id: missingRow

                required property string modelData
                required property int index

                anchors.left: missingList.list.contentItem.left
                anchors.right: missingList.list.contentItem.right
                first: missingRow.index === 0
                last: missingRow.index === (SoftwareInventory.trace.declared_missing ?? []).length - 1
                icon: "download"
                label: missingRow.modelData
            }
        }
    }
}
