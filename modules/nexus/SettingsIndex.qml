pragma Singleton

import QtQuick

// Indice da busca do Nexus: uma entrada por linha/grupo que alguem procuraria
// pelo nome. `keywords` sao sinonimos (o que o usuario digita, nao o nome
// tecnico). Ao criar uma linha nova numa pagina, acrescente aqui.
//
// page = id do PageRegistry; sub = indice da subpagina no StackPage (0 = a
// pagina principal).
QtObject {
    id: root

    readonly property list<var> entries: [
        // Home
        { page: "home", sub: 0, title: qsTr("Overview"), subtitle: qsTr("Status of network, sound, battery, storage, updates"), keywords: "dashboard summary status home" },

        // Network
        { page: "network", sub: 0, title: qsTr("Wi-Fi"), subtitle: qsTr("Turn on, connect to a network"), keywords: "wireless wlan internet ssid" },
        { page: "network", sub: 0, title: qsTr("Ethernet"), subtitle: qsTr("Wired connection, IP address"), keywords: "cable lan wired ip" },
        { page: "network", sub: 0, title: qsTr("VPN"), subtitle: qsTr("Providers, connect"), keywords: "tunnel wireguard netbird tailscale proxy" },
        { page: "network", sub: 5, title: qsTr("All networks"), subtitle: qsTr("Every Wi-Fi network in range"), keywords: "scan list wifi" },
        { page: "network", sub: 6, title: qsTr("Saved networks"), subtitle: qsTr("Known Wi-Fi networks, forget"), keywords: "known remembered forget password" },
        { page: "network", sub: 2, title: qsTr("Add network"), subtitle: qsTr("Hidden network"), keywords: "hidden ssid manual" },

        // Devices
        { page: "devices", sub: 0, title: qsTr("Bluetooth"), subtitle: qsTr("Turn on, paired devices"), keywords: "bt headphones earbuds buds controller" },
        { page: "devices", sub: 2, title: qsTr("Pair new device"), subtitle: qsTr("Bluetooth pairing"), keywords: "add connect pairing discover" },
        { page: "devices", sub: 0, title: qsTr("Peripheral batteries"), subtitle: qsTr("Keyboard, mouse, headphones charge"), keywords: "battery charge azoth razer naga mouse keyboard level" },
        { page: "devices", sub: 0, title: qsTr("Mouse DPI"), subtitle: qsTr("Sensitivity, polling rate, sleep (Razer)"), keywords: "dpi mouse razer naga polling hz sleep idle sensitivity" },
        { page: "devices", sub: 0, title: qsTr("Keyboard lighting"), subtitle: qsTr("RGB modes, theme colour, laptop keyboard light"), keywords: "rgb lighting backlight azoth keyboard light led colour aura" },
        { page: "devices", sub: 0, title: qsTr("Keyboard layout"), subtitle: qsTr("Language of the keyboard"), keywords: "keymap abnt br us international typing" },
        { page: "devices", sub: 0, title: qsTr("Key repeat"), subtitle: qsTr("Repeat rate and delay"), keywords: "typing hold delay rate keyboard" },
        { page: "devices", sub: 0, title: qsTr("Pointer speed"), subtitle: qsTr("Mouse and touchpad sensitivity"), keywords: "mouse sensitivity cursor fast slow dpi" },
        { page: "devices", sub: 0, title: qsTr("Mouse acceleration"), subtitle: qsTr("Flat or adaptive"), keywords: "accel profile flat adaptive precision" },
        { page: "devices", sub: 0, title: qsTr("Natural scrolling"), subtitle: qsTr("Touchpad scroll direction"), keywords: "touchpad reverse scroll direction" },
        { page: "devices", sub: 0, title: qsTr("Sharing"), subtitle: qsTr("Send files to phones and computers nearby"), keywords: "share send receive files localsend snapdrop airdrop phone transfer" },
        { page: "devices", sub: 0, title: qsTr("Cameras"), subtitle: qsTr("Webcam and infrared camera"), keywords: "webcam video ir camera v4l" },

        // Display
        { page: "display", sub: 0, title: qsTr("Scale"), subtitle: qsTr("Make everything bigger or smaller"), keywords: "zoom size text bigger smaller hidpi dpi scaling" },
        { page: "display", sub: 0, title: qsTr("Resolution & refresh rate"), subtitle: qsTr("Screen mode, Hz"), keywords: "resolution hz refresh rate fps mode 240 144 60" },
        { page: "display", sub: 0, title: qsTr("Use this display"), subtitle: qsTr("Turn a monitor on or off"), keywords: "disable enable monitor screen off external hdmi" },
        { page: "display", sub: 0, title: qsTr("Brightness"), subtitle: qsTr("Screen brightness"), keywords: "backlight dim light ddc" },
        { page: "display", sub: 0, title: qsTr("Text size for X11 apps"), subtitle: qsTr("Steam and games font size"), keywords: "xft dpi steam xwayland font size" },
        { page: "display", sub: 0, title: qsTr("Arrange displays"), subtitle: qsTr("Position and mirroring (nwg-displays)"), keywords: "arrange position mirror layout nwg" },

        // Sound
        { page: "sound", sub: 0, title: qsTr("Output device"), subtitle: qsTr("Speakers, headphones, volume"), keywords: "speaker headphones volume sink output audio" },
        { page: "sound", sub: 0, title: qsTr("Input device"), subtitle: qsTr("Microphone, input volume"), keywords: "mic microphone input source record" },
        { page: "sound", sub: 0, title: qsTr("Audio scene"), subtitle: qsTr("Precise, spatial, cinematic"), keywords: "spatial surround hrtf cinematic scene profile" },
        { page: "sound", sub: 0, title: qsTr("Playing now"), subtitle: qsTr("Which app plays on which device"), keywords: "routing apps streams playback qpwgraph" },
        { page: "sound", sub: 0, title: qsTr("Recording now"), subtitle: qsTr("Which app uses the microphone"), keywords: "routing mic discord recording capture" },
        { page: "sound", sub: 0, title: qsTr("Effects"), subtitle: qsTr("EasyEffects presets, bypass"), keywords: "easyeffects equalizer eq preset noise" },
        { page: "sound", sub: 0, title: qsTr("Microphone hardware gain"), subtitle: qsTr("Boost +30 / +40 / +50 dB"), keywords: "mic gain boost clipping loud quiet" },
        { page: "sound", sub: 1, title: qsTr("App volumes"), subtitle: qsTr("Volume per app"), keywords: "mixer per app volume stream" },

        // Power
        { page: "power", sub: 0, title: qsTr("Battery"), subtitle: qsTr("Charge, time left, power draw"), keywords: "battery charge percent watts time remaining" },
        { page: "power", sub: 0, title: qsTr("Performance profile"), subtitle: qsTr("Quiet, balanced, performance"), keywords: "power mode asus profile fan silent turbo performance quiet balanced" },
        { page: "power", sub: 0, title: qsTr("Charge limit"), subtitle: qsTr("Stop charging at 60 / 80 / 100%"), keywords: "battery lifespan limit 80 charging threshold" },
        { page: "power", sub: 0, title: qsTr("Battery health"), subtitle: qsTr("Capacity compared with new"), keywords: "health wear capacity cycles" },
        { page: "power", sub: 0, title: qsTr("Graphics mode"), subtitle: qsTr("Integrated, hybrid, dedicated GPU"), keywords: "gpu nvidia mux dgpu igpu supergfx hybrid integrated" },
        { page: "power", sub: 0, title: qsTr("Hibernate"), subtitle: qsTr("Save session to disk"), keywords: "hibernate sleep suspend resume swap" },

        // System
        { page: "system", sub: 0, title: qsTr("Resources"), subtitle: qsTr("CPU, GPU, memory, temperatures"), keywords: "cpu gpu ram memory temperature usage load monitor" },
        { page: "system", sub: 0, title: qsTr("Top processes"), subtitle: qsTr("What uses CPU and memory, end a process"), keywords: "processes task manager kill end app frozen" },
        { page: "system", sub: 0, title: qsTr("Failed services"), subtitle: qsTr("Services that stopped with an error"), keywords: "systemd units services failed restart" },
        { page: "system", sub: 0, title: qsTr("Errors since boot"), subtitle: qsTr("Recent errors in the system log"), keywords: "logs journal errors journalctl" },

        // Storage
        { page: "storage", sub: 0, title: qsTr("Disk usage"), subtitle: qsTr("Free space per partition"), keywords: "disk space free full partition" },
        { page: "storage", sub: 0, title: qsTr("Safe cleanups"), subtitle: qsTr("Package cache, journal, trash"), keywords: "clean cache trash free space pacman flatpak" },
        { page: "storage", sub: 0, title: qsTr("Largest folders"), subtitle: qsTr("What takes the most space"), keywords: "big folders baobab size" },
        { page: "storage", sub: 1, title: qsTr("Browse disk usage"), subtitle: qsTr("Folder tree, largest first"), keywords: "tree browse folders files baobab du size explore" },

        // Security
        { page: "security", sub: 0, title: qsTr("Face recognition"), subtitle: qsTr("Howdy models, turn off"), keywords: "face howdy unlock camera biometric login" },
        { page: "security", sub: 0, title: qsTr("PIN"), subtitle: qsTr("Unlock with a PIN"), keywords: "pin code unlock password" },
        { page: "security", sub: 0, title: qsTr("Lock screen"), subtitle: qsTr("Unlock methods, notifications"), keywords: "lock screen unlock method" },

        // Software
        { page: "software", sub: 4, title: qsTr("Updates"), subtitle: qsTr("Pending updates, update everything"), keywords: "update upgrade pacman aur flatpak packages" },
        { page: "software", sub: 0, title: qsTr("Traceability"), subtitle: qsTr("Requirement › design › implementation"), keywords: "requirements design trace" },
        { page: "software", sub: 1, title: qsTr("Installed packages"), subtitle: qsTr("Explicit, orphaned, dependencies"), keywords: "packages orphans installed derived" },

        // Region
        { page: "region", sub: 0, title: qsTr("Time zone"), subtitle: qsTr("Clock region"), keywords: "timezone clock time zone city" },
        { page: "region", sub: 0, title: qsTr("Set time automatically"), subtitle: qsTr("Network time (NTP)"), keywords: "ntp sync time clock automatic" },
        { page: "region", sub: 0, title: qsTr("Language"), subtitle: qsTr("Shell language, system locale"), keywords: "language locale translation" },
        { page: "region", sub: 0, title: qsTr("Weather location"), subtitle: qsTr("Location for the weather widget"), keywords: "weather city location forecast" },
        { page: "region", sub: 0, title: qsTr("Units"), subtitle: qsTr("Temperature units, clock format"), keywords: "celsius fahrenheit 24h 12h units clock format" },

        // Personalization
        { page: "appearance", sub: 0, title: qsTr("Dark theme"), subtitle: qsTr("Light or dark"), keywords: "dark light mode theme night" },
        { page: "appearance", sub: 3, title: qsTr("Theme"), subtitle: qsTr("Colour scheme: catppuccin, gruvbox, onedark, wallpaper colours"), keywords: "theme colours colors scheme palette catppuccin gruvbox onedark rosepine dynamic wallpaper accent" },
        { page: "appearance", sub: 1, title: qsTr("Wallpaper"), subtitle: qsTr("Choose wallpaper"), keywords: "background wallpaper image picture" },
        { page: "appearance", sub: 0, title: qsTr("Transparency"), subtitle: qsTr("Translucent panels"), keywords: "transparent blur opacity" },
        { page: "panels", sub: 2, title: qsTr("Taskbar"), subtitle: qsTr("Bar components, clock, tray"), keywords: "bar taskbar panel tray clock workspaces" },
        { page: "panels", sub: 1, title: qsTr("Dashboard"), subtitle: qsTr("Tabs, performance widgets"), keywords: "dashboard widgets" },
        { page: "panels", sub: 8, title: qsTr("Tray icons"), subtitle: qsTr("Show or hide app icons in the bar (Spotify, Discord…)"), keywords: "tray icons systray hide show spotify discord steam bar" },
        { page: "panels", sub: 3, title: qsTr("Launcher"), subtitle: qsTr("App launcher options"), keywords: "launcher search apps menu" },
        { page: "windows", sub: 0, title: qsTr("Gaps"), subtitle: qsTr("Space between windows"), keywords: "gaps windows tiling spacing border" },
        { page: "apps", sub: 0, title: qsTr("Default applications"), subtitle: qsTr("Terminal, file manager, media"), keywords: "default terminal browser file manager" },
        { page: "apps", sub: 1, title: qsTr("All apps"), subtitle: qsTr("Favourites, hidden apps"), keywords: "apps favourite hide" },
        { page: "shell", sub: 1, title: qsTr("Notifications"), subtitle: qsTr("Toasts, notification behaviour"), keywords: "notifications toast popup do not disturb" },
        { page: "shell", sub: 0, title: qsTr("Volume & brightness steps"), subtitle: qsTr("Step size for keys"), keywords: "volume step brightness step keys" },

        // About
        { page: "about", sub: 0, title: qsTr("System information"), subtitle: qsTr("Hardware, versions, copy for bug reports"), keywords: "about specs version kernel hardware copy info" }
    ]

    function normalize(text: string): string {
        return (text ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
    }

    // Todas as palavras precisam casar em algum campo; pontuacao favorece o
    // titulo (3) sobre sinonimos (2) e subtitulo/pagina (1).
    function search(query: string): list<var> {
        const words = root.normalize(query).split(/\s+/).filter(w => w.length > 0);
        if (words.length === 0)
            return [];

        // Casa pelo INICIO de cada palavra: "scale" acha Scale, nao tailscale.
        const tokens = text => root.normalize(text).split(/[^a-z0-9]+/).filter(t => t.length > 0);
        const hit = (toks, w) => toks.some(t => t.startsWith(w));

        const scored = [];
        for (const e of root.entries) {
            const page = PageRegistry.page(e.page);
            const title = tokens(e.title);
            const keys = tokens(e.keywords);
            const rest = tokens(`${e.subtitle} ${page?.label ?? ""}`);
            let score = 0;
            let all = true;
            for (const w of words) {
                if (hit(title, w))
                    score += title[0]?.startsWith(w) ? 4 : 3;
                else if (hit(keys, w))
                    score += 2;
                else if (hit(rest, w))
                    score += 1;
                else {
                    all = false;
                    break;
                }
            }
            if (all)
                scored.push({ entry: e, page: page, score: score });
        }
        scored.sort((a, b) => b.score - a.score || a.entry.title.localeCompare(b.entry.title));
        return scored.slice(0, 12).map(s => Object.assign({ icon: s.page?.icon ?? "search", pageLabel: s.page?.label ?? "" }, s.entry));
    }
}
