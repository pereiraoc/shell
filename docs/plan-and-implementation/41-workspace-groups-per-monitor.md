# 🖥️ Workspace Groups per Monitor — Redesign

**ID**: 41
**Status**: 🔄 Planejamento (state 6 do workflow)
**Complexidade**: 🔴 Alta
**Tempo Estimado**: 7-8h (4 fases)

> **Source of truth**: este plano é apenas índice. Documento detalhado vive no backlog do workflow:
>
> [`development/backlog/UXShellRedesign/WorkspacePerMonitor/`](../../../caelestia-arch-setup/development/backlog/UXShellRedesign/WorkspacePerMonitor/) (no repo `caelestia-arch-setup`)
>
> - [Epic EPIC-002 UX Shell Redesign](../../../caelestia-arch-setup/development/backlog/UXShellRedesign/UXShellRedesign.md)
> - [Feature FEAT-002 Workspace Groups per Monitor](../../../caelestia-arch-setup/development/backlog/UXShellRedesign/WorkspacePerMonitor/WorkspacePerMonitor.md)
> - [User Story US-005](../../../caelestia-arch-setup/development/backlog/UXShellRedesign/WorkspacePerMonitor/US-005-WorkspaceGroupsPerMonitor/US-005-WorkspaceGroupsPerMonitor.md)
> - [Plano técnico TSK-005](../../../caelestia-arch-setup/development/backlog/UXShellRedesign/WorkspacePerMonitor/US-005-WorkspaceGroupsPerMonitor/TSK-005-plan-WorkspaceGroupsPerMonitor.md)

---

## 📋 Resumo

Reorganizar workspaces no bar e Hyprland em **grupos de 3 workspaces por monitor**, com identidade hardware-based (`desc:`) e plug-and-play estável a hotplug.

Substitui o modelo atual ("5 bubbles globais com offset") que é confuso em setup multi-monitor — bar do laptop e bar do HDMI externo mostram aparentemente as mesmas bubbles 1-5 mesmo quando workspaces ativas estão em monitores diferentes.

## 🎯 Modelo conceitual

```
Sistema = N monitores conectados
  Monitor = M grupos (G1, G2, G3...)
    Grupo = 3 workspaces (bubbles)

Invariantes:
- Workspaces de um grupo SEMPRE no mesmo monitor.
- Identidade do monitor é por hardware (desc:), não por porta.
- Plug-and-play: monitor novo entra automaticamente em role livre.
```

## 🎮 Atalhos novos

| Atalho | Ação |
|--------|------|
| `Alt+1`/`Alt+2`/`Alt+3` | Vai pro slot 1/2/3 do grupo atual |
| `Alt+Tab` | Próximo slot no grupo (cicla 1→2→3→1) |
| `Alt+Shift+Tab` | Slot anterior |
| `Super+Tab` | Próximo grupo do mesmo monitor |
| `Super+Shift+Tab` | Grupo anterior do mesmo monitor |
| `Super+1`/`Super+2`/`Super+3` | Mover janela ativa pro slot 1/2/3 |

⚠️ **Conflito**: Hyprland default `Alt+Tab` faz `cyclenext` (próxima janela). Reassignar em Fase 4.

## 🏗️ Arquitetura (4 camadas)

1. **Hyprland workspace rules** geradas dinamicamente via script (`workspace-allocator.sh`)
2. **MonitorRoles service** (QML singleton) — resolve `{primary, secondary, tertiary}`
3. **Bar UI** — `WorkspacesPerMonitor.qml` + 3 sub-componentes
4. **Hyprland binds** — scripts em `scripts/window-management/` invocados via `caelestia-binds.conf`

## 📦 Estrutura nova

**Plugin C++**:
- `plugin/src/Caelestia/Config/rootconfig.hpp` — adicionar `monitorRoleOverrides: QVariantMap`

**QML services**:
- `services/MonitorRoles.qml` (singleton novo)

**QML bar components**:
- `modules/bar/components/workspaces/WorkspacesPerMonitor.qml` (orquestrador)
- `modules/bar/components/workspaces/GroupCycleIndicator.qml` (●○○ dots)
- `modules/bar/components/workspaces/WorkspaceGroup.qml` (3 bubbles)
- `modules/bar/components/workspaces/OtherMonitorsSummary.qml` (pills compactos)

**Scripts (no repo `caelestia-arch-setup`)**:
- `scripts/system/caelestia-workspace-allocator.sh`
- `scripts/system/caelestia-workspace-listener.sh`
- `scripts/window-management/hypr-ws-slot.sh`
- `scripts/window-management/hypr-ws-cycle.sh`

## 🔢 Workspace ID layout

```
primary monitor:   ws  1..15  (G1=1-3, G2=4-6, G3=7-9, G4=10-12, G5=13-15)
secondary:         ws 100..114
tertiary:          ws 200..214
```

Display no bar: bubbles mostram **posição no grupo (1, 2, 3)** — IDs raw escondidos.

## ✅ Critérios de aceite

- Bar mostra grupo atual do monitor com 3 bubbles
- GroupCycleIndicator (●○○) quando >1 grupo no monitor
- OtherMonitorsSummary (pills) quando >1 monitor
- Atalhos Alt+1/2/3, Alt+Tab, Super+Tab funcionando
- Plug/unplug monitor sem perder workspaces
- Estável a reboot

## 🚧 Fases (ver TSK-005 detalhado)

| Fase | Entrega | Tempo |
|------|---------|-------|
| 1 | MonitorRoles service | 1.5h |
| 2 | Workspace allocator + Hyprland wsbind dinâmico | 2h |
| 3 | Bar UI components | 3h |
| 4 | Keybinds Alt+1/2/3, Alt+Tab, Super+Tab | 1h |

## 🔗 Substitui / supersede

- **Plano 24 (Workspace Visual Grouping)** — implementado anteriormente, mas era apenas separação visual de janelas dentro do mesmo workspace. Esta feature redesenha totalmente o conceito de workspaces.
- **Item 24 de `01-pendencias.md`** ("Não está aparecendo a tray...") foi resolvido independentemente.
