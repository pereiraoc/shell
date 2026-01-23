# 📚 Índice da Documentação

**Última Atualização**: 2026-01-23

---

## 🗂️ Estrutura de Pastas

```
docs/
├── 00-index.md                  # Este arquivo - índice e navegação
├── 10-arquitetura.md            # Visão arquitetural (alto nível das modificações)
├── 80-troubleshooting.md        # Problemas transversais (não específicos de features)
├── 99-pendencias.md             # Lista de tarefas (aponta para plan-and-implementation)
│
└── plan-and-implementation/     # Planos detalhados e autocontidos
    ├── 21-lock-screen-auth-selector.md
    ├── 22-tray-system-icons.md
    ├── 23-assets-customization.md
    ├── 24-workspace-visual-grouping.md
    ├── 25-gaps-configuration.md
    ├── 26-shortcuts-widget.md
    ├── 27-games-widget.md
    ├── 28-help-modal.md
    ├── 29-apps-integration.md
    ├── 30-launcher-customization.md
    ├── 31-theme-customization.md
    └── 32-gpu-mode-selector.md
```

---

## 📖 Guia de Navegação

### Para Entender o Projeto

1. **[README.md](../README.md)** - Comece aqui (overview do projeto)
2. **[10-arquitetura.md](10-arquitetura.md)** - Visão técnica em alto nível

### Para Implementar uma Feature

1. **[99-pendencias.md](99-pendencias.md)** - Veja a lista de tarefas
2. **[plan-and-implementation/2X-nome.md](plan-and-implementation/)** - Abra o plano específico
3. Siga o plano (é autocontido, tem tudo que precisa)
4. Ao concluir, atualize **[10-arquitetura.md](10-arquitetura.md)** com visão alto nível
5. Atualize **[99-pendencias.md](99-pendencias.md)** marcando como concluído

### Para Resolver Problemas

- **Feature específica**: Veja seção "Troubleshooting" no respectivo `plan-and-implementation/2X-nome.md`
- **Problema transversal** (build, git, quickshell): Veja **[80-troubleshooting.md](80-troubleshooting.md)**

---

## 🚫 O Que NÃO Modificar

### Estrutura do Repositório

```
caelestia-shell-pereiraoc-patch/
├── components/          ⚠️ NÃO MODIFICAR (a menos que absolutamente necessário)
├── config/              ✅ OK adicionar configs, NÃO remover existentes
├── modules/             ✅ OK modificar e adicionar
├── services/            ⚠️ CUIDADO - modificações podem quebrar o shell
├── utils/               ⚠️ CUIDADO - usado por todo o projeto
├── assets/              ✅ OK adicionar/substituir
├── plugin/              🚫 NÃO TOCAR - código C++ do Quickshell
└── CMakeLists.txt       ⚠️ Só modificar se adicionar novos módulos
```

### Arquivos de Config do Usuário

**SEMPRE faça backup antes de modificar**:
- `~/.config/caelestia/shell.json`
- `~/.config/hypr/hyprland.conf`

---

## 📏 Convenções de Código

### QML

```qml
// Componentes: PascalCase
AuthMethodSelector.qml

// Properties: camelCase
property string selectedMethod

// Signals: camelCase com prefixo on
onSelectedMethodChanged

// Imports (sempre nesta ordem):
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts
```

### Cores

```qml
// ✅ SEMPRE usar Colours.palette.*
color: Colours.palette.m3primary

// ❌ NUNCA hardcode cores
color: "#FF0000"
```

### Espaçamento

```qml
// ✅ SEMPRE usar Appearance.*
spacing: Appearance.spacing.normal
radius: Appearance.rounding.small

// ❌ NUNCA hardcode valores
spacing: 10
```

---

## 🔄 Workflow de Implementação

### 1. Antes de Começar

```bash
# Branch correta
git checkout main

# Backup do config
cp ~/.config/caelestia/shell.json ~/.config/caelestia/shell.json.backup
```

### 2. Durante o Desenvolvimento

```bash
# Editar arquivos QML

# Rebuild (se modificou C++/CMakeLists)
cmake --build build

# Reinstalar (se necessário)
sudo cmake --install build

# Reiniciar Quickshell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize

# Ver logs
tail -f /run/user/1000/quickshell/by-id/*/log.qslog
```

### 3. Após Concluir

1. Teste todas as funcionalidades
2. **Atualize o plano** em `plan-and-implementation/2X-nome.md` com notas de implementação
3. **Atualize arquitetura** em `10-arquitetura.md` com visão alto nível
4. **Atualize pendências** em `99-pendencias.md` marcando como concluído
5. Commit com mensagem descritiva

---

## 📚 Estrutura dos Planos

Cada arquivo em `plan-and-implementation/` é **autocontido** e contém:

- ✅ Resumo e objetivos
- ✅ Arquivos a modificar/criar
- ✅ Código de exemplo
- ✅ Passo a passo de implementação
- ✅ Testes
- ✅ Troubleshooting específico da feature
- ✅ Referências

**Não precisa consultar outros arquivos para implementar.**

---

## 🎯 Numeração dos Arquivos

### Documentação Principal

- `00-` = Índice/navegação
- `10-` = Arquitetura (visão geral)
- `80-` = Troubleshooting transversal
- `99-` = Pendências/roadmap

### Planos de Implementação

- `21-31` = Planos individuais (cada um autocontido)

Para adicionar novo plano: `32-nome-da-feature.md`

---

**Dúvidas?** Comece pelo [README.md](../README.md) e depois volte aqui para navegar!
