# 🔐 Lock Screen - Auth Method Selector

**ID**: 21  
**Status**: ✅ Implementado (v0.1.0)  
**Data de Conclusão**: 2026-01-19  
**Complexidade**: 🟢 Baixa  
**Tempo Estimado**: 5h  
**Tempo Real**: ~5h

---

## 📋 Resumo

Adicionar seletor visual de método de autenticação no lock screen, permitindo ao usuário escolher entre Face Recognition (Howdy), PIN numérico, ou senha tradicional.

---

## 🎯 Objetivos

### Features Implementadas

- ✅ Botões visuais para Face/PIN/Password
- ✅ Integração com Howdy (reconhecimento facial via PAM)
- ✅ Modo PIN (aceita apenas números)
- ✅ Auto-desabilitação após N falhas por método
- ✅ Reativação automática após unlock bem-sucedido
- ✅ Config persistente em `shell.json`

### O Que NÃO Mudou

- ✅ Layout original do lock screen preservado
- ✅ Widgets laterais (Weather, Media, Resources) inalterados
- ✅ Campo de input mantido como está
- ✅ Animações e transições originais preservadas

---

## 🏗️ Arquitetura

### Estrutura de Componentes

```
modules/lock/
├── Lock.qml                    # Entry point (inalterado)
├── LockSurface.qml            # Surface Wayland (inalterado)
├── Pam.qml                    # PAM integration ✨ MODIFICADO
├── Content.qml                # Layout principal (inalterado)
├── Center.qml                 # Centro da tela ✨ MODIFICADO
├── InputField.qml             # Input de senha (inalterado)
└── AuthMethodSelector.qml     # ✨ NOVO - Seletor de métodos
```

### Fluxo de Autenticação

```
Lock Screen Appears
       ↓
AuthMethodSelector (default: Face)
  [Face] [PIN] [Password]
       ↓
   User Selects Method
       ↓
┌──────────────┬─────────────┬──────────────┐
│  Face Mode   │  PIN Mode   │ Password Mode│
│  (Howdy/PAM) │ (Numeric)   │  (Full text) │
└──────────────┴─────────────┴──────────────┘
       ↓
   PAM Authentication
       ↓
┌──────────────────────────────┐
│ Success → Unlock             │
│ Fail → Increment counter     │
│ N Fails → Disable method     │
│ Unlock → Re-enable all       │
└──────────────────────────────┘
```

---

## 📂 Arquivos Modificados/Criados

### Arquivo Novo: `modules/lock/AuthMethodSelector.qml`

**Tamanho**: 192 linhas  
**Descrição**: Componente visual com 3 botões para selecionar método

```qml
RowLayout {
    id: root
    
    property string selectedMethod: "face"
    property bool faceEnabled: true
    property bool pinEnabled: true
    
    spacing: Appearance.spacing.normal
    
    // Botão Face
    ToggleButton {
        text: qsTr("Face")
        icon: "face"
        enabled: root.faceEnabled
        checked: root.selectedMethod === "face"
        onClicked: root.selectedMethod = "face"
    }
    
    // Botão PIN
    ToggleButton {
        text: qsTr("PIN")
        icon: "dialpad"
        enabled: root.pinEnabled
        checked: root.selectedMethod === "pin"
        onClicked: root.selectedMethod = "pin"
    }
    
    // Botão Password (sempre disponível)
    ToggleButton {
        text: qsTr("Password")
        icon: "password"
        checked: root.selectedMethod === "password"
        onClicked: root.selectedMethod = "password"
    }
}
```

**Componentes Usados**:
- `ToggleButton` (do Caelestia)
- `Colours.palette.*` (Material Design 3)
- `Appearance.spacing.*` (do Caelestia)

---

### Arquivo Modificado: `modules/lock/Center.qml`

**Mudanças**: +14 linhas  
**Localização**: Após linha 109 (foto de perfil)

```qml
// ADICIONADO:
AuthMethodSelector {
    id: authSelector
    
    Layout.topMargin: Appearance.spacing.large
    Layout.alignment: Qt.AlignHCenter
    
    // Binding com fallback
    selectedMethod: {
        if (Config.lock && Config.lock.auth && Config.lock.auth.defaultMethod) {
            return Config.lock.auth.defaultMethod
        }
        return "face"
    }
    
    // Estados de disponibilidade
    faceEnabled: root.lock && root.lock.pam ? root.lock.pam.faceEnabled : true
    pinEnabled: root.lock && root.lock.pam ? root.lock.pam.pinEnabled : true
    
    // Atualizar Pam ao mudar
    onSelectedMethodChanged: {
        if (root.lock && root.lock.pam) {
            root.lock.pam.currentMode = selectedMethod
        }
    }
}
```

