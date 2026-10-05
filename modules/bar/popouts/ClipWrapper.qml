pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts // Need to import this module so the Wrapper type is the same as others

Item {
    id: root

    required property ShellScreen screen
    required property real borderThickness
    // Barra na direita: o popout cola na borda direita e desliza para la.
    property bool barRight

    readonly property alias content: content
    // x > 0 = destacado (centralizado); na direita x e sempre > 0, entao
    // la vale o estado direto.
    property real offsetScale: (barRight ? content.isDetached : x > 0) || content.hasCurrent ? 0 : 1

    visible: width > 0 && height > 0
    clip: true

    implicitWidth: content.implicitWidth * (1 - offsetScale)
    implicitHeight: content.implicitHeight

    x: content.isDetached ? (parent.width - content.nonAnimWidth) / 2 : barRight ? parent.width - width : 0
    y: {
        if (content.isDetached)
            return (parent.height - content.nonAnimHeight) / 2;

        const off = content.currentCenter - borderThickness - content.nonAnimHeight / 2;
        const diff = parent.height - Math.floor(off + content.nonAnimHeight);
        if (diff < 0)
            return off + diff;
        return Math.max(off, 0);
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on x {
        // Na direita x acompanha a largura animada; animar de novo descolaria
        // o popout da barra. So anima indo para o modo destacado.
        enabled: !root.barRight || root.content.isDetached

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Behavior on y {
        enabled: root.offsetScale < 1

        Anim {
            duration: content.animLength
            easing: content.animCurve
        }
    }

    Wrapper {
        id: content

        screen: root.screen
        offsetScale: root.offsetScale

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.barRight ? undefined : parent.left
        anchors.right: root.barRight ? parent.right : undefined
        anchors.leftMargin: (-implicitWidth - 5) * root.offsetScale
        anchors.rightMargin: anchors.leftMargin
    }
}
