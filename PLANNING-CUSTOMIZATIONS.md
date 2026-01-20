# Planejamento de Customizações do Caelestia Shell

> **Status**: Planejamento  
> **Data**: 2026-01-19

## Resumo das Tarefas

| # | Tarefa | Complexidade | Arquivos Principais |
|---|--------|--------------|---------------------|
| 1 | Tray não aparece (Steam/Spotify) | 🟢 Config | Sistema SNI |
| 2 | Trocar GIF de desligar (kurukuru) | 🟢 Baixa | `config/UserPaths.qml` |
| 3 | Trocar imagem do gatinho (bongocat) | 🟢 Baixa | `config/UserPaths.qml` |
| 4 | Remover ícone pacman dos workspaces | 🟢 Baixa | `config/BarConfig.qml` |
| 5 | Agrupar janelas por workspace na barra | 🟡 Média | `modules/bar/components/workspaces/Workspace.qml` |
| 6 | Configurar gaps via UI | 🟡 Média | `AppearancePane.qml`, Hyprland IPC |
| 7 | Widget Shortcuts configurável | 🟡 Média | Novo widget + pane |
| 8 | Widget Games (Steam) | 🟡 Média | Novo widget + pane + Steam API |
| 9 | Botão Help com shortcuts | 🟡 Média | Novo componente modal |
| 10 | Integrar programas no settings | 🟡 Média | Novo pane "Apps" |
| 11 | Editar ícone pelo settings | 🟡 Média | Estender `LauncherPane.qml` |
| 12 | Editar nome pelo settings | 🟡 Média | Estender `LauncherPane.qml` |
| 13 | Tema preto/amarelo customizável | 🔴 Alta | Sistema de cores M3 |

---

## 1. Tray não aparece (Steam/Spotify)

### Diagnóstico
```
StatusNotifierWatcher not running or no items
```

O problema é que o **StatusNotifierWatcher** (SNI host) não está recebendo registros do Steam/Spotify.

### Causa Provável
- Steam e Spotify usam **XEmbed** (protocolo antigo) em vez de SNI
- Ou precisam de `--enable-features=UseOzonePlatform` para usar SNI

### Solução

**Opção A**: Instalar `snixembed` (converte XEmbed → SNI)
```bash
paru -S snixembed
# Adicionar ao autostart
echo "snixembed &" >> ~/.config/hypr/autostart.conf
```

**Opção B**: Forçar Steam a usar SNI
```bash
# Em ~/.local/share/applications/steam.desktop
Exec=env GDK_BACKEND=wayland steam %U
```

**Opção C**: Verificar se Quickshell está registrando como SNI host
```bash
qdbus org.kde.StatusNotifierWatcher /StatusNotifierWatcher
```

### Arquivos a Modificar
- `~/.config/hypr/hyprland.conf` (autostart)
- Scripts de instalação

---

## 2. Trocar GIF de Desligar (kurukuru.gif)

### Localização Atual
```
assets/kurukuru.gif
```

### Configuração
```qml
// config/UserPaths.qml
property string sessionGif: "root:/assets/kurukuru.gif"
```

### Componente que Usa
```qml
// modules/session/Content.qml (linha 48-58)
AnimatedImage {
    source: Paths.absolutePath(Config.paths.sessionGif)
}
```

### Solução
1. Substituir `assets/kurukuru.gif` por nova animação
2. Ou adicionar UI para escolher animação em `config/UserPaths.qml`

### Sugestões de Animação
- Loading spinner simples
- Ícone de power pulsando
- Sem animação (apenas ícone estático)

---

## 3. Trocar Imagem do Gatinho (bongocat.gif)

### Localização Atual
```
assets/bongocat.gif
```

### Configuração
```qml
// config/UserPaths.qml
property string mediaGif: "root:/assets/bongocat.gif"
```

### Componente que Usa
```qml
// modules/dashboard/dash/Media.qml (linha 204-220)
AnimatedImage {
    source: Paths.absolutePath(Config.paths.mediaGif)
}
```

### Solução
1. Substituir `assets/bongocat.gif` por nova animação
2. Ou adicionar opção para esconder completamente

