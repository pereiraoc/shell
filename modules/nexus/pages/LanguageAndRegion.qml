import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.misc
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24-hour")
        },
        MenuItem {
            text: qsTr("12-hour")
        }
    ]

    readonly property var region: regionBridge.info

    title: qsTr("Language & region")
    description: qsTr("Time zone, language, weather and units")

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

        // Language
        SectionHeader {
            first: true
            text: qsTr("Language")
        }

        // Read-only: the shell follows the system locale (no in-shell translations yet)
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: !root.region.locale
            implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

            RowLayout {
                id: localeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("System language")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Follows your system locale (%1)").arg(Qt.locale().name)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    text: Qt.locale().nativeLanguageName || Qt.locale().name
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
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

        // Weather
        SectionHeader {
            text: qsTr("Weather")
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
                    text: qsTr("Location picker coming soon")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: qsTr("Choose your weather location on a map in a future update")
                    color: Colours.palette.m3outlineVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Units
        SectionHeader {
            text: qsTr("Units")
        }

        SelectRow {
            first: true
            label: qsTr("Temperature")
            subtext: qsTr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheit = root.tempItems.indexOf(item) === 1
        }

        SelectRow {
            last: true
            label: qsTr("System temperatures")
            subtext: qsTr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems[GlobalConfig.services.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => GlobalConfig.services.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1
        }

        // Time & date
        SectionHeader {
            text: qsTr("Time & date")
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
            label: qsTr("Clock format")
            subtext: qsTr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems[GlobalConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => GlobalConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }

        ActionErrorRow {
            bridge: regionBridge
        }
    }
}
