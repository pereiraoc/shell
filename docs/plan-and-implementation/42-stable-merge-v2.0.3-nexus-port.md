# 42 — Merge stable v2.0.3 + port das features para o "nexus"

> **Plano de execução auto-contido.** Tudo que é preciso pra continuar no Claude Code (terminal) está aqui. Não precisa re-rodar recon.
> Criado 2026-06-20 (FEAT-002 / US-007). Repo: `caelestia-shell-pereiraoc-patch`.

## 0. TL;DR

O upstream `v2.0.3` **reescreveu a UI de settings**: matou `modules/controlcenter/` (nosso) e criou `modules/nexus/` (46 arquivos), e migrou TODA a config de QML (`qs.config`) para C++ (`Caelestia.Config`). Por isso o merge stable é um **port** das nossas features, não um merge mecânico. Objetivo: ir pra stable preservando nossas features (menos as dropadas), com config 100% em C++.

## 1. Estado atual (2026-06-20)

- Fork em `main` @ `f19790e6` (limpo). Snapshot de segurança: branch **`pre-upstream-sync-2026-06-20`** (fork) e idem no `quickshell-patched`.
- `quickshell` já convergido ao pacote oficial `extra/quickshell 0.3.0` (FEAT-002/US-006). Plugin C++ atual instalado em `/usr/lib/qt6/qml/Caelestia/`.
- O merge `v2.0.3` já foi **ensaiado e abortado**. Resultado conhecido: **14 conflitos**; o plugin C++ **compila** com nossas adições (validado).
- `~/.config/quickshell/caelestia` (deploy) NÃO é git checkout — é cópia (via `deploy-to-user-config.sh`).

## 2. Decisões (do usuário — fixas)

- **DROPAR** (mapeado p/ revisitar em `caelestia-arch-setup` US-011):
  - Help modal (Super+F1) — já estava desativado.
  - Workspace por-monitor CUSTOM nosso (`MonitorRoles`/`GroupCycleIndicator`/`MonitorSection`). Usar o **`perMonitorWorkspaces` nativo** do upstream (`Config.bar.workspaces.perMonitorWorkspaces`, já existe no C++).
- **IMPLEMENTAR (não adiar):** lock auth face/PIN/senha; GPU Mode Selector; **Security/PIN UI** (→página nexus); **Apps** (→página nexus); **Gaps** (→página nexus); **toggle de Taskbar nosso** (`showGpuMode` → nexus). Preservar também: brilho piso 5%, fix launcher (AppEntry), idle AC/bateria, fix de Visibilities.
- **Config:** migrar **100% para C++ `Caelestia.Config`** (caminho limpo). **Remover** `qs.config` (dir `config/` QML). NÃO manter dois sistemas.
- **Validação (regra dura):** `qmllint` (parse/marcadores/sintaxe) + `cmake --build` do plugin. ⚠️ **NUNCA** subir compositor aninhado/headless (derrubou a sessão em 2026-06-20 — ver memória `feedback-never-nested-compositor-on-live`). Validação visual/funcional = **usuário** na sessão dele. Deploy só com OK do usuário; rollback pronto.

## 3. Arquitetura nexus (como portar uma tela do control-center)

Uma "página" nexus é uma **tríade alinhada por índice** entre dois singletons:
- `modules/nexus/PageRegistry.qml` → lista `pages` de metadados `{label, icon (Material Symbols), description, category}`. `category` ∈ `appearance|connectivity|system|shell|about` (só agrupa visual no NavPane).
- `modules/nexus/PageCompRegistry.qml` → lista `pageComps` (Components) **no MESMO índice**. Padrão: `Component { StackPage { Component { MinhaPagina {} } /*sub-páginas*/ } }`. Índice faltante cai no `placeholderComp` ("under construction") — não crasha, mas mascara erro. **Conferir contagem dos dois arrays.**
- Conteúdo: arquivo em `modules/nexus/pages/` herdando `PageBase` (`required title:string`, `required nState:NexusState` injetado automático, `cappedWidth=min(800,width)`, `default contentChild` = 1 `Item`). Embrulhar tudo num único `ColumnLayout`.

Esqueleto de página:
```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root
    title: qsTr("Minha página")
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader { first: true; text: qsTr("Geral") }
        ToggleRow {
            Layout.fillWidth: true; first: true; last: true
            text: qsTr("Algo"); subtext: qsTr("desc")
            checked: Config.grupo.flag
            onToggled: GlobalConfig.grupo.flag = checked
        }
    }
}
```
Rows prontas em `modules/nexus/common/`: `ToggleRow{text;subtext;checked;onToggled}`, `SliderRow{icon;label;valueLabel;value(0..1);onMoved(v)}`, `StepperRow{label;subtext;value;from;to;stepSize;onMoved(v)}` (inteiros), `SelectRow{label;subtext;menuItems;active;onSelected(item)}` (dropdown), `NavRow{icon;label;status;onClicked}` (sub-página via `nState.openSubPage(N)`), `InfoRow{label;value}`, `SectionHeader{text;first}`. **`first`/`last` são manuais** (arredondam cantos do grupo via ConnectedRect).

