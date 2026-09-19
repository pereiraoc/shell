pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.services

// HEADPHONE <-> HEADSET de um dispositivo, com as DUAS opcoes visiveis.
//
// Mostrar so a opcao ativa esconderia a escolha: o usuario nao saberia que ha
// outra, nem qual e. Aqui os dois icones ficam sempre a vista e o indicador
// desliza entre eles, no mesmo molde do seletor de cena.
//
// Nao e uma politica de "desabilitar o microfone": em A2DP o perfil tem
// sources=0, o microfone literalmente nao existe. Por isso o custo aparece de
// imediato nas tags ao lado (LDAC/STEREO vira MSBC/MONO).
StyledRect {
    id: root

    required property PwNode node

    readonly property string nodeName: root.node?.name ?? ""
    readonly property bool headset: AudioProfile.modeFor(root.nodeName) === "headset"

    implicitWidth: modeRow.implicitWidth + Tokens.padding.extraSmall * 2
    implicitHeight: modeRow.implicitHeight + Tokens.padding.extraSmall
    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.full

    // Mesmo motivo do AudioSceneSelector: os botoes vivem dentro do Row, um
    // nivel abaixo, e anchors so alcancam irmao ou pai. Por binding funciona.
    StyledRect {
        id: modeIndicator

        readonly property Item sel: root.headset ? setBtn : phoneBtn

        x: modeRow.x + (sel?.x ?? 0)
        y: modeRow.y + (sel?.y ?? 0)
        width: sel?.width ?? 0
        height: sel?.height ?? 0
        color: Colours.palette.m3primary
        radius: Tokens.rounding.full

        Behavior on x {
            Anim {}
        }
    }

    Row {
        id: modeRow

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall

        ModeButton {
            id: phoneBtn

            icon: "headphones"
            target: "headphone"
        }

        ModeButton {
            id: setBtn

            icon: "headset_mic"
            target: "headset"
        }
    }

    component ModeButton: Item {
        required property string icon
        required property string target

        readonly property bool isCurrent: (root.headset ? "headset" : "headphone") === target

        // Quadrado de proposito: com largura igual a altura o indicador de
        // fundo (radius full) vira um CIRCULO em volta do icone, e nao uma
        // pilula esticada -- e o que deixa o selecionado obvio, no mesmo
        // desenho do resto da interface.
        readonly property int side: modeIcon.implicitHeight + Tokens.padding.small

        implicitWidth: side
        implicitHeight: side

        StateLayer {
            radius: Tokens.rounding.full
            color: parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: AudioProfile.setMode(root.nodeName, parent.target)
        }

        MaterialIcon {
            id: modeIcon

            anchors.centerIn: parent
            text: parent.icon
            fontStyle: Tokens.font.icon.small
            color: parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
            fill: parent.isCurrent ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }
}
