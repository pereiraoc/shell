import QtQuick
import QtQuick.Controls
import Caelestia.Config
import qs.components
import qs.modules.nexus

StackView {
    id: root

    required property NexusState nState
    // Indice da pagina no PageRegistry (Pages.loadPage); -1 = desconhecido
    property int pageIdx: -1
    default property list<Component> pages
    readonly property int animMovement: Tokens.padding.extraExtraLarge * 2

    function openSubPage(idx: int, immediate: bool): void {
        const page = pages[idx];
        if (page) {
            push(page, {
                nState
            }, immediate ? StackView.Immediate : StackView.PushTransition);
        } else {
            console.warn(logCat, "Attempted to open invalid sub-page index", idx);
            nState.closeSubPage();
        }
    }

    clip: busy

    Component.onCompleted: {
        openSubPage(0, true);
        // Incubacao antiga terminando depois de uma troca de pagina (ex.: Home
        // nascendo quando o IPC ja pediu Keyboard > sub 2): a pilha de
        // subpaginas e da pagina nova -- nao aplicar nem desempilhar.
        if (root.pageIdx >= 0 && root.pageIdx !== root.nState.currentPageIdx)
            return;
        for (const page of nState.subPageIdxStack)
            openSubPage(page, true);
    }

    pushEnter: Transition {
        SequentialAnimation {
            PropertyAction {
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: Tokens.anim.durations.expressiveDefaultEffects
            }
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    to: 1
                    type: Anim.SlowEffects
                }
                Anim {
                    property: "x"
                    from: root.animMovement
                    to: 0
                    type: Anim.SlowEffects
                }
            }
        }
    }

    pushExit: Transition {
        Anim {
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
    }

    popEnter: Transition {
        SequentialAnimation {
            PropertyAction {
                property: "opacity"
                value: 0
            }
            PauseAnimation {
                duration: Tokens.anim.durations.expressiveDefaultEffects
            }
            ParallelAnimation {
                Anim {
                    property: "opacity"
                    to: 1
                    type: Anim.SlowEffects
                }
                Anim {
                    property: "x"
                    from: -root.animMovement
                    to: 0
                    type: Anim.SlowEffects
                }
            }
        }
    }

    popExit: Transition {
        Anim {
            property: "opacity"
            to: 0
            type: Anim.DefaultEffects
        }
    }

    LoggingCategory {
        id: logCat

        name: "caelestia.nexus"
        defaultLogLevel: LoggingCategory.Info
    }

    Connections {
        function onSubPageOpened(idx: int): void {
            root.openSubPage(idx, false);
        }

        function onSubPageClosed(): void {
            if (root.depth < root.nState.subPageIdxStack.length) {
                console.log(logCat, "Attempted to close page while depth < stack depth. Ignoring.");
                return;
            }
            root.pop();
        }

        target: root.nState
    }
}
