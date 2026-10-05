pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import Caelestia.Internal
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper

    // Com o wallpaper Prism o visualizer e o proprio wallpaper (Prism.qml):
    // as barras ficam desligadas para nao desenhar por cima.
    property bool prismMode
    // Barra na direita: folga dela na direita. mirrored: graves do outro lado.
    property bool barRight
    property bool mirrored
    readonly property bool visibleOnScreen: Config.background.visualiser.enabled && (!Config.background.visualiser.autoHide || (Hypr.monitorFor(screen)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))
    readonly property bool shouldBeActive: visibleOnScreen && !prismMode
    property real offset: shouldBeActive ? 0 : screen.height * 0.2

    opacity: shouldBeActive ? 1 : 0

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: root.opacity > 0 && Config.background.visualiser.blur

        sourceComponent: MultiEffect {
            source: root.wallpaper
            maskSource: wrapper
            maskEnabled: true
            blurEnabled: true
            blur: 1
            blurMax: 32
            autoPaddingEnabled: false
        }
    }

    Item {
        id: wrapper

        anchors.fill: parent
        layer.enabled: true

        Loader {
            asynchronous: true
            anchors.fill: parent
            anchors.topMargin: root.offset
            anchors.bottomMargin: -root.offset

            active: root.opacity > 0

            sourceComponent: Item {
                ServiceRef {
                    service: Audio.cava
                }

                VisualiserBars {
                    id: bars

                    anchors.fill: parent
                    anchors.margins: Config.border.thickness
                    readonly property real barGap: (ShellState.componentsFor(root.screen)?.bar?.exclusiveZone ?? 0) + Tokens.spacing.small * Config.background.visualiser.spacing

                    anchors.leftMargin: root.barRight ? Config.border.thickness : barGap
                    anchors.rightMargin: root.barRight ? barGap : Config.border.thickness
                    transform: Scale {
                        origin.x: bars.width / 2
                        xScale: root.mirrored ? -1 : 1
                    }

                    values: Audio.cava.values
                    primaryColor: Qt.alpha(Colours.palette.m3primary, 0.7)
                    secondaryColor: Qt.alpha(Colours.palette.m3inversePrimary, 0.7)
                    rounding: Tokens.rounding.medium * Config.background.visualiser.rounding
                    spacing: Tokens.spacing.extraSmall * Config.background.visualiser.spacing
                    animationDuration: Tokens.anim.durations.normal

                    Behavior on anchors.leftMargin {
                        Anim {}
                    }

                    Behavior on anchors.rightMargin {
                        Anim {}
                    }
                }

                FrameAnimation {
                    running: root.opacity > 0 && !bars.settled
                    onTriggered: bars.advance(frameTime)
                }
            }
        }
    }

    Behavior on offset {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
