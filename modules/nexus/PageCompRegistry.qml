pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.nexus.common
import qs.modules.nexus.pages
import qs.modules.nexus.pages.apps
import qs.modules.nexus.pages.audio
import qs.modules.nexus.pages.bluetooth
import qs.modules.nexus.pages.network
import qs.modules.nexus.pages.panels
import qs.modules.nexus.pages.services
import qs.modules.nexus.pages.software
import qs.modules.nexus.pages.storage
import qs.modules.nexus.pages.wallandstyle
import qs.modules.nexus.pages.panels.taskbar

QtObject {
    id: root

    // id da pagina (PageRegistry) -> componente `<id>Comp`. Por nome, nao por
    // indice: casar por indice quebrava toda vez que a ordem do menu mudava.
    readonly property Component homeComp: Component {
        StackPage {
            Component {
                HomePage {}
            }
        }
    }

    readonly property Component networkComp: Component {
        StackPage {
            Component {
                NetworkPage {}
            }
            Component {
                EthernetDetailPage {}
            }
            Component {
                AddNetworkPage {}
            }
            Component {
                NetworkDetailPage {}
            }
            Component {
                AddVpnPage {}
            }
            Component {
                AllNetworksPage {}
            }
            Component {
                SavedNetworksPage {}
            }
        }
    }

    readonly property Component devicesComp: Component {
        StackPage {
            Component {
                BluetoothPage {}
            }
            Component {
                BtDeviceInfo {}
            }
            Component {
                BluetoothPairing {}
            }
            Component {
                RgbLighting {}
            }
            Component {
                MouseSettings {}
            }
        }
    }

    readonly property Component displayComp: Component {
        StackPage {
            Component {
                DisplayPage {}
            }
        }
    }

    readonly property Component soundComp: Component {
        StackPage {
            Component {
                AudioPage {}
            }
            Component {
                AppVolumes {}
            }
        }
    }

    readonly property Component powerComp: Component {
        StackPage {
            Component {
                PowerPage {}
            }
        }
    }

    readonly property Component systemComp: Component {
        StackPage {
            Component {
                SystemPage {}
            }
        }
    }

    readonly property Component storageComp: Component {
        StackPage {
            Component {
                StoragePage {}
            }
            Component {
                StorageBrowser {}
            }
        }
    }

    readonly property Component securityComp: Component {
        StackPage {
            Component {
                SecurityPage {}
            }
        }
    }

    readonly property Component softwareComp: Component {
        StackPage {
            Component {
                SoftwarePage {}
            }
            Component {
                DerivedPage {}
            }
            Component {
                UntrackedPage {}
            }
            Component {
                RepoIssuesPage {}
            }
            Component {
                UpdatesPage {}
            }
        }
    }

    readonly property Component regionComp: Component {
        StackPage {
            Component {
                LanguageAndRegion {}
            }
        }
    }

    readonly property Component appearanceComp: Component {
        StackPage {
            Component {
                WallpaperAndStyle {}
            }
            Component {
                WallpaperSelect {}
            }
            Component {
                WallpaperCategory {}
            }
            Component {
                ColourSelect {}
            }
        }
    }

    readonly property Component panelsComp: Component {
        StackPage {
            Component {
                PanelsPage {}
            }
            Component {
                DashboardPanel {}
            }
            Component {
                TaskbarPanel {}
            }
            Component {
                LauncherPanel {}
            }
            Component {
                SidebarPanel {}
            }
            Component {
                UtilitiesPanel {}
            }

            // Taskbar component sub-pages
            Component {
                BarWorkspaces {}
            }
            Component {
                BarActiveWindow {}
            }
            Component {
                BarTray {}
            }
            Component {
                BarStatusIcons {}
            }
            Component {
                BarClock {}
            }
        }
    }

    readonly property Component windowsComp: Component {
        StackPage {
            Component {
                WindowManagement {}
            }
        }
    }

    readonly property Component appsComp: Component {
        StackPage {
            Component {
                AppsPage {}
            }
            Component {
                AllApps {}
            }
            Component {
                AppInfo {}
            }
        }
    }

    readonly property Component shellComp: Component {
        StackPage {
            Component {
                ServicesPage {}
            }
            Component {
                NotificationsPage {}
            }
        }
    }

    readonly property Component aboutComp: Component {
        StackPage {
            Component {
                AboutPage {}
            }
        }
    }

    function forId(id: string): Component {
        return root[`${id}Comp`] ?? root.placeholderComp;
    }

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    component PlaceholderComp: Item {
        property NexusState nState // To avoid the warning from non-existent property

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Page under construction")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("This page will be available in a future update.")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }
        }
    }
}
