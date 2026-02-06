# Sequência de Implementação Recomendada

**Última atualização**: 2026-02-06

Este documento define a ordem recomendada para implementar os planos, considerando dependências técnicas, prioridade de uso e complexidade.

---

## Diagrama de Dependências

```mermaid
flowchart TB
    subgraph Implementado [✅ Implementado]
        P21[21 Lock Screen]
        P24[24 Workspace Grouping]
        P25[25 Gaps Configuration]
        P28[28 Help Modal]
        P32[32 GPU Mode Selector]
    end
    
    subgraph Fase1 [Fase 1 - Fundação]
        P39[39 Keyboard Shortcuts]
        P29[29 Configuration Panel]
    end
    
    subgraph Fase2 [Fase 2 - Dashboard]
        P36[36 Help Dashboard Tab]
        P40[40 Peripheral Battery]
    end
    
    subgraph Fase3 [Fase 3 - Wallpaper + Lock]
        P38[38 Wallpaper per Monitor]
        P35[35 Face Reading Retry]
    end
    
    subgraph Fase4 [Fase 4 - Widgets Barra]
        P26[26 Shortcuts Widget]
        P27[27 Games Widget]
    end
    
    subgraph Fase5 [Fase 5 - Notifications + Weather]
        P34[34 Notification Manager]
        P33[33 Weather Multi-Locations]
    end
    
    subgraph Fase6 [Fase 6 - Customization]
        P30[30 Launcher Customization]
        P31[31 Theme Customization]
    end
    
    subgraph Fase7 [Fase 7 - Software Manager]
        P37[37 Software Manager]
    end
    
    subgraph Futuro [⏳ Postergado]
        P22[22 System Tray]
    end
    
    P39 --> P36
    P28 --> P39
    P29 --> P38
    P29 --> P30
    P29 --> P37
```

---

## Sequência Detalhada

### ✅ Implementado

| Plano | Status | Notas |
|-------|--------|-------|
| **21** Lock Screen Auth Selector | ✅ | Face/PIN selection |
| **24** Workspace Visual Grouping | ✅ | Groups de 5 workspaces |
| **25** Gaps Configuration | ✅ | Inner/outer gaps |
| **28** Help Modal | ✅ | 212 linhas, Super+F1 |
| **32** GPU Mode Selector | ✅ | NVIDIA/Intel toggle |

---

### Fase 1: Fundação (Config + Shortcuts)

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 1 | **39** Keyboard Shortcuts Management | 8-10h | ShortcutsManager centraliza core+custom; base para Help Tab |
| 2 | **29** Configuration Panel | 6-8h | Painel central de config; usado por vários planos |

**Dependências**:
- 39 usa HelpModal.qml como referência (shortcuts hardcoded → ShortcutsManager)
- 29 estabelece padrão de config que 30, 37, 38 reutilizam

**Total Fase 1**: ~14-18h

---

### Fase 2: Dashboard Enhancements

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 3 | **36** Help Dashboard Tab | 3-4h | Reutiliza ShortcutsManager do plano 39 |
| 4 | **40** Peripheral Battery Card | 4-6h | Card independente; usa Bluetooth API existente |

**Dependências**:
- 36 depende de 39 (ShortcutsManager.getCoreByCategory)
- 40 independente (apenas layout do Dashboard)

**Total Fase 2**: ~7-10h

---

### Fase 3: Wallpaper + Lock Screen

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 5 | **38** Wallpaper per Monitor | 6-8h | Multi-source + per-monitor; usa FileSystemModel existente |
| 6 | **35** Face Reading Retry | 4-6h | Complementa Lock Screen; baixa complexidade |

**Dependências**:
- 38 usa Config system (estabelecido em fase 1)
- 35 independente

**Total Fase 3**: ~10-14h

---

### Fase 4: Widgets na Barra

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 7 | **26** Shortcuts Widget | 6-8h | Atalhos rápidos na barra (apps, vaults, etc) |
| 8 | **27** Games Widget | 8-10h | Steam favorites; parsing VDF |

**Nota**: 26 (Shortcuts Widget) ≠ 39 (Keyboard Shortcuts)
- 26 = botões clicáveis na barra para abrir apps
- 39 = atalhos de teclado (Super+X)

**Total Fase 4**: ~14-18h

---

### Fase 5: Notifications + Weather

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 9 | **34** Notification Manager | 12-16h | Histórico existe; adicionar blockedApps + iconOverrides |
| 10 | **33** Weather Multi-Locations | 6-8h | Refatorar Weather service |

**Total Fase 5**: ~18-24h

