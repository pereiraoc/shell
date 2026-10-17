import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.services
import qs.utils

Item {
    id: root

    readonly property var today: Weather.forecast && Weather.forecast.length > 0 ? Weather.forecast[0] : null

    implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840
    implicitHeight: layout.implicitHeight
    Component.onCompleted: Weather.reload()

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            Layout.fillWidth: true

            Column {
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: Weather.city || Tr.tr("Loading...")
                    font: Tokens.font.body.builders.large.size(28).weight(Font.DemiBold).build()
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: new Date().toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: Tokens.spacing.largeIncreased

                WeatherStat {
                    icon: "wb_twilight"
                    label: Tr.tr("Sunrise")
                    value: Weather.sunrise
                    colour: Colours.palette.m3tertiary
                }

                WeatherStat {
                    icon: "bedtime"
                    label: Tr.tr("Sunset")
                    value: Weather.sunset
                    colour: Colours.palette.m3tertiary
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: bigInfoRow.implicitHeight + Tokens.padding.small

            radius: Tokens.rounding.extraLarge * 2
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: bigInfoRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.largeIncreased

                MaterialIcon {
                    Layout.alignment: Qt.AlignVCenter
                    text: Weather.icon
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(3).build()
                    color: Colours.palette.m3secondary
                    animate: true
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: -Tokens.spacing.small

                    StyledText {
                        text: Weather.temp
                        font: Tokens.font.body.builders.large.size(28 * 2).weight(Font.Medium).build()
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        Layout.leftMargin: Tokens.padding.extraSmall
                        text: Weather.description
                        font: Tokens.font.body.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            DetailCard {
                icon: "water_drop"
                label: Tr.tr("Humidity")
                value: Strings.percent(Weather.humidity)
                colour: Colours.palette.m3secondary
            }
            DetailCard {
                icon: "thermostat"
                label: Tr.trCtx("Feels like", "apparent temperature")
                value: Weather.feelsLike
                colour: Colours.palette.m3primary
            }
            DetailCard {
                icon: "air"
                label: Tr.tr("Wind")
                value: Weather.windSpeed ? Tr.tr("%1 km/h").arg(Weather.windSpeed) : "--"
                colour: Colours.palette.m3tertiary
            }
        }

        // Previsao hora a hora das proximas 24 h (o servico ja baixa o hourly do
        // open-meteo; antes so a tela de lock usava). Rola de lado com a roda.
        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.leftMargin: Tokens.padding.medium
            visible: hourlyList.count > 0
            text: Tr.tr("Next 24 hours")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        StyledListView {
            id: hourlyList

            Layout.fillWidth: true
            implicitHeight: contentItem.childrenRect.height
            visible: count > 0

            orientation: ListView.Horizontal
            spacing: Tokens.spacing.small
            clip: true
            model: Math.min(24, Weather.hourlyForecast.length)

            delegate: StyledRect {
                id: hourItem

                required property int index
                readonly property var cond: Weather.hourlyForecast[index]
                readonly property bool now: index === 0

                implicitWidth: Math.max(hourColumn.implicitWidth + Tokens.padding.medium * 2, 64)
                implicitHeight: hourColumn.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.large
                color: now ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    id: hourColumn

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: hourItem.now ? Tr.trCtx("Now", "forecast column") : Qt.formatDateTime(new Date(hourItem.cond.timestamp.replace("T", " ")), Units.twelveHourClock ? "h A" : "hh:00")
                        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                        color: hourItem.now ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3primary
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: hourItem.cond.icon
                        fontStyle: Tokens.font.icon.large
                        color: hourItem.now ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3secondary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Weather.formatTemp(hourItem.cond.tempC, true)
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                        color: hourItem.now ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3tertiary
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Strings.percent(hourItem.cond.precipChance)
                        font: Tokens.font.body.small
                        opacity: 0.8
                        color: hourItem.now ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.medium
            Layout.leftMargin: Tokens.padding.medium
            visible: forecastRepeater.count > 0
            text: Tr.tr("7-day forecast")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Repeater {
                id: forecastRepeater

                model: Weather.forecast

                StyledRect {
                    id: forecastItem

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: forecastItemColumn.implicitHeight + Tokens.padding.medium * 2

                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainer

                    ColumnLayout {
                        id: forecastItemColumn

                        anchors.centerIn: parent
                        spacing: Tokens.spacing.small

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.index === 0 ? Tr.trCtx("Today", "forecast column") : new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "ddd")
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: Colours.palette.m3primary
                        }

                        StyledText {
                            Layout.topMargin: -Tokens.spacing.extraSmall
                            Layout.alignment: Qt.AlignHCenter
                            text: new Date(forecastItem.modelData.date).toLocaleDateString(Qt.locale(), "MMM d")
                            font: Tokens.font.body.small
                            opacity: 0.7
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: forecastItem.modelData.icon
                            fontStyle: Tokens.font.icon.extraLarge
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                const min = Weather.formatTemp(forecastItem.modelData.minTempC, true);
                                const max = Weather.formatTemp(forecastItem.modelData.maxTempC, true);
                                return Tr.trCtx("%1 / %2", "min/max temperature").arg(min).arg(max);
                            }
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: Colours.palette.m3tertiary
                        }
                    }
                }
            }
        }
    }

    component DetailCard: StyledRect {
        id: detailRoot

        property string icon
        property string label
        property string value
        property color colour

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: detailRoot.icon
                color: detailRoot.colour
                fontStyle: Tokens.font.icon.large
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: detailRoot.label
                    font: Tokens.font.body.small
                    opacity: 0.7
                    horizontalAlignment: Text.AlignLeft
                }
                StyledText {
                    text: detailRoot.value
                    font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }
    }

    component WeatherStat: Row {
        id: weatherStat

        property string icon
        property string label
        property string value
        property color colour

        spacing: Tokens.spacing.small

        MaterialIcon {
            text: weatherStat.icon
            fontStyle: Tokens.font.icon.extraLarge
            color: weatherStat.colour
        }

        Column {
            StyledText {
                text: weatherStat.label
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }
            StyledText {
                text: weatherStat.value
                font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                color: Colours.palette.m3onSurface
            }
        }
    }
}
