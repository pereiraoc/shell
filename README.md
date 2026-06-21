# Caelestia Shell - Pereiraoc Patch
## caelestia-shell-pereiraoc-patch

[![Status](https://img.shields.io/badge/status-alpha-yellow?style=for-the-badge)](https://github.com/pereiraoc/caelestia-shell-pereiraoc-patch)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue?style=for-the-badge)](LICENSE)
[![Based on](https://img.shields.io/badge/based%20on-caelestia--shell-9ccbfb?style=for-the-badge)](https://github.com/caelestia-dots/shell)

---

## 📚 Documentação

**[👉 Acesse a Documentação Completa](docs/00-index.md)**

A documentação completa do projeto está organizada em `docs/`:
- **[00-index.md](docs/00-index.md)** - Índice e guia de navegação
- **[10-arquitetura.md](docs/10-arquitetura.md)** - Arquitetura e modificações vs upstream
- **[20-troubleshooting.md](docs/20-troubleshooting.md)** - Guia de solução de problemas
- **[99-pendencias.md](docs/99-pendencias.md)** - Tarefas pendentes e roadmap
- **[plan-and-implementation/](docs/plan-and-implementation/)** - Planos detalhados de cada feature

---

## 🎯 Sobre Este Fork

Este é um fork personalizado do [Caelestia Shell](https://github.com/caelestia-dots/shell) criado para adicionar **autenticação biométrica e por PIN no lock screen**.

### ✨ Novos Recursos

- **🔐 Autenticação Facial (Howdy)**: Reconhecimento facial via câmera
- **🔢 Autenticação por PIN**: Teclado numérico para entrada rápida de código
- **🎨 Seletor Visual**: Botões para escolher entre Face, PIN ou Senha
- **🔄 Fallback Inteligente**: Sempre mantém senha tradicional como backup
- **⚡ Rate Limiting**: Proteção contra brute force com lockout temporário
- **📊 Feedback Visual**: Animações e indicadores durante autenticação

### 🆚 Diferenças do Upstream

| Recurso | Upstream | Este Fork |
|---------|----------|-----------|
| Lock Screen Auth | Senha + Fingerprint | Senha + Face (Howdy) + PIN |
| Auth Method Selector | Não | ✅ Botões visuais |
| PIN Keyboard | Não | ✅ Teclado numérico |
| Face Auth Feedback | Não | ✅ Indicador visual |
| Rate Limiting | Básico | ✅ Avançado + lockout |

---

## 📸 Screenshots

> 🚧 Em desenvolvimento - screenshots serão adicionados em breve

---

## 📦 Instalação

### Pré-requisitos

**Dependências do Caelestia Shell original**:
```bash
# Ver lista completa em:
# https://github.com/caelestia-dots/shell#manual-installation
```

**Dependências Adicionais deste Fork**:
```bash
# Howdy (reconhecimento facial)
paru -S howdy-git

# V4L Utils (acesso à câmera)
sudo pacman -S v4l-utils

# Python OpenCV (detecção facial)
sudo pacman -S python-opencv
```

### Instalação Manual

```bash
# 1. Clonar este patch
cd ~/.config/quickshell
git clone https://github.com/pereiraoc/caelestia-shell-pereiraoc-patch.git caelestia

# 2. Build e instalação
cd caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build

# 3. Configurar Howdy
sudo howdy add  # Adicionar seu rosto
sudo howdy test # Testar reconhecimento

# 4. Reiniciar shell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

### Instalação via caelestia-arch-setup

Se você usa o [caelestia-arch-setup](https://github.com/pereiraoc/caelestia-arch-setup):

```bash
# Script de instalação automática (em breve)
bash scripts/stage3/35-caelestia-fork-install.sh
```

---

## ⚙️ Configuração

### Configuração Básica

Edite `~/.config/caelestia/shell.json` — este fork adiciona a seção `lock.auth` (face/PIN):

```json
{
  "lock": {
    "recolourLogo": false,
    "enableFprint": true,
    "maxFprintTries": 3,
    "auth": {
      "enableFaceAuth": true,
      "enablePinAuth": true,
      "defaultMethod": "face",
      "faceAuthTimeout": 5000,
      "maxFaceRetries": 3,
      "pinLength": 4,
      "pinAutoSubmit": true,
      "rateLimitDelay": 2000,
      "lockoutAfterTries": 5,
      "lockoutDuration": 30000
    }
  }
}
```

The profile picture for the dashboard is read from the file `~/.face`, so to set
it you can copy your image to there or set it via the dashboard.

The wallpapers for the wallpaper switcher are read from `~/Pictures/Wallpapers`
by default. To change it, change the wallpapers path in `~/.config/caelestia/shell.json`.

To set the wallpaper, you can use the command `caelestia wallpaper`. Use `caelestia wallpaper -h` for more info about
the command.

## Updating

If installed via the AUR package, simply update your system (e.g. using `yay`).

If installed manually, you can update by running `git pull` in `$XDG_CONFIG_HOME/quickshell/caelestia`.

```sh
cd $XDG_CONFIG_HOME/quickshell/caelestia
git pull
```

## Configuring

All configuration options should be put in `~/.config/caelestia/shell.json`. This file is _not_ created by
default, you must create it manually. Options that you omit from the config file will use their default
values.

### Per-monitor configuration

You can configure options per-monitor in `~/.config/caelestia/monitors/<screen-name>/shell.json`. Options
set in this file will **override** the respective options in the global config. Otherwise, the options will
use their values from the global config.

For example, to disable the bar on DP-1:

**`~/.config/caelestia/monitors/DP-1/shell.json`**

```json
{
    "bar": {
        "persistent": false
    }
}
```

> [!NOTE]
> Not all options are respect per-monitor overrides. Most notably, the following options will only read
> from the global config, and ignore the respective option in per-monitor config files.
>
> <details><summary>Ignored options</summary>
>
> - `appearance` (`anim`, `transparency`)
> - `general` (`logo`, `apps`, `idle`, `battery`)
> - `bar.workspaces` (`perMonitorWorkspaces`, `specialWorkspaceIcons`, `windowIcons`)
> - `bar.tray` (`iconSubs`, `hiddenIcons`)
> - `dashboard` (`mediaUpdateInterval`, `resourceUpdateInterval`)
> - `launcher` (`specialPrefix`, `actionPrefix`, `enableDangerousActions`, `vimKeybinds`,
>   `favouriteApps`, `hiddenApps`, `actions`)
> - `launcher.useFuzzy` (`apps`, `actions`, `schemes`, `variants`, `wallpapers`)
> - `notifs` (`expire`, `fullscreen`, `defaultExpireTimeout`, `fullscreenExpireTimeout`, `actionOnClick`)
> - `lock` (`enableFprint`, `maxFprintTries`)
> - `nexus` (`networkRescanInterval`)
> - `utilities.toasts` (all except `fullscreen`)
> - `utilities.vpn` (`enabled`, `provider`)
> - `services` (`weatherLocation`, `useFahrenheit`, `useFahrenheitPerformance`, `useTwelveHourClock`,
>   `gpuType`, `visualiserBars`, `audioIncrement`, `brightnessIncrement`, `maxVolume`, `smartScheme`,
>   `defaultPlayer`, `playerAliases`, `lyricsBackend`)
> - `paths` (`wallpaperDir`, `lyricsDir`)
>
> </details>

### Example configuration

> [!NOTE]
> The example configuration includes ALL configuration options in `shell.json`. You are
> **not** recommended to copy and paste this entire configuration into `shell.json`.
> This is meant to serve as a reference of all the available options, and you should
> only add the ones you want to change to `shell.json`.

<details><summary>Example</summary>

```json
{
    "enabled": true,
    "appearance": {
        "deformScale": 1,
        "rounding": {
            "scale": 1
        },
        "spacing": {
            "scale": 1
        },
        "padding": {
            "scale": 1
        },
        "font": {
            "scale": 1,
            "clock": "Rubik",
            "workspaces": "Rubik",
            "headline": {
                "family": "GoogleSansFlex",
                "large": { "size": 32, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "medium": { "size": 28, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "small": { "size": 24, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } }
            },
            "title": {
                "family": "GoogleSansFlex",
                "large": { "size": 22, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "medium": { "size": 16, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "small": { "size": 14, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } }
            },
            "body": {
                "family": "GoogleSansFlex",
                "large": { "size": 16, "weight": 400, "italic": false, "vaxes": { "ROND": 25 } },
                "medium": { "size": 14, "weight": 400, "italic": false, "vaxes": { "ROND": 25 } },
                "small": { "size": 12, "weight": 400, "italic": false, "vaxes": { "ROND": 25 } }
            },
            "label": {
                "family": "GoogleSansFlex",
                "large": { "size": 14, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "medium": { "size": 12, "weight": 500, "italic": false, "vaxes": { "ROND": 25 } },
                "small": { "size": 11, "weight": 400, "italic": false, "vaxes": { "ROND": 25 } }
            },
            "mono": {
                "family": "CaskaydiaCove NF",
                "large": { "size": 16, "weight": 400, "italic": false, "vaxes": {} },
                "medium": { "size": 14, "weight": 400, "italic": false, "vaxes": {} },
                "small": { "size": 12, "weight": 400, "italic": false, "vaxes": {} }
            },
            "icon": {
                "family": "Material Symbols Rounded",
                "extraLarge": { "size": 36, "weight": 400, "italic": false, "vaxes": {} },
                "large": { "size": 24, "weight": 400, "italic": false, "vaxes": {} },
                "medium": { "size": 18, "weight": 400, "italic": false, "vaxes": {} },
                "small": { "size": 15, "weight": 400, "italic": false, "vaxes": {} }
            }
        },
        "anim": {
            "durations": {
                "scale": 1
            }
        },
        "transparency": {
            "enabled": false,
            "base": 0.85,
            "layers": 0.4
        }
    },
    "general": {
        "logo": "",
        "showOverFullscreen": false,
        "mediaGifSpeedAdjustment": 300,
        "sessionGifSpeed": 0.7,
        "apps": {
            "terminal": ["foot"],
            "audio": ["pavucontrol"],
            "playback": ["mpv"],
            "explorer": ["thunar"]
        },
        "idle": {
            "lockBeforeSleep": true,
            "inhibitWhenAudio": true,
            "timeouts": [
                {
                    "timeout": 180,
                    "idleAction": "lock"
                },
                {
                    "timeout": 300,
                    "idleAction": "dpms off",
                    "returnAction": "dpms on"
                },
                {
                    "timeout": 600,
                    "idleAction": ["systemctl", "suspend-then-hibernate"]
                }
            ]
        },
        "battery": {
            "warnLevels": [
                {
                    "level": 20,
                    "title": "Low battery",
                    "message": "You might want to plug in a charger",
                    "icon": "battery_android_frame_2"
                },
                {
                    "level": 10,
                    "title": "Did you see the previous message?",
                    "message": "You should probably plug in a charger <b>now</b>",
                    "icon": "battery_android_frame_1"
                },
                {
                    "level": 5,
                    "title": "Critical battery level",
                    "message": "PLUG THE CHARGER RIGHT NOW!!",
                    "icon": "battery_android_alert",
                    "critical": true
                }
            ],
            "criticalLevel": 3
        }
    },
    "background": {
        "enabled": true,
        "wallpaperEnabled": true,
        "desktopClock": {
            "enabled": false,
            "scale": 1.0,
            "position": "bottom-right",
            "invertColors": false,
            "background": {
                "enabled": false,
                "opacity": 0.7,
                "blur": true
            },
            "shadow": {
                "enabled": true,
                "opacity": 0.7,
                "blur": 0.4
            }
        },
        "visualiser": {
            "enabled": false,
            "autoHide": true,
            "blur": false,
            "rounding": 1,
            "spacing": 1
        }
    },
    "bar": {
        "persistent": true,
        "showOnHover": true,
        "dragThreshold": 20,
        "scrollActions": {
            "workspaces": true,
            "volume": true,
            "brightness": true
        },
        "popouts": {
            "activeWindow": true,
            "tray": true,
            "statusIcons": true
        },
        "workspaces": {
            "shown": 5,
            "activeIndicator": true,
            "occupiedBg": false,
            "showWindows": true,
            "showWindowsOnSpecialWorkspaces": true,
            "maxWindowIcons": 5,
            "activeTrail": false,
            "perMonitorWorkspaces": true,
            "label": "  ",
            "occupiedLabel": "󰮯",
            "activeLabel": "󰮯",
            "capitalisation": "preserve",
            "specialWorkspaceIcons": [
                {
                    "name": "steam",
                    "icon": "sports_esports"
                }
            ],
            "windowIcons": [
                {
                    "regex": "steam(_app_(default|[0-9]+))?",
                    "icon": "sports_esports"
                }
            ]
        },
        "activeWindow": {
            "compact": false,
            "inverted": false,
            "showOnHover": true
        },
        "tray": {
            "background": false,
            "recolour": false,
            "compact": false,
            "iconSubs": [],
            "hiddenIcons": []
        },
        "status": {
            "showAudio": false,
            "showMicrophone": false,
            "showKbLayout": false,
            "showNetwork": true,
            "showWifi": true,
            "showBluetooth": true,
            "showBattery": true,
            "showLockStatus": true
        },
        "clock": {
            "background": false,
            "showDate": false,
            "showIcon": true
        },
        "entries": [
            {
                "id": "logo",
                "enabled": true
            },
            {
                "id": "workspaces",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "activeWindow",
                "enabled": true
            },
            {
                "id": "spacer",
                "enabled": true
            },
            {
                "id": "tray",
                "enabled": true
            },
            {
                "id": "clock",
                "enabled": true
            },
            {
                "id": "statusIcons",
                "enabled": true
            },
            {
                "id": "power",
                "enabled": true
            }
        ],
        "excludedScreens": []
    },
    "border": {
        "thickness": 10,
        "rounding": 25,
        "smoothing": 20
    },
    "dashboard": {
        "enabled": true,
        "showOnHover": true,
        "showDashboard": true,
        "showMedia": true,
        "showPerformance": true,
        "showWeather": true,
        "mediaUpdateInterval": 500,
        "resourceUpdateInterval": 1000,
        "dragThreshold": 50,
        "performance": {
            "showBattery": true,
            "showGpu": true,
            "showCpu": true,
            "showMemory": true,
            "showStorage": true,
            "showNetwork": true
        }
    },
    "launcher": {
        "enabled": true,
        "showOnHover": false,
        "maxShown": 7,
        "maxWallpapers": 9,
        "specialPrefix": "@",
        "actionPrefix": ">",
        "enableDangerousActions": false,
        "dragThreshold": 50,
        "vimKeybinds": false,
        "favouriteApps": [],
        "hiddenApps": [],
        "useFuzzy": {
            "apps": false,
            "actions": false,
            "schemes": false,
            "variants": false,
            "wallpapers": false
        },
        "actions": [
            {
                "name": "Calculator",
                "icon": "calculate",
                "description": "Do simple math equations (powered by Qalc)",
                "command": ["autocomplete", "calc"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Scheme",
                "icon": "palette",
                "description": "Change the current colour scheme",
                "command": ["autocomplete", "scheme"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Wallpaper",
                "icon": "image",
                "description": "Change the current wallpaper",
                "command": ["autocomplete", "wallpaper"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Variant",
                "icon": "colors",
                "description": "Change the current scheme variant",
                "command": ["autocomplete", "variant"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Random",
                "icon": "casino",
                "description": "Switch to a random wallpaper",
                "command": ["caelestia", "wallpaper", "-r"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Light",
                "icon": "light_mode",
                "description": "Change the scheme to light mode",
                "command": ["setMode", "light"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Dark",
                "icon": "dark_mode",
                "description": "Change the scheme to dark mode",
                "command": ["setMode", "dark"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Shutdown",
                "icon": "power_settings_new",
                "description": "Shutdown the system",
                "command": ["systemctl", "poweroff"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Reboot",
                "icon": "cached",
                "description": "Reboot the system",
                "command": ["systemctl", "reboot"],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Logout",
                "icon": "exit_to_app",
                "description": "Log out of the current session",
                "command": ["loginctl", "terminate-user", ""],
                "enabled": true,
                "dangerous": true
            },
            {
                "name": "Lock",
                "icon": "lock",
                "description": "Lock the current session",
                "command": ["loginctl", "lock-session"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Sleep",
                "icon": "bedtime",
                "description": "Suspend then hibernate",
                "command": ["systemctl", "suspend-then-hibernate"],
                "enabled": true,
                "dangerous": false
            },
            {
                "name": "Settings",
                "icon": "settings",
                "description": "Configure the shell",
                "command": ["caelestia", "shell", "nexus", "open"],
                "enabled": true,
                "dangerous": false
            }
        ]
    },
    "lock": {
        "recolourLogo": true,
        "enableFprint": true,
        "maxFprintTries": 3,
        "hideNotifs": false
    },
    "nexus": {
        "wallpapersPerRow": 4,
        "networkRescanInterval": 15000
    },
    "notifs": {
        "expire": true,
        "fullscreen": "on",
        "defaultExpireTimeout": 5000,
        "fullscreenExpireTimeout": 2000,
        "clearThreshold": 0.3,
        "expandThreshold": 20,
        "actionOnClick": false,
        "groupPreviewNum": 3,
        "openExpanded": false
    },
    "osd": {
        "enabled": true,
        "hideDelay": 2000,
        "enableBrightness": true,
        "enableMicrophone": false
    },
    "services": {
        "weatherLocation": "",
        "useFahrenheit": false,
        "useFahrenheitPerformance": false,
        "useTwelveHourClock": false,
        "gpuType": "",
        "visualiserBars": 60,
        "audioIncrement": 0.1,
        "brightnessIncrement": 0.1,
        "maxVolume": 1.0,
        "smartScheme": true,
        "defaultPlayer": "Spotify",
        "playerAliases": [{ "from": "com.github.th_ch.youtube_music", "to": "YT Music" }],
        "lyricsBackend": "Auto"
    },
    "session": {
        "enabled": true,
        "dragThreshold": 30,
        "vimKeybinds": false,
        "icons": {
            "logout": "logout",
            "shutdown": "power_settings_new",
            "hibernate": "downloading",
            "reboot": "cached"
        },
        "commands": {
            "logout": ["loginctl", "terminate-user", ""],
            "shutdown": ["systemctl", "poweroff"],
            "hibernate": ["systemctl", "hibernate"],
            "reboot": ["systemctl", "reboot"]
        }
    },
    "sidebar": {
        "enabled": true,
        "dragThreshold": 80
    },
    "utilities": {
        "enabled": true,
        "maxToasts": 4,
        "toasts": {
            "fullscreen": "off",
            "configLoaded": true,
            "chargingChanged": true,
            "gameModeChanged": true,
            "dndChanged": true,
            "audioOutputChanged": true,
            "audioInputChanged": true,
            "capsLockChanged": true,
            "numLockChanged": true,
            "kbLayoutChanged": true,
            "kbLimit": true,
            "vpnChanged": true,
            "nowPlaying": false
        },
        "vpn": {
            "enabled": false,
            "provider": [
                {
                    "name": "wireguard",
                    "interface": "your-connection-name",
                    "displayName": "Wireguard (Your VPN)",
                    "enabled": false
                }
            ]
        },
        "quickToggles": [
            {
                "id": "wifi",
                "enabled": true
            },
            {
                "id": "bluetooth",
                "enabled": true
            },
            {
                "id": "mic",
                "enabled": true
            },
            {
                "id": "settings",
                "enabled": true
            },
            {
                "id": "gameMode",
                "enabled": true
            },
            {
                "id": "dnd",
                "enabled": true
            },
            {
                "id": "vpn",
                "enabled": false
            }
        ]
    },
    "paths": {
        "wallpaperDir": "~/Pictures/Wallpapers",
        "lyricsDir": "~/Music/lyrics/",
        "sessionGif": "root:/assets/kurukuru.gif",
        "mediaGif": "root:/assets/bongocat.gif",
        "noNotifsPic": "root:/assets/dino.png",
        "lockNoNotifsPic": "root:/assets/dino.png"
    }
  }
}
```

### Opções de Configuração

#### Face Authentication
- `enableFaceAuth`: Habilitar reconhecimento facial (padrão: `true`)
- `faceAuthTimeout`: Timeout em ms (padrão: `5000`)
- `maxFaceRetries`: Falhas antes de desabilitar Face (padrão: `5`)

**Comportamento**: Após 5 falhas, Face é desabilitado até próximo unlock bem-sucedido.

#### PIN Authentication
- `enablePinAuth`: Habilitar autenticação por PIN (padrão: `true`)
- `pinLength`: Tamanho do PIN (4-8 dígitos, padrão: `4`)
- `pinAutoSubmit`: Auto-enviar quando atingir pinLength (padrão: `true`)
- `maxPinRetries`: Falhas antes de desabilitar PIN (padrão: `10`)

**Comportamento**: Após 10 falhas, PIN é desabilitado até próximo unlock bem-sucedido.

#### Password Authentication
- `maxPasswordRetries`: Falhas antes de lockout total (padrão: `30`)

**Comportamento**: Senha sempre disponível. Lockout total apenas após 30 falhas.

#### Default Method
- `defaultMethod`: Método padrão ao abrir lock screen
  - `"face"`: Face authentication (padrão)
  - `"pin"`: PIN numpad
  - `"password"`: Senha tradicional

**Lógica de Auto-Desabilitação**:
- Face desabilitado → Default muda para PIN (se disponível) ou Password
- PIN desabilitado → Default muda para Face (se disponível) ou Password
- Ambos desabilitados → Default muda para Password
- Unlock bem-sucedido → Todos métodos reativam e default volta ao configurado

---

## 🚀 Uso

### Lock Screen

**Trancar sessão**:
```bash
# Via atalho Hyprland
Super + L

# Via comando
loginctl lock-session

# Via IPC
caelestia shell lock lock
```

### Métodos de Autenticação

#### 1. Face Recognition
1. Lock screen aparece
2. Clique no botão "Face Recognition" (ou aguarde, se for padrão)
3. Posicione seu rosto na câmera
4. Aguarde reconhecimento (~2s)
5. Unlock automático se reconhecido

#### 2. PIN
1. Lock screen aparece
2. Clique no botão "PIN"
3. Digite seu PIN no teclado numérico
4. Pressione Enter (ou auto-submit se configurado)
5. Unlock se PIN correto

#### 3. Password (Fallback)
1. Pressione qualquer tecla alfabética
2. Digite sua senha tradicional
3. Pressione Enter
4. Unlock se senha correta

### Atalhos de Teclado

- `F`: Mudar para Face authentication
- `P`: Mudar para PIN authentication
- `Enter`: Tentar autenticação
- `Backspace`: Apagar último dígito (PIN) ou caractere (senha)
- `Ctrl+Backspace`: Limpar tudo
- `Esc`: Cancelar tentativa atual

---

## 🔒 Segurança

### Considerações Importantes

⚠️ **Howdy não é tão seguro quanto senha**:
- Pode ser enganado por fotos em alguns casos
- Depende de iluminação e ângulo
- Use como conveniência, não como única linha de defesa

✅ **Práticas Recomendadas**:
- Sempre mantenha senha forte como fallback
- Adicione múltiplos modelos faciais (diferentes ângulos/iluminação)
- Configure `motion_detection` no Howdy para evitar fotos estáticas
- Use PIN como backup quando câmera não disponível
- **Não use para**: unlock de LUKS, disk encryption

### Estratégia de Auto-Desabilitação

**Filosofia**: Sem lockout temporal frustrante. Métodos se auto-desabilitam após abuse, mas sempre mantém alternativas.

#### Face Authentication
- **5 falhas**: Face desabilitado temporariamente
- **Reativação**: Unlock bem-sucedido via PIN ou Senha
- **Feedback**: Botão Face fica grayed out com mensagem clara

#### PIN Authentication
- **10 falhas**: PIN desabilitado temporariamente  
- **Reativação**: Unlock bem-sucedido via Face ou Senha
- **Feedback**: Botão PIN fica grayed out com mensagem clara

#### Password (Senha Tradicional)
- **Sempre disponível**: Último recurso
- **30 falhas**: Lockout total (todos métodos bloqueados)
- **Escape**: TTY sempre disponível (Ctrl+Alt+F2)

### Cenários de Falha

```
Cenário 1: Face falha 5x
  → Face desabilitado
  → PIN e Senha disponíveis
  → User usa PIN → Unlock → Face reativa

Cenário 2: PIN falha 10x
  → PIN desabilitado
  → Face e Senha disponíveis
  → User usa Face → Unlock → PIN reativa

Cenário 3: Face falha 5x, PIN falha 10x
  → Ambos desabilitados
  → Apenas Senha disponível
  → User usa Senha → Unlock → Ambos reativam

Cenário 4: Senha falha 30x
  → Lockout total
  → Apenas TTY disponível (Ctrl+Alt+F2)
  → Login via TTY → Todos métodos reativam
```

**Vantagem**: User nunca fica esperando countdown. Sempre há alternativa disponível.

---

## 🐛 Troubleshooting

### Howdy não funciona

```bash
# 1. Verificar câmera
ls /dev/video*

# 2. Testar Howdy
sudo howdy test

# 3. Verificar config
sudo cat /lib/security/howdy/config.ini | grep device_path

# 4. Checar logs
sudo journalctl -xe | grep howdy
```

### PIN não aceita

- Verifique que está usando sua senha do sistema (não um PIN separado)
- PIN é apenas um método de entrada, valida contra senha PAM
- Para usar PIN dedicado, configure keyring (futuro)

### Lock screen não aparece

```bash
# Reiniciar shell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize

# Verificar erros
journalctl --user -u quickshell -f
```

### Camera access denied

```bash
# Adicionar user ao grupo video
sudo usermod -aG video $USER

# Logout e login novamente
```

---

## 📝 Desenvolvimento

### Build Local

```bash
# Desenvolvimento
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Watch mode (rebuild on changes)
while inotifywait -r -e modify,create,delete modules/ components/; do
  cmake --build build
  killall quickshell
  XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
done
```

### Estrutura de Arquivos (Novos)

```
modules/lock/
├── AuthMethodSelector.qml     # Botões Face/PIN/Password
├── PinKeyboard.qml            # Teclado numérico
├── PinInputField.qml          # Display do PIN (dots)
├── FaceAuthIndicator.qml      # Indicador de face scanning
├── AuthFeedback.qml           # Mensagens de erro/sucesso
└── AuthConfig.qml             # Configurações de autenticação
```

### Roadmap

**v0.1.0-alpha** (Em andamento):
- [x] Fork do repositório
- [x] Planejamento detalhado
- [ ] AuthMethodSelector component
- [ ] PinKeyboard component
- [ ] Face authentication integration
- [ ] Rate limiting & lockout
- [ ] Documentação básica

**v0.2.0-beta**:
- [ ] GUI para configurações
- [ ] Fingerprint real (fprintd)
- [ ] Smart card support
- [ ] PIN dedicado (keyring)

**v1.0.0**:
- [ ] Testes completos
- [ ] Performance otimizada
- [ ] Documentação completa
- [ ] Integração CI/CD

Ver [PLANNING.md](PLANNING.md) para roadmap detalhado.

---

## 🤝 Contribuição

Contribuições são bem-vindas! Este é um projeto pessoal, mas aceito PRs.

### Como Contribuir

1. Fork este repositório
2. Crie branch: `git checkout -b feature/minha-feature`
3. Commit: `git commit -m "feat: minha feature"`
4. Push: `git push origin feature/minha-feature`
5. Abra Pull Request

### Convenções

- **Commits**: Semantic commits (feat/fix/docs/style/refactor/test/chore)
- **QML**: PascalCase para componentes, camelCase para properties
- **Código**: Seguir estilo do Caelestia upstream
- **Testes**: Adicionar testes para novos recursos

---

## 📚 Documentação

- **[PLANNING.md](PLANNING.md)**: Plano detalhado de implementação
- **[HOWDY_SETUP.md](HOWDY_SETUP.md)**: Guia de setup do Howdy (em breve)
- **[CHANGELOG.md](CHANGELOG.md)**: Histórico de mudanças (em breve)
- **[Upstream Docs](https://github.com/caelestia-dots/shell)**: Documentação original do Caelestia

---

## 🙏 Créditos

### Base
- **[Caelestia Shell](https://github.com/caelestia-dots/shell)** by [@soramane](https://github.com/soramane)
- **[Quickshell](https://quickshell.outfoxxed.me)** by [@outfoxxed](https://github.com/outfoxxed)

### Autenticação
- **[Howdy](https://github.com/boltgolt/howdy)** - Linux face authentication

### Inspiração
- **Windows Hello**: Face + PIN UI/UX
- **macOS Touch ID**: Biometric fallback patterns
- **Android Smart Lock**: Multiple auth methods

---

## 📄 Licença

GPLv3 - Ver [LICENSE](LICENSE) para detalhes.

Este fork mantém a mesma licença do upstream.

---

## 📞 Contato

**Mantenedor**: @pereiraoc  
**Projeto Principal**: [caelestia-arch-setup](https://github.com/pereiraoc/caelestia-arch-setup)  
**Upstream**: [caelestia-dots/shell](https://github.com/caelestia-dots/shell)

---

## ⭐ Star History

Se este fork foi útil, considere dar uma estrela!

---

<div align="center">

**Made with ❤️ for Arch Linux + Hyprland**

</div>
