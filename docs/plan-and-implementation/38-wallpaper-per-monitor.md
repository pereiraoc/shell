# 38. Wallpaper por Monitor e Biblioteca Manual

**Status**: 📋 Planejado  
**Prioridade**: Média  
**Complexidade**: Média

---

## 📋 Requisitos

### RF-38.1: Wallpaper Independente por Monitor
- Permitir selecionar wallpaper diferente para cada monitor
- Persistir configuração por nome do monitor (ex: `eDP-1`, `HDMI-A-1`)
- Fallback para wallpaper padrão se monitor não tiver config específica

### RF-38.2: Biblioteca de Wallpapers com Múltiplas Fontes
- Manter diretório padrão (`~/Pictures/Wallpapers`)
- Adicionar diretórios adicionais como fonte (ex: `/data/img`)
- Adicionar arquivos individuais à biblioteca
- Remover fontes da biblioteca (sem deletar arquivos originais)

### RF-38.3: Interface de Seleção por Monitor
- Dropdown para selecionar monitor alvo
- Grid de wallpapers de todas as fontes
- Indicador visual de qual wallpaper está em cada monitor
- Botão para adicionar nova fonte

---

## 🔍 Análise Técnica

### Como Funciona Atualmente

**Wallpaper é renderizado diretamente pelo Quickshell** (não usa hyprpaper/swww):

1. `Background.qml` cria uma janela por monitor via `Variants`:
```qml
Variants {
    model: Quickshell.screens
    StyledWindow {
        required property ShellScreen modelData
        screen: modelData
        WlrLayershell.layer: WlrLayer.Background
        Wallpaper { }  // ← Mesmo source para todos
    }
}
```

2. `Wallpaper.qml` usa `CachingImage` com source de `Wallpapers.current`:
```qml
property string source: Wallpapers.current  // ← Global, igual para todos
```

3. `Wallpapers.qml` (singleton) gerencia wallpaper único:
```qml
property string actualCurrent  // ← Um único wallpaper
FileSystemModel {
    path: Paths.wallsdir  // ← Único diretório
}
```

### Limitações Identificadas

| Aspecto | Atual | Necessário |
|---------|-------|------------|
| Wallpaper | 1 global | 1 por monitor |
| Fontes | 1 diretório | N diretórios |
| Persistência | `path.txt` | JSON por monitor |

---

## 📐 Implementação

### Fase 1: Configuração de Múltiplas Fontes

#### 1.1 Estender UserPaths.qml

**Arquivo**: `config/UserPaths.qml`

Adicionar após `mediaGif`:
```qml
// Fontes adicionais de wallpapers
property var additionalWallpaperSources: []
// Formato: ["/data/img", "/media/photos/favorites"]
```

#### 1.2 Atualizar Config.qml - serializePaths()

**Arquivo**: `config/Config.qml`

Na função `serializePaths()`, adicionar:
```qml
function serializePaths(): var {
    return {
        wallpaperDir: paths.wallpaperDir,
        sessionGif: paths.sessionGif,
        mediaGif: paths.mediaGif,
        additionalWallpaperSources: paths.additionalWallpaperSources || []  // NOVO
    };
}
```

### Fase 2: Modificar Wallpapers.qml

**Arquivo**: `services/Wallpapers.qml`

Adicionar novas propriedades e funções:

