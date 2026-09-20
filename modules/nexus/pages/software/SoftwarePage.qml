pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// REQUIREMENT -> DESIGN -> IMPLEMENTATION, empilhados em vez de lado a lado.
//
// O conteudo do Nexus e limitado a Tokens.sizes.nexus.maxContentWidth (800),
// entao tres colunas dariam ~253 px cada e um caminho como
// scripts/stage4/40-hypr-binds-shortcuts.sh viraria reticencias. Empilhado,
// cada camada usa a largura inteira e a cascata continua a mesma: escolher um
// requisito filtra as duas camadas abaixo.
PageBase {
    id: root

    property string selectedId

    readonly property var selectedReq: SoftwareInventory.requirements.find(r => r.id === root.selectedId) ?? null
    readonly property var shownDesign: root.selectedReq ? SoftwareInventory.designFor(root.selectedReq) : SoftwareInventory.design
    readonly property var shownImpl: root.selectedReq ? SoftwareInventory.implFor(root.selectedReq) : SoftwareInventory.implementation

    function statusLabel(s: string): string {
        if (s === "parcial")
            return qsTr("Partial");
        if (s === "pendente")
            return qsTr("Pending");
        return qsTr("Not assessed");
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
            text: qsTr("Required software traces back to a requirement. Derived software does not — it is the list of things to formalise or remove.")
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
            text: qsTr("REQUIREMENT")
        }

        Repeater {
            model: SoftwareInventory.requirements

            RowButton {
                id: reqRow

                required property var modelData
                required property int index

                readonly property bool selected: root.selectedId === reqRow.modelData.id

                first: reqRow.index === 0
                last: reqRow.index === SoftwareInventory.requirements.length - 1
                color: reqRow.selected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
                icon: reqRow.selected ? "radio_button_checked" : "radio_button_unchecked"
                text: `${reqRow.modelData.id}  ${reqRow.modelData.title}`
                subtext: qsTr("%1 · %2 design · %3 implementation").arg(root.statusLabel(reqRow.modelData.status)).arg(reqRow.modelData.design.length).arg(reqRow.modelData.implementation.length)
                onClicked: root.selectedId = reqRow.selected ? "" : reqRow.modelData.id
            }
        }

        SectionHeader {
            text: root.selectedReq ? qsTr("DESIGN — %1").arg(root.selectedReq.id) : qsTr("DESIGN — all")
        }

        ItemList {
            id: designList

            showList: true
            placeholderIcon: "description"
            placeholderText: qsTr("No design document serves this requirement")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...root.shownDesign]
            }

            delegate: InfoRow {
                id: designRow

                required property var modelData
                required property int index

                anchors.left: designList.list.contentItem.left
                anchors.right: designList.list.contentItem.right
                first: designRow.index === 0
                last: designRow.index === root.shownDesign.length - 1
                icon: "description"
                label: `${designRow.modelData.id}  ${designRow.modelData.title}`
                subtext: designRow.modelData.file
                value: designRow.modelData.requirements.join(" ")
            }
        }

        SectionHeader {
            text: root.selectedReq ? qsTr("IMPLEMENTATION — %1").arg(root.selectedReq.id) : qsTr("IMPLEMENTATION — all")
        }

        ItemList {
            id: implList

            showList: true
            placeholderIcon: "folder_off"
            placeholderText: qsTr("No implementation declared")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...root.shownImpl]
            }

            delegate: InfoRow {
                id: implRow

                required property var modelData
                required property int index

                anchors.left: implList.list.contentItem.left
                anchors.right: implList.list.contentItem.right
                first: implRow.index === 0
                last: implRow.index === root.shownImpl.length - 1
                icon: implRow.modelData.stub ? "warning" : (implRow.modelData.kind === "dir" ? "folder" : "terminal")
                iconColour: implRow.modelData.stub ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                label: implRow.modelData.path
                subtext: implRow.modelData.stub ? qsTr("Stub — declared but does nothing") : implRow.modelData.requirements.join(" ")
                value: implRow.modelData.packages.length > 0 ? qsTr("%1 pkg").arg(implRow.modelData.packages.length) : ""
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
            subtext: qsTr("%1 broken edges · %2 stubs · %3 unused design").arg(SoftwareInventory.broken.length).arg(SoftwareInventory.stubs.length).arg(SoftwareInventory.unusedDesign.length)
            onClicked: root.nState.openSubPage(3)
        }
    }
}
