pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

// Bateria de cada aparelho conectado, um abaixo do outro.
//
// UPower e a fonte principal: cobre o notebook, os aparelhos Bluetooth (ja com
// o apelido definido no BlueZ) e o controle quando conectado, e traz o tipo do
// aparelho no enum UPowerDeviceType -- que e o que permite ordenar e escolher
// o simbolo. Perifericos com dongle proprietario de 2.4 GHz nao aparecem nele;
// esses vem do caelestia-peripheral-battery, que le o sysfs do driver.
//
// Aparelho que nao reporta bateria simplesmente nao entra na lista -- nada de
// linha vazia ou "desconhecido". O mouse Razer e o Xbox Controller, por
// exemplo, nao publicam nivel nenhum mesmo conectados.
ColumnLayout {
    id: root

    property var extras: []

    readonly property var entries: {
        const out = [];

        const laptop = UPower.displayDevice;
        if (laptop?.isLaptopBattery)
            out.push({
                order: 0,
                icon: "laptop",
                name: qsTr("Laptop"),
                pct: laptop.percentage,
                charging: !UPower.onBattery,
                // Sub-linha so do notebook: os perifericos nao estimam tempo.
                //
                // Nada e' mostrado quando ja esta cheio: nao ha tempo restante
                // que faca sentido, e antes aparecia um "carreg..." elidido no
                // lugar do valor. O estimador tambem devolve 0 nesse caso.
                subIcon: UPower.onBattery ? "schedule" : "bolt",
                subLabel: root.timeLabel(laptop),
                subValue: root.timeValue(laptop)
            });

        for (const d of UPower.devices.values) {
            // A bateria do notebook ja entrou acima; linha de energia e o
            // agregado DisplayDevice nao sao aparelhos.
            if (!d.ready || d.isLaptopBattery || !d.isPresent)
                continue;
            if (d.type === UPowerDeviceType.LinePower || d.type === UPowerDeviceType.Unknown)
                continue;
            out.push({
                order: root.kindOrder(d.type),
                icon: root.symbolFor(d.type),
                name: d.model,
                pct: d.percentage,
                charging: d.state === UPowerDeviceState.Charging
            });
        }

        for (const e of root.extras)
            out.push({
                order: root.orderForKind(e.kind),
                icon: e.kind === "keyboard" ? "keyboard" : "mouse",
                name: e.name,
                pct: e.pct,
                charging: e.charging
            });

        return out.sort((a, b) => a.order - b.order);
    }

    // Ordem pedida: notebook, mouse, teclado, fones, controle, resto.
    function kindOrder(type: int): int {
        if (type === UPowerDeviceType.Mouse)
            return 1;
        if (type === UPowerDeviceType.Keyboard)
            return 2;
        if (type === UPowerDeviceType.Headset || type === UPowerDeviceType.Headphones || type === UPowerDeviceType.Speakers || type === UPowerDeviceType.OtherAudio)
            return 3;
        if (type === UPowerDeviceType.GamingInput)
            return 4;
        return 5;
    }

    function symbolFor(type: int): string {
        if (type === UPowerDeviceType.Mouse)
            return "mouse";
        if (type === UPowerDeviceType.Keyboard)
            return "keyboard";
        if (type === UPowerDeviceType.Headset || type === UPowerDeviceType.Headphones)
            return "headphones";
        if (type === UPowerDeviceType.Speakers)
            return "speaker";
        if (type === UPowerDeviceType.GamingInput)
            return "stadia_controller";
        return "battery_full";
    }

    // kind vem como texto do script de perifericos.
    function orderForKind(kind: string): int {
        return kind === "mouse" ? 1 : kind === "keyboard" ? 2 : 5;
    }

    // Rotulo curto e em ingles, no mesmo idioma do resto do popout.
    function timeLabel(dev: var): string {
        if (!UPower.onBattery && (dev.percentage >= 1 || dev.state === UPowerDeviceState.FullyCharged))
            return "";
        return UPower.onBattery ? qsTr("Remaining") : qsTr("Until full");
    }

    function timeValue(dev: var): string {
        const secs = UPower.onBattery ? dev.timeToEmpty : dev.timeToFull;
        if (!root.timeLabel(dev) || secs <= 0)
            return "";
        return root.formatSeconds(secs, "…");
    }

    function formatSeconds(s: int, fallback: string): string {
        const hr = Math.floor(s / 3600);
        const min = Math.floor(s / 60) % 60;
        const comps = [];
        if (hr > 0)
            comps.push(`${hr}h`);
        if (min > 0)
            comps.push(`${min}m`);
        return comps.join(" ") || fallback;
    }

    visible: entries.length > 0
    spacing: Tokens.spacing.small

    Process {
        id: extrasProc

        running: true
        command: [`${Quickshell.env("HOME")}/.local/bin/caelestia-peripheral-battery`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.extras = JSON.parse(text);
                } catch (e) {
                    root.extras = [];
                }
            }
        }
    }

    // O nivel destes muda devagar; uma sondagem lenta basta e nao custa nada.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: extrasProc.running = true
    }

    Repeater {
        model: root.entries

        delegate: ColumnLayout {
            id: entry

            required property var modelData

            // Abaixo disto o icone e a percentagem ficam vermelhos: e o aviso
            // de "vai acabar", que so serve se saltar aos olhos.
            readonly property bool low: entry.modelData.pct < 0.2
            readonly property color tint: low ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant

            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: entry.modelData.icon
                    color: entry.tint
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: entry.modelData.name
                    color: entry.low ? Colours.palette.m3error : Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                // Icone e percentual formam um par COMPACTO: eles se referem a
                // mesma coisa, entao ficam juntos, com o espacamento normal da
                // linha so antes do par. A margem a direita e o que afasta o
                // "100%" da borda arredondada do popout.
                RowLayout {
                    Layout.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.extraSmall / 2

                    // Largura FIXA nos dois: sem isso o texto da percentagem muda
                    // de largura ("100%" vs "40%") e empurra o icone, deixando as
                    // linhas desalinhadas entre si. O glifo tambem varia de avanco
                    // conforme o nivel (battery_full vs battery_2_bar).
                    MaterialIcon {
                        Layout.preferredWidth: implicitWidth
                        text: Icons.getBatteryIcon(entry.modelData.pct, entry.modelData.charging)
                        color: entry.tint
                        fontStyle: Tokens.font.icon.small
                        fill: 1
                    }

                    StyledText {
                        Layout.preferredWidth: pctMetrics.width
                        horizontalAlignment: Text.AlignRight
                        text: `${Math.round(entry.modelData.pct * 100)}%`
                        color: entry.tint
                        font: Tokens.font.body.small

                        TextMetrics {
                            id: pctMetrics

                            font: Tokens.font.body.small
                            text: "100%"
                        }
                    }
                }
            }

            // Tempo estimado, indentado sob o notebook. Fonte de rotulo (menor
            // que a do corpo) pra nao competir com a linha principal.
            RowLayout {
                Layout.leftMargin: Tokens.spacing.large
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall
                visible: !!entry.modelData.subLabel

                MaterialIcon {
                    text: entry.modelData.subIcon ?? "schedule"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: entry.modelData.subLabel ?? ""
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                StyledText {
                    Layout.fillWidth: true
                    text: entry.modelData.subValue ?? ""
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }
        }
    }
}
