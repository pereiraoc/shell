# 📋 Pendências e Tarefas

**Última Atualização**: 2026-02-01  
**Progresso**: 3/19 tarefas concluídas (16%)

---

## 📊 Resumo

| Status | Quantidade |
|--------|------------|
| ✅ Concluídas | 3 |
| ⏱️ Pendentes | 16 |
| **TOTAL** | **19** |

---

## ✅ Concluídas

### 21. Lock Screen - Auth Method Selector

**Status**: ✅ Implementado (v0.1.0)  
**Data**: 2026-01-19  
**Detalhes**: [plan-and-implementation/21-lock-screen-auth-selector.md](plan-and-implementation/21-lock-screen-auth-selector.md)

**Resumo**:
- Seletor visual Face/PIN/Password
- Integração com Howdy
- Auto-desabilitação após falhas
- 276 linhas de código

---

### 25. Gaps Configuration

**Status**: ✅ Implementado (v0.1.0)  
**Data**: 2026-02-01  
**Detalhes**: [plan-and-implementation/25-gaps-configuration.md](plan-and-implementation/25-gaps-configuration.md)

**Resumo**:
- GapsSection e HyprlandConfig já existem
- Sliders para gaps_in e gaps_out no Appearance pane
- Aplicação via Hyprland IPC

---

### 24. Workspace Visual Grouping

**Status**: ✅ Implementado  
**Data**: 2026-02-01  
**Detalhes**: [plan-and-implementation/24-workspace-visual-grouping.md](plan-and-implementation/24-workspace-visual-grouping.md)

**Resumo**:
- StyledRect container com borda por workspace
- Pacman removido (occupiedLabel/activeLabel vazios)
- Highlight do workspace ativo

---

---

## ⏱️ Pendentes

### Fase 1: Quick Wins (Rápidas - 1-2h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 23 | Remover GIFs (kurukuru/bongocat) — quase feito | ~30min | [23-assets-customization.md](plan-and-implementation/23-assets-customization.md) |
| ~~24~~ | ~~Remover ícone pacman + Agrupar workspaces~~ | ~~3-4h~~ | ~~[24-workspace-visual-grouping.md](plan-and-implementation/24-workspace-visual-grouping.md)~~ ✅ |

### Fase 2: Modificações Médias (2-6h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| ~~25~~ | ~~Configurar gaps via UI~~ | ~~3-4h~~ | ~~[25-gaps-configuration.md](plan-and-implementation/25-gaps-configuration.md)~~ ✅ |
| 26 | Widget Shortcuts configurável | 6-8h | [26-shortcuts-widget.md](plan-and-implementation/26-shortcuts-widget.md) |
| 27 | Widget Games (Steam) | 8-10h | [27-games-widget.md](plan-and-implementation/27-games-widget.md) |
| 28 | Botão Help com shortcuts | 2-3h | [28-help-modal.md](plan-and-implementation/28-help-modal.md) |

### Fase 3: Features Novas (4-8h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 29 | Configuration (ex-Apps) - painel configurável | 4-6h | [29-apps-integration.md](plan-and-implementation/29-apps-integration.md) |
| 30 | Editar ícones/nomes de apps | 6-8h | [30-launcher-customization.md](plan-and-implementation/30-launcher-customization.md) |
| 33 | Weather multi-locations | 4-6h | [33-weather-multi-locations.md](plan-and-implementation/33-weather-multi-locations.md) |
| 34 | Notification Manager | 12-16h | [34-notification-manager.md](plan-and-implementation/34-notification-manager.md) |
| 35 | Face Reading Retry (Howdy) | 2-4h | [35-face-reading-retry-howdy.md](plan-and-implementation/35-face-reading-retry-howdy.md) |
| 36 | Help Dashboard Tab | 3-4h | [36-help-dashboard-tab.md](plan-and-implementation/36-help-dashboard-tab.md) |
| 37 | Software Manager - atualizar/remover apps | A definir | [37-software-manager.md](plan-and-implementation/37-software-manager.md) |

### Fase 4: Sistema Complexo (10h+)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 31 | Tema preto/amarelo customizável | 10-15h | [31-theme-customization.md](plan-and-implementation/31-theme-customization.md) |
| 32 | GPU Mode Selector (supergfxctl) ⭐ | 6-8h | [32-gpu-mode-selector.md](plan-and-implementation/32-gpu-mode-selector.md) |

### Futuro: Avaliar por Último

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 22 | System Tray (Steam/Spotify) — **postergado** | A definir | [22-tray-system-icons.md](plan-and-implementation/22-tray-system-icons.md) |

*Feature complexa de implementar; avaliar por último no futuro.*

---

## 🎯 Priorização Sugerida

### Alta Prioridade
1. ✅ Lock Screen (feito)
2. ✅ Gaps Configuration (25) (feito)
3. ✅ Workspace Grouping (24) (feito)
4. **GPU Mode Selector (32) - resolve problema HDMI lag** ⭐

### Média Prioridade
6. Help Modal (28) - ajuda usuários
7. Configuration (29) - painel configuráveis do sistema
8. Help Dashboard Tab (36)
9. Notification Manager (34) - requer investigação prévia

### Baixa Prioridade
10. Shortcuts Widget (26)
11. Games Widget (27)
12. Launcher Customization (30)
13. Theme Customization (31)
14. Weather multi-locations (33)
15. Face Reading Retry (35)
16. Software Manager (37) - atualizar/remover apps do PC
17. **System Tray (22) - avaliar por último** (feature complexa)

---

## 📋 Sequência de Implementação Recomendada

Para uma ordem de implementação pensada em dependências e prioridades, ver:

**[00-sequencia-implementacao.md](plan-and-implementation/00-sequencia-implementacao.md)**

Resumo: Fase 1 (23, 32) → Fase 2 (29, 28, 36) → Fase 3 (35, 26, 27) → Fase 4 (investigação + 34, 37) → Fase 5 (30, 33, 31) → Futuro (22).

---

## 📝 Como Usar Esta Lista

### Para Implementar uma Tarefa

1. Consulte a [sequência recomendada](plan-and-implementation/00-sequencia-implementacao.md) ou escolha uma tarefa da lista acima
2. Abra o plano correspondente (link na coluna "Plano")
3. Siga o plano passo a passo (é autocontido)
4. Ao concluir:
   - Atualize o plano com notas de implementação
   - Atualize `10-arquitetura.md` com visão alto nível
   - Mova a tarefa para "Concluídas" neste arquivo

### Template para Marcar Como Concluída

```markdown
### XX. Nome da Tarefa

**Status**: ✅ Implementado (vX.X.X)  
**Data**: YYYY-MM-DD  
**Detalhes**: [plan-and-implementation/XX-nome.md](plan-and-implementation/XX-nome.md)

**Resumo**:
- Feature 1
- Feature 2
- X linhas de código
```

---

## 📋 Pendências Relacionadas

- **29 (Configuration)**: Renomeou "Apps" → "Configuration". O nome "Apps" fica livre para o Software Manager (37) se desejado.
- **37 (Software Manager)**: Requer decisões sobre pacman/pamac/flatpak e nível de integração. Ver [37-software-manager.md](plan-and-implementation/37-software-manager.md).

---

## 🔮 Futuro (v0.2.0+)

Features planejadas para versões futuras (não priorizadas):

- Fingerprint reader (fprintd)
- PIN dedicado (via keyring)
- Teclado numérico visual
- Smart card (PKCS#11)
- OTP/2FA
- Bluetooth proximity unlock

---

**Quer começar?** Escolha uma tarefa e abra o plano correspondente!