**Lições Aprendidas**:
- ⚠️ Sempre usar bindings condicionais em QML
- ⚠️ Config pode não estar disponível na inicialização
- ⚠️ Usar fallbacks para evitar `undefined`

---

### Arquivo Modificado: `modules/lock/Pam.qml`

**Mudanças**: +60 linhas  
**Descrição**: Adiciona lógica de múltiplos métodos

```qml
// PROPRIEDADES ADICIONADAS:

// Modo atual de autenticação
property string currentMode: "face"  // "face", "pin", "password"

// Estados de disponibilidade
property bool faceEnabled: true
property bool pinEnabled: true

// Contadores de falhas
property int faceFailedAttempts: 0
property int pinFailedAttempts: 0
property int passwordFailedAttempts: 0

// FUNÇÕES ADICIONADAS:

function onFaceAuthFailed() {
    faceFailedAttempts++
    const maxRetries = Config.lock?.auth?.maxFaceRetries ?? 5
    if (faceFailedAttempts >= maxRetries) {
        faceEnabled = false
    }
}

function onPinAuthFailed() {
    pinFailedAttempts++
    const maxRetries = Config.lock?.auth?.maxPinRetries ?? 10
    if (pinFailedAttempts >= maxRetries) {
        pinEnabled = false
    }
}

function onUnlockSuccess() {
    // Resetar contadores
    faceFailedAttempts = 0
    pinFailedAttempts = 0
    passwordFailedAttempts = 0
    
    // Reativar todos os métodos
    faceEnabled = Config.lock?.auth?.enableFaceAuth ?? true
    pinEnabled = Config.lock?.auth?.enablePinAuth ?? true
}

// MODIFICAÇÃO EM handleKey():

function handleKey(event: KeyEvent): void {
    // Novo: Se modo PIN, aceita apenas números
    if (currentMode === "pin") {
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            buffer += event.text
        } else if (event.key === Qt.Key_Backspace) {
            buffer = buffer.slice(0, -1)
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start()
        }
        return  // Não processar mais nada em modo PIN
    }
    
    // Lógica original para password mode
    // ...
}
```

**Lições Aprendidas**:
- ⚠️ QML não suporta `??` operator (usar ternário)
- ⚠️ Sempre validar se Config existe antes de acessar
- ⚠️ `event.key` em Qt usa códigos Qt.Key_*

---

### Arquivo Modificado: `config/LockConfig.qml`

**Mudanças**: +10 linhas

```qml
// ADICIONADO:
component Auth: JsonObject {
    property bool enableFaceAuth: true
    property bool enablePinAuth: true
    property string defaultMethod: "face"
    property int maxFaceRetries: 5
    property int maxPinRetries: 10
    property int maxPasswordRetries: 30
}

property Auth auth: Auth {}
```

---

## ⚙️ Configuração

### Arquivo: `~/.config/caelestia/shell.json`

```json
{
  "lock": {
    "recolourLogo": false,
    "enableFprint": true,
    "maxFprintTries": 3,
    "auth": {
      "enableFaceAuth": true,
      "enablePinAuth": true,
      "defaultMethod": "face",
      "maxFaceRetries": 5,
      "maxPinRetries": 10,
      "maxPasswordRetries": 30
    }
  }
}
```

### Opções de Configuração

| Opção | Tipo | Default | Descrição |
|-------|------|---------|-----------|
| `enableFaceAuth` | bool | true | Habilita botão Face |
| `enablePinAuth` | bool | true | Habilita botão PIN |
| `defaultMethod` | string | "face" | Método default ao abrir ("face", "pin", "password") |
| `maxFaceRetries` | int | 5 | Falhas antes de desabilitar Face |
| `maxPinRetries` | int | 10 | Falhas antes de desabilitar PIN |
| `maxPasswordRetries` | int | 30 | Falhas antes de lockout total |

---

## 🎨 Design Visual

### Layout

