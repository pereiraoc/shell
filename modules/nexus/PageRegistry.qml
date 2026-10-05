pragma Singleton

import QtQuick

// Menu do Nexus. A ordem aqui e a ordem na navegacao; o componente de cada
// pagina e casado por `id` em PageCompRegistry (nunca por indice). Quem abre o
// Nexus numa pagina usa NexusState.openPage(id) ou indexOf(id).
//
// Grupos seguem a pesquisa de IA de paineis de controle (Win11, GNOME 46,
// KDE 6, Android 16): conexoes -> hardware -> sistema -> personalizacao ->
// About. Spec: docs/superpowers/specs/2026-10-04-painel-de-controle-nexus-design.md
// (repositorio caelestia-arch-setup).
QtObject {
    id: root

    readonly property list<var> pages: [
        {
            id: "home",
            label: qsTr("Home"),
            icon: "home",
            description: qsTr("Status at a glance"),
            group: ""
        },

        {
            id: "network",
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet, VPN"),
            group: qsTr("Connectivity")
        },
        {
            id: "bluetooth",
            label: qsTr("Bluetooth"),
            icon: "bluetooth",
            description: qsTr("Devices, pairing, batteries"),
            group: qsTr("Connectivity")
        },

        {
            id: "display",
            label: qsTr("Display"),
            icon: "monitor",
            description: qsTr("Resolution, scale, brightness"),
            group: qsTr("Hardware")
        },
        {
            id: "sound",
            label: qsTr("Sound"),
            icon: "volume_up",
            description: qsTr("Devices, headphones, apps, microphone"),
            group: qsTr("Hardware")
        },
        {
            id: "keyboard",
            label: qsTr("Keyboard"),
            icon: "keyboard",
            description: qsTr("Layout, repeat, lighting"),
            group: qsTr("Hardware")
        },
        {
            id: "mouse",
            label: qsTr("Mouse"),
            icon: "mouse",
            description: qsTr("Pointer, touchpad, gaming mice"),
            group: qsTr("Hardware")
        },
        {
            id: "camera",
            label: qsTr("Camera"),
            icon: "videocam",
            description: qsTr("Preview, picture settings"),
            group: qsTr("Hardware")
        },
        {
            id: "power",
            label: qsTr("Power"),
            icon: "battery_charging_full",
            description: qsTr("Battery, performance, graphics"),
            group: qsTr("Hardware")
        },

        {
            id: "system",
            label: qsTr("System"),
            icon: "memory",
            description: qsTr("Resources, processes, health"),
            group: qsTr("System")
        },
        {
            id: "storage",
            label: qsTr("Storage"),
            icon: "hard_drive",
            description: qsTr("Disk usage, safe cleanups"),
            group: qsTr("System")
        },
        {
            id: "security",
            label: qsTr("Security"),
            icon: "security",
            description: qsTr("PIN, face recognition, lock screen"),
            group: qsTr("System")
        },
        {
            id: "software",
            label: qsTr("Software"),
            icon: "inventory_2",
            description: qsTr("Updates, packages, traceability"),
            group: qsTr("System")
        },
        {
            id: "region",
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("Time zone, language, units"),
            group: qsTr("System")
        },

        {
            id: "appearance",
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, fonts, colours"),
            group: qsTr("Personalization")
        },
        {
            id: "panels",
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard, taskbar, launcher, sidebar"),
            group: qsTr("Personalization")
        },
        {
            id: "windows",
            label: qsTr("Window management"),
            icon: "select_window",
            description: qsTr("Gaps"),
            group: qsTr("Personalization")
        },
        {
            id: "apps",
            label: qsTr("Apps"),
            icon: "apps",
            description: qsTr("Default apps, favourites, hidden apps"),
            group: qsTr("Personalization")
        },
        {
            id: "shell",
            label: qsTr("Shell behaviour"),
            icon: "tune",
            description: qsTr("Notifications, polling, media"),
            group: qsTr("Personalization")
        },

        {
            id: "about",
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information, versions"),
            group: ""
        }
    ]

    function indexOf(id: string): int {
        return root.pages.findIndex(p => p.id === id);
    }

    function page(id: string): var {
        return root.pages.find(p => p.id === id) ?? null;
    }
}
