# 📋 Pendências e Tarefas

**Última Atualização**: 2026-01-23  
**Progresso**: 1/14 tarefas concluídas (7%)

---

## 📊 Resumo

| Status | Quantidade |
|--------|------------|
| ✅ Concluídas | 1 |
| ⏱️ Pendentes | 13 |
| **TOTAL** | **14** |

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

## ⏱️ Pendentes

### Fase 1: Quick Wins (Rápidas - 1-2h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 22 | System Tray (Steam/Spotify) | 1-2h | [22-tray-system-icons.md](plan-and-implementation/22-tray-system-icons.md) |
| 23 | Trocar GIFs (kurukuru/bongocat) | ❌ FEITO | [23-assets-customization.md](plan-and-implementation/23-assets-customization.md) |
| 24 | Remover ícone pacman + Agrupar workspaces | 3-4h | [24-workspace-visual-grouping.md](plan-and-implementation/24-workspace-visual-grouping.md) |

### Fase 2: Modificações Médias (2-6h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 25 | Configurar gaps via UI | 3-4h | [25-gaps-configuration.md](plan-and-implementation/25-gaps-configuration.md) |
| 26 | Widget Shortcuts configurável | 6-8h | [26-shortcuts-widget.md](plan-and-implementation/26-shortcuts-widget.md) |
| 27 | Widget Games (Steam) | 8-10h | [27-games-widget.md](plan-and-implementation/27-games-widget.md) |
| 28 | Botão Help com shortcuts | 2-3h | [28-help-modal.md](plan-and-implementation/28-help-modal.md) |

### Fase 3: Features Novas (4-8h)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 29 | Integrar apps no Control Center | 4-6h | [29-apps-integration.md](plan-and-implementation/29-apps-integration.md) |
| 30 | Editar ícones/nomes de apps | 6-8h | [30-launcher-customization.md](plan-and-implementation/30-launcher-customization.md) |

### Fase 4: Sistema Complexo (10h+)

| # | Tarefa | Tempo | Plano |
|---|--------|-------|-------|
| 31 | Tema preto/amarelo customizável | 10-15h | [31-theme-customization.md](plan-and-implementation/31-theme-customization.md) |
| 32 | GPU Mode Selector (supergfxctl) ⭐ | 6-8h | [32-gpu-mode-selector.md](plan-and-implementation/32-gpu-mode-selector.md) |

---

## 🎯 Priorização Sugerida

### Alta Prioridade
1. ✅ Lock Screen (feito)
2. **GPU Mode Selector (32) - resolve problema HDMI lag** ⭐
3. System Tray (22) - afeta usabilidade
4. Workspace Grouping (24) - melhora workflow

### Média Prioridade
5. Gaps Configuration (25) - QoL
6. Help Modal (28) - ajuda usuários
7. Apps Integration (29) - facilita acesso

### Baixa Prioridade
8. Shortcuts Widget (26)
9. Games Widget (27)
10. Launcher Customization (30)
11. Theme Customization (31)

---

## 📝 Como Usar Esta Lista

### Para Implementar uma Tarefa

1. Escolha uma tarefa da lista acima
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