Abertura do nexus: keybind `nexus` (CustomShortcut em `modules/Shortcuts.qml`) + IPC `nexus open` → `WindowFactory.create()`. (Antes era `controlCenter`/`controlcenter open` — renomear keybinds externos no `caelestia-arch-setup` se houver.)

## 4. Config em C++ (`Caelestia.Config`) — padrão

- **LER** = `Config.<grupo>.<key>` (attached, por-tela, read-only). **ESCREVER** = `GlobalConfig.<grupo>.<key> = v` (singleton, persiste sozinho com debounce em `~/.config/caelestia/shell.json`).
- Chave nova num subobjeto existente: só editar o header do subobjeto (ex.: `plugin/src/Caelestia/Config/barconfig.hpp` classe `BarStatus`): `CONFIG_PROPERTY(bool, showGpuMode, true)` (por-tela) ou `CONFIG_GLOBAL_PROPERTY(...)` (global-only, avisa em overlay por-monitor). Exposição em `Config`/`GlobalConfig` é automática (CONFIG_SUBOBJECT). **Não** mexer em `configattached.hpp` p/ campo de subobjeto.
- Subobjeto/raiz NOVO (ex.: `HyprlandConfig` p/ gaps): criar header + `Q_MOC_INCLUDE` e `CONFIG_SUBOBJECT(HyprlandConfig, hyprland)` em `config.hpp` + inicializar `m_hyprland = new HyprlandConfig(this)` no construtor em `config.cpp` + `Q_MOC_INCLUDE`/`Q_PROPERTY`/getter em `configattached.hpp` + getter em `configattached.cpp`. Headers entram no `SOURCES` do `Config/CMakeLists.txt`. **Rebuild do plugin** depois.
- ⚠️ Chave em `shell.json` sem declaração C++ → toast `unknownOption` a cada reload (`modules/ConfigToasts.qml`). Toda chave custom PRECISA existir no C++.

## 5. Conflitos do merge (14) — estratégia de resolução

| Arquivo | Tipo | Resolução |
|---|---|---|
| `modules/lock/Pam.qml` | UU | base=**upstream** + re-aplicar nossas adições (§6.1) |
| `modules/lock/Center.qml` | UU | base=**upstream** + inserir só o `AuthMethodSelector` (§6.1) |
| `modules/lock/InputField.qml` | UD (deletado) | `git rm`; portar SÓ o placeholder mode-specific p/ `modules/lock/center/PasswordInput.qml` |
| `modules/bar/components/workspaces/Workspace.qml` | UU | `git checkout --theirs` (drop workspace custom) |
| `modules/bar/components/workspaces/Workspaces.qml` | UU | `git checkout --theirs` |
| `modules/controlcenter/PaneRegistry.qml` | UD | `git rm` (controlcenter morreu) |
| `modules/controlcenter/appearance/AppearancePane.qml` | UD | `git rm` |
| `modules/controlcenter/taskbar/TaskbarPane.qml` | UD | `git rm` |
| `modules/bar/components/Tray.qml` | UU | `git checkout --theirs` (nosso diff era só remover log de debug — sem perda) |
| `modules/bar/components/TrayItem.qml` | UU | `git checkout --theirs` (idem) |
| `modules/dashboard/Media.qml` | UU | `git checkout --theirs` (nosso era tweak "F6" de 3 linhas; reavaliar se F6 ainda quer) |
| `modules/session/Content.qml` | UU | `git checkout --theirs` (tweak 1 linha) |
| `modules/Shortcuts.qml` | UU | **manual**: base upstream + re-adicionar nossos binds custom (conferir o que é nosso; GPU=F2, etc.) |
| `shell.qml` | UU | base=**upstream**; dropar `MonitorRoles` (workspaces dropados) e o `import qs.config`/aplicação de gaps no boot (gaps via página nexus + C++) |

Comandos mecânicos (Fase A):
```bash
git switch -c sync/stable-2026-06 main && git merge --no-edit v2.0.3   # 14 conflitos
git checkout --theirs modules/bar/components/workspaces/Workspace.qml modules/bar/components/workspaces/Workspaces.qml \
  modules/bar/components/Tray.qml modules/bar/components/TrayItem.qml modules/dashboard/Media.qml modules/session/Content.qml
git add <os acima>
git rm modules/controlcenter/PaneRegistry.qml modules/controlcenter/appearance/AppearancePane.qml \
  modules/controlcenter/taskbar/TaskbarPane.qml modules/lock/InputField.qml
# restam manuais: lock/Pam.qml, lock/Center.qml, modules/Shortcuts.qml, shell.qml
```

