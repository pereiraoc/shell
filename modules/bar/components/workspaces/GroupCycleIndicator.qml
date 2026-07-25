pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// US-012 — Indicador dos GRUPOS do monitor: <groupCount> dots; o grupo ativo é destacado.
// Read-only: recebe groupCount (fixo 3) e activeGroupIdx do pai, que os deriva do ws ativo.
RowLayout {
    id: root

    required property int groupCount
    required property int activeGroupIdx

    Layout.alignment: Qt.AlignHCenter
    spacing: Math.floor(Tokens.spacing.small / 2)

    Repeater {
        model: root.groupCount

        StyledRect {
            required property int index

            readonly property bool isActive: index === root.activeGroupIdx

            Layout.preferredWidth: isActive ? 10 : 4
            Layout.preferredHeight: 4
            radius: 2
            color: isActive ? Colours.palette.m3primary : Colours.palette.m3outlineVariant

            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Tokens.anim.durations.small
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Tokens.anim.durations.small
                }
            }
        }
    }
}
