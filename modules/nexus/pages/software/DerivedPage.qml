pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Derived nao e acusacao, e fila de trabalho. Os tres grupos pedem acoes
// diferentes, por isso aparecem separados em vez de numa lista so.
//
// NAO usar Flow aqui. A versao em chips travava a interface: a altura do Flow
// depende da largura (ele quebra linha) e o pai tirava a altura dele, o que
// fecha um ciclo de layout -- "Flow called polish() inside updatePolish()",
// a 50% de CPU. Ancorar no topo nao resolve, porque a volta e' pela LARGURA,
// nao pela posicao. ItemList com delegate de linha nao tem essa realimentacao
// e e' o padrao ja usado nas outras paginas.
PageBase {
    id: root

    // O grupo de dependencias tem ~291 itens e e' o menos acionavel (some
    // sozinho quando a causa sair), entao comeca fechado: sem isso sao 400
    // delegates criados de uma vez so para abrir a pagina.
    property bool showDependencies: false

    readonly property var sizes: SoftwareInventory.trace.derived_sizes ?? ({})

    // Maior primeiro: remover `cuda` (4,8 GiB) e remover `nopt` sao decisoes
    // de peso bem diferente.
    function bySize(key: string): var {
        const items = SoftwareInventory.derived[key] ?? [];
        return [...items].sort((a, b) => (root.sizes[b] ?? 0) - (root.sizes[a] ?? 0));
    }

    function fmtSize(bytes: int): string {
        if (!bytes)
            return "";
        if (bytes >= 1048576)
            return `${(bytes / 1048576).toFixed(1)} MiB`;
        return `${Math.round(bytes / 1024)} KiB`;
    }

    function groupTotal(key: string): int {
        return (SoftwareInventory.derived[key] ?? []).reduce((acc, p) => acc + (root.sizes[p] ?? 0), 0);
    }

    title: qsTr("Derived software")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("EXPLICIT  ·  %1  ·  %2").arg(root.bySize("explicit").length).arg(root.fmtSize(root.groupTotal("explicit")))
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("Someone asked for these and the repository does not record them. On a clean install they would not come back — either they become a requirement, or they go.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: explicitList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("Nothing unexplained")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: root.bySize("explicit")
            }

            delegate: InfoRow {
                id: explicitRow

                required property string modelData
                required property int index

                anchors.left: explicitList.list.contentItem.left
                anchors.right: explicitList.list.contentItem.right
                first: explicitRow.index === 0
                last: explicitRow.index === explicitList.list.count - 1
                icon: "person_alert"
                label: explicitRow.modelData
                value: root.fmtSize(root.sizes[explicitRow.modelData] ?? 0)
            }
        }

        SectionHeader {
            text: qsTr("ORPHANED  ·  %1  ·  %2").arg(root.bySize("orphan").length).arg(root.fmtSize(root.groupTotal("orphan")))
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("Installed as a dependency and now depended on by nothing.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        ItemList {
            id: orphanList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("No orphans")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: root.bySize("orphan")
            }

            delegate: InfoRow {
                id: orphanRow

                required property string modelData
                required property int index

                anchors.left: orphanList.list.contentItem.left
                anchors.right: orphanList.list.contentItem.right
                first: orphanRow.index === 0
                last: orphanRow.index === orphanList.list.count - 1
                icon: "delete_sweep"
                label: orphanRow.modelData
                value: root.fmtSize(root.sizes[orphanRow.modelData] ?? 0)
            }
        }

        SectionHeader {
            text: qsTr("DEPENDENCIES OF DERIVED  ·  %1  ·  %2").arg(root.bySize("dependency").length).arg(root.fmtSize(root.groupTotal("dependency")))
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: qsTr("These disappear on their own once the cause above is resolved. Nothing to decide here.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        RowButton {
            Layout.fillWidth: true
            first: true
            last: !root.showDependencies
            icon: root.showDependencies ? "expand_more" : "chevron_right"
            text: root.showDependencies ? qsTr("Hide the list") : qsTr("Show %1 packages").arg(root.bySize("dependency").length)
            trailingIcon: ""
            onClicked: root.showDependencies = !root.showDependencies
        }

        ItemList {
            id: depList

            visible: root.showDependencies
            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("None")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: root.showDependencies ? root.bySize("dependency") : []
            }

            delegate: InfoRow {
                id: depRow

                required property string modelData
                required property int index

                anchors.left: depList.list.contentItem.left
                anchors.right: depList.list.contentItem.right
                first: depRow.index === 0
                last: depRow.index === depList.list.count - 1
                icon: "layers"
                label: depRow.modelData
                value: root.fmtSize(root.sizes[depRow.modelData] ?? 0)
            }
        }
    }
}
