pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.containers
import qs.services

// Despedida ao desligar/reiniciar: o filme do boot ao contrario, por cima de
// tudo, e so depois o systemctl. Comeca no desktop e termina no preto -- o
// Plymouth de desligar so segura esse preto (configs/plymouth/caelestia-prism).
//
//   caelestia-farewell poweroff|reboot   (scripts/system/boot-splash; os
//   comandos de sessao do Caelestia chamam esse script, que desliga sozinho se
//   o shell nao responder)
//
// Linha do tempo (s): fundo #282828 cobre as janelas, o logo do wallpaper
// esquenta, implode num ponto, o ponto abre a linha ate as bordas, a linha sai
// pela esquerda e tudo apaga no preto. Medidas do wallpaper Prism.
Scope {
    id: root

    property string action
    property bool playing
    // testes: toca sem desligar (CAELESTIA_FAREWELL_DRYRUN=1)
    readonly property bool dryRun: Quickshell.env("CAELESTIA_FAREWELL_DRYRUN") === "1"
    property real t
    readonly property real tA: 0.30     // fundo cobre
    readonly property real tB: 0.30     // logo esquenta
    readonly property real tC: 0.35     // implode
    readonly property real tD: 0.35     // a linha abre
    readonly property real tE: 0.55     // a linha sai
    readonly property real tF: 0.30     // apaga no preto
    readonly property real total: tA + tB + tC + tD + tE + tF

    function play(what: string): void {
        if (root.playing)
            return;
        root.action = what;
        root.t = 0;
        root.playing = true;
        timeline.start();
    }

    NumberAnimation {
        id: timeline

        target: root
        property: "t"
        from: 0
        to: root.total
        duration: root.total * 1000
        onFinished: {
            if (!root.dryRun)
                Quickshell.execDetached(["systemctl", root.action]);
            giveUp.start();
        }
    }

    // O desligamento foi recusado (inibido por algum app, por ex.): em vez de
    // tela preta para sempre, o desktop volta.
    Timer {
        id: giveUp

        interval: root.dryRun ? 300 : 10000
        onTriggered: root.playing = false
    }

    LazyLoader {
        active: root.playing

        Variants {
            model: Screens.screens

            StyledWindow {
                id: win

                required property ShellScreen modelData

                screen: modelData
                name: "farewell"
                color: "transparent"
                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                anchors.top: true
                anchors.bottom: true
                anchors.left: true
                anchors.right: true

                Item {
                    id: stage

                    readonly property real t: root.t
                    readonly property real logoH: height * 0.1856
                    readonly property real glowW: height * 0.010
                    readonly property real y0: height / 2 + height * 0.0123
                    readonly property real cx: width / 2

                    // fase atual: progresso 0..1 de cada trecho
                    function seg(a: real, d: real): real {
                        return Math.max(0, Math.min(1, (t - a) / d));
                    }
                    readonly property real pA: seg(0, root.tA)
                    readonly property real pB: seg(root.tA, root.tB)
                    readonly property real pC: seg(root.tA + root.tB, root.tC)
                    readonly property real pD: seg(root.tA + root.tB + root.tC, root.tD)
                    readonly property real pE: seg(root.tA + root.tB + root.tC + root.tD, root.tE)
                    readonly property real pF: seg(root.total - root.tF, root.tF)
                    readonly property int phase: t < root.tA + root.tB ? 0 : pC < 1 ? 1 : pD < 1 ? 2 : 3

                    function easeIn(p: real): real {
                        return p * p * p;
                    }
                    function easeOut(p: real): real {
                        const q = 1 - p;
                        return 1 - q * q * q;
                    }
                    function easeIO(p: real): real {
                        return p * p * (3 - 2 * p);
                    }
                    function easeBack(p: real): real {
                        const q = p - 1;
                        return 1 + q * q * (2.6 * q + 1.6);
                    }

                    anchors.fill: parent

                    Rectangle {
                        anchors.fill: parent
                        color: "#282828"
                        opacity: stage.pA
                    }

                    // aura (esquenta, some na implosao)
                    Img {
                        file: "glow.png"
                        size: stage.logoH * 0.85 / 0.20
                        cy: stage.y0
                        opacity: stage.phase === 0 ? 0.55 * stage.pB * stage.pB : stage.phase === 1 ? 0.55 * (1 - stage.pC) : 0
                    }

                    // implosao: o contrario da explosao do boot (pf = 1 -> 0)
                    Img {
                        readonly property real pf: 1 - stage.pC
                        file: "glow.png"
                        size: Math.min(stage.logoH * (0.12 + 1.2 * stage.easeOut(pf)) / 0.20, stage.logoH * 3)
                        cy: stage.y0
                        opacity: stage.phase === 1 ? Math.min(1, 3 * stage.pC * Math.sqrt(stage.pC)) : 0
                    }
                    Img {
                        readonly property real pf: 1 - stage.pC
                        file: "ring.png"
                        size: Math.min(stage.logoH * (0.1 + 1.9 * stage.easeOut(pf)) / 0.40, stage.logoH * 3)
                        cy: stage.y0
                        opacity: stage.phase === 1 ? 0.9 * stage.pC * stage.pC : 0
                    }

                    // logo: creme do wallpaper -> quente -> implode
                    Item {
                        readonly property real pf: 1 - stage.pC
                        readonly property real s: stage.phase === 0 ? 1 : 0.7 + 0.3 * stage.easeBack(pf)
                        x: stage.cx - width / 2
                        y: stage.height / 2 - height / 2
                        width: stage.logoH * s
                        height: width
                        opacity: stage.phase === 0 ? stage.pA : stage.phase === 1 ? Math.min(1, pf * 1.6) : 0

                        Image {
                            anchors.fill: parent
                            source: Quickshell.shellPath("assets/boot/logo.png")
                            smooth: true
                            mipmap: true
                        }
                        Image {
                            anchors.fill: parent
                            source: Quickshell.shellPath("assets/boot/logo-white.png")
                            smooth: true
                            mipmap: true
                            opacity: stage.phase === 0 ? stage.easeIn(stage.pB) : 1
                        }
                    }

                    // a linha: abre do centro ate as bordas (contracao ao
                    // contrario) e sai pela esquerda (entrada ao contrario)
                    Image {
                        readonly property real u: 1 - stage.pD                    // contracao ao contrario
                        readonly property real ep: stage.easeIn(u)
                        readonly property real b: stage.width * stage.easeIO(1 - stage.pE)
                        visible: stage.phase >= 2 && stage.pE < 1
                        source: Quickshell.shellPath(stage.phase === 2 ? "assets/boot/line.png" : "assets/boot/line-grad.png")
                        width: stage.phase === 2 ? Math.max(1, stage.width * (1 - ep)) : stage.width
                        height: stage.glowW * (stage.phase === 2 ? 1 + 0.8 * ep : 1) * 8
                        x: stage.phase === 2 ? stage.cx - width / 2 : b - stage.width
                        y: stage.y0 - height / 2
                        smooth: true
                    }
                    Img {
                        readonly property real u: 1 - stage.pD
                        readonly property real ep: stage.easeIn(u)
                        readonly property real b: stage.width * stage.easeIO(1 - stage.pE)
                        file: "dot.png"
                        size: stage.phase === 2 ? stage.logoH * 0.08 * (0.3 + ep) / 0.225 : stage.glowW * 6.2
                        cx: stage.phase === 2 ? stage.cx : b
                        cy: stage.y0
                        opacity: stage.phase === 1 ? stage.pC * stage.pC : stage.phase === 2 ? Math.min(1, 1.5 * ep + 0.3) : stage.pE < 1 ? 0.9 : 0
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: stage.pF
                    }
                }
            }
        }

    }

    IpcHandler {
        function play(action: string): void {
            if (action === "poweroff" || action === "reboot")
                root.play(action);
        }

        target: "farewell"
    }

    component Img: Image {
        property string file
        property real size
        property real cx: parent.width / 2
        property real cy: parent.height / 2

        source: Quickshell.shellPath(`assets/boot/${file}`)
        width: size
        height: size
        x: cx - size / 2
        y: cy - size / 2
        smooth: true
    }
}
