# 🔔 Notification Manager

**ID**: 34 (V3-10)  
**Status**: ⏱️ Planejado  
**Complexidade**: 🔴 Alta  
**Tempo Estimado**: 12-16h

---

## 📋 Resumo

Histórico de notificações + bloquear/desbloquear por app + definir ícone para notificações sem ícone.

---

## 🎯 Objetivos

- Histórico de notificações (persistir em memória ou SQLite)
- Bloquear/desbloquear notificações por app
- Definir ícone override para apps sem ícone
- Painel Notifications no Control Center

---

## 🏗️ Arquitetura

```mermaid
flowchart TB
    subgraph Config [Config]
        NC[NotifsConfig]
        NC --> Blocked[blockedApps]
        NC --> Icons[iconOverrides]
    end
    
    subgraph Service [Service]
        Notifs[Notifs.qml]
        Notifs --> QS[Quickshell Notifications]
    end
    
    subgraph Pane [UI]
        NP[NotificationsPane]
        NP --> Tab1[Histórico]
        NP --> Tab2[Bloqueados]
        NP --> Tab3[Ícones]
    end
    
    Config <--> Notifs
    Notifs -->|exibir| QS
    Notifs <--> Pane
```

### Fluxo de Exibição de Notificação

```mermaid
sequenceDiagram
    participant App as App externo
    participant QS as Quickshell Notifications
    participant Notifs as Notifs.qml
    participant Config as NotifsConfig

    App->>QS: notificação
    QS->>Notifs: nova notificação
    Notifs->>Config: appName in blockedApps?
    alt Bloqueado
        Notifs->>Notifs: não exibir popup
    else Permitido
        Notifs->>Config: iconOverrides[appName]
        Notifs->>QS: exibir com ícone
    end
```

---

## 📂 Estrutura de Arquivos

### 1. `config/NotifsConfig.qml` - Estender

```qml
property list<string> blockedApps: []
property var iconOverrides: {}  // appName -> icon path ou nome
```

### 2. `services/Notifs.qml` - Modificar

- Ao exibir notificação: verificar se `appName` está em `blockedApps`; se sim, não exibir popup (ou exibir em área "bloqueadas")
- Ao exibir ícone: usar `iconOverrides[appName] ?? notif.appIcon ?? defaultIcon`
- Histórico: Notifs já persiste `notClosed` via `storage.setText`. Verificar se há lista de histórico completo ou apenas notificações abertas. Se não houver histórico, adicionar lista que retenha últimas N notificações (appName, summary, body, icon, timestamp)

### 3. `modules/controlcenter/notifications/NotificationsPane.qml` (novo)

```qml
// Abas ou seções:
// - Histórico: lista de notificações recentes
// - Bloqueados: lista de apps com toggle block/unblock
// - Ícones: lista de apps com campo icon override
```

### 4. `modules/controlcenter/PaneRegistry.qml`

Adicionar pane `{ id: "notifications", label: "notifications", icon: "notifications", component: "notifications/NotificationsPane.qml" }`

---

## 🔧 Implementação

1. **Config** (1h): Estender NotifsConfig com blockedApps, iconOverrides. Serialize em Config.qml.
2. **Histórico** (3-4h): Verificar se Toaster/Notifs já armazena histórico. Se não, adicionar lista em Notifs que retenha últimas N notificações.
3. **Bloquear** (2-3h): Ao exibir, verificar blockedApps. Não exibir popup se bloqueado.
4. **Ícone override** (1-2h): Ao exibir, usar iconOverrides[appName] ?? notif.appIcon.
5. **Pane** (4-5h): NotificationsPane com abas Histórico, Bloqueados, Ícones.

**Total**: 12-16h

---

## ⚠️ Complexidade

**Alta** — depende da estrutura interna do Quickshell Notifications. O Notifs.qml usa `NotificationServer` do Quickshell; o histórico pode já existir via `storage.setText`.

---

## ✅ Validações Confirmadas (2026-02-05)

| Item | Decisão |
|------|---------|
| Histórico | ✅ Já existe! `Notifs.qml` persiste em `${Paths.state}/notifs.json` |
| Storage | `FileView` + `storage.setText()` (linhas 88-102) |
| NotificationServer | Quickshell.Services.Notifications (linhas 62-81) |
| Config list | Usar `list<string>` para blockedApps |

### 🔬 Investigação Concluída (2026-02-05)

**Estrutura atual do Notifs.qml:**

```qml
// services/Notifs.qml (339 linhas)
property list<Notif> list: []
readonly property list<Notif> notClosed: list.filter(n => !n.closed)
readonly property list<Notif> popups: list.filter(n => n.popup)
property alias dnd: props.dnd

// Persistência existente (linhas 36-55):
Timer {
    id: saveTimer
    interval: 1000
    onTriggered: storage.setText(JSON.stringify(root.notClosed.map(n => ({
        time: n.time,
        id: n.id,
        summary: n.summary,
        body: n.body,
        appIcon: n.appIcon,
        appName: n.appName,
        // ... mais campos
    }))))
}

// FileView para persistência (linhas 88-102):
FileView {
    id: storage
    path: `${Paths.state}/notifs.json`
    onLoaded: { /* parse JSON */ }
}
```

**Achados importantes:**
1. ✅ Histórico **já existe** — persiste `notClosed` em `notifs.json`
2. ✅ `appName` disponível para filtro de blockedApps
3. ✅ `appIcon` disponível para iconOverrides
4. ⚠️ Histórico atual só persiste `notClosed` (não fechadas) — pode precisar ajuste para histórico completo

**Implementação simplificada:**
- Para blockedApps: adicionar check em `onNotification` (linha 74)
- Para iconOverrides: modificar lógica de ícone no delegate
- Histórico: já funciona, pode expandir para N últimas

---

## 🧪 Testes

- [ ] Histórico exibe notificações recentes
- [ ] Bloquear app → notificações não aparecem
- [ ] Desbloquear app → notificações voltam
- [ ] Ícone override aplica corretamente
- [ ] Persistência em shell.json

---

## 📚 Referências

- **Fonte**: [21-caelestia-custom-v3.md](../../../caelestia-arch-setup/development/docs/21-caelestia-custom-v3.md) — V3-10
- **Estado atual**: `services/Notifs.qml` — NotificationServer, PersistentProperties
- **NotifsConfig**: `config/NotifsConfig.qml` — sizes, expire, etc.
