pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Uma peca do setup do Home: fica onde o layout salvo manda (ou no lugar
// padrao), em cm; com `editing` arrasta-se (encaixa em 0,5 cm) e ao soltar
// sai `moved(key, xCm, yCm)`; fora da edicao, clique = `clicked`. Passar o
// mouse mostra o nome (`label`) num balao -- nada escrito antes disso -- e
// as pecas pequenas (fones, mouses) crescem um pouco para dar para ver o que
// sao. O conteudo (silhueta) vai dentro.
Item {
    id: root

    required property string key
    // Lugar padrao (cm) e tamanho (cm)
    required property real defX
    required property real defY
    required property real wCm
    required property real hCm
    // { key: { x, y } } salvo; cm = pixels por cm
    required property var layout
    required property real cm
    property string label
    property bool editing
    property bool online: true
    property bool showOffline

    readonly property real xCm: root.layout[root.key]?.x ?? root.defX
    readonly property real yCm: root.layout[root.key]?.y ?? root.defY
    readonly property bool hovered: hit.containsMouse && !root.editing
    property bool held

    default property alias content: inner.data

    signal clicked
    signal moved(key: string, xCm: real, yCm: real)

    visible: root.online || root.showOffline
    opacity: root.online ? 1 : 0.4
    x: root.xCm * root.cm
    y: root.yCm * root.cm
    width: root.wCm * root.cm
    height: root.hCm * root.cm
    z: root.held ? 3 : root.hovered ? 2 : 0
    // Pecas pequenas crescem no hover: um estojo de 5 cm nao se le em 20 px
    scale: root.hovered && root.wCm < 15 ? 1.6 : 1
    transformOrigin: Item.Center

    Behavior on x {
        enabled: !root.held

        Anim {}
    }

    Behavior on y {
        enabled: !root.held

        Anim {}
    }

    Behavior on scale {
        Anim {}
    }

    Item {
        id: inner

        anchors.fill: parent
    }

    // Na edicao: contorno tracejado em volta da peca
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        visible: root.editing
        radius: 6
        color: root.held ? Qt.alpha(Colours.palette.m3tertiary, 0.1) : "transparent"
        border.width: 1
        border.color: root.held ? Colours.palette.m3tertiary : Qt.alpha(Colours.palette.m3outline, 0.7)
    }

    // Balao com o nome, so no hover
    StyledRect {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        visible: root.hovered && root.label !== ""
        implicitWidth: tip.implicitWidth + Tokens.padding.normal * 2
        implicitHeight: tip.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.small
        color: Colours.palette.m3inverseSurface
        // o balao nao cresce junto com a peca
        scale: root.scale > 1 ? 1 / root.scale : 1

        StyledText {
            id: tip

            anchors.centerIn: parent
            text: root.label
            color: Colours.palette.m3inverseOnSurface
            font: Tokens.font.label.medium
        }
    }

    MouseArea {
        id: hit

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.editing ? (root.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
        drag.target: root.editing ? root : null
        drag.threshold: 3
        onPressed: root.held = root.editing
        onReleased: {
            const was = root.held;
            root.held = false;
            if (!was || !drag.active)
                return;
            const nx = Math.round(root.x / root.cm * 2) / 2;
            const ny = Math.round(root.y / root.cm * 2) / 2;
            root.moved(root.key, nx, ny);
            root.x = Qt.binding(() => root.xCm * root.cm);
            root.y = Qt.binding(() => root.yCm * root.cm);
        }
        onClicked: {
            if (!root.editing)
                root.clicked();
        }
    }
}
