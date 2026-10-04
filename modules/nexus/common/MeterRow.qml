pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Medidor numa linha: rotulo, valor em texto e barra. A barra muda para a cor
// de alerta acima de `warnAt` (ou abaixo, com `warnBelow`, para bateria/saude).
ConnectedRect {
    id: root

    property string icon
    property string label
    property string subtext
    property string valueText
    // 0..1
    property real value
    property real warnAt: 0.85
    property bool warnBelow

    readonly property bool warning: root.warnBelow ? root.value < root.warnAt : root.value > root.warnAt
    readonly property color barColour: root.warning ? Colours.palette.m3tertiary : Colours.palette.m3primary

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        MaterialIcon {
            visible: root.icon !== ""
            text: root.icon
            color: root.warning ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
            fill: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: root.label
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: root.valueText
                    color: root.warning ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.medium
                }
            }

            StyledRect {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.small
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainerHighest

                StyledRect {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    radius: Tokens.rounding.full
                    color: root.barColour

                    Behavior on width {
                        Anim {}
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }
    }
}
