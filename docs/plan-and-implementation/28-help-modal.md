# ❓ Help Modal - Keyboard Shortcuts

**ID**: 28  
**Status**: ✅ Substituído (2026-10-18) pela página **Nexus › Keyboard › Shortcuts** (`modules/nexus/pages/keyboard/ShortcutsPage.qml` + `shortcuts.js`), que lê os atalhos ao vivo do Hyprland (`hyprctl binds -j`, categoria no `desc` do `binds.lua`) e abre/fecha com `Super + /` (IPC `nexus togglePage keyboard 2`). Spec no setup: `docs/superpowers/specs/2026-10-18-keyboard-shortcuts-page-design.md`  
**Complexidade**: 🟡 Média  
**Tempo Estimado**: concluído

---

## 📋 Resumo

Modal com lista de atalhos de teclado disponíveis no sistema.

---

## ✅ Estado Atual: IMPLEMENTADO

**Arquivo**: `modules/help/HelpModal.qml` (212 linhas)

### Recursos implementados:
- ✅ Modal popup com lista categorizada de shortcuts
- ✅ 6 categorias: Navigation, Window Management, Applications, Session, Screenshots, Caelestia Shell
- ✅ Layout em 2 colunas com GridLayout
- ✅ Badges estilo kbd com efeito 3D
- ✅ Scrollable com StyledFlickable + StyledScrollBar
- ✅ Property `showing` para controle de visibilidade
- ✅ Shortcut Super+F1 para abrir (configurado no shell)

---

## 📂 Arquivos Existentes

### `modules/help/HelpModal.qml`

\`\`\`qml
Item {
    id: root
    property bool showing: false
    visible: showing

    readonly property var shortcuts: [
        { category: qsTr("Navigation"), items: [
            { keys: "Super + 1-5", action: qsTr("Switch to workspace") },
            { keys: "Super + Tab", action: qsTr("Next workspace group") },
            // ... mais items
        ]},
        { category: qsTr("Window Management"), items: [...] },
        { category: qsTr("Applications"), items: [...] },
        { category: qsTr("Session"), items: [...] },
        { category: qsTr("Screenshots"), items: [...] },
        { category: qsTr("Caelestia Shell"), items: [...] }
    ]
    
    StyledRect {
        // Modal com GridLayout 2 colunas
        // Badges kbd-style com efeito 3D
    }
}
\`\`\`

---

## 🔄 Melhorias Futuras (Opcional)

Se desejar, pode-se migrar os shortcuts hardcoded para:
1. Ler de \`keyboard-shortcuts.md\` como fonte única
2. Criar \`config/HelpConfig.qml\` para persistência

**Decisão**: Manter hardcoded (mais simples, já funciona) ou migrar para arquivo externo?

---

## ✅ Validações Confirmadas (2026-02-05)

| Item | Status |
|------|--------|
| HelpModal.qml | ✅ Existe (212 linhas) |
| Shortcuts hardcoded | ✅ 6 categorias implementadas |
| Layout 2 colunas | ✅ GridLayout |
| Badges kbd-style | ✅ Com efeito 3D |
| Shortcut Super+F1 | ✅ Configurado |

---

**Ver também**: \`36-help-dashboard-tab.md\` (versão como aba no Dashboard)