---

### Fase 6: Customization

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 11 | **30** Launcher Customization | 6-8h | Editar ícones/nomes de apps |
| 12 | **31** Theme Customization | 10-15h | Gerar paleta M3; mais complexo |

**Total Fase 6**: ~16-23h

---

### Fase 7: Software Manager

| Ordem | Plano | Tempo | Motivo |
|-------|-------|-------|--------|
| 13 | **37** Software Manager | 15-23h | Listar/atualizar/remover apps (pacman, flatpak, AUR) |

**Total Fase 7**: ~15-23h

---

## Resumo da Sequência

| # | Plano | Fase | Tempo | Status |
|---|-------|------|-------|--------|
| - | 21 Lock Screen | - | - | ✅ Implementado |
| - | 24 Workspace Grouping | - | - | ✅ Implementado |
| - | 25 Gaps Configuration | - | - | ✅ Implementado |
| - | 28 Help Modal | - | - | ✅ Implementado |
| - | 32 GPU Mode Selector | - | - | ✅ Implementado |
| 1 | **39 Keyboard Shortcuts** | 1 | 8-10h | ⏱️ Planejado |
| 2 | 29 Configuration Panel | 1 | 6-8h | ⏱️ Planejado |
| 3 | 36 Help Dashboard Tab | 2 | 3-4h | ⏱️ Planejado |
| 4 | **40 Peripheral Battery** | 2 | 4-6h | ⏱️ Planejado |
| 5 | **38 Wallpaper per Monitor** | 3 | 6-8h | ⏱️ Planejado |
| 6 | 35 Face Reading Retry | 3 | 4-6h | ⏱️ Planejado |
| 7 | 26 Shortcuts Widget | 4 | 6-8h | ⏱️ Planejado |
| 8 | 27 Games Widget | 4 | 8-10h | ⏱️ Planejado |
| 9 | 34 Notification Manager | 5 | 12-16h | ⏱️ Planejado |
| 10 | 33 Weather Multi-Locations | 5 | 6-8h | ⏱️ Planejado |
| 11 | 30 Launcher Customization | 6 | 6-8h | ⏱️ Planejado |
| 12 | 31 Theme Customization | 6 | 10-15h | ⏱️ Planejado |
| 13 | 37 Software Manager | 7 | 15-23h | ⏱️ Planejado |
| - | 22 System Tray | Futuro | TBD | ⏳ Bloqueado (sync incubation) |

**Total estimado restante**: ~94-130h

---

## ✅ Validações Técnicas (2026-02-06)

| Item | Status | Notas |
|------|--------|-------|
| FileView.setText() | ✅ | Persistência de config |
| hyprctl keyword bind/unbind | ✅ | Runtime keybindings (testado) |
| Bluetooth.devices.values | ✅ | Lista dispositivos conectados |
| device.battery/batteryAvailable | ✅ | Bateria de BT devices |
| FileSystemModel multi-source | ✅ | Repeater com múltiplos FSM |
| Shape + PathAngleArc | ✅ | Usado em Media.qml (rings) |
| Qt.uuidCreate() | ✅ | Gerar IDs únicos |

---

## Notas de Implementação

### Plano 39 (Keyboard Shortcuts)
- **Core shortcuts**: Hardcoded no ShortcutsManager (imutáveis)
- **Custom shortcuts**: Persistidos em config.json
- **HelpModal**: Refatorar para usar `ShortcutsManager.getCoreByCategory()`
- **Runtime**: `hyprctl keyword bind/unbind` funciona

### Plano 40 (Peripheral Battery)
- **Dispositivos BT**: `Bluetooth.devices.values.filter(d => d.connected)`
- **Tipos**: Detectar via `device.icon.includes("mouse"|"keyboard"|"headset")`
- **2.4GHz**: Pode precisar UPower (investigação futura)

### Plano 38 (Wallpaper)
- **Não usa hyprpaper**: Quickshell renderiza direto via QML
- **Multi-source**: Repeater de FileSystemModel
- **Per-monitor**: `Wallpapers.getForMonitor(screen.name)`

---

## Ajustes Possíveis

- **Paralelizar 3+4**: Help Tab e Peripheral Battery são independentes
- **Paralelizar 7+8**: Shortcuts Widget e Games Widget são independentes
- **Antecipar 40**: Se quiser ver periféricos logo (baixa complexidade)
- **Adiar 31**: Theme Customization é complexo; pode ficar para v0.3.0+
- **22 System Tray**: Bloqueado por bug de sync incubation; postergado indefinidamente
