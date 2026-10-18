pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

// Previsao hora a hora das proximas 24 h, no estilo do Climatempo: grafico (curva
// suave com preenchimento, icone e valor em cada ponto) ou lista de cartoes.
// Abas Temperatura / Chuva / Vento / Umidade no modo grafico.
ColumnLayout {
    id: root

    property string metric: "temp"
    property bool chartView: true

    readonly property var hours: Weather.hourlyForecast.slice(0, 24)
    // Rotulos (icone + valor) a cada 2 h, como no Climatempo; a curva usa todas as horas
    readonly property int labelEvery: 2

    readonly property var metrics: [
        {
            key: "temp",
            icon: "device_thermostat",
            label: Tr.tr("Temperature")
        },
        {
            key: "rain",
            icon: "rainy",
            label: Tr.tr("Rain")
        },
        {
            key: "wind",
            icon: "air",
            label: Tr.tr("Wind")
        },
        {
            key: "humidity",
            icon: "humidity_percentage",
            label: Tr.tr("Humidity")
        }
    ]

    readonly property color lineColour: {
        if (metric === "rain" || metric === "humidity")
            return Colours.palette.m3primary;
        if (metric === "wind")
            return Colours.palette.m3secondary;
        return Colours.palette.m3tertiary;
    }

    // Chuva = chance (%) por hora: quase sempre ha chance e quase nunca ha mm
    // previstos -- em mm o grafico ficava vazio com o eixo 0-2. Os mm entram no
    // rotulo e escurecem a barra.
    function valueOf(h: var): real {
        if (metric === "rain")
            return h.precipChance;
        if (metric === "wind")
            return h.windSpeed;
        if (metric === "humidity")
            return h.humidity;
        return Units.toTemperature(h.tempC, GlobalConfig.services.weatherUnits);
    }

    function labelOf(h: var): string {
        if (metric === "rain")
            return Strings.percent(h.precipChance) + (h.precipMm > 0 ? ` · ${Number(h.precipMm.toFixed(1))} mm` : "");
        if (metric === "wind")
            return `${h.windSpeed} km/h`;
        if (metric === "humidity")
            return Strings.percent(h.humidity);
        return Weather.formatTemp(h.tempC, true);
    }

    function hourText(h: var, index: int): string {
        if (index === 0)
            return Tr.trCtx("Now", "forecast column");
        return Qt.formatDateTime(new Date(h.timestamp.replace("T", " ")), Units.twelveHourClock ? "h A" : "hh:00");
    }

    // Rosa dos ventos de 16 pontos a partir da direcao (de onde o vento vem)
    function compass(deg: real): string {
        const names = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        return names[Math.round(((deg % 360) + 360) % 360 / 22.5) % 16];
    }

    spacing: Tokens.spacing.small
    visible: hours.length > 0

    // Cabecalho: titulo + alternar grafico/lista
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.medium

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Hourly forecast")
            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
            color: Colours.palette.m3onSurface
        }

        IconTextButton {
            icon: "show_chart"
            text: Tr.tr("Chart")
            checked: root.chartView
            type: checked ? IconTextButton.Filled : IconTextButton.Text
            onClicked: root.chartView = true
        }

        IconTextButton {
            icon: "view_list"
            text: Tr.tr("List")
            checked: !root.chartView
            type: checked ? IconTextButton.Filled : IconTextButton.Text
            onClicked: root.chartView = false
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: root.chartView ? chartColumn.implicitHeight + Tokens.padding.large * 2 : list.implicitHeight + Tokens.padding.medium * 2

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        clip: true

        // ---------------- Grafico ----------------
        ColumnLayout {
            id: chartColumn

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            visible: root.chartView
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.metrics

                    IconTextButton {
                        required property var modelData

                        icon: modelData.icon
                        text: modelData.label
                        checked: root.metric === modelData.key
                        type: checked ? IconTextButton.Filled : IconTextButton.Text
                        onClicked: root.metric = modelData.key
                    }
                }
            }

            Item {
                id: chart

                // Faixas verticais: ícone em cima do ponto, valor embaixo, horas no rodape
                readonly property real axisWidth: root.metric === "rain" ? 40 : 32
                readonly property real iconSpace: 34
                readonly property real labelSpace: 26
                readonly property real hourSpace: 22
                readonly property real plotLeft: axisWidth
                readonly property real plotWidth: Math.max(1, width - axisWidth)
                readonly property real plotTop: iconSpace
                readonly property real plotBottom: height - hourSpace - labelSpace
                readonly property real step: plotWidth / Math.max(1, root.hours.length)

                readonly property var values: root.hours.map(h => root.valueOf(h))
                readonly property real minV: {
                    if (root.metric === "rain" || values.length === 0)
                        return 0;
                    return Math.min(...values);
                }
                readonly property real maxV: {
                    if (values.length === 0)
                        return 1;
                    return Math.max(...values);
                }
                // Folga em cima/embaixo para a curva nao encostar nos rotulos;
                // chuva e uma chance: eixo fixo 0-100 %
                readonly property real lo: root.metric === "rain" ? 0 : Math.floor(minV - Math.max(1, (maxV - minV) * 0.25))
                readonly property real hi: root.metric === "rain" ? 100 : Math.ceil(maxV + Math.max(1, (maxV - minV) * 0.25))

                function xAt(i: int): real {
                    return plotLeft + step * (i + 0.5);
                }

                function yAt(v: real): real {
                    return plotBottom - (v - lo) / Math.max(0.001, hi - lo) * (plotBottom - plotTop);
                }

                Layout.fillWidth: true
                implicitHeight: 230

                onValuesChanged: canvas.requestPaint()
                onWidthChanged: canvas.requestPaint()
                onHeightChanged: canvas.requestPaint()

                // Eixo Y: maximo, meio e minimo
                Repeater {
                    model: 3

                    StyledText {
                        required property int index

                        readonly property real v: chart.hi - (chart.hi - chart.lo) * index / 2

                        x: 0
                        y: chart.yAt(v) - height / 2
                        width: chart.axisWidth - Tokens.spacing.small
                        horizontalAlignment: Text.AlignRight
                        text: root.metric === "rain" ? `${Math.round(v)}%` : Math.round(v)
                        font: Tokens.font.body.small
                        color: Colours.palette.m3onSurfaceVariant
                        opacity: 0.7
                    }
                }

                Canvas {
                    id: canvas

                    readonly property color colour: root.lineColour

                    function css(c: color, a: real): string {
                        return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a})`;
                    }

                    anchors.fill: parent
                    onColourChanged: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const vals = chart.values;
                        const n = vals.length;
                        if (n === 0)
                            return;

                        // Linha de base suave
                        ctx.strokeStyle = css(Colours.palette.m3outlineVariant, 0.5);
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.moveTo(chart.plotLeft, chart.plotBottom + 0.5);
                        ctx.lineTo(chart.width, chart.plotBottom + 0.5);
                        ctx.stroke();

                        if (root.metric === "rain") {
                            // Chance de chuva em barras; com mm previstos a barra fica cheia
                            const bw = Math.max(3, chart.step * 0.5);
                            for (let i = 0; i < n; i++) {
                                const y = chart.yAt(vals[i]);
                                const h = chart.plotBottom - y;
                                ctx.fillStyle = css(colour, (root.hours[i]?.precipMm ?? 0) > 0 ? 0.95 : 0.55);
                                if (h > 0.5)
                                    ctx.fillRect(chart.xAt(i) - bw / 2, y, bw, h);
                            }
                            return;
                        }

                        // Curva suave: bezier com controles no meio de cada trecho (sem
                        // ultrapassar os pontos, como uma curva monotona)
                        const path = () => {
                            ctx.moveTo(chart.plotLeft, chart.yAt(vals[0]));
                            ctx.lineTo(chart.xAt(0), chart.yAt(vals[0]));
                            for (let i = 1; i < n; i++) {
                                const x0 = chart.xAt(i - 1), y0 = chart.yAt(vals[i - 1]);
                                const x1 = chart.xAt(i), y1 = chart.yAt(vals[i]);
                                const mx = (x0 + x1) / 2;
                                ctx.bezierCurveTo(mx, y0, mx, y1, x1, y1);
                            }
                            ctx.lineTo(chart.width, chart.yAt(vals[n - 1]));
                        };

                        // Preenchimento em degrade sob a curva
                        const grad = ctx.createLinearGradient(0, chart.plotTop, 0, chart.plotBottom);
                        grad.addColorStop(0, css(colour, 0.28));
                        grad.addColorStop(1, css(colour, 0));
                        ctx.beginPath();
                        path();
                        ctx.lineTo(chart.width, chart.plotBottom);
                        ctx.lineTo(chart.plotLeft, chart.plotBottom);
                        ctx.closePath();
                        ctx.fillStyle = grad;
                        ctx.fill();

                        ctx.beginPath();
                        path();
                        ctx.strokeStyle = css(colour, 1);
                        ctx.lineWidth = 2.5;
                        ctx.lineJoin = "round";
                        ctx.stroke();
                    }
                }

                // Ponto "Agora"
                Rectangle {
                    visible: root.metric !== "rain" && chart.values.length > 0
                    x: chart.xAt(0) - width / 2
                    y: chart.yAt(chart.values[0] ?? 0) - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: width / 2
                    color: Colours.palette.m3surfaceContainer
                    border.width: 2.5
                    border.color: root.lineColour
                }

                // Icone em cima e valor embaixo de cada ponto (a cada 2 h) + hora no rodape
                Repeater {
                    model: root.hours.length

                    Item {
                        id: point

                        required property int index
                        readonly property var hour: root.hours[index]
                        readonly property bool labelled: index % root.labelEvery === 0
                        readonly property real px: chart.xAt(index)
                        readonly property real py: root.metric === "rain" ? chart.plotBottom : chart.yAt(chart.values[index] ?? 0)

                        anchors.fill: parent
                        visible: labelled

                        MaterialIcon {
                            x: point.px - width / 2
                            y: Math.max(0, (root.metric === "rain" ? chart.yAt(chart.values[point.index] ?? 0) : point.py) - height - Tokens.spacing.small)
                            text: point.hour.icon
                            fontStyle: Tokens.font.icon.medium
                            color: Colours.palette.m3secondary
                        }

                        StyledText {
                            x: point.px - width / 2
                            y: point.py + Tokens.spacing.small
                            text: root.labelOf(point.hour)
                            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
                            color: root.lineColour
                        }

                        StyledText {
                            x: point.px - width / 2
                            y: chart.height - height
                            text: root.hourText(point.hour, point.index)
                            font: Tokens.font.body.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }
            }
        }

        // ---------------- Lista ----------------
        StyledListView {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.medium
            implicitHeight: contentItem.childrenRect.height
            visible: !root.chartView

            // Todos os cartoes com a largura do conteudo mais largo (antes era fixa em
            // 132 px e "0.0 mm · 87%" / "WSW · 13 km/h" vazavam para o cartao vizinho)
            property real cardWidth: 0

            orientation: ListView.Horizontal
            spacing: Tokens.spacing.small
            clip: true
            model: root.hours.length

            delegate: StyledRect {
                id: card

                required property int index
                readonly property var hour: root.hours[index]
                readonly property real naturalWidth: cardColumn.implicitWidth + Tokens.padding.medium * 2

                implicitWidth: Math.max(list.cardWidth, naturalWidth)
                implicitHeight: cardColumn.implicitHeight + Tokens.padding.medium * 2
                onNaturalWidthChanged: list.cardWidth = Math.max(list.cardWidth, naturalWidth)
                Component.onCompleted: list.cardWidth = Math.max(list.cardWidth, naturalWidth)

                radius: Tokens.rounding.medium
                color: index === 0 ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                readonly property color fg: index === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                readonly property color fgDim: index === 0 ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant

                // Sem ancorar a direita: a largura vem do conteudo (implicitWidth)
                ColumnLayout {
                    id: cardColumn

                    x: Tokens.padding.medium
                    y: Tokens.padding.medium
                    width: card.width - Tokens.padding.medium * 2
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: root.hourText(card.hour, card.index)
                        font: Tokens.font.body.small
                        color: card.fgDim
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: Weather.formatTemp(card.hour.tempC, true)
                            font: Tokens.font.title.large
                            color: card.fg
                        }

                        MaterialIcon {
                            text: card.hour.icon
                            fontStyle: Tokens.font.icon.large
                            color: card.index === 0 ? card.fg : Colours.palette.m3secondary
                        }
                    }

                    ListStat {
                        icon: "humidity_percentage"
                        text: Strings.percent(card.hour.humidity)
                        colour: card.fgDim
                    }

                    ListStat {
                        icon: "rainy"
                        text: `${Number(card.hour.precipMm.toFixed(1))} mm · ${Strings.percent(card.hour.precipChance)}`
                        colour: card.fgDim
                    }

                    ListStat {
                        icon: "arrow_downward"
                        // A seta aponta para onde o vento vai (a direcao e de onde vem)
                        iconRotation: card.hour.windDirection
                        text: `${root.compass(card.hour.windDirection)} · ${card.hour.windSpeed} km/h`
                        colour: card.fgDim
                    }
                }
            }
        }
    }

    component ListStat: RowLayout {
        id: stat

        property string icon
        property string text
        property real iconRotation
        property color colour

        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            text: stat.icon
            rotation: stat.iconRotation
            fontStyle: Tokens.font.icon.small
            color: stat.colour
        }

        StyledText {
            text: stat.text
            font: Tokens.font.body.small
            color: stat.colour
        }
    }
}
