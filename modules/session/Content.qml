pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Column {
    id: root

    required property ScreenState screenState

    // Ordem dos botoes para a navegacao por teclado (a mesma da tela). Um botao sem
    // comando (lista vazia no shell.json, ex.: "hibernate": []) fica escondido e as
    // setas pulam por cima dele.
    readonly property list<Item> buttons: [shutdown, reboot, hibernate, suspend, logout]

    function neighbour(item: Item, step: int): Item {
        let i = buttons.indexOf(item) + step;
        while (i >= 0 && i < buttons.length) {
            if (buttons[i].visible)
                return buttons[i];
            i += step;
        }
        return null;
    }

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    // Grupos: desligar/reiniciar · hibernar · suspender/sair. Dentro do grupo, o
    // espacamento normal; entre grupos, um pouco mais.
    spacing: Tokens.spacing.large + Tokens.spacing.small

    AnimatedImage {
        width: Tokens.sizes.session.button
        height: Tokens.sizes.session.button
        sourceSize.width: width * ((QsWindow.window as QsWindow)?.devicePixelRatio ?? 1)

        playing: visible
        asynchronous: true
        speed: Config.general.sessionGifSpeed
        source: Paths.absolutePath(Config.paths.sessionGif)
        fillMode: AnimatedImage.PreserveAspectFit
    }

    Column {
        spacing: Tokens.spacing.large

        SessionButton {
            id: shutdown

            tooltip: Tr.tr("Shut down")
            icon: Config.session.icons.shutdown
            command: Config.session.commands.shutdown
        }

        SessionButton {
            id: reboot

            tooltip: Tr.tr("Reboot")
            icon: Config.session.icons.reboot
            command: Config.session.commands.reboot
        }
    }

    // Suspender (RAM, volta em segundos) e hibernar (disco, sobrevive a falta
    // de bateria) sao coisas diferentes: os dois botoes ficam. Hibernar so
    // volta a sessao com resume= configurado; sem isso, esconder o botao com
    // "hibernate": [] no shell.json.
    SessionButton {
        id: hibernate

        tooltip: Tr.tr("Hibernate")
        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate
    }

    Column {
        spacing: Tokens.spacing.large

        SessionButton {
            id: suspend

            tooltip: Tr.tr("Suspend")
            icon: Config.session.icons.suspend
            command: Config.session.commands.suspend
        }

        SessionButton {
            id: logout

            tooltip: Tr.tr("Log out")
            icon: Config.session.icons.logout
            command: Config.session.commands.logout

            // O foco comeca aqui, nao no topo: Enter sem querer nao desliga o PC.
            Component.onCompleted: forceActiveFocus()

            Connections {
                function onLauncherChanged(): void {
                    if (!root.screenState.launcher)
                        logout.forceActiveFocus();
                }

                target: root.screenState
            }
        }
    }

    component SessionButton: IconButton {
        id: button

        required property list<string> command
        required property string tooltip

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        visible: command.length > 0
        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        inactiveColour: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
        inactiveOnColour: activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        radius: pressed ? Tokens.rounding.medium : activeFocus ? Tokens.rounding.extraLarge : Tokens.rounding.largeIncreased
        font: Tokens.font.icon.builders.large.scale(1.3).build()
        onClicked: exec()

        KeyNavigation.up: root.neighbour(button, -1)
        KeyNavigation.down: root.neighbour(button, 1)

        ToolTip.visible: button.hovered
        ToolTip.text: button.tooltip

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.screenState.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }
}
