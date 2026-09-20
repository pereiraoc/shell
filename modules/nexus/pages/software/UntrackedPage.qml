pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Arquivos que nenhum pacote reivindica. Inclui os dois mais sensiveis do
// sistema -- gpu-mode-persist, com regra NOPASSWD no sudoers, e pam-pin-auth,
// que participa da autenticacao -- e nenhuma ferramenta de pacote os enxerga.
PageBase {
    id: root

    readonly property var leftovers: SoftwareInventory.untracked.filter(u => u.leftover)
    readonly property var rest: SoftwareInventory.untracked.filter(u => !u.leftover)

    title: qsTr("Untracked files")
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
            text: qsTr("Files in the watched directories that no package claims. Edit the watched list in ~/.config/caelestia/software-inventory.json.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.WordWrap
        }

        SectionHeader {
            first: true
            text: qsTr("BUILD AND EDIT LEFTOVERS  ·  %1").arg(root.leftovers.length)
        }

        ItemList {
            id: leftoverList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("No leftovers")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...root.leftovers]
            }

            delegate: InfoRow {
                id: leftoverRow

                required property var modelData
                required property int index

                anchors.left: leftoverList.list.contentItem.left
                anchors.right: leftoverList.list.contentItem.right
                first: leftoverRow.index === 0
                last: leftoverRow.index === root.leftovers.length - 1
                icon: "delete_sweep"
                iconColour: Colours.palette.m3error
                label: leftoverRow.modelData.path
                subtext: leftoverRow.modelData.dir
            }
        }

        SectionHeader {
            text: qsTr("EVERYTHING ELSE  ·  %1").arg(root.rest.length)
        }

        ItemList {
            id: restList

            showList: true
            placeholderIcon: "check_circle"
            placeholderText: qsTr("Nothing untracked")
            list.spacing: Tokens.spacing.extraSmall / 2

            model: ScriptModel {
                values: [...root.rest]
            }

            delegate: InfoRow {
                id: restRow

                required property var modelData
                required property int index

                anchors.left: restList.list.contentItem.left
                anchors.right: restList.list.contentItem.right
                first: restRow.index === 0
                last: restRow.index === root.rest.length - 1
                icon: restRow.modelData.kind === "dir" ? "folder" : "description"
                label: restRow.modelData.path
                subtext: restRow.modelData.dir
            }
        }
    }
}
