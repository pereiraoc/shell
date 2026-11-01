pragma Singleton

import QtQuick
import Caelestia.I18n

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
        { page: "lan", sub: 1, title: qsTr("Devices on this network"), subtitle: qsTr("Who is connected, names by MAC, open ports, router page, SSH to the Raspberry Pi"), keywords: "lan devices network scan router switch raspberry retropie ssh ports ip mac" },
        { page: "lan", sub: 0, title: qsTr("Network map"), subtitle: qsTr("Internet, router, this PC, VPN; the home network on the NAS"), keywords: "network map diagram topology router gateway home nas monitor" },
        { page: "lan", sub: 0, title: qsTr("Use this PC from your phone or tablet"), subtitle: qsTr("Sunshine + Moonlight: pair with a PIN, stream the screen"), keywords: "remote desktop sunshine moonlight stream phone tablet pin pair control" },
        { page: "network", sub: 0, title: qsTr("Ethernet"), subtitle: qsTr("Wired connection, IP address"), keywords: "cable lan wired ip" },
        { page: "network", sub: 0, title: qsTr("VPN"), subtitle: qsTr("Providers, connect"), keywords: "tunnel wireguard netbird tailscale proxy" },
        { page: "network", sub: 5, title: qsTr("All networks"), subtitle: qsTr("Every Wi-Fi network in range"), keywords: "scan list wifi" },
        { page: "network", sub: 6, title: qsTr("Saved networks"), subtitle: qsTr("Known Wi-Fi networks, forget"), keywords: "known remembered forget password" },
        { page: "network", sub: 2, title: qsTr("Add network"), subtitle: qsTr("Hidden network"), keywords: "hidden ssid manual" },

        // Bluetooth, Keyboard, Mouse
        { page: "bluetooth", sub: 0, title: qsTr("Bluetooth"), subtitle: qsTr("Turn on, paired devices"), keywords: "bt headphones earbuds buds controller" },
        { page: "bluetooth", sub: 2, title: qsTr("Pair new device"), subtitle: qsTr("Bluetooth pairing"), keywords: "add connect pairing discover" },
        { page: "bluetooth", sub: 0, title: qsTr("Peripheral batteries"), subtitle: qsTr("Keyboard, mouse, headphones charge"), keywords: "battery charge azoth razer naga mouse keyboard level" },
        { page: "mouse", sub: 0, tab: "razer-naga-v2-hyperspeed", title: qsTr("Mouse DPI"), subtitle: qsTr("Sensitivity and polling rate (Razer)"), keywords: "dpi mouse razer naga atheris polling hz sensitivity" },
        { page: "mouse", sub: 0, tab: "razer-naga-v2-hyperspeed", title: qsTr("Mouse buttons"), subtitle: qsTr("Remap side buttons, DPI stages, sleep, low battery"), keywords: "razer naga atheris side buttons remap macro keys shortcut dpi stages sleep idle battery warning" },
        { page: "keyboard", sub: 0, tab: "laptop", title: qsTr("Keyboard lighting"), subtitle: qsTr("RGB effect, colours and speed — laptop keyboard and Azoth"), keywords: "rgb lighting backlight azoth keyboard light led colour color aura effect breathing wave pulse boot sleep" },
        { page: "keyboard", sub: 0, tab: "general", title: qsTr("Keyboard layout"), subtitle: qsTr("Language of the keyboard"), keywords: "keymap abnt br us international typing" },
        { page: "keyboard", sub: 0, tab: "general", title: qsTr("Key repeat"), subtitle: qsTr("Repeat rate and delay"), keywords: "typing hold delay rate keyboard" },
        { page: "keyboard", sub: 0, tab: "shortcuts", title: qsTr("Keyboard shortcuts"), subtitle: qsTr("Every Hyprland and Caelestia key binding"), keywords: "shortcuts keybinds hotkeys atalhos teclas binds help cheat sheet super slash" },
        { page: "keyboard", sub: 0, tab: "laptop", title: qsTr("Laptop keys"), subtitle: qsTr("M1–M4 and the Fn row: what each key does; Fn + F11 action"), keywords: "fn m1 m2 m3 m4 rog hotkeys sleep suspend touchpad mirror display airplane aura backlight laptop" },
        { page: "mouse", sub: 0, tab: "general", title: qsTr("Pointer speed"), subtitle: qsTr("Mouse and touchpad sensitivity"), keywords: "mouse sensitivity cursor fast slow dpi" },
        { page: "mouse", sub: 0, tab: "general", title: qsTr("Mouse acceleration"), subtitle: qsTr("Flat or adaptive"), keywords: "accel profile flat adaptive precision" },
        { page: "mouse", sub: 0, tab: "general", title: qsTr("Natural scrolling"), subtitle: qsTr("Mouse and touchpad scroll direction"), keywords: "touchpad reverse scroll direction wheel" },
        { page: "mouse", sub: 0, tab: "general", title: qsTr("Scroll speed"), subtitle: qsTr("Mouse wheel and touchpad"), keywords: "scroll factor wheel fast slow touchpad" },
        { page: "mouse", sub: 0, tab: "touchpad", title: qsTr("Touchpad"), subtitle: qsTr("Tap to click, ignore while typing"), keywords: "tap click palm typing dwt trackpad" },
        { page: "mouse", sub: 0, tab: "general", title: qsTr("Left-handed mouse"), subtitle: qsTr("Swap left and right buttons"), keywords: "left handed swap buttons" },
        { page: "bluetooth", sub: 0, title: qsTr("Sharing"), subtitle: qsTr("Send files to phones and computers nearby"), keywords: "share send receive files localsend snapdrop airdrop phone transfer" },
        { page: "camera", sub: 0, tab: "general", title: qsTr("Camera"), subtitle: qsTr("Preview, brightness, exposure, white balance, anti-flicker"), keywords: "webcam video ir camera v4l preview brightness contrast exposure white balance flicker privacy in use" },

        { page: "sound", sub: 0, tab: "output", title: qsTr("Headphone modes"), subtitle: qsTr("Noise cancelling, ambient sound, equalizer, gestures"), keywords: "anc noise cancelling ambient transparency sony wh-1000xm5 wf-1000xm5 huawei freeclip buds earbuds equalizer eq speak to chat low latency gesture tap" },

        // Display
        { page: "display", sub: 0, tab: "general", title: qsTr("Scale"), subtitle: qsTr("Make everything bigger or smaller"), keywords: "zoom size text bigger smaller hidpi dpi scaling" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Resolution & refresh rate"), subtitle: qsTr("Screen mode, Hz"), keywords: "resolution hz refresh rate fps mode 240 144 60" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Use this display"), subtitle: qsTr("Turn a monitor on or off"), keywords: "disable enable monitor screen off external hdmi" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Bar position"), subtitle: qsTr("Bar on the left or right, per display"), keywords: "taskbar side left right mirror flip panel" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Mirror the wallpaper visualiser"), subtitle: qsTr("Visualiser follows the bar side"), keywords: "prism visualizer flip mirror audio bars" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Brightness"), subtitle: qsTr("Screen brightness"), keywords: "backlight dim light ddc" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Text size for X11 apps"), subtitle: qsTr("Steam and games font size"), keywords: "xft dpi steam xwayland font size" },
        { page: "display", sub: 0, tab: "general", title: qsTr("Tablet as a monitor"), subtitle: qsTr("Android tablet over USB as an extra display"), keywords: "tablet android usb cable vnc avnc second screen extra display adb" },
        { page: "display", sub: 0, title: qsTr("Arrange displays"), subtitle: qsTr("Position and mirroring (nwg-displays)"), keywords: "arrange position mirror layout nwg" },

        // Sound
        { page: "sound", sub: 0, tab: "output", title: qsTr("Output device"), subtitle: qsTr("Speakers, headphones, volume"), keywords: "speaker headphones volume sink output audio" },
        { page: "sound", sub: 0, tab: "input", title: qsTr("Input device"), subtitle: qsTr("Microphone, input volume"), keywords: "mic microphone input source record" },
        { page: "sound", sub: 0, tab: "output", title: qsTr("Audio scene"), subtitle: qsTr("Precise, spatial, cinematic"), keywords: "spatial surround hrtf cinematic scene profile" },
        { page: "sound", sub: 0, tab: "output", title: qsTr("Playing now"), subtitle: qsTr("Which app plays on which device"), keywords: "routing apps streams playback qpwgraph" },
        { page: "sound", sub: 0, tab: "input", title: qsTr("Recording now"), subtitle: qsTr("Which app uses the microphone"), keywords: "routing mic discord recording capture" },
        { page: "sound", sub: 0, tab: "effects", title: qsTr("Effects"), subtitle: qsTr("EasyEffects presets, bypass"), keywords: "easyeffects equalizer eq preset noise" },
        { page: "sound", sub: 0, tab: "input", title: qsTr("Microphone hardware gain"), subtitle: qsTr("Boost +30 / +40 / +50 dB"), keywords: "mic gain boost clipping loud quiet" },
        { page: "sound", sub: 1, title: qsTr("App volumes"), subtitle: qsTr("Volume per app"), keywords: "mixer per app volume stream" },

        // Power
        { page: "power", sub: 0, title: qsTr("Battery"), subtitle: qsTr("Charge, time left, power draw"), keywords: "battery charge percent watts time remaining" },
        { page: "power", sub: 0, title: qsTr("Performance profile"), subtitle: qsTr("Quiet, balanced, performance"), keywords: "power mode asus profile fan silent turbo performance quiet balanced" },
        { page: "power", sub: 0, title: qsTr("Charge limit"), subtitle: qsTr("Stop charging at 60 / 80 / 100%"), keywords: "battery lifespan limit 80 charging threshold" },
        { page: "power", sub: 0, title: qsTr("Battery health"), subtitle: qsTr("Capacity compared with new"), keywords: "health wear capacity cycles" },
        { page: "power", sub: 0, title: qsTr("Graphics mode"), subtitle: qsTr("Integrated, hybrid, dedicated GPU"), keywords: "gpu nvidia mux dgpu igpu supergfx hybrid integrated" },
        { page: "power", sub: 0, title: qsTr("Hibernate"), subtitle: qsTr("Save session to disk"), keywords: "hibernate sleep suspend resume swap" },

        // System
        { page: "system", sub: 0, tab: "overview", title: qsTr("Resources"), subtitle: qsTr("CPU, GPU, memory, temperatures"), keywords: "cpu gpu ram memory temperature usage load monitor" },
        { page: "system", sub: 0, tab: "processes", title: qsTr("Top processes"), subtitle: qsTr("What uses CPU and memory, end a process"), keywords: "processes task manager kill end app frozen" },
        { page: "system", sub: 0, tab: "health", title: qsTr("Failed services"), subtitle: qsTr("Services that stopped with an error"), keywords: "systemd units services failed restart" },
        { page: "system", sub: 0, tab: "logs", title: qsTr("Errors since boot"), subtitle: qsTr("Recent errors in the system log"), keywords: "logs journal errors journalctl" },
        { page: "system", sub: 0, tab: "boot", title: qsTr("Boot time"), subtitle: qsTr("What ran until the desktop, slowest first"), keywords: "boot slow startup systemd-analyze blame critical chain time" },
        { page: "system", sub: 0, tab: "logs", title: qsTr("System log"), subtitle: qsTr("journalctl: errors, warnings, kernel, search"), keywords: "logs journal journalctl dmesg kernel errors warnings search" },

        // Storage
        { page: "storage", sub: 0, tab: "partitions", title: qsTr("Disk usage"), subtitle: qsTr("Free space per partition"), keywords: "disk space free full partition" },
        { page: "storage", sub: 0, tab: "cleanup", title: qsTr("Safe cleanups"), subtitle: qsTr("Package cache, journal, trash"), keywords: "clean cache trash free space pacman flatpak" },
        { page: "storage", sub: 0, tab: "largest", title: qsTr("Largest folders"), subtitle: qsTr("What takes the most space"), keywords: "big folders baobab size" },
        { page: "storage", sub: 1, title: qsTr("Browse disk usage"), subtitle: qsTr("Folder tree, largest first"), keywords: "tree browse folders files baobab du size explore" },
        { page: "server", sub: 0, tab: "overview", title: Tr.tr("Server overview"), subtitle: Tr.tr("NAS health; open photos, cloud, movies, music"), keywords: "nas server home immich nextcloud jellyfin navidrome photos cloud movies music open" },
        { page: "server", sub: 0, tab: "services", title: Tr.tr("Server services"), subtitle: Tr.tr("Start, stop and restart the Docker stacks"), keywords: "nas docker stack start stop restart immich nextcloud jellyfin navidrome" },
        { page: "server", sub: 0, tab: "network", title: Tr.tr("Home network monitor"), subtitle: Tr.tr("Who is on the network, new devices, mark as known"), keywords: "nas network monitor netalertx new unknown devices known alert ntfy intruder wifi" },
        { page: "server", sub: 0, tab: "home", title: Tr.tr("Home (Home Assistant)"), subtitle: Tr.tr("Smart plugs, lights, power use, toggles"), keywords: "home assistant smart home iot plug light power energy watt toggle zigbee mqtt casa" },
        { page: "server", sub: 0, tab: "storage", title: Tr.tr("Server storage"), subtitle: Tr.tr("HDs in RAID1, SMART, scrub, shared folders"), keywords: "nas disks hdd raid btrfs smart scrub samba smb nextcloud folders thunar" },
        { page: "server", sub: 0, tab: "system", title: Tr.tr("Server system"), subtitle: Tr.tr("NixOS, watchdog, fans, rebuild, reboot"), keywords: "nas nixos flake rebuild reboot poweroff watchdog fans tailscale netbird vpn" },
        { page: "server", sub: 0, tab: "logs", title: Tr.tr("Server logs"), subtitle: Tr.tr("Journal of a unit on the NAS"), keywords: "nas logs journal journalctl docker containers" },

        // Security
        { page: "security", sub: 0, tab: "unlock", title: qsTr("Face recognition"), subtitle: qsTr("Howdy models, turn off"), keywords: "face howdy unlock camera biometric login" },
        { page: "security", sub: 0, tab: "unlock", title: qsTr("PIN"), subtitle: qsTr("Unlock with a PIN"), keywords: "pin code unlock password" },
        { page: "security", sub: 0, tab: "lock", title: qsTr("Lock screen"), subtitle: qsTr("Unlock methods, notifications"), keywords: "lock screen unlock method" },

        // Software
        { page: "software", sub: 4, title: qsTr("Updates"), subtitle: qsTr("Pending updates, update everything"), keywords: "update upgrade pacman aur flatpak packages" },
        { page: "software", sub: 0, tab: "traceability", title: qsTr("Traceability"), subtitle: qsTr("Requirement › design › implementation"), keywords: "requirements design trace" },
        { page: "software", sub: 1, title: qsTr("Installed packages"), subtitle: qsTr("Explicit, orphaned, dependencies"), keywords: "packages orphans installed derived" },

        // Region
        { page: "region", sub: 0, tab: "time", title: qsTr("Time zone"), subtitle: qsTr("Clock region"), keywords: "timezone clock time zone city" },
        { page: "region", sub: 0, tab: "time", title: qsTr("Set time automatically"), subtitle: qsTr("Network time (NTP)"), keywords: "ntp sync time clock automatic" },
        { page: "region", sub: 0, tab: "language", title: qsTr("Language"), subtitle: qsTr("Shell language, system locale"), keywords: "language locale translation" },
        { page: "region", sub: 0, tab: "region", title: qsTr("Weather places"), subtitle: qsTr("Several places for the weather widget, switched in the dashboard"), keywords: "weather city location places forecast automatic" },
        { page: "region", sub: 0, tab: "region", title: qsTr("Units"), subtitle: qsTr("Temperature units, clock format"), keywords: "celsius fahrenheit 24h 12h units clock format" },

        // Personalization
        { page: "appearance", sub: 0, title: qsTr("Dark theme"), subtitle: qsTr("Light or dark"), keywords: "dark light mode theme night" },
        { page: "appearance", sub: 3, title: qsTr("Theme"), subtitle: qsTr("Colour scheme: catppuccin, gruvbox, onedark, wallpaper colours"), keywords: "theme colours colors scheme palette catppuccin gruvbox onedark rosepine dynamic wallpaper accent" },
        { page: "appearance", sub: 1, title: qsTr("Wallpaper"), subtitle: qsTr("Choose wallpaper"), keywords: "background wallpaper image picture" },
        { page: "appearance", sub: 0, title: qsTr("Transparency"), subtitle: qsTr("Translucent panels"), keywords: "transparent blur opacity" },
        { page: "panels", sub: 2, title: qsTr("Taskbar"), subtitle: qsTr("Bar components, clock, tray"), keywords: "bar taskbar panel tray clock workspaces" },
        { page: "panels", sub: 1, title: qsTr("Dashboard"), subtitle: qsTr("Tabs, performance widgets"), keywords: "dashboard widgets" },
        { page: "panels", sub: 8, title: qsTr("Tray icons"), subtitle: qsTr("Show or hide app icons in the bar (Spotify, Discord…)"), keywords: "tray icons systray hide show spotify discord steam bar" },
        { page: "panels", sub: 11, title: qsTr("Shortcuts"), subtitle: qsTr("Your commands and Obsidian vaults in the dashboard"), keywords: "shortcuts dashboard obsidian vault command widget launch" },
        { page: "panels", sub: 12, title: qsTr("Games"), subtitle: qsTr("Steam games to launch from the dashboard"), keywords: "games steam dashboard widget favourite launch" },
        { page: "panels", sub: 3, title: qsTr("Launcher"), subtitle: qsTr("App launcher options"), keywords: "launcher search apps menu" },
        { page: "windows", sub: 0, title: qsTr("Gaps"), subtitle: qsTr("Space between windows"), keywords: "gaps windows tiling spacing border" },
        { page: "apps", sub: 0, title: qsTr("Default applications"), subtitle: qsTr("Terminal, file manager, media"), keywords: "default terminal browser file manager" },
        { page: "apps", sub: 1, title: qsTr("All apps"), subtitle: qsTr("Favourites, hidden apps"), keywords: "apps favourite hide" },
        { page: "shell", sub: 1, title: qsTr("Notifications"), subtitle: qsTr("Toasts, notification behaviour"), keywords: "notifications toast popup do not disturb" },
        { page: "notifications", sub: 0, tab: "history", title: qsTr("Notification history"), subtitle: qsTr("Everything that was shown, searchable"), keywords: "notifications history log past search" },
        { page: "notifications", sub: 0, tab: "apps", title: qsTr("Block notifications from an app"), subtitle: qsTr("Per-app block and icon"), keywords: "notifications block mute app icon silence" },
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
