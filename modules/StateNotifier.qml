import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Caelestia.I18n

// Avisa mudancas de estado que acontecem sem ninguem ver (regra do projeto,
// 18/10/2026): o perfil de energia muda por Fn+F5 (o kernel 7.x cicla sozinho e
// nem entrega a tecla), pelo asusd ao trocar de tomada ou pela barra -- e o
// usuario so descobria depois. A primeira leitura nao avisa; so as mudancas.
// Notificacao pelo notify-send, com id fixo (-r) para substituir a anterior.
Scope {
    id: root

    property int lastProfile: -1

    function profileName(p: int): string {
        switch (p) {
        case PowerProfile.PowerSaver:
            return Tr.tr("Quiet");
        case PowerProfile.Performance:
            return Tr.tr("Performance");
        default:
            return Tr.tr("Balanced");
        }
    }

    function profileIcon(p: int): string {
        switch (p) {
        case PowerProfile.PowerSaver:
            return "energy_savings_leaf";
        case PowerProfile.Performance:
            return "speed";
        default:
            return "balance";
        }
    }

    Component.onCompleted: root.lastProfile = PowerProfiles.profile

    Connections {
        function onProfileChanged(): void {
            const p = PowerProfiles.profile;
            if (root.lastProfile < 0 || p === root.lastProfile) {
                root.lastProfile = p;
                return;
            }
            root.lastProfile = p;
            notify.command = ["notify-send", "-a", "Caelestia", "-i", root.profileIcon(p), "-r", "7430", "-t", "2500", Tr.tr("Power profile: %1").arg(root.profileName(p))];
            notify.running = true;
        }

        target: PowerProfiles
    }

    Process {
        id: notify
    }
}
