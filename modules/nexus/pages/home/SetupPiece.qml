pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import "setup.js" as L

// Uma peca do setup do Home: fica onde o layout salvo manda (ou no lugar
// padrao), em cm; com `editing` arrasta-se (ao soltar encaixa na grade de
// `snapCm`; a base a ate 2 cm da linha da mesa encosta nela) e sai
// `moved(key, xCm, yCm)`; fora da edicao, clique = `clicked`. Nada escrito na
// peca em nenhum modo: passar o mouse avisa o diagrama (`hover(label, on)`,
// que mostra o nome na legenda) e, na edicao, `hoverKey(key, on)` (a lista de
// pecas acende a linha); `highlighted` vem da lista (mouse na linha) e
// `selected` do clique (na peca ou na linha). `hotspots` = areas clicaveis
// dentro da peca ([{ id, label, x, y, w, h }] em fracoes da peca): no hover a
// area ganha um tom e a legenda vira "Peca · Area"; o clique sai em
// `partClicked(id)`; na edicao ficam desligadas (a peca inteira arrasta).
// `ox`/`oy` deslocam o mundo (cm) quando o diagrama encaixa o conteudo na largura.
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
    // Passo da grade (cm) em que a peca encaixa ao soltar
    property real snapCm: 2.5
    property string label
    // Tipo da peca (icone e ordem na lista da edicao)
    property string kind: "device"
    // Aparelho (entra na legenda do hover); mesa, mesinha e mousepad nao sao
    property bool device: true
    property bool editing
    property bool online: true
    property bool showOffline
    // Edicao: acesa pela lista (mouse na linha) / escolhida (clique)
    property bool highlighted
    property bool selected
    property var hotspots: []

    readonly property real xCm: root.layout[root.key]?.x ?? root.defX
    readonly property real yCm: root.layout[root.key]?.y ?? root.defY
    property string hoveredPart
    readonly property bool hovered: root.device && !root.editing && (hit.containsMouse || root.hoveredPart !== "")
    readonly property string hoverText: root.hoveredPart !== "" ? `${root.label} · ${root.partLabel(root.hoveredPart)}` : root.label
    readonly property bool editHovered: root.editing && hit.containsMouse
    readonly property bool lit: root.editing && (root.highlighted || root.selected || root.editHovered || root.held)
    property bool held

    default property alias content: inner.data

    signal clicked
    signal partClicked(id: string)
    signal moved(key: string, xCm: real, yCm: real)
    signal hover(label: string, on: bool)
    signal hoverKey(key: string, on: bool)
    signal pressedPiece(key: string)

    function partLabel(id: string): string {
        const p = root.hotspots.find(h => h.id === id);
        return p?.label ?? id;
    }

    visible: root.online || root.showOffline
    opacity: root.online ? 1 : 0.4
    x: (root.xCm + root.ox) * root.cm
    y: (root.yCm + root.oy) * root.cm
    width: root.wCm * root.cm
    height: root.hCm * root.cm
    z: root.held ? 3 : root.lit ? 2 : 0

    onHoveredChanged: root.hover(root.hoverText, root.hovered)
    onHoverTextChanged: {
        if (root.hovered)
            root.hover(root.hoverText, true);
    }
    onEditHoveredChanged: root.hoverKey(root.key, root.editHovered)

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

    // Na edicao: contorno em volta da peca; acende quando a lista, o mouse ou a
    // escolha apontam para ela
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        visible: root.editing
        radius: 6
        color: root.held ? Qt.alpha(Colours.palette.m3tertiary, 0.14) : root.lit ? Qt.alpha(Colours.palette.m3tertiary, 0.08) : "transparent"
        border.width: root.selected ? 2 : 1
        border.color: root.lit ? Colours.palette.m3tertiary : Qt.alpha(Colours.palette.m3outline, 0.5)
    }

    MouseArea {
        id: hit

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.editing ? (root.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
        drag.target: root.editing ? root : null
        drag.threshold: 3
        onPressed: {
            root.held = root.editing;
            if (root.editing)
                root.pressedPiece(root.key);
        }
        onReleased: {
            const was = root.held;
            root.held = false;
            if (!was || !drag.active)
                return;
            const p = L.dropPosition(root.x / root.cm - root.ox, root.y / root.cm - root.oy, root.hCm, root.snapCm, root.deskCm);
            root.moved(root.key, p.x, p.y);
            root.x = Qt.binding(() => (root.xCm + root.ox) * root.cm);
            root.y = Qt.binding(() => (root.yCm + root.oy) * root.cm);
        }
        onClicked: {
            if (!root.editing)
                root.clicked();
        }
    }

    // Areas clicaveis dentro da peca (por cima do `hit`): so fora da edicao
    Repeater {
        model: root.editing ? [] : root.hotspots

        MouseArea {
            id: spot

            required property var modelData
            readonly property bool on: root.hoveredPart === spot.modelData.id

            x: spot.modelData.x * root.width
            y: spot.modelData.y * root.height
            width: spot.modelData.w * root.width
            height: spot.modelData.h * root.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.hoveredPart = spot.modelData.id
            onExited: {
                if (root.hoveredPart === spot.modelData.id)
                    root.hoveredPart = "";
            }
            onClicked: root.partClicked(spot.modelData.id)

            Rectangle {
                anchors.fill: spot
                radius: Math.min(6, spot.height / 2)
                color: spot.on ? Qt.alpha(Colours.palette.m3tertiary, 0.16) : "transparent"
                border.width: 1
                border.color: spot.on ? Qt.alpha(Colours.palette.m3tertiary, 0.8) : "transparent"
            }
        }
    }
}