### Sugestões
- Visualizador de áudio (já existe `Audio.beatTracker`)
- Equalizer animado
- Sem animação

---

## 4. Remover Ícone Pacman dos Workspaces

### Localização
```qml
// config/BarConfig.qml (linha 77-78)
property string occupiedLabel: "󰮯"  // ← Este é o pacman
property string activeLabel: "󰮯"
```

### Componente que Usa
```qml
// modules/bar/components/workspaces/Workspace.qml (linha 37-49)
text: root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : label;
```

### Solução
Mudar para string vazia ou outro símbolo:
```qml
property string occupiedLabel: ""  // Sem ícone extra
property string activeLabel: ""
```

Ou em `~/.config/caelestia/shell.json`:
```json
{
  "bar": {
    "workspaces": {
      "occupiedLabel": "",
      "activeLabel": ""
    }
  }
}
```

---

## 5. Agrupar Janelas por Workspace na Barra

### Problema Atual
Janelas de workspaces diferentes aparecem lado a lado sem separação visual.

### Localização
```qml
// modules/bar/components/workspaces/Workspace.qml
// modules/bar/components/workspaces/Workspaces.qml
```

### Solução Proposta
Adicionar borda/container ao redor das janelas de cada workspace:

```qml
// Em Workspace.qml, envolver o Repeater de janelas
StyledRect {
    visible: root.hasWindows
    color: "transparent"
    border.color: Colours.palette.m3outline
    border.width: 1
    radius: Appearance.rounding.small
    
    Column {
        // Janelas aqui
    }
}
```

### Arquivos a Modificar
- `modules/bar/components/workspaces/Workspace.qml`
- Possivelmente `config/BarConfig.qml` para configuração

---

## 6. Configurar Gaps via UI

### Gaps Atuais (Hyprland)
```
gaps_in = 5 5 5 5
gaps_out = 20 20 20 20
```

### Solução

**Parte 1**: Adicionar config no Caelestia
```qml
// config/GeneralConfig.qml
component Gaps: JsonObject {
    property int inner: 5
    property int outer: 20
}
```

**Parte 2**: Adicionar seção no AppearancePane
```qml
// Nova seção "Window Gaps"
SliderInput {
    label: qsTr("Inner Gap")
    from: 0
    to: 30
    value: root.gapsInner
    onMoved: value => {
        root.gapsInner = value;
        Hypr.dispatch(`keyword general:gaps_in ${value}`);
    }
}
```

**Parte 3**: Aplicar no Hyprland via IPC
```qml
Hypr.dispatch(`keyword general:gaps_in ${value}`)
Hypr.dispatch(`keyword general:gaps_out ${value}`)
```

### Arquivos a Modificar
- `config/GeneralConfig.qml` ou novo `HyprlandConfig.qml`
- `modules/controlcenter/appearance/AppearancePane.qml`
- Adicionar persistência via hyprland.conf

---

## 7. Widget Shortcuts Configurável (Vaults Obsidian)

### Conceito
Adicionar widget na barra superior com atalhos configuráveis.

### Estrutura Proposta

**Config**:
```qml
// config/ShortcutsConfig.qml
JsonObject {
    property list<var> shortcuts: [
        { name: "Vault 1", icon: "folder", command: "obsidian obsidian://open?vault=Vault1" },
        { name: "Vault 2", icon: "folder", command: "obsidian obsidian://open?vault=Vault2" }
    ]
}
```

**Widget**:
```qml
// modules/bar/components/Shortcuts.qml
Row {
    Repeater {
        model: Config.shortcuts.shortcuts
        
        StyledRect {
            MaterialIcon { text: modelData.icon }
            MouseArea {
                onClicked: Quickshell.execDetached(modelData.command)
            }
        }
    }
}
```

**Painel de Configuração**:
```qml
// modules/controlcenter/shortcuts/ShortcutsPane.qml
- Lista de shortcuts existentes
- Botão adicionar novo
- Campos: nome, ícone, comando
```

### Arquivos a Criar
- `config/ShortcutsConfig.qml`
- `modules/bar/components/Shortcuts.qml`
- `modules/controlcenter/shortcuts/ShortcutsPane.qml`

