pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Ids escondidos (bar.tray.hiddenIcons, ja respeitado pela barra e pelo
    // popout). Os que estao escondidos mas nao rodando tambem aparecem, para
    // poder reexibir.
    readonly property var hidden: GlobalConfig.bar.tray.hiddenIcons
    readonly property var running: SystemTray.items.values
    readonly property var offline: root.hidden.filter(id => !root.running.some(i => i.id === id))

    function setShown(id: string, shown: bool): void {
        const list = [...GlobalConfig.bar.tray.hiddenIcons].filter(x => x !== id);
        if (!shown)
            list.push(id);
        GlobalConfig.bar.tray.hiddenIcons = list;
    }

    title: qsTr("Tray")
    description: qsTr("App icons between the clock and the status icons")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Icons")
        }

        InfoRow {
            first: true
            last: true
            visible: root.running.length === 0 && root.offline.length === 0
            icon: "apps"
            label: qsTr("No app is showing a tray icon right now")
            subtext: qsTr("Spotify, Discord, Steam and similar apps appear here while they run")
        }

        Repeater {
            model: ScriptModel {
                values: root.running
            }

            ConnectedRect {
                id: trayRow

                required property var modelData
                required property int index

                readonly property bool shown: !root.hidden.includes(trayRow.modelData.id)

                Layout.fillWidth: true
                first: trayRow.index === 0
                last: trayRow.index === root.running.length - 1 && root.offline.length === 0
                implicitHeight: trayLayout.implicitHeight + Tokens.padding.small * 2

                StateLayer {
                    onClicked: root.setShown(trayRow.modelData.id, !trayRow.shown)
                }

                RowLayout {
                    id: trayLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    IconImage {
                        implicitSize: Tokens.font.icon.large.pointSize * 1.6
                        source: trayRow.modelData.icon
                        opacity: trayRow.shown ? 1 : 0.4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: trayRow.modelData.title || trayRow.modelData.id
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: trayRow.shown ? qsTr("Shown in the bar") : qsTr("Hidden — still running")
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledSwitch {
                        checked: trayRow.shown
                        onToggled: root.setShown(trayRow.modelData.id, checked)
                    }
                }
            }
        }

        Repeater {
            model: root.offline.length

            ToggleRow {
                // Modelo = quantidade: atualizar o status nao recria a linha
                // (sliders e chips nao voltam do zero). Lista encolhendo: a linha
                // que vai sumir guarda o ultimo item ate ser destruida.
                property var modelData: root.offline[index] ?? ({})
                readonly property var liveItem: root.offline[index]
                onLiveItemChanged: if (liveItem !== undefined) modelData = liveItem
                required property int index

                first: root.running.length === 0 && index === 0
                last: index === root.offline.length - 1
                text: modelData
                subtext: qsTr("Hidden · not running now")
                checked: false
                onToggled: root.setShown(modelData, checked)
            }
        }

        SectionHeader {
            text: qsTr("Appearance")
        }

        ToggleRow {
            first: true
            text: qsTr("Background")
            checked: Config.bar.tray.background
            onToggled: GlobalConfig.bar.tray.background = checked
        }

        ToggleRow {
            text: qsTr("Recolour icons")
            checked: Config.bar.tray.recolour
            onToggled: GlobalConfig.bar.tray.recolour = checked
        }

        ToggleRow {
            text: qsTr("Compact")
            checked: Config.bar.tray.compact
            onToggled: GlobalConfig.bar.tray.compact = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Popout on hover")
            subtext: qsTr("Show the tray menu popout when hovering")
            checked: Config.bar.popouts.tray
            onToggled: GlobalConfig.bar.popouts.tray = checked
        }
    }
}
