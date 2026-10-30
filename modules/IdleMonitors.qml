pragma ComponentBehavior: Bound

import "lock"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    required property Lock lock
    property bool blanked
    readonly property bool hasPlayer: Players.list.some(p => p.isPlaying)
    readonly property bool isCharging: !UPower.onBattery
    readonly property bool enabled: {
        if (GlobalConfig.general.idle.inhibitWhenAudio && hasPlayer)
            return false;
        if (GlobalConfig.general.idle.inhibitWhenCharging && isCharging)
            return false;
        return true;
    }
    // US-004 (custom): timeouts por fonte de energia; vazio = usa timeouts legado
    readonly property var activeTimeouts: {
        const ac = GlobalConfig.general.idle.timeoutsOnAC
        const bat = GlobalConfig.general.idle.timeoutsOnBattery
        const legacy = GlobalConfig.general.idle.timeouts.values
        if (ac && ac.length > 0 && bat && bat.length > 0)
            return UPower.onBattery ? bat : ac
        if (legacy && legacy.length > 0)
            return legacy
        return (bat && bat.length > 0) ? bat : (ac && ac.length > 0 ? ac : [])
    }

    // Libera a suspensao (ver sleepHold).
    function releaseSleep(): void {
        lockDrawn.stop();
        lockTimeout.stop();
        sleepHold.running = false;
    }

    function handleIdleAction(action: var): void {
        if (!action)
            return;

        if (action === "lock")
            lock.lock.locked = true;
        else if (action === "unlock")
            lock.lock.locked = false;
        else if (typeof action === "string")
            Hypr.dispatch(Hypr.usingLua && ["dpms off", "dpms on"].includes(action) ? `hl.dsp.dpms({ action = "${action === "dpms off" ? "disable" : "enable"}" })` : action);
        else if (!SessionManager.exec(action))
            Quickshell.execDetached(action);
    }

    Connections {
        function onAboutToSleep(): void {
            // Hibernar pelo shell (Hibernation.active): sem tela de bloqueio ANTES -- a
            // despedida esta na tela. Bloquear ao voltar e opcao (hibernateLock).
            if (!GlobalConfig.general.idle.lockBeforeSleep || Hibernation.active) {
                root.releaseSleep();
                return;
            }
            // Preto primeiro: apaga na hora e bloqueia por tras, sem transicao visivel no
            // monitor externo. Ao acordar, so acende quando estiver pronto (wakeReady).
            wakeReady.stop();
            dpmsRetry.stop();
            root.blanked = true;
            root.handleIdleAction("dpms off");
            lockTimeout.restart();
            if (root.lock.lock.secure)
                lockDrawn.restart();
            else {
                root.lock.lock.instant = true;
                root.lock.lock.locked = true;
            }
        }

        function onResumed(): void {
            if (Hibernation.active && Hibernation.hibernateLock)
                root.lock.lock.locked = true;
            if (root.blanked)
                wakeReady.restart();
            sleepHold.running = true;
        }

        function onLockRequested(): void {
            root.lock.lock.locked = true;
        }

        function onUnlockRequested(): void {
            root.lock.lock.unlock();
        }

        target: SessionManager
    }

    // Sem isto o sistema podia dormir antes de o bloqueio ser desenhado: ao acordar, o
    // desktop aparecia aberto ate o bloqueio entrar. O inibidor "delay" segura a suspensao
    // enquanto o shell bloqueia (o logind so espera ate 5 s, nunca impede de dormir).
    // tail --pid: morre junto com o systemd-inhibit, nao sobra processo a cada ciclo.
    Process {
        id: sleepHold

        running: true
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=Caelestia", "--why=Bloquear a tela antes de dormir", "sh", "-c", "exec tail --pid=$PPID -f /dev/null"]
    }

    Connections {
        function onSecureChanged(): void {
            if (root.lock.lock.secure && lockTimeout.running)
                lockDrawn.restart();
            if (!root.lock.lock.secure)
                root.lock.lock.instant = false;
        }

        target: root.lock.lock
    }

    // Bloqueio "secure" ainda precisa de alguns quadros para aparecer de fato.
    Timer {
        id: lockDrawn

        interval: 200
        onTriggered: root.releaseSleep()
    }

    Timer {
        id: lockTimeout

        interval: 3000
        onTriggered: root.releaseSleep()
    }

    // Acordou: fica preto ate assentar (conserto de monitores no gancho ~2 s, camera pronta)
    // e so entao acende, com o bloqueio pronto e respondendo.
    Timer {
        id: wakeReady

        interval: 2500
        onTriggered: {
            root.blanked = false;
            root.handleIdleAction("dpms on");
            dpmsRetry.restart();
        }
    }

    // O monitor externo pode ainda estar acordando na 1a ordem de ligar.
    Timer {
        id: dpmsRetry

        interval: 1500
        onTriggered: root.handleIdleAction("dpms on")
    }

    Variants {
        model: root.activeTimeouts

        IdleMonitor {
            required property var modelData

            enabled: {
                if (!root.enabled || !(modelData.enabled ?? true))
                    return false;
                if (modelData.inhibitWhenAudio && root.hasPlayer)
                    return false;
                if (modelData.inhibitWhenCharging && root.isCharging)
                    return false;
                return true;
            }
            timeout: modelData.timeout
            respectInhibitors: modelData.respectInhibitors ?? true
            onIsIdleChanged: root.handleIdleAction(isIdle ? modelData.idleAction : modelData.returnAction)
        }
    }
}
