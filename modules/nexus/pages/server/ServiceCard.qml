pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import "server.js" as S

// Um servico do NAS (stack Docker ou unidade do NixOS) como card: logo de marca
// monocromatico (ou simbolo Material), nome, bolinha de estado (verde no ar,
// vermelho falhou, amarelo mudando, cinza parado) e uma linha de resumo.
// Com o mouse em cima (ou um toque, para fixar no tablet) o card troca o resumo
// pelos botoes: start/stop/restart (parar e reiniciar pedem dois cliques, via
// NasBridge.press), abrir o app e o log. A linha de dica diz o que o botao sob
// o mouse faz.
StyledRect {
    id: root

    required property var bridge
    required property string name       // nome da stack ou unidade (stack-x / caddy.service)
    required property string stateKey   // S.stateKey(active)
    property string stateText
    property string summary
    property string since
    property string logUnit
    property var actions: []            // start/stop/restart desta stack
    property var openAction: null       // open:<app>, quando o app tem pagina
    property bool compact
    property bool pinned
    readonly property string art: S.serviceArt(root.name)
    readonly property string dot: S.dotKey(root.stateKey)
    readonly property bool open: hover.hovered || root.pinned
    // Vermelho fixo: no esquema monocromatico o m3error sai amarelo (= tertiary),
    // e a bolinha precisa ler "verde ou vermelho" de relance.
    readonly property color failColour: Colours.light ? "#c62828" : "#ef6b6b"
    readonly property color dotColour: root.dot === "on" ? Colours.palette.m3success : root.dot === "failed" ? root.failColour : root.dot === "busy" ? Colours.palette.m3tertiary : Colours.palette.m3outline
    // Margem interna que tira a bolinha e os botoes da curva do canto (o raio
    // escala com rounding.scale; com 2x a padding normal cai dentro da curva)
    readonly property real inset: Math.round(Math.max(Tokens.padding.large, root.radius * 0.42))
    property string hint

    signal showLog(string unit)

    function actionIcon(id: string): string {
        if (id.startsWith("start:"))
            return "play_arrow";
        if (id.startsWith("stop:"))
            return "stop";
        return "restart_alt";
    }

    // altura minima fixa (abrir no hover nao pula a grade) ou o conteudo + margens
    implicitHeight: Math.max(root.compact ? Math.round(Tokens.font.icon.large.pointSize * 3.4) : Math.round(Tokens.font.icon.large.pointSize * 5.6), body.implicitHeight + body.anchors.topMargin + body.anchors.bottomMargin)
    radius: Tokens.rounding.large
    color: root.open ? Colours.tPalette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainer
    border.width: root.dot === "failed" ? 1 : 0
    border.color: root.failColour

    HoverHandler {
        id: hover
    }

    // Toque/clique no fundo fixa os botoes abertos (tablet nao tem hover)
    TapHandler {
        onTapped: root.pinned = !root.pinned
    }

    ColumnLayout {
        id: body

        anchors.fill: parent
        anchors.margins: root.inset
        anchors.topMargin: root.compact ? root.inset : Math.round(root.inset * 0.8)
        anchors.bottomMargin: root.compact ? root.inset : Math.round(root.inset * 0.8)
        spacing: Tokens.spacing.extraSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            Item {
                implicitWidth: Math.round((root.compact ? Tokens.font.icon.medium : Tokens.font.icon.large).pointSize * 1.6)
                implicitHeight: implicitWidth

                ColouredIcon {
                    anchors.centerIn: parent
                    visible: root.art !== ""
                    implicitSize: Math.round(parent.implicitWidth * 0.85)
                    source: root.art ? `file://${Quickshell.shellPath(root.art)}` : ""
                    colour: root.dot === "off" ? Colours.palette.m3outline : Colours.palette.m3onSurface
                }

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: root.art === ""
                    text: S.serviceGlyph(root.name)
                    color: root.dot === "off" ? Colours.palette.m3outline : Colours.palette.m3onSurface
                    fontStyle: root.compact ? Tokens.font.icon.medium : Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: S.serviceTitle(root.name)
                    font: root.compact ? Tokens.font.body.small : Tokens.font.title.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.compact
                    text: root.compact && root.open && root.hint !== "" ? root.hint : root.summary
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            // Bolinha de estado (no compacto, os botoes ocupam o lugar dela no hover)
            StyledRect {
                Layout.alignment: Qt.AlignTop
                visible: !(root.compact && root.open)
                implicitWidth: Math.round(Tokens.font.icon.small.pointSize * 0.75)
                implicitHeight: implicitWidth
                radius: Tokens.rounding.full
                color: root.dotColour

                // halo suave so quando no ar, para o verde ler como "vivo"
                StyledRect {
                    anchors.centerIn: parent
                    visible: root.dot === "on" || root.dot === "failed"
                    width: parent.width * 2
                    height: width
                    radius: Tokens.rounding.full
                    color: Qt.alpha(root.dotColour, 0.22)
                    z: -1
                }
            }

            // Compacto (unidades do sistema): so o log, ao lado do nome
            IconButton {
                visible: root.compact && root.open && root.logUnit !== ""
                icon: "subject"
                type: IconButton.Tonal
                isRound: true
                onHoveredChanged: root.hint = hovered ? Tr.tr("Show log") : ""
                onClicked: root.showLog(root.logUnit)
            }
        }

        Item {
            Layout.fillHeight: true
            visible: !root.compact
        }

        // Fechado: o resumo. Aberto: dica + botoes.
        StyledText {
            Layout.fillWidth: true
            visible: !root.compact && !root.open
            text: root.summary
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.compact && !root.open
            text: root.stateText + (root.since ? Tr.tr(" since %1").arg(root.since) : "")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: !root.compact && root.open
            text: {
                const armed = root.actions.find(a => a.id === root.bridge.armed);
                if (armed)
                    return Tr.tr("Click again: %1").arg(armed.label ?? "");
                const busy = root.actions.find(a => a.id === root.bridge.busyAction);
                if (busy)
                    return Tr.tr("%1 — running…").arg(busy.label ?? "");
                return root.hint !== "" ? root.hint : root.stateText;
            }
            color: root.actions.some(a => a.id === root.bridge.armed) ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.compact && root.open
            spacing: Tokens.spacing.small

            Repeater {
                model: root.actions.length

                IconButton {
                    id: btn

                    required property int index
                    readonly property var act: root.actions[btn.index] ?? ({})
                    readonly property bool armed: root.bridge.armed === btn.act.id
                    readonly property bool busy: root.bridge.busyAction === btn.act.id

                    icon: btn.busy ? "hourglass_top" : root.actionIcon(String(btn.act.id ?? ""))
                    type: IconButton.Tonal
                    isRound: true
                    inactiveColour: btn.armed ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
                    inactiveOnColour: btn.armed ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer
                    disabled: root.bridge.busyAction !== "" && !btn.busy
                    onHoveredChanged: root.hint = hovered ? (btn.act.label ?? "") : ""
                    onClicked: {
                        if (!btn.busy)
                            root.bridge.press(btn.act);
                    }
                }
            }

            IconButton {
                visible: root.openAction !== null && root.dot === "on"
                icon: "open_in_new"
                type: IconButton.Tonal
                isRound: true
                onHoveredChanged: root.hint = hovered ? Tr.tr("Open the app") : ""
                onClicked: root.bridge.run(root.openAction)
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                visible: root.logUnit !== ""
                icon: "subject"
                type: IconButton.Tonal
                isRound: true
                onHoveredChanged: root.hint = hovered ? Tr.tr("Show log") : ""
                onClicked: root.showLog(root.logUnit)
            }
        }
    }
}
