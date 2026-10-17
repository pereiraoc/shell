pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Estagios de DPI numa barra so (Mouse > <mouse> > DPI): escala logaritmica de
// minDpi a maxDpi, um ponto por estagio com o valor em cima. Arrastar muda o
// valor (arredonda) e, ao soltar, os estagios se reordenam; clique no ponto =
// estagio em uso; clique na barra vazia = novo estagio ali; o x no ponto
// (passando o mouse) remove. Emite edited(estagios, ativo 1-based).
Item {
    id: root

    property var stages: []
    property int active: 1
    property int minDpi: 100
    property int maxDpi: 30000
    property int maxStages: 5
    property bool disabled

    signal edited(stages: var, active: int)

    readonly property real knob: 20
    readonly property real trackX: root.knob / 2 + 4
    readonly property real trackW: root.width - root.trackX * 2

    function pos(v: real): real {
        const l0 = Math.log(root.minDpi), l1 = Math.log(root.maxDpi);
        return root.trackX + (Math.log(Math.max(root.minDpi, Math.min(root.maxDpi, v))) - l0) / (l1 - l0) * root.trackW;
    }

    function value(x: real): int {
        const l0 = Math.log(root.minDpi), l1 = Math.log(root.maxDpi);
        const t = Math.max(0, Math.min(1, (x - root.trackX) / root.trackW));
        const v = Math.exp(l0 + t * (l1 - l0));
        // Passo cresce com o valor (50 embaixo, 500 em cima); sempre multiplo de 50
        const step = v < 1000 ? 50 : v < 5000 ? 100 : 500;
        return Math.max(root.minDpi, Math.min(root.maxDpi, Math.round(v / step) * step));
    }

    // Reordena, tira repetidos e acha onde o ativo foi parar
    function commit(list: var, activeValue: int): void {
        const s = [...new Set(list)].sort((a, b) => a - b);
        const a = Math.max(1, s.indexOf(activeValue) + 1);
        root.edited(s, a);
    }

    implicitHeight: 64
    opacity: root.disabled ? 0.5 : 1

    // Marcas de referencia embaixo da barra
    Repeater {
        model: [100, 400, 1600, 6400, 25600].filter(v => v >= root.minDpi && v <= root.maxDpi)

        StyledText {
            required property int modelData

            x: root.pos(modelData) - width / 2
            y: track.y + track.height + 6
            text: modelData >= 1000 ? `${modelData / 1000}k` : String(modelData)
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
        }
    }

    StyledRect {
        id: track

        x: root.trackX
        y: 30
        width: root.trackW
        height: 6
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainerHighest

        // Clique na barra vazia: novo estagio naquele valor
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            enabled: !root.disabled && root.stages.length < root.maxStages
            cursorShape: enabled ? Qt.PointingHandCursor : undefined
            onClicked: e => {
                const v = root.value(e.x + track.x);
                root.commit([...root.stages, v], root.stages[root.active - 1]);
            }
        }
    }

    Repeater {
        model: root.stages.length

        Item {
            id: knob

            required property int index
            readonly property int stageValue: root.stages[index] ?? 0
            readonly property bool isActive: index === root.active - 1
            property int dragValue: knob.stageValue
            readonly property bool dragging: drag.drag.active

            width: root.knob
            height: root.knob
            y: track.y + track.height / 2 - height / 2
            x: knob.dragging ? x : root.pos(knob.stageValue) - width / 2

            // Valor em cima do ponto
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: 2
                text: knob.dragValue >= 1000 ? `${+(knob.dragValue / 1000).toFixed(knob.dragValue % 1000 ? 1 : 0)}k` : String(knob.dragValue)
                color: knob.isActive ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledRect {
                anchors.fill: parent
                radius: Tokens.rounding.full
                color: knob.isActive ? Colours.palette.m3tertiary : Colours.palette.m3surfaceContainerHigh
                border.width: 2
                border.color: Colours.palette.m3tertiary
                scale: drag.containsMouse || knob.dragging ? 1.15 : 1

                Behavior on scale {
                    Anim {}
                }

                StyledText {
                    anchors.centerIn: parent
                    text: String(knob.index + 1)
                    color: knob.isActive ? Colours.palette.m3onTertiary : Colours.palette.m3onSurface
                    font: Tokens.font.label.small
                }
            }

            MouseArea {
                id: drag

                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.disabled
                cursorShape: Qt.PointingHandCursor
                drag.target: knob
                drag.axis: Drag.XAxis
                drag.minimumX: root.trackX - knob.width / 2
                drag.maximumX: root.trackX + root.trackW - knob.width / 2
                drag.threshold: 3
                onPositionChanged: if (knob.dragging) knob.dragValue = root.value(knob.x + knob.width / 2)
                onReleased: {
                    if (!knob.dragging && knob.dragValue === knob.stageValue)
                        return;
                    const list = [...root.stages];
                    const activeValue = knob.isActive ? knob.dragValue : root.stages[root.active - 1];
                    list[knob.index] = knob.dragValue;
                    root.commit(list, activeValue);
                }
                onClicked: {
                    if (!knob.isActive)
                        root.edited([...root.stages], knob.index + 1);
                }
            }

            onStageValueChanged: knob.dragValue = knob.stageValue

            // Remover (passando o mouse); sempre fica ao menos um
            StyledRect {
                visible: (drag.containsMouse || closeArea.containsMouse) && root.stages.length > 1 && !knob.dragging
                anchors.left: parent.right
                anchors.leftMargin: -4
                anchors.bottom: parent.top
                anchors.bottomMargin: -4
                width: 14
                height: 14
                radius: Tokens.rounding.full
                color: Colours.palette.m3errorContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    // fontStyle (nao font): mexer em font troca a fonte de icone por texto
                    fontStyle: Tokens.font.icon.builders.small.scale(0.6).build()
                    color: Colours.palette.m3onErrorContainer
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const list = root.stages.filter((_, i) => i !== knob.index);
                        const activeValue = knob.isActive ? list[Math.max(0, knob.index - 1)] : root.stages[root.active - 1];
                        root.commit(list, activeValue);
                    }
                }
            }
        }
    }
}