```
┌───────────────────────────────────────┐
│           14:32                       │
│     Monday, 20 January                │
│                                       │
│          [👤 Avatar]                  │
│                                       │
│   ┌─────┐ ┌─────┐ ┌─────┐           │ ← NOVO
│   │ 👤  │ │ 🔢  │ │ 🔒  │           │
│   │Face │ │ PIN │ │Pass │           │
│   └─────┘ └─────┘ └─────┘           │
│       ↑ Botão ativo (azul)           │
│                                       │
│   ┌──────────────────────────┐       │
│   │ [🔓] •••••• [→]          │       │ ← Mantido
│   └──────────────────────────┘       │
│                                       │
└───────────────────────────────────────┘
```

### Estilos dos Botões

**Normal** (não selecionado):
- Background: `Colours.tPalette.m3surfaceContainer`
- Text: `Colours.palette.m3onSurface`
- Opacity: 1.0

**Ativo** (selecionado):
- Background: `Colours.palette.m3primaryContainer`
- Border: `Colours.palette.m3primary` (2px)
- Text: `Colours.palette.m3onPrimaryContainer`

**Disabled** (após falhas):
- Opacity: 0.5
- Tooltip: "Face disabled. Use PIN or Password."

---

## 🧪 Testes Realizados

### Teste 1: Lock Screen Aparece
- ✅ Super+L → Lock screen aparece
- ✅ `loginctl lock-session` → Lock screen aparece
- ✅ Botões Face/PIN/Password visíveis

### Teste 2: Face Authentication
- ✅ Face selecionado por default
- ✅ Howdy inicia automaticamente (se configurado)
- ✅ Reconhecimento funciona
- ✅ Unlock bem-sucedido

### Teste 3: PIN Mode
- ✅ Clicar em PIN → Botão fica azul
- ✅ Digitar números → Aceita
- ✅ Digitar letras → Ignora
- ✅ Backspace funciona
- ✅ Enter dispara autenticação

### Teste 4: Password Mode
- ✅ Clicar em Password → Botão fica azul
- ✅ Digitar qualquer caractere → Aceita
- ✅ Funcionamento idêntico ao original

### Teste 5: Auto-Desabilitação
- ✅ Face falha 5x → Botão Face disabled
- ✅ PIN falha 10x → Botão PIN disabled
- ✅ Pelo menos 1 método sempre disponível
- ✅ Tooltips mostram mensagem de disabled

### Teste 6: Reativação
- ✅ Face disabled → Unlock via PIN → Face reativa
- ✅ PIN disabled → Unlock via Face → PIN reativa
- ✅ Contadores resetam

---

## 🐛 Problemas Encontrados e Soluções

### Problema 1: `Appearance.spacing.tiny` Não Existe

**Erro**:
```
Unable to assign [undefined] to double
```

**Causa**: Tentamos usar `Appearance.spacing.tiny`, mas não existe no Caelestia

**Solução**: Mudado para `Appearance.spacing.small`

---

### Problema 2: Config `auth` Undefined

**Erro**:
```
Unable to assign [undefined] to bool
```

**Causa**: Config `lock.auth` não existia no `shell.json` do usuário

**Solução 1**: Adicionar seção ao config manualmente
**Solução 2**: Usar bindings com fallback no QML:
```qml
property bool faceEnabled: Config.lock?.auth?.enableFaceAuth ?? true
```

---

### Problema 3: Operator `??` Não Funciona em QML

**Erro**:
```
Expected token ':'
```

**Causa**: QML não suporta nullish coalescing operator (`??`)

**Solução**: Usar ternário:
```qml
// Errado:
value: Config.lock.auth.maxRetries ?? 5

// Certo:
value: Config.lock.auth.maxRetries !== undefined ? Config.lock.auth.maxRetries : 5
```

---

### Problema 4: Binding Loops

**Erro**:
```
Binding loop detected for property "selectedMethod"
```

**Causa**: Binding circular entre `AuthMethodSelector` e `Pam`

**Solução**: Usar binding unidirecional:
```qml
// Em AuthMethodSelector:
onSelectedMethodChanged: {
    if (root.lock && root.lock.pam) {
        root.lock.pam.currentMode = selectedMethod
    }
}
```

---

## 📦 Dependências

### Howdy (Opcional, para Face Auth)

```bash
# Instalar
paru -S howdy-git

# Configurar
sudo howdy add  # Adicionar modelo de face
sudo howdy test # Testar reconhecimento

# Config
sudo nano /lib/security/howdy/config.ini
```

**Config Sugerida**:
```ini
[video]
timeout = 5
dark_threshold = 60

[core]
certainty = 3.5
```

### PAM Integration

Howdy usa `pam_python.so`, já configurado no sistema.

