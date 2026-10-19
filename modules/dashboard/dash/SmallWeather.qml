import QtQuick
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    anchors.centerIn: parent

    implicitWidth: Math.max(main.implicitWidth, nav.implicitWidth)
    implicitHeight: main.implicitHeight + (nav.visible ? nav.implicitHeight + Tokens.spacing.small : 0) + Tokens.padding.largeIncreased * 2

    // Ao abrir, o primeiro local da lista (V3-09); as setas trocam
    Component.onCompleted: Weather.reset()

    Connections {
        function onDashboardChanged(): void {
            if (root.screenState.dashboard)
                Weather.reset();
        }

        target: root.screenState
    }

    Item {
        id: main

        anchors.top: parent.top
        anchors.topMargin: Tokens.padding.largeIncreased
        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: icon.implicitWidth + info.implicitWidth + info.anchors.leftMargin
        implicitHeight: Math.max(icon.implicitHeight, info.implicitHeight)

        MaterialIcon {
            id: icon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left

            animate: true
            text: Weather.icon
            color: Colours.palette.m3secondary
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
        }

        Column {
            id: info

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.largeIncreased

            spacing: Tokens.spacing.extraSmall

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                animate: true
                text: Weather.temp
                color: Colours.palette.m3primary
                font: Tokens.font.headline.builders.medium.width(110).weight(Font.DemiBold).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter

                animate: true
                text: Weather.description
                font: Tokens.font.body.small

                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                horizontalAlignment: Text.AlignHCenter
                width: Math.min(implicitWidth, root.parent.width - icon.implicitWidth - info.anchors.leftMargin - Tokens.padding.extraLargeIncreased)
            }
        }
    }

    // Anterior / nome do local / proximo -- so com mais de um local
    Row {
        id: nav

        visible: Weather.multi
        anchors.top: main.bottom
        anchors.topMargin: Tokens.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Tokens.spacing.small

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            type: IconButton.Text
            isRound: true
            icon: "chevron_left"
            font: Tokens.font.icon.small
            onClicked: Weather.prev()
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            animate: true
            text: Weather.placeName || Tr.tr("Loading...")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.medium
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.parent.width - Tokens.padding.extraLargeIncreased * 2 - Tokens.font.icon.small.pointSize * 6)
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            type: IconButton.Text
            isRound: true
            icon: "chevron_right"
            font: Tokens.font.icon.small
            onClicked: Weather.next()
        }
    }
}
