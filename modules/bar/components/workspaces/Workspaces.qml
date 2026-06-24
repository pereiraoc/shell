pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// US-012 — raiz é um ColumnLayout (NÃO-clipping): os 3 dots de grupo ficam ACIMA do pill
// arredondado (que continua com clipping só nos bubbles). Assim os dots não são cortados.
ColumnLayout {
    id: root

    required property ShellScreen screen
    required property bool fullscreen

    readonly property bool onSpecial: (GlobalConfig.bar.workspaces.perMonitorWorkspaces ? Hypr.monitorFor(screen) : Hypr.focusedMonitor)?.lastIpcObject.specialWorkspace?.name !== ""
    readonly property int activeWsId: GlobalConfig.bar.workspaces.perMonitorWorkspaces ? (Hypr.monitorFor(screen).activeWorkspace?.id ?? 1) : Hypr.activeWsId

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }
    readonly property int groupOffset: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) * Config.bar.workspaces.shown
    // US-012 — qual dos 3 grupos do monitor está ativo (vale enquanto shown == subgrupos == 3).
    readonly property int activeGroupIdx: Math.floor((activeWsId - 1) / Config.bar.workspaces.shown) % 3

    spacing: Tokens.spacing.small

    GroupCycleIndicator {
        Layout.alignment: Qt.AlignHCenter
        visible: !root.fullscreen && !root.onSpecial
        groupCount: 3
        activeGroupIdx: root.activeGroupIdx
    }

    StyledClippingRect {
        id: pill

        property real blur: root.onSpecial ? 1 : 0

        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Tokens.sizes.bar.innerWidth
        implicitHeight: layout.implicitHeight + Tokens.padding.small

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        Item {
            anchors.fill: parent
            scale: root.onSpecial ? 0.8 : 1
            opacity: root.onSpecial ? 0.5 : 1
            visible: !root.fullscreen

            layer.enabled: pill.blur > 0
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: pill.blur
                blurMax: 32
            }

            Loader {
                asynchronous: true
                active: Config.bar.workspaces.occupiedBg

                anchors.fill: parent
                anchors.margins: Tokens.padding.extraSmall

                sourceComponent: OccupiedBg {
                    workspaces: workspaces
                    occupied: root.occupied
                    groupOffset: root.groupOffset
                }
            }

            ColumnLayout {
                id: layout

                anchors.centerIn: parent
                spacing: Math.floor(Tokens.spacing.extraSmall)

                Repeater {
                    id: workspaces

                    model: Config.bar.workspaces.shown

                    Workspace {
                        activeWsId: root.activeWsId
                        occupied: root.occupied
                        groupOffset: root.groupOffset
                    }
                }
            }

            Loader {
                asynchronous: true
                anchors.horizontalCenter: parent.horizontalCenter
                active: Config.bar.workspaces.activeIndicator

                sourceComponent: ActiveIndicator {
                    activeWsId: root.activeWsId
                    workspaces: workspaces
                    mask: layout
                    fullscreen: root.fullscreen
                }
            }

            MouseArea {
                anchors.fill: layout
                onClicked: event => {
                    const ws = (layout.childAt(event.x, event.y) as Workspace)?.ws;
                    if (!ws)
                        return;
                    if (Hypr.activeWsId !== ws)
                        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
                    else
                        Hypr.dispatch(Hypr.usingLua ? 'hl.dsp.workspace.toggle_special("special")' : "togglespecialworkspace special");
                }
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Loader {
            id: specialWs

            asynchronous: true

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall

            active: opacity > 0

            scale: root.onSpecial ? 1 : 0.5
            opacity: root.onSpecial ? 1 : 0

            sourceComponent: SpecialWorkspaces {
                screen: root.screen
            }

            Behavior on scale {
                Anim {}
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        Behavior on blur {
            Anim {
                type: Anim.StandardSmall
            }
        }
    }
}