```qml
pragma Singleton

import qs.config
import qs.utils
import Caelestia.Models
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    // === EXISTENTE (manter) ===
    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: Config.services.smartScheme ? [] : ["--no-smart"]
    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock

    // === NOVO: Estado por Monitor ===
    property var monitorWallpapers: ({})
    readonly property string monitorWallpapersPath: `${Paths.state}/wallpaper/monitors.json`
    
    function getForMonitor(monitorName: string): string {
        return monitorWallpapers[monitorName] || actualCurrent;
    }
    
    function setForMonitor(monitorName: string, path: string): void {
        let updated = {...monitorWallpapers};
        updated[monitorName] = path;
        monitorWallpapers = updated;
        saveMonitorWallpapers();
    }
    
    function saveMonitorWallpapers(): void {
        monitorStateFile.setText(JSON.stringify(monitorWallpapers, null, 2));
    }
    
    FileView {
        id: monitorStateFile
        path: root.monitorWallpapersPath
        watchChanges: false
        onLoaded: {
            try {
                root.monitorWallpapers = JSON.parse(text()) || {};
            } catch (e) {
                root.monitorWallpapers = {};
            }
        }
    }

    // === NOVO: Múltiplas Fontes ===
    readonly property var allWallpapers: {
        let all = [...wallpapers.entries];
        for (let i = 0; i < additionalSources.count; i++) {
            const item = additionalSources.itemAt(i);
            if (item?.fsModel?.entries) {
                all = all.concat(item.fsModel.entries);
            }
        }
        return all;
    }

    // Atualizar list para usar allWallpapers
    list: allWallpapers
    key: "path"

    // === EXISTENTE (manter funções) ===
    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (!previewColourLock)
            Colours.showPreview = false;
    }

    useFuzzy: Config.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({ forward: false })

    // === EXISTENTE: Handlers ===
    IpcHandler {
        target: "wallpaper"
        function get(): string { return root.actualCurrent; }
        function set(path: string): void { root.setWallpaper(path); }
        function list(): string { return root.allWallpapers.map(w => w.path).join("\n"); }
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.actualCurrent = text().trim();
            root.previewColourLock = false;
        }
    }

    // Fonte padrão
    FileSystemModel {
        id: wallpapers
        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }

    // === NOVO: Fontes adicionais ===
    Repeater {
        id: additionalSources
        model: Config.paths.additionalWallpaperSources || []
        
        Item {
            required property string modelData
            property alias fsModel: fsm
            
            FileSystemModel {
                id: fsm
                recursive: true
                path: modelData
                filter: FileSystemModel.Images
            }
        }
    }

    Process {
        id: getPreviewColoursProc
        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
    
    Component.onCompleted: monitorStateFile.reload()
}
```

### Fase 3: Wallpaper por Monitor

#### 3.1 Modificar Background.qml

**Arquivo**: `modules/background/Background.qml`

Linha ~37, mudar:
```qml
// DE:
Wallpaper {
    id: wallpaper
}

// PARA:
Wallpaper {
    id: wallpaper
    source: Wallpapers.getForMonitor(win.modelData.name)
}
```

### Fase 4: UI de Gerenciamento

#### 4.1 Criar WallpaperSection.qml

**Arquivo**: `modules/controlcenter/settings/WallpaperSection.qml`