## 6. Port por feature

### 6.1 Lock auth face/PIN (merge cirúrgico — CRÍTICO, validar com senha de fallback garantida)
Config já alinhada: `plugin/src/Caelestia/Config/lockconfig.hpp` (auto-merge preserva nossas 7 chaves `CONFIG_GLOBAL_PROPERTY`: enableFaceAuth, enablePinAuth, defaultMethod=`face`, userPin, maxFaceRetries=3, maxPinRetries=10, maxPasswordRetries=30). Ajustar `recolourLogo` p/ `false` (nossa pref). `config/LockConfig.qml` (QML) é **morto** → remover.
- **Pam.qml**: tomar a base do upstream (estruturalmente = nossa base) e re-inserir: aliases/props (`howdy` PamContext, `howdyState`, `currentMode=GlobalConfig.lock.defaultMethod`, `faceEnabled`/`pinEnabled`, contadores), `pinSalt='caelestia-lock-2026'` + `hashPin()`/`verifyPin()`, ramo PIN em `handleKey` (só dígitos, auto-submit em 4) ANTES do ramo password — **manter a regex nova do upstream** `/^[^\x00-\x1F\x7F-\x9F]+$/`, só prefixar o ramo PIN; `Process howdyAvailProc` (`command -v howdy` + `ls /etc/howdy/models/$USER.dat`); timers howdy; `onCurrentModeChanged` (reset contadores + `howdy.checkAvail()`); Connections extras (`onEnableFaceAuthChanged`, reset `currentMode` em `onSecureChanged`, `howdy.abort()` em onUnlock).
- **AuthMethodSelector.qml**: mover `modules/lock/AuthMethodSelector.qml` → `modules/lock/center/AuthMethodSelector.qml` (autocontido; trocar `font.pointSize` pelos builders `Tokens.font.*` novos).
- **Center.qml**: base=upstream (monta `center/{Clock,ProfilePic,PasswordInput,StateMessage}`) + inserir UM `AuthMethodSelector{}` entre ProfilePic e PasswordInput, ligando `selectedMethod ↔ lock.pam.currentMode`, `faceEnabled/pinEnabled`. Descartar o resto da nossa Center antiga.
- **center/PasswordInput.qml**: no `TextMetrics nonAnimPlaceholder.text`, adicionar ramos: `pam.currentMode==='face'` → "Look directly at the camera"; `==='pin'` → "Enter your 4-digit PIN"; `pam.passwd.active` → "Authenticating...". Render dos chars = manter o do upstream (MaterialShape).
- **center/StateMessage.qml**: estender o getter `msg` com estados howdy/PIN (face não reconhecido n/maxFaceRetries → troca pra PIN/senha; PIN incorreto/sem-PIN).
- **assets/pam.d/howdy**: nosso, garantir que é deployado (não existe no upstream). `PamContext howdy.configDirectory: Quickshell.shellDir + '/assets/pam.d'`.

### 6.2 GPU Mode Selector (sobrevive quase intacto)
`services/GpuModeService.qml` (singleton) e `modules/bar/popouts/GpuMode.qml` (popout do bar) **sobrevivem** — só ajustar imports `Appearance.*`(qs.config)→`Tokens.*`/`Colours.*` se houver. Re-wire: `showGpuMode` no C++ (`barconfig.hpp` `BarStatus`: `CONFIG_PROPERTY(bool, showGpuMode, true)`) + `modules/bar/components/StatusIcons.qml` (ícone "memory", lê `Config.bar.status.showGpuMode && GpuModeService.available`) + `modules/bar/popouts/Content.qml` (`Popout{name:"gpumode"; sourceComponent: GpuMode{}}`). Depende do helper `sudo /usr/local/bin/gpu-mode-persist` + supergfxd (no caelestia-arch-setup). Opcional: SelectRow numa página nexus reusando `GpuModeService`.

### 6.3 Security/PIN → página nexus nova (`modules/nexus/pages/SecurityPage.qml`)
PageRegistry `{label:"Security", icon:"security", description:"PIN, face auth", category:"system"}` + Component alinhado. Reimplementar com `ToggleRow` (enable face / enable PIN) + campos de PIN (`StyledTextField`) + `SelectRow` (defaultMethod: face/pin/password) + botão reset. Lógica-núcleo idêntica: `pinSalt='caelestia-lock-2026'`, `hashPin=Qt.md5(salt+pin+salt)`, `savePin()` (len==4 + match → `GlobalConfig.lock.userPin=hash`), `resetLockouts()`. Fonte: `modules/controlcenter/security/SecurityPane.qml` (461 linhas) — portar UI p/ vocabulário nexus/Tokens.