### Arquivos a Modificar
- `config/BarConfig.qml` (adicionar entry)
- `modules/bar/Bar.qml` (adicionar delegate)
- `modules/controlcenter/PaneRegistry.qml`

---

## 8. Widget Games (Steam)

### Conceito
Widget na barra com jogos favoritos da Steam.

### Desafio
Listar jogos da Steam requer:
1. Ler `~/.steam/steam/steamapps/*.acf` (manifests)
2. Ou usar API Steam (requer key)

### Estrutura Proposta

**Config**:
```qml
// config/GamesConfig.qml
JsonObject {
    property list<var> favoriteGames: [
        { appId: "123456", name: "Game Name" }
    ]
}
```

**Widget**:
```qml
// modules/bar/components/Games.qml
Row {
    Repeater {
        model: Config.games.favoriteGames
        
        StyledRect {
            // Ícone do jogo (pode ser fetchado da Steam CDN)
            Image { source: `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg` }
            MouseArea {
                onClicked: Quickshell.execDetached(["steam", `steam://run/${appId}`])
            }
        }
    }
}
```

**Painel de Configuração**:
```qml
// modules/controlcenter/games/GamesPane.qml
- Lista jogos instalados (parse de steamapps/*.acf)
- Toggle para adicionar/remover dos favoritos
```

### Script para Listar Jogos
```bash
#!/bin/bash
for acf in ~/.steam/steam/steamapps/*.acf; do
    appid=$(grep '"appid"' "$acf" | cut -d'"' -f4)
    name=$(grep '"name"' "$acf" | cut -d'"' -f4)
    echo "$appid|$name"
done
```

### Arquivos a Criar
- `config/GamesConfig.qml`
- `modules/bar/components/Games.qml`
- `modules/controlcenter/games/GamesPane.qml`
- `scripts/list-steam-games.sh`

---

## 9. Botão Help com Shortcuts

### Conceito
Botão que abre modal com lista de atalhos de teclado.

### Localização Sugerida
- Na barra (perto do power)
- Ou no Control Center

### Estrutura Proposta

**Componente Modal**:
```qml
// modules/help/HelpModal.qml
Popup {
    ColumnLayout {
        StyledText { text: qsTr("Keyboard Shortcuts") }
        
        Repeater {
            model: [
                { keys: "Super+L", action: qsTr("Lock screen") },
                { keys: "Super+Tab", action: qsTr("Workspace overview") },
                // ...
            ]
            
            RowLayout {
                StyledText { text: modelData.keys }
                StyledText { text: modelData.action }
            }
        }
    }
}
```

**Atalho para Abrir**:
```qml
// Adicionar CustomShortcut
CustomShortcut {
    name: "help"
    description: "Show keyboard shortcuts"
    onPressed: helpModal.open()
}
```

### Arquivos a Criar
- `modules/help/HelpModal.qml`
- `config/HelpConfig.qml` (lista de shortcuts)

### Arquivos a Modificar
- `modules/bar/Bar.qml` ou `modules/Shortcuts.qml`

---

## 10. Integrar Programas no Settings

### Conceito
Novo painel "Apps" no Control Center com botões para abrir configuradores.

### Lista de Programas
| Categoria | Programa | Comando |
|-----------|----------|---------|
| Audio | qpwgraph | `qpwgraph` |
| Audio | EasyEffects | `easyeffects` |
| Display | nwg-displays | `nwg-displays` |
| Display | Font Scaling | `font-scaling-manager` |
| System | System Monitor | `gnome-system-monitor` ou `btop` |
| System | Logs | `gnome-logs` |
| Share | Packet | `packet` |
| Share | Snapdrop | `firefox snapdrop.net` |
| Share | LocalSend | `localsend` |

### Estrutura Proposta

```qml
// modules/controlcenter/apps/AppsPane.qml
GridLayout {
    columns: 2
    
    Repeater {
        model: [
            { name: "qpwgraph", icon: "graphic_eq", command: ["qpwgraph"] },
            { name: "EasyEffects", icon: "tune", command: ["easyeffects"] },
            // ...
        ]
        
        AppButton {
            text: modelData.name
            icon: modelData.icon
            onClicked: Quickshell.execDetached(modelData.command)
        }
    }
}
```

### Arquivos a Criar
- `modules/controlcenter/apps/AppsPane.qml`

### Arquivos a Modificar
- `modules/controlcenter/PaneRegistry.qml`

---

## 11 & 12. Editar Ícone/Nome pelo Settings

### Localização Atual
```qml
// modules/controlcenter/launcher/LauncherPane.qml
// Já tem UI para apps, precisa adicionar edição
```

### Mecanismo
Desktop entries são salvos em `~/.local/share/applications/`

### Solução
Adicionar campos de edição no painel de detalhes do app:

```qml
// Em LauncherPane.qml, seção appDetails
StyledTextField {
    placeholderText: qsTr("Custom name")
    text: displayedApp.name
    onEditingFinished: {
        // Salvar em ~/.local/share/applications/app-overrides.json
        // Ou criar .desktop modificado
    }
}

IconPicker {
    currentIcon: displayedApp.icon
    onIconSelected: icon => {
        // Salvar override
    }
}
```

### Arquivos a Modificar
- `modules/controlcenter/launcher/LauncherPane.qml`
- Criar sistema de overrides para .desktop

---

## 13. Tema Preto/Amarelo Customizável

### Sistema Atual
Cores são carregadas de `${Paths.state}/scheme.json` via comando `caelestia scheme`.

```qml
// services/Colours.qml
FileView {
    path: `${Paths.state}/scheme.json`
    onLoaded: root.load(text(), false)
}
```

### Esquema M3 (Material Design 3)
O Caelestia usa paleta M3 completa (~50 cores).

### Solução Proposta

**Opção A**: Criar tema pré-definido
```bash
# Criar arquivo de tema
cat > ~/.config/caelestia/themes/dark-yellow.json << 'EOF'
{
  "name": "Dark Yellow",
  "flavour": "dark",
  "mode": "dark",
  "colours": {
    "background": "0a0a0a",
    "surface": "121212",
    "primary": "ffc107",
    "secondary": "ffca28",
    "onPrimary": "000000",
    "onBackground": "ffffff"
    // ... resto das cores M3
  }
}
EOF
```

**Opção B**: Adicionar editor de cores na UI
```qml
// modules/controlcenter/appearance/sections/CustomColorsSection.qml
ColorPicker {
    label: qsTr("Primary Color")
    color: Config.customColors.primary
    onColorChanged: {
        // Gerar paleta M3 a partir da cor primária
        // Aplicar ao sistema
    }
}
```

### Ferramentas para Gerar Paleta M3
- Material Theme Builder: https://m3.material.io/theme-builder
- Ou usar biblioteca Python/JS para gerar

### Arquivos a Modificar/Criar
- `modules/controlcenter/appearance/sections/CustomColorsSection.qml`
- Scripts para gerar/aplicar temas

---

## Ordem de Implementação Sugerida

### Fase 1: Quick Wins (1-2h cada)
1. ✅ Remover ícone pacman → editar `shell.json`
2. ✅ Trocar kurukuru.gif → substituir asset
3. ✅ Trocar bongocat.gif → substituir asset
4. 🔧 Investigar tray → instalar snixembed

### Fase 2: Modificações Moderadas (2-4h cada)
5. Agrupar janelas por workspace
6. Configurar gaps via UI
7. Botão Help com shortcuts
8. Integrar programas no settings

### Fase 3: Features Novas (4-8h cada)
9. Widget Shortcuts configurável
10. Widget Games (Steam)
11. Editar ícone pelo settings
12. Editar nome pelo settings

### Fase 4: Sistema Complexo (8h+)
13. Tema preto/amarelo customizável

---

## Próximos Passos

1. **Confirmar prioridades** com usuário
2. **Começar pela Fase 1** (quick wins)
3. **Testar cada mudança** incrementalmente
4. **Documentar** no 01-pendencias.md

---

## Referências

- [Material Design 3 Colors](https://m3.material.io/styles/color/overview)
- [Quickshell Documentation](https://quickshell.sh/)
- [Hyprland Wiki - Variables](https://wiki.hyprland.org/Configuring/Variables/)
- [Steam Shortcut Format](https://developer.valvesoftware.com/wiki/Steam_browser_protocol)
