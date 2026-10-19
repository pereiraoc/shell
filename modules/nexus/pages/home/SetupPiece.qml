pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Uma peca do setup do Home: fica onde o layout salvo manda (ou no lugar
// padrao), em cm; com `editing` arrasta-se (encaixa em 0,5 cm) e ao soltar
// sai `moved(key, xCm, yCm)`; fora da edicao, clique = `clicked`. Passar o
// mouse avisa o diagrama (`hover`), que mostra o nome na legenda embaixo --
// nada escrito na peca antes disso. Na edicao o nome fica
// escrito na propria peca (senao nao se sabe o que se esta movendo). `ox`/`oy`
// deslocam o mundo (cm) quando o diagrama encaixa o conteudo na largura.
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
    property real ox: 0
    property real oy: 0
    // Anima mudancas de posicao (desligado enquanto o diagrama ainda monta)
    property bool animate: true
    // Linha da mesa (cm): soltar a peca com a base a ate 2 cm dela encosta nela
    property real deskCm: 1e9
    property string label
    // Aparelho (entra na legenda do hover e cresce no hover); mesa, mesinha e
    // mousepad nao sao
    property bool device: true
    property bool editing
    property bool online: true
    property bool showOffline

    readonly property real xCm: root.layout[root.key]?.x ?? root.defX
    readonly property real yCm: root.layout[root.key]?.y ?? root.defY
    readonly property bool hovered: root.device && hit.containsMouse && !root.editing
    property bool held

    default property alias content: inner.data

    signal clicked
    signal moved(key: string, xCm: real, yCm: real)
    signal hover(label: string, on: bool)

    visible: root.online || root.showOffline
    opacity: root.online ? 1 : 0.4
    x: (root.xCm + root.ox) * root.cm
    y: (root.yCm + root.oy) * root.cm
    width: root.wCm * root.cm
    height: root.hCm * root.cm
    z: root.held ? 3 : 0

    onHoveredChanged: root.hover(root.label, root.hovered)

    Behavior on x {
        enabled: root.animate && !root.held

        Anim {}
    }

    Behavior on y {
        enabled: root.animate && !root.held

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

    // Na edicao: o nome escrito na peca, num fundo solido (legivel em cima da silhueta)
    StyledRect {
        anchors.centerIn: parent
        visible: root.editing && root.label !== ""
        implicitWidth: Math.min(tip.implicitWidth + Tokens.padding.normal * 2, root.width + Tokens.padding.large * 2)
        implicitHeight: tip.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.small
        color: Colours.palette.m3surfaceContainerHighest

        StyledText {
            id: tip

            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - Tokens.padding.normal * 2)
            text: root.label
            color: Colours.palette.m3onSurface
            font: Tokens.font.label.medium
            elide: Text.ElideRight
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
            const nx = Math.round((root.x / root.cm - root.ox) * 2) / 2;
            let ny = Math.round((root.y / root.cm - root.oy) * 2) / 2;
            if (Math.abs(ny + root.hCm - root.deskCm) <= 2)
                ny = root.deskCm - root.hCm;
            root.moved(root.key, nx, ny);
            root.x = Qt.binding(() => (root.xCm + root.ox) * root.cm);
            root.y = Qt.binding(() => (root.yCm + root.oy) * root.cm);
        }
        onClicked: {
            if (!root.editing)
                root.clicked();
        }
    }
}
