import QtQuick
import Caelestia.Config
import qs.services
import "shortcuts.js" as Shortcuts

// Alternativas da ultima tecla de uma combinacao (1 / 2 / 3): um keycap por
// tecla, "/" entre eles, dentro de um contorno pontilhado que diz "uma destas".
// O contorno e uma imagem de 16 px em 9 fatias com repeticao (BorderImage):
// desenha-lo com QtQuick.Shapes custava ~250 ms na abertura da pagina.
Item {
    id: root

    property var alts: []
    // Altura de um keycap, para os "/" (ShortcutsPage.capHeight)
    property int capHeight: 20

    readonly property int pad: Tokens.padding.extraSmall / 2

    implicitWidth: row.implicitWidth + root.pad * 2
    implicitHeight: row.implicitHeight + root.pad * 2

    BorderImage {
        anchors.fill: parent
        source: Qt.resolvedUrl("../../../../assets/dotted-outline.png")
        border.left: 4
        border.top: 4
        border.right: 4
        border.bottom: 4
        horizontalTileMode: BorderImage.Repeat
        verticalTileMode: BorderImage.Repeat
        opacity: Colours.light ? 0.7 : 0.9
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

                KeySeparator {
                    height: root.capHeight
                    visible: alt.index > 0
                    text: "/"
                }

                KeyCap {
                    text: alt.modelData
                    kind: Shortcuts.modKind(alt.modelData)
                }
            }
        }
    }
}
