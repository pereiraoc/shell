pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData
        // Nexus > Display: barra na direita e visualizador espelhado.
        readonly property bool barRight: Screens.barRight(modelData.name)
        readonly property bool mirrorVisualiser: Screens.mirrorVisualiser(modelData.name)

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Loader {
                id: wallpaper

                asynchronous: true

                anchors.fill: parent
                active: Config.background.wallpaperEnabled

                sourceComponent: Wallpaper {}
            }

            // Wallpaper Prism: logo + feixe + arco-iris reagindo ao audio.
            Loader {
                id: prism

                readonly property bool on: Config.background.wallpaperEnabled && Wallpapers.current.endsWith("caelestia-prism.png")

                anchors.fill: parent
                active: on
                // Espelhado: a luz entra pela direita e o arco-iris sai pela esquerda.
                transform: Scale {
                    origin.x: prism.width / 2
                    xScale: win.mirrorVisualiser ? -1 : 1
                }

                sourceComponent: Prism {
                    reactive: visualiser.visibleOnScreen
                }
            }

            Visualiser {
                id: visualiser

                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
                prismMode: prism.on
                barRight: win.barRight
                mirrored: win.mirrorVisualiser
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled

            readonly property real barGap: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            anchors.margins: Tokens.padding.extraLargeIncreased
            anchors.leftMargin: win.barRight ? Tokens.padding.extraLargeIncreased : barGap
            anchors.rightMargin: win.barRight ? barGap : Tokens.padding.extraLargeIncreased

            state: Config.background.desktopClock.position
            states: [
                State {
                    name: "top-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "top-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "top-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "middle-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "middle-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "middle-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "bottom-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "bottom-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "bottom-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
