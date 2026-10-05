pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    // Na borda esquerda (barra na direita): folga interna do outro lado.
    property bool mirrored
    readonly property Props props: Props {}

    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    anchors.leftMargin: anchors.rightMargin
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        readonly property real innerPad: Tokens.padding.large

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: root.mirrored ? undefined : parent.left
        anchors.right: root.mirrored ? parent.right : undefined
        anchors.leftMargin: root.mirrored ? anchors.margins : innerPad
        anchors.rightMargin: root.mirrored ? innerPad : anchors.margins
        anchors.margins: CUtils.clamp(innerPad - Config.border.thickness, 0, innerPad)
        anchors.bottomMargin: 0

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.sidebar.width - content.innerPad - content.anchors.margins
            props: root.props
            screenState: root.screenState
        }
    }
}
