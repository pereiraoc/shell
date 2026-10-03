pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// O que esta desatualizado, por fonte, e o botao que abre o aplicador num
// terminal. A pagina so le: a lista vem de ~/.cache/caelestia/updates.json,
// gravado pelo timer, pelo "Check now" ou pelo proprio caelestia-update ao
// terminar.
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
        }
    ]

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
            text: qsTr("Checked every 6 hours in the background; a notification appears only when the pending list changes. Updating opens a terminal: official repositories first, then AUR, then Flatpak, and it tells you afterwards whether a reboot or a plugin rebuild is needed.")
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
            value: SoftwareInventory.updatesFetched ? qsTr("%1 · %2 · %3").arg((SoftwareInventory.updates.repo ?? []).length).arg((SoftwareInventory.updates.aur ?? []).length).arg((SoftwareInventory.updates.flatpak ?? []).length) : ""
        }

        RowButton {
            icon: "refresh"
            text: qsTr("Check now")
            subtext: qsTr("Asks the repositories, AUR and Flathub — takes a few seconds")
            disabled: SoftwareInventory.loadingUpdates
            onClicked: SoftwareInventory.fetchUpdates()
        }

        RowButton {
            last: true
            icon: "terminal"
            text: qsTr("Update everything")
            subtext: qsTr("Opens a terminal running caelestia-update (asks for sudo)")
            trailingIcon: "open_in_new"
            onClicked: SoftwareInventory.runUpdate()
        }

        Repeater {
            model: root.sources

            ColumnLayout {
                id: section

                required property var modelData

                readonly property var items: SoftwareInventory.updates[section.modelData.key] ?? []
                readonly property string problem: root.sourceState(section.modelData.key)

                Layout.fillWidth: true
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
                        subtext: row.modelData.from ? `${row.modelData.from}  →  ${row.modelData.to}` : row.modelData.to
                    }
                }
            }
        }
    }
}