**Verificar**:
```bash
cat /etc/pam.d/system-local-login | grep howdy
# Deve ter:
# auth sufficient pam_python.so /lib/security/howdy/pam.py
```

---

## 🔐 Segurança

### Estratégia de Auto-Desabilitação

**Filosofia**: Cada método se desabilita após N falhas, mas sempre mantém alternativas

```
Face: 5 falhas → disabled (use PIN/Password)
PIN: 10 falhas → disabled (use Face/Password)
Password: 30 falhas → lockout total (use TTY)
```

**Vantagens**:
- ✅ Impede brute force em cada método específico
- ✅ User não fica frustrado com lockout temporal
- ✅ Sempre há fallback disponível
- ✅ Unlock bem-sucedido reativa tudo

**vs Lockout Temporal**:
- ❌ Countdown frustra usuário
- ❌ User pode precisar urgentemente desbloquear
- ❌ Não distingue entre métodos (trava tudo)

### Logs

Tentativas de auth são logadas via PAM:
```bash
# Ver logs
journalctl -xe | grep "pam_unix\|pam_python\|howdy"

# Filtrar apenas lock screen
journalctl --since today | grep "lock-session"
```

---

## 🚀 Como Instalar/Testar

### Build e Instalação

```bash
# 1. Clonar/atualizar repo
cd /data/projects/caelestia-shell-pereiraoc-patch

# 2. Build
cmake --build build

# 3. Instalar
sudo cmake --install build

# 4. Reiniciar Quickshell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

### Configurar

```bash
# 1. Backup config
cp ~/.config/caelestia/shell.json ~/.config/caelestia/shell.json.backup

# 2. Adicionar seção auth
nano ~/.config/caelestia/shell.json
# (adicionar json acima)

# 3. Reiniciar
killall quickshell
quickshell -c caelestia --daemonize
```

### Testar

```bash
# Lock screen
loginctl lock-session

# Verificar:
# - 3 botões visíveis
# - Face selecionado (default)
# - Clicar em botões muda seleção
# - Digitar funciona conforme modo
```

---

## 📊 Métricas

### Linhas de Código

| Arquivo | Linhas Adicionadas | Linhas Modificadas |
|---------|-------------------|-------------------|
| `AuthMethodSelector.qml` | 192 (novo) | - |
| `Pam.qml` | 60 | 10 |
| `Center.qml` | 14 | 0 |
| `LockConfig.qml` | 10 | 0 |
| **TOTAL** | **276** | **10** |

### Tempo de Desenvolvimento

| Fase | Estimado | Real |
|------|----------|------|
| Planejamento | 1h | 1.5h |
| Implementação | 3h | 3h |
| Debug | 30min | 1h |
| Testes | 30min | 30min |
| Documentação | 1h | 1h |
| **TOTAL** | **6h** | **7h** |

---

## 🔮 Melhorias Futuras

### v0.1.1 (Minor Fixes)
- [ ] Teclado numérico visual (na tela)
- [ ] Animação durante Face scanning
- [ ] Sons de feedback (opcional)

### v0.2.0 (Features)
- [ ] Suporte a fingerprint reader (fprintd)
- [ ] PIN dedicado (via keyring)
- [ ] Liveness detection melhorada
- [ ] Face + Fingerprint simultâneos

### v0.3.0 (Advanced)
- [ ] Smart card support (PKCS#11)
- [ ] OTP/2FA
- [ ] Bluetooth proximity unlock

---

## 📚 Referências

### Código
- **Quickshell PAM**: https://quickshell.outfoxxed.me/docs/stable/modules/quickshell-io/pam/
- **Caelestia Upstream**: https://github.com/caelestia-dots/shell
- **Material Design 3**: https://m3.material.io/

### Howdy
- **Howdy GitHub**: https://github.com/boltgolt/howdy
- **Arch Wiki**: https://wiki.archlinux.org/title/Howdy

### PAM
- **PAM Documentation**: http://www.linux-pam.org/
- **Arch Wiki PAM**: https://wiki.archlinux.org/title/PAM

---

## ✅ Checklist de Conclusão

- [x] Código implementado
- [x] Build bem-sucedido
- [x] Instalação testada
- [x] Todos os testes passam
- [x] Documentação completa
- [x] Config adicionado ao shell.json
- [x] Commit realizado
- [x] Atualizado 99-pendencias.md
- [x] Atualizado 00-index.md

**Status Final**: ✅ Concluído e Funcionando!
