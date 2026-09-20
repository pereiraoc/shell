pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// Seletor de cena de audio, quatro posicoes, no molde do seletor de modo de
// GPU: nome e descricao do selecionado ACIMA, pilula com indicador deslizante
// abaixo, botoes so de icone.
//
// O eixo NAO e genero de conteudo -- generos se sobrepoem (CS2 e jogo E
// precisao; KCD2 e jogo E cinema). O eixo e a pergunta do momento: preciso
// IDENTIFICAR onde a coisa esta, ou SENTIR que estou no lugar?
//
// OFF nao e "surround sem efeito": sem a cadeia o motor do jogo ve um endpoint
// estereo e renderiza estereo, perdendo a informacao posicional na origem.
ColumnLayout {
    id: root

    // A descricao so faz sentido na pagina de configuracao. No popout da barra
    // ela rouba espaco de um lugar que existe para ser rapido.
    property bool showDescription: false

    readonly property list<string> ids: ["off", "precise", "spatial", "cinematic"]
    readonly property string current: AudioProfile.scene === "custom" ? (AudioProfile.preset || "spatial") : "off"
    readonly property string currentLabel: {
        if (root.current === "off")
            return qsTr("Raw");
        return AudioProfile.presets.find(x => x.id === root.current)?.label ?? root.current;
    }
    readonly property string currentDesc: {
        if (root.current === "off")
            return qsTr("No processing. The game gets a stereo endpoint and renders stereo.");
        if (!AudioProfile.customEffective)
            return qsTr("Inert: output is mono/HFP, there is nothing to spatialise.");
        return AudioProfile.presets.find(x => x.id === root.current)?.desc ?? "";
    }

    function select(id: string): void {
        if (id === "off")
            AudioProfile.setScene("normal");
        else
            AudioProfile.setPreset(id);
    }

    spacing: Tokens.spacing.small

    StyledText {
        Layout.fillWidth: true
        // Durante a troca o rotulo assume o lugar do nome: sem isso ele
        // seguiria anunciando a cena ANTIGA enquanto o spinner gira.
        text: AudioProfile.busy ? qsTr("Audio scene: applying…") : qsTr("Audio scene: %1").arg(root.currentLabel)
        font: Tokens.font.body.small
        elide: Text.ElideRight
    }

    StyledText {
        // preferredWidth 0 impede que o texto sem quebra dite a largura do
        // container: ele passa a usar o espaco disponivel e quebra dentro dele.
        Layout.fillWidth: true
        Layout.preferredWidth: 0
        visible: root.showDescription && !!text
        text: root.currentDesc
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
        wrapMode: Text.WordWrap
    }

    StyledRect {
        id: pill

        // Acompanha a largura do popout em vez de ficar encolhido no centro.
        Layout.fillWidth: true
        implicitHeight: sceneRow.implicitHeight + Tokens.padding.small * 2
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        // O indicador NAO usa anchors: no QML so da pra ancorar em irmao ou
        // pai, e os botoes vivem dentro do RowLayout, um nivel abaixo. Ancorar
        // falhava em silencio e o destaque ficava com tamanho zero. Binding de
        // geometria atravessa niveis e ainda anima.
        // O spinner toma o lugar dos botoes em vez de se somar a eles: enquanto
        // a acao corre o estado exibido nao vale, e deixar a pilula a vista
        // convidaria a cliques que o exec() descarta em silencio.
        CircularIndicator {
            anchors.centerIn: parent
            implicitSize: sceneRow.implicitHeight
            visible: AudioProfile.busy
            running: visible
        }

        StyledRect {
            id: indicator

            readonly property Item sel: {
                const items = [offBtn, preciseBtn, spatialBtn, cinematicBtn];
                const i = root.ids.indexOf(root.current);
                return items[i >= 0 ? i : 0];
            }

            // Itens invisiveis nao recebem clique no QML, entao esconder a
            // linha ja desabilita a interacao -- nao e' preciso mexer nos
            // StateLayer de cada botao.
            visible: !AudioProfile.busy
            x: sceneRow.x + (sel?.x ?? 0)
            y: sceneRow.y + (sel?.y ?? 0)
            width: sel?.width ?? 0
            height: sel?.height ?? 0
            color: Colours.palette.m3primary
            radius: Tokens.rounding.full

            Behavior on x {
                Anim {}
            }

            Behavior on width {
                Anim {}
            }
        }

        RowLayout {
            id: sceneRow

            visible: !AudioProfile.busy
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            spacing: Tokens.spacing.small

            SceneButton {
                id: offBtn

                scene: "off"
                // "Alvo com flecha" nao existe como glifo unico no Material
                // Symbols, e OFF nao tem icone que diga "cru" -- por isso um
                // circulo com RAW escrito dentro.
                label: "RAW"
            }

            SceneButton {
                id: preciseBtn

                scene: "precise"
                icon: "target"
            }

            SceneButton {
                id: spatialBtn

                scene: "spatial"
                icon: "center_focus_strong"
            }

            SceneButton {
                id: cinematicBtn

                scene: "cinematic"
                icon: "theaters"
            }
        }
    }

    component SceneButton: Item {
        required property string scene
        property string icon: ""
        property string label: ""

        readonly property bool isCurrent: root.current === scene
        readonly property color fg: isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant

        Layout.fillWidth: true
        implicitWidth: Math.max(btnIcon.implicitWidth, btnLabel.implicitWidth) + Tokens.padding.medium
        implicitHeight: Math.max(btnIcon.implicitHeight, btnLabel.implicitHeight) + Tokens.padding.small

        StateLayer {
            radius: Tokens.rounding.full
            color: parent.isCurrent ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: root.select(parent.scene)
        }

        MaterialIcon {
            id: btnIcon

            anchors.centerIn: parent
            visible: !!parent.icon
            text: parent.icon
            fontStyle: Tokens.font.icon.large
            color: parent.fg
            fill: parent.isCurrent ? 1 : 0

            Behavior on fill {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }

        StyledText {
            id: btnLabel

            anchors.centerIn: parent
            visible: !!parent.label
            text: parent.label
            color: parent.fg
            font: Tokens.font.label.small
        }
    }
}