### 6.4 Apps → página nexus nova (`modules/nexus/pages/AppsPage.qml`)
PageRegistry `{label:"System apps", icon:"apps", category:"system"}` + Component. Puramente declarativo: `Repeater` sobre `appCategories` (copiar array literal de `modules/controlcenter/apps/AppsPane.qml`, 210 linhas) → botões; `onClicked: Quickshell.execDetached(modelData.command)`. Sem Config.

### 6.5 Gaps → página/seção nexus + config C++
Criar subobjeto C++ `HyprlandConfig` (§4) com `CONFIG_PROPERTY(int, gapsInner, 5)`/`gapsOuter, 20` (grupo `hyprland.gaps` ou flat `hyprland.gapsInner`). UI: `StepperRow` Inner(0-30)/Outer(0-50) + presets, numa página nova (`category:"shell"`, ex. "Window management") ou seção. `onMoved`: `applyGaps()` = `Quickshell.execDetached(["hyprctl","keyword","general:gaps_in",String(v)])` (+gaps_out) e `GlobalConfig.hyprland.gapsInner = v`. Boot: ler `Config.hyprland.gaps*` e aplicar (substitui a lógica antiga do `shell.qml` que usava qs.config). Fonte: `modules/controlcenter/appearance/sections/GapsSection.qml`.

### 6.6 Taskbar toggle (showGpuMode)
Adicionar `ToggleRow` "GPU mode" em `modules/nexus/pages/panels/taskbar/BarStatusIcons.qml` lendo `Config.bar.status.showGpuMode` / escrevendo `GlobalConfig.bar.status.showGpuMode`. (resto da nossa TaskbarPane antiga é coberto pelo nexus.)

### 6.7 Features auto-mergeadas (verificar quebra por qs.config)
`services/Brightness.qml` (piso 5%), `modules/launcher/*` (AppEntry fix), `modules/IdleMonitors.qml` (idle AC/bateria — usa `Config.general.idle.timeoutsOnAC/onBattery` CUSTOM — upstream tem `timeouts` único: precisa **migrar p/ C++** ou adaptar p/ `timeouts`), `services/Visibilities.qml` (key por screen.name — fix de hotplug). Todas auto-mergearam mas várias **importam `qs.config`** → ao remover `config/`, migrar cada uma p/ `Caelestia.Config` (`Config.*`). Rodar `git grep -l "qs.config"` e migrar todos os consumidores.

## 7. Limpeza (Fase F)
Após resolver tudo: `git rm -r modules/controlcenter/ modules/help/ config/ services/MonitorRoles.qml modules/bar/components/workspaces/{GroupCycleIndicator,MonitorSection}.qml`. Conferir que nada importa mais `qs.config`/`controlcenter`/`MonitorRoles`/`qs.modules.help` (`git grep`). Remover `modules/drawers/Panels.qml` refs ao help (já comentadas) e o keybind do help em `Shortcuts.qml`.

## 8. Gates de validação (Fase G)
1. `git grep -nE '^(<<<<<<< |>>>>>>> )'` → zero marcadores.
2. `git grep -l "qs.config"` → vazio (migração completa).
3. `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DENABLE_MODULES=plugin && cmake --build build` → compila.
4. `qmllint` (parse) nos QML alterados/novos: `for f in $(git diff --name-only main -- '*.qml'); do /usr/lib/qt6/bin/qmllint "$f"; done` (ignorar falso-positivo de `qs.*` imports — focar em sintaxe/marcadores/erros locais).
5. ⚠️ **NÃO** rodar quickshell/Hyprland aninhado. Deploy só com OK do usuário:
   `sudo cmake --install build && bash scripts/deploy-to-user-config.sh && sudo rm -rf /etc/xdg/quickshell/caelestia`
6. Usuário valida na GUI (lock auth com senha de fallback PRIMEIRO!) + soak. Só então `git checkout main && git merge --ff-only sync/stable-2026-06`.

## 9. Rollback
`git reset --hard pre-upstream-sync-2026-06-20` (fork) · restaurar `~/.config/quickshell/caelestia.snapshot-*` · reinstalar plugin do snapshot. Nada toca `main` até validação.

## 10. Sequência recomendada
A (merge+mecânicos) → B (C++: showGpuMode, recolourLogo=false, HyprlandConfig/gaps) → build → C (lock auth) → E (GPU rewire + migrar qs.config dos auto-mergeados) → D (páginas nexus Security/Apps/Gaps + taskbar toggle) → F (limpeza) → G (gates + deploy com OK). Lock auth e GPU primeiro (diário). Gaps/Apps/Security depois. Workspaces: nada a fazer (upstream nativo).
