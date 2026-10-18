import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (there must be one for each value of the TemperatureUnit enum)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: TemperatureUnit.Auto
        },
        MenuItem {
            text: Tr.tr("°C")
            value: TemperatureUnit.Celsius
        },
        MenuItem {
            text: Tr.tr("°F")
            value: TemperatureUnit.Fahrenheit
        },
        MenuItem {
            text: Tr.tr("K")
            value: TemperatureUnit.Kelvin
        }
    ]

    // Data size units (there must be one for each value of the DataUnit enum)
    readonly property list<MenuItem> dataItems: [
        MenuItem {
            text: Tr.tr("Binary (KiB, MiB)")
            value: DataUnit.Binary
        },
        MenuItem {
            text: Tr.tr("Decimal (KB, MB)")
            value: DataUnit.Decimal
        }
    ]

    // Clock formats (there must be one for each value of the ClockFormat enum)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: Tr.tr("Auto")
            value: ClockFormat.Auto
        },
        MenuItem {
            text: Tr.tr("12-hour")
            value: ClockFormat.TwelveHour
        },
        MenuItem {
            text: Tr.tr("24-hour")
            value: ClockFormat.TwentyFourHour
        }
    ]

    readonly property var region: regionBridge.info

    title: qsTr("Language & region")
    description: qsTr("Time zone, language, weather and units")
    tabs: [
        { id: "language", label: Tr.tr("Language") },
        { id: "region", label: Tr.tr("Region") },
        { id: "time", label: Tr.tr("Time & date") }
    ]

    // Fuso, NTP, locale e keymap pelo caelestia-region (timedatectl/localectl;
    // mudar fuso/NTP pede senha pelo polkit do proprio systemd).
    ToolBridge {
        id: regionBridge

        tool: "region"
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        TabPane {
            active: root.tab === "language"

            // Language
            SectionHeader {
                first: true
                text: Tr.tr("Language")
            }

            SelectRow {
                first: true
                last: !root.region.locale
                implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

                menuItems: [autoLang, ...langItems.instances]

                MenuItem {
                    id: autoLang

                    text: Tr.tr("Auto")
                }

                Variants {
                    id: langItems

                    model: Tr.supportedLanguages

                    MenuItem {
                        required property string modelData

                        text: {
                            const locale = Qt.locale(modelData);
                            return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                        }
                    }
                }
            }

            InfoRow {
                visible: !!root.region.locale
                last: true
                icon: "keyboard"
                label: qsTr("System locale %1 · console keyboard %2").arg(root.region.locale ?? "").arg(root.region.keymap_console ?? "")
                subtext: qsTr("Changing these needs a terminal (localectl) and a new session. Keyboard layout for apps is in Devices.")
            }
        }

        TabPane {
            active: root.tab === "region"

            // Weather
            SectionHeader {
                first: true
                text: Tr.tr("Weather")
            }

            // Placeholder until the map-based location picker lands
            ConnectedRect {
                Layout.fillWidth: true
                first: true
                last: true
                implicitHeight: comingSoon.implicitHeight + Tokens.padding.extraLarge * 2

                ColumnLayout {
                    id: comingSoon

                    anchors.centerIn: parent
                    width: parent.width - Tokens.padding.largeIncreased * 2
                    spacing: Tokens.padding.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "map"
                        color: Colours.palette.m3outlineVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Location picker coming soon")
                        color: Colours.palette.m3outlineVariant
                        font: Tokens.font.title.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: Tr.tr("Choose your weather location on a map in a future update")
                        color: Colours.palette.m3outlineVariant
                        font: Tokens.font.body.small
                    }
                }
            }

            // Units
            SectionHeader {
                text: Tr.tr("Units")
            }

            SelectRow {
                first: true
                label: Tr.tr("Temperature")
                subtext: Tr.tr("Units for weather temperatures")
                menuItems: root.tempItems
                active: root.tempItems.find(i => i.value === GlobalConfig.services.weatherUnits)
                onSelected: item => GlobalConfig.services.weatherUnits = item.value
            }

            SelectRow {
                label: Tr.tr("System temperatures")
                subtext: Tr.tr("Units for CPU and GPU temperatures")
                menuItems: root.tempItems
                active: root.tempItems.find(i => i.value === GlobalConfig.services.sensorUnits)
                onSelected: item => GlobalConfig.services.sensorUnits = item.value
            }

            SelectRow {
                last: true
                label: Tr.tr("Data sizes")
                subtext: Tr.tr("Units for data sizes and network speeds")
                menuItems: root.dataItems
                active: root.dataItems.find(i => i.value === GlobalConfig.services.dataUnits)
                onSelected: item => GlobalConfig.services.dataUnits = item.value
            }
        }

        TabPane {
            active: root.tab === "time"

            // Time & date
            SectionHeader {
                first: true
                text: Tr.tr("Time & date")
            }

            ExpandSelectRow {
                first: true
                icon: "schedule"
                label: qsTr("Time zone")
                subtext: qsTr("Asks for your password")
                filterable: true
                options: (root.region.timezones ?? []).map(z => ({ value: z, label: z.replace(/_/g, " ") }))
                current: root.region.timezone ?? ""
                busy: regionBridge.busyAction.startsWith("timezone-")
                onPicked: v => regionBridge.run({ id: `timezone-${v}` })
            }

            ToggleRow {
                text: qsTr("Set time automatically")
                subtext: root.region.ntp ? (root.region.synced ? qsTr("Synchronized with network time") : qsTr("Waiting for network time…")) : qsTr("The clock is not corrected automatically")
                checked: !!root.region.ntp
                disabled: regionBridge.busyAction !== "" || root.region.ntp === undefined
                onToggled: regionBridge.run({ id: checked ? "ntp-on" : "ntp-off" })
            }

            SelectRow {
                last: true
                label: Tr.tr("Clock format")
                subtext: Tr.tr("How times are shown across the shell")
                menuItems: root.clockItems
                active: root.clockItems.find(i => i.value === GlobalConfig.services.clockFormat)
                onSelected: item => GlobalConfig.services.clockFormat = item.value
            }

            ActionErrorRow {
                bridge: regionBridge
            }
        }
    }
}
