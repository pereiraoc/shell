pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

// Agente polkit do Caelestia: a caixa de senha para tudo que pede autorizacao
// (pkexec das ferramentas caelestia-*, GParted, Flatpak de sistema...).
//
// Antes disto nao havia NENHUM agente rodando na sessao (o hyprpolkitagent
// esta instalado mas nunca foi iniciado), entao todo pedido via polkit
// falhava calado. So pode haver um agente por sessao -- nao iniciar outro.
//
// A janela so existe enquanto ha um pedido (LazyLoader), no monitor em foco,
// em camada Overlay com teclado exclusivo. A senha nunca sai daqui a nao ser
// por flow.submit(), e o campo e limpo a cada envio.
Scope {
    id: root

    readonly property AuthFlow flow: agent.flow
    readonly property bool active: agent.isActive && root.flow !== null

    PolkitAgent {
        id: agent

        onIsRegisteredChanged: console.info(`[Polkit] agente ${agent.isRegistered ? "registrado" : "NAO registrado"}`)
    }

    LazyLoader {
        active: root.active

        StyledWindow {
            id: win

            name: "polkit"
            screen: Screens.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Screens.screens[0] ?? null
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            // Fundo escurecido; clicar fora nao cancela (clique perdido nao
            // deve negar uma autorizacao que alguem esta esperando).
            StyledRect {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, 0.45)
            }

            StyledRect {
                id: card

                anchors.centerIn: parent
                width: Math.min(parent.width - Tokens.padding.extraLarge * 2, 440)
                implicitHeight: col.implicitHeight + Tokens.padding.extraLarge * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.palette.m3surfaceContainer

                Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                ColumnLayout {
                    id: col

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.extraLarge
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "admin_panel_settings"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("Authentication required")
                            font: Tokens.font.title.medium
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.flow?.message ?? ""
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.medium
                        wrapMode: Text.WordWrap
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: root.flow?.actionId ?? ""
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideMiddle
                    }

                    StyledTextField {
                        id: field

                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        enabled: root.flow?.isResponseRequired ?? false
                        focus: true
                        leadingIcon: "key"
                        placeholderText: root.flow?.inputPrompt || qsTr("Password")
                        echoMode: (root.flow?.responseVisible ?? false) ? TextInput.Normal : TextInput.Password
                        isError: root.flow?.supplementaryIsError ?? false
                        errorText: root.flow?.supplementaryMessage ?? ""
                        supportingText: (root.flow?.supplementaryIsError ?? false) ? "" : (root.flow?.supplementaryMessage ?? "")

                        onAccepted: submitBtn.clicked()
                        Keys.onEscapePressed: root.flow?.cancelAuthenticationRequest()

                        // Novo prompt (ex.: senha errada, tentar de novo): foco
                        // de volta no campo.
                        Connections {
                            target: root.flow

                            function onIsResponseRequiredChanged(): void {
                                if (root.flow?.isResponseRequired)
                                    field.forceActiveFocus();
                            }
                        }

                        Component.onCompleted: field.forceActiveFocus()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.spacing.small
                        spacing: Tokens.spacing.small

                        Item {
                            Layout.fillWidth: true
                        }

                        TextButton {
                            type: TextButton.Tonal
                            isRound: true
                            horizontalPadding: Tokens.padding.extraLarge
                            text: qsTr("Cancel")
                            onClicked: root.flow?.cancelAuthenticationRequest()
                        }

                        TextButton {
                            id: submitBtn

                            type: TextButton.Filled
                            isRound: true
                            horizontalPadding: Tokens.padding.extraLarge
                            text: qsTr("Authorize")
                            disabled: !(root.flow?.isResponseRequired ?? false)
                            onClicked: {
                                if (!root.flow?.isResponseRequired)
                                    return;
                                root.flow.submit(field.text);
                                field.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
