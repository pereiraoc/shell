pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// US-005 — Indicador visual ●○○ mostrando "estou no grupo X de N" do monitor atual.
// Visível apenas quando há mais de 1 grupo no monitor (groupCount > 1).
RowLayout {
    id: root

    required property int groupCount
    required property int activeGroupIdx

    Layout.alignment: Qt.AlignHCenter
    spacing: Math.floor(Tokens.spacing.small / 2)
    visible: groupCount > 1

    Repeater {
        model: root.groupCount

        StyledRect {
            required property int index

            readonly property bool isActive: index === root.activeGroupIdx

            Layout.preferredWidth: isActive ? 8 : 4
            Layout.preferredHeight: 4
            radius: 2
            color: isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: Tokens.anim.durations.small }
            }
            Behavior on color {
                ColorAnimation { duration: Tokens.anim.durations.small }
            }
        }
    }
}