```qml
pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.images
import qs.components.filedialog
import qs.services
import qs.config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

CollapsibleSection {
    id: root
    
    title: qsTr("Wallpaper")
    icon: "wallpaper"
    
    content: Column {
        width: parent.width
        spacing: Appearance.spacing.normal
        
        // Seletor de monitor
        Row {
            spacing: Appearance.spacing.small
            
            StyledText {
                text: qsTr("Monitor:")
                anchors.verticalCenter: parent.verticalCenter
            }
            
            StyledComboBox {
                id: monitorSelector
                width: 150
                model: Quickshell.screens.map(s => s.name)
                currentIndex: {
                    const focused = Hypr.focusedMonitor?.name;
                    const idx = Quickshell.screens.findIndex(s => s.name === focused);
                    return idx >= 0 ? idx : 0;
                }
            }
        }
        
        // Wallpaper atual
        Row {
            spacing: Appearance.spacing.small
            
            StyledText {
                text: qsTr("Current:")
                opacity: 0.7
            }
            StyledText {
                text: Paths.shortenHome(Wallpapers.getForMonitor(monitorSelector.currentValue) || qsTr("(default)"))
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }
        
        // Grid de wallpapers
        StyledRect {
            width: parent.width
            height: 180
            color: Colours.palette.m3surfaceContainerLow
            radius: Appearance.rounding.normal
            
            GridView {
                id: wallpaperGrid
                anchors.fill: parent
                anchors.margins: Appearance.padding.small
                
                cellWidth: 100
                cellHeight: 65
                clip: true
                
                model: Wallpapers.allWallpapers
                
                delegate: Item {
                    width: 96
                    height: 61
                    
                    required property var modelData
                    required property int index
                    
                    readonly property bool isSelected: 
                        Wallpapers.getForMonitor(monitorSelector.currentValue) === modelData.path
                    
                    CachingImage {
                        anchors.fill: parent
                        anchors.margins: 2
                        path: modelData.path
                        fillMode: Image.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: isSelected ? 2 : 0
                        border.color: Colours.palette.m3primary
                        radius: Appearance.rounding.small
                    }
                    
                    StateLayer {
                        radius: Appearance.rounding.small
                        function onClicked(): void {
                            Wallpapers.setForMonitor(monitorSelector.currentValue, modelData.path);
                        }
                    }
                }
                
                StyledScrollBar.vertical: StyledScrollBar {}
            }
        }
        
        // Gerenciamento de fontes
        CollapsibleSection {
            width: parent.width
            title: qsTr("Sources")
            icon: "folder"
            collapsed: true
            
            content: Column {
                width: parent.width
                spacing: Appearance.spacing.small
                
                // Fonte padrão
                Row {
                    spacing: Appearance.spacing.small
                    MaterialIcon { text: "folder"; opacity: 0.5 }
                    StyledText { 
                        text: Paths.shortenHome(Paths.wallsdir) + qsTr(" (default)")
                        opacity: 0.5
                    }
                }
                
                // Fontes adicionais
                Repeater {
                    model: Config.paths.additionalWallpaperSources || []
                    
                    Row {
                        required property string modelData
                        required property int index
                        
                        spacing: Appearance.spacing.small
                        
                        MaterialIcon { text: "folder" }
                        StyledText { 
                            text: Paths.shortenHome(modelData)
                            width: 180
                            elide: Text.ElideMiddle
                        }
                        IconButton {
                            icon: "close"
                            size: Appearance.font.size.small
                            tooltip: qsTr("Remove source")
                            function onClicked(): void {
                                let sources = [...Config.paths.additionalWallpaperSources];
                                sources.splice(index, 1);
                                Config.paths.additionalWallpaperSources = sources;
                                Config.save();
                            }
                        }
                    }
                }
                
                // Botão adicionar
                StyledButton {
                    text: qsTr("+ Add folder")
                    function onClicked(): void {
                        folderDialog.open();
                    }
                }
                
                FileDialog {
                    id: folderDialog
                    title: qsTr("Select wallpaper folder")
                    onAccepted: path => {
                        let sources = Config.paths.additionalWallpaperSources || [];
                        if (!sources.includes(path)) {
                            sources.push(path);
                            Config.paths.additionalWallpaperSources = sources;
                            Config.save();
                        }
                    }
                }
            }
        }
    }
}
```

#### 4.2 Incluir em Settings.qml

**Arquivo**: `modules/controlcenter/settings/Settings.qml`

Adicionar import e incluir `WallpaperSection {}` na lista de seções.

---

## 📁 Resumo de Arquivos

| Arquivo | Ação | Linhas Afetadas |
|---------|------|-----------------|
| `config/UserPaths.qml` | Modificar | +1 property |
| `config/Config.qml` | Modificar | serializePaths() |
| `services/Wallpapers.qml` | Modificar | +50 linhas |
| `modules/background/Background.qml` | Modificar | 1 linha |
| `modules/controlcenter/settings/WallpaperSection.qml` | Criar | ~150 linhas |
| `modules/controlcenter/settings/Settings.qml` | Modificar | +2 linhas |

---

## 🗄️ Persistência

**Por monitor**: `~/.local/state/caelestia/wallpaper/monitors.json`
```json
{
  "eDP-1": "/home/user/Pictures/Wallpapers/nature.jpg",
  "HDMI-A-1": "/data/img/city.png"
}
```

**Fontes**: `~/.config/caelestia/config.json`
```json
{
  "paths": {
    "additionalWallpaperSources": ["/data/img"]
  }
}
```

---

## ✅ Critérios de Aceitação

- [ ] Selecionar wallpaper diferente para cada monitor
- [ ] Adicionar pasta como fonte de wallpapers
- [ ] Remover fonte adicional
- [ ] Persistir configuração entre reinícios
- [ ] Monitor novo usa wallpaper padrão
- [ ] Grid mostra wallpapers de todas as fontes
