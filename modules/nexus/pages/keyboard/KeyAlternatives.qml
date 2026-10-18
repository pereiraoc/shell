import QtQuick
import QtQuick.Shapes
import Caelestia.Config
import qs.components
import qs.services
import "shortcuts.js" as Shortcuts

// Alternativas da ultima tecla de uma combinacao (1 / 2 / 3): um keycap por
// tecla, "/" entre eles, dentro de um contorno pontilhado que diz "uma destas".
Item {
    id: root

    property var alts: []

    readonly property int pad: Tokens.padding.extraSmall / 2

    implicitWidth: row.implicitWidth + root.pad * 2
    implicitHeight: row.implicitHeight + root.pad * 2

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Colours.palette.m3outline
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 3]
            fillColor: "transparent"

            PathRectangle {
                x: 0.5
                y: 0.5
                width: root.width - 1
                height: root.height - 1
                radius: Tokens.rounding.small
            }
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall / 2

        Repeater {
            model: root.alts

            Row {
                id: alt

                required property int index
                required property string modelData

                spacing: Tokens.spacing.extraSmall / 2

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: alt.index > 0
                    text: "/"
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.small
                }

                KeyCap {
                    text: alt.modelData
                    kind: Shortcuts.modKind(alt.modelData)
                }
            }
        }
    }
}
