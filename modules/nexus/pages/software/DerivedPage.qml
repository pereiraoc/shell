pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common

// Derived nao e acusacao, e fila de trabalho. Os tres grupos pedem acoes
// diferentes, por isso aparecem separados em vez de numa lista so.
PageBase {
    id: root

    readonly property var groups: [
        {
            key: "explicit",
            title: qsTr("Explicit"),
            hint: qsTr("Someone asked for these and the repository does not record them. On a clean install they would not come back — either they become a requirement, or they go."),
            icon: "person_alert"
        },
        {
            key: "orphan",
            title: qsTr("Orphaned"),
            hint: qsTr("Installed as a dependency and now depended on by nothing."),
            icon: "delete_sweep"
        },
        {
            key: "dependency",
            title: qsTr("Dependencies of derived"),
            hint: qsTr("These disappear on their own once the cause above is resolved."),
            icon: "layers"
        }
    ]

    title: qsTr("Derived software")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: root.groups

            ColumnLayout {
                id: group

                required property var modelData
                required property int index

                readonly property var items: SoftwareInventory.derived[group.modelData.key] ?? []

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: group.index === 0
                    text: `${group.modelData.title}  ·  ${group.items.length}`
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Tokens.padding.small
                    Layout.bottomMargin: Tokens.spacing.extraSmall
                    text: group.modelData.hint
                    color: Colours.palette.m3outline
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }

                // Nomes de pacote sao curtos; uma linha por pacote gastaria a
                // tela inteira com ate 291 itens. Em fluxo cabem todos e ainda
                // da pra varrer com o olho.
                ConnectedRect {
                    Layout.fillWidth: true
                    first: true
                    last: true
                    implicitHeight: flow.implicitHeight + Tokens.padding.largeIncreased * 2
                    visible: group.items.length > 0

                    Flow {
                        id: flow

                        // Ancorado no TOPO, nunca centralizado: a altura do pai
                        // vem de flow.implicitHeight, entao centralizar faria o
                        // Flow se reposicionar a cada mudanca de altura, o que o
                        // faz relayoutar, o que muda a altura -- polish() loop, a
                        // 50% de CPU e a interface travada.
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.padding.largeIncreased
                        spacing: Tokens.spacing.small

                        Repeater {
                            model: group.items

                            StyledRect {
                                id: chip

                                required property string modelData

                                implicitWidth: chipText.implicitWidth + Tokens.padding.normal * 2
                                implicitHeight: chipText.implicitHeight + Tokens.padding.smaller * 2
                                radius: Tokens.rounding.full
                                color: Colours.tPalette.m3surfaceContainerHigh

                                StyledText {
                                    id: chipText

                                    anchors.centerIn: parent
                                    text: chip.modelData
                                    color: Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.medium
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
