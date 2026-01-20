# Caelestia Lock Screen - Plano de Implementação
## Patch Personalizado: caelestia-shell-pereiraoc-patch

---

## 📋 Visão Geral

Este patch do Caelestia Shell adiciona suporte para autenticação via reconhecimento facial (Howdy) e PIN no lock screen, permitindo ao usuário escolher o método de autenticação através de botões visuais.

**Objetivo**: Criar uma tela de bloqueio moderna, segura e conveniente que integre:
- Autenticação via reconhecimento facial (Howdy/PAM)
- Autenticação via PIN numérico
- Interface visual para escolher entre os métodos
- Fallback automático para senha tradicional

---

## 🎯 Requisitos Funcionais

### RF1: Seleção de Método de Autenticação
- [ ] Exibir dois botões no lock screen: "Face Recognition" e "PIN"
- [ ] Botões devem seguir o design system do Caelestia (Material Design 3)
- [ ] Indicação visual do método ativo (highlight, animação)
- [ ] Transição suave entre os modos

### RF2: Autenticação Facial (Howdy)
- [ ] Integração com Howdy via PAM (já existe no código atual)
- [ ] Feedback visual durante o reconhecimento (scanning, success, fail)
- [ ] Timeout configurável (padrão: 5 segundos)
- [ ] Fallback automático para senha em caso de falha
- [ ] Contador de tentativas (máximo configurável)

### RF3: Autenticação via PIN
- [ ] Campo numérico para entrada de PIN (4-8 dígitos)
- [ ] Teclado numérico visual (0-9 + backspace + enter)
- [ ] Obscurecimento da entrada (dots ao invés de números)
- [ ] Validação via PAM contra senha do usuário
- [ ] Suporte para PINs salvos em keyring (futuro)

### RF4: Fallback e Segurança
- [ ] Sempre manter senha tradicional como fallback
- [ ] Rate limiting: delay progressivo após falhas
- [ ] Lockout temporário após N tentativas (configurável)
- [ ] Log de tentativas falhas em journal
- [ ] Modo de emergência: Ctrl+Alt+F2 sempre disponível

---

## 🏗️ Arquitetura

### Estrutura de Módulos

```
modules/lock/
├── Lock.qml                    # Entry point (já existe)
├── LockSurface.qml            # Surface principal (já existe)
├── Pam.qml                    # PAM integration (já existe)
├── Content.qml                # Layout principal (já existe)
├── Center.qml                 # Centro da tela (já existe)
├── InputField.qml             # Input senha (já existe)
│
├── AuthMethodSelector.qml     # NOVO: Botões de seleção (Face/PIN)
├── PinKeyboard.qml            # NOVO: Teclado numérico
├── PinInputField.qml          # NOVO: Display do PIN
├── FaceAuthIndicator.qml      # NOVO: Indicador de face scanning
├── AuthFeedback.qml           # NOVO: Mensagens de erro/sucesso
└── AuthConfig.qml             # NOVO: Configurações de autenticação
```

### Fluxo de Autenticação

```
Lock Screen Appears
       ↓
┌──────────────────────────────┐
│  AuthMethodSelector          │
│  [Face] [PIN]               │
└──────────────────────────────┘
       ↓
   User Selects
       ↓
┌─────────────┬────────────────┐
│  Face Mode  │   PIN Mode     │
└─────────────┴────────────────┘
       ↓              ↓
  Howdy/PAM      PIN → PAM
       ↓              ↓
  ┌─────────────────────┐
  │  Success? Unlock    │
  │  Fail? Retry/Fallback│
  └─────────────────────┘
```

### Integração PAM

**PAM Stack Atual** (em `/etc/pam.d/`):
- `system-local-login`: Usado pelo SDDM
- `passwd`: Config PAM para senha (já existe em `assets/pam.d/`)
- `fprint`: Config PAM para fingerprint (já existe, adaptar para Howdy)

**Nova Configuração PAM**:
```
# /etc/pam.d/howdy-lock
auth sufficient pam_python.so /lib/security/howdy/pam.py
auth required   pam_unix.so try_first_pass nullok
```

---

## 🎨 Design e UX

### Princípios de Design

1. **Consistência**: Seguir Material Design 3 do Caelestia
2. **Clareza**: Estado do auth sempre visível
3. **Feedback**: Animações e mensagens imediatas
4. **Acessibilidade**: Teclado + mouse + touch
5. **Performance**: Renderização < 16ms (60fps)

### Paleta de Cores

```qml
// Usar Colours.palette do Caelestia
- Primary: Botão ativo
- OnPrimary: Texto do botão ativo
- Surface: Background dos botões
- OnSurface: Texto dos botões inativos
- Error: Feedback de falha
- Success: Feedback de sucesso (verde M3)
```

### Animações

- **Transição entre métodos**: 200ms easeInOut
- **Face scanning**: Pulsação suave (500ms loop)
- **PIN digit entry**: Scale up 150ms
- **Error shake**: 300ms horizontal shake
- **Success**: 400ms scale + fade out

### Mockup ASCII

```
┌───────────────────────────────────────────┐
│                                           │
│         🕐 14:32                          │
│         Segunda, 20 de Janeiro            │
│                                           │
│              👤                           │
│         User Name                         │
│                                           │
│   ┌──────────┐  ┌──────────┐            │
│   │   👤     │  │   🔢     │            │
│   │  Face    │  │  PIN     │            │
│   └──────────┘  └──────────┘            │
│                                           │
│   ┌───────────────────────┐              │
│   │   • • • •             │              │
│   └───────────────────────┘              │
│                                           │
│   ┌───┬───┬───┐                          │
│   │ 1 │ 2 │ 3 │                          │
│   ├───┼───┼───┤                          │
│   │ 4 │ 5 │ 6 │                          │
│   ├───┼───┼───┤                          │
│   │ 7 │ 8 │ 9 │                          │
│   ├───┼───┼───┤                          │
│   │ ← │ 0 │ ✓ │                          │
│   └───┴───┴───┘                          │
│                                           │
│   Or press Enter for password            │
│                                           │
└───────────────────────────────────────────┘
```

---

## 🔧 Implementação Técnica

### Fase 1: Preparação (Dia 1)
**Objetivo**: Setup do ambiente e estrutura base

**Tarefas**:
1. ✅ Fork do repositório upstream
2. ✅ Git init e commit inicial
3. [ ] Criar branch `feature/howdy-pin-auth`
4. [ ] Atualizar README.md com informações do fork
5. [ ] Criar este PLANNING.md
6. [ ] Setup de build local (`cmake` + `ninja`)
7. [ ] Testar build e instalação local
8. [ ] Criar estrutura de testes (shell scripts)

**Arquivos Modificados**:
- `README.md`: Adicionar seção sobre o fork
- `PLANNING.md`: Este documento
- `.gitignore`: Adicionar arquivos de build local

**Entregáveis**:
- Repositório configurado
- Build funcional
- Documentação inicial

---

### Fase 2: AuthMethodSelector (Dia 1-2)
**Objetivo**: Criar seletor de método de autenticação

**Componente**: `modules/lock/AuthMethodSelector.qml`

```qml
// Pseudocódigo
AuthMethodSelector {
    enum AuthMethod { Face, Pin, Password }
    property AuthMethod selected: AuthMethod.Face
    
    Row {
        spacing: Appearance.spacing.large
        
        ToggleButton {
            text: "Face Recognition"
            icon: "face"
            active: selected === AuthMethod.Face
            onClicked: selected = AuthMethod.Face
        }
        
        ToggleButton {
            text: "PIN"
            icon: "pin"
            active: selected === AuthMethod.Pin
            onClicked: selected = AuthMethod.Pin
        }
    }
}
```

**Integração**:
- Adicionar ao `Content.qml` ou `Center.qml`
- Conectar com `Pam.qml` para alternar modo

**Testes**:
- [ ] Botões renderizam corretamente
- [ ] Transição visual funciona
- [ ] Estado persiste durante sessão de lock
- [ ] Acessibilidade via teclado (Tab, Enter)

---

### Fase 3: PinKeyboard e PinInputField (Dia 2-3)
**Objetivo**: Teclado numérico funcional

**Componente 1**: `modules/lock/PinKeyboard.qml`

```qml
// Pseudocódigo
PinKeyboard {
    signal digitPressed(int digit)
    signal backspacePressed()
    signal enterPressed()
    
    Grid {
        columns: 3
        spacing: Appearance.spacing.small
        
        Repeater {
            model: [1,2,3,4,5,6,7,8,9]
            delegate: IconButton {
                text: modelData
                onClicked: digitPressed(modelData)
                // Styling: M3 filled button
            }
        }
        
        Row { // Last row: backspace, 0, enter
            IconButton { icon: "backspace"; onClicked: backspacePressed() }
            IconButton { text: "0"; onClicked: digitPressed(0) }
            IconButton { icon: "check"; onClicked: enterPressed() }
        }
    }
}
```

**Componente 2**: `modules/lock/PinInputField.qml`

```qml
// Pseudocódigo
PinInputField {
    property string pin: ""
    readonly property int maxLength: 8
    
    Row {
        spacing: Appearance.spacing.small
        
        Repeater {
            model: maxLength
            delegate: StyledRect {
                width: 16; height: 16
                radius: 8
                color: index < pin.length ? 
                    Colours.palette.m3primary : 
                    Colours.palette.m3outline
                // Animação ao adicionar/remover
            }
        }
    }
}
```

**Lógica**:
```qml
// Em Pam.qml ou novo AuthManager.qml
property string pinBuffer: ""

function handlePinDigit(digit) {
    if (pinBuffer.length < 8) {
        pinBuffer += digit.toString()
    }
}

function handlePinBackspace() {
    pinBuffer = pinBuffer.slice(0, -1)
}

function handlePinEnter() {
    // Validar PIN via PAM
    passwd.respond(pinBuffer)
    pinBuffer = ""
}
```

**Testes**:
- [ ] Teclado responde a cliques
- [ ] PIN display atualiza corretamente
- [ ] Backspace funciona
- [ ] Enter dispara autenticação
- [ ] Limite de 8 dígitos respeitado
- [ ] Animações suaves

---

### Fase 4: FaceAuthIndicator (Dia 3-4)
**Objetivo**: Feedback visual durante reconhecimento facial

**Componente**: `modules/lock/FaceAuthIndicator.qml`

```qml
// Pseudocódigo
FaceAuthIndicator {
    property bool scanning: false
    property string state: "" // "", "scanning", "success", "fail"
    
    Column {
        spacing: Appearance.spacing.medium
        
        // Face icon com animação
        MaterialIcon {
            icon: "face"
            size: 64
            color: {
                if (state === "scanning") return Colours.palette.m3primary
                if (state === "success") return Colours.palette.m3success
                if (state === "fail") return Colours.palette.m3error
                return Colours.palette.m3onSurface
            }
            
            // Pulsação quando scanning
            SequentialAnimation on scale {
                running: state === "scanning"
                loops: Animation.Infinite
                NumberAnimation { to: 1.2; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }
        
        StyledText {
            text: {
                if (state === "scanning") return "Looking for your face..."
                if (state === "success") return "Face recognized!"
                if (state === "fail") return "Face not recognized. Try again."
                return "Position your face in view"
            }
            color: Colours.palette.m3onSurface
        }
    }
}
```

**Integração com Howdy**:
```qml
// Em Pam.qml
Connections {
    target: fprint // Reutilizar fprint para Howdy
    
    function onActiveChanged() {
        if (fprint.active) {
            root.fprintState = "scanning"
        }
    }
    
    function onCompleted(res) {
        if (res === PamResult.Success) {
            root.fprintState = "success"
        } else {
            root.fprintState = "fail"
        }
    }
}
```

**Testes**:
- [ ] Indicador aparece quando Face mode ativo
- [ ] Animação de scanning funciona
- [ ] Estados success/fail exibem feedback correto
- [ ] Timeout funciona (5s padrão)

---

### Fase 5: Integração PAM e Howdy (Dia 4-5)
**Objetivo**: Conectar UI com Howdy/PAM

**Modificações em `Pam.qml`**:

```qml
// Adicionar propriedade de modo
enum AuthMode { Password, Pin, Face }
property AuthMode currentMode: AuthMode.Face

// Modificar handleKey para diferenciar PIN de Password
function handleKey(event) {
    if (currentMode === AuthMode.Pin) {
        // Redirecionar para PIN keyboard logic
        return
    }
    // Lógica existente para password
}

// Adicionar função para iniciar auth facial
function startFaceAuth() {
    currentMode = AuthMode.Face
    fprint.checkAvail() // Chama Howdy via PAM fprint
}

// Adicionar função para iniciar PIN auth
function startPinAuth() {
    currentMode = AuthMode.Pin
    // PIN será coletado e enviado via passwd.respond()
}
```

**Configuração Howdy**:
- Verificar `/lib/security/howdy/config.ini`
- Confirmar `device_path` correto
- Ajustar `dark_threshold` se necessário
- Timeout: 5000ms

**Fluxo de Autenticação**:
1. User seleciona Face
2. `startFaceAuth()` é chamado
3. `fprint.checkAvail()` → inicia Howdy
4. Howdy verifica via câmera
5. PAM retorna Success/Fail
6. UI atualiza feedback
7. Se sucesso: `lock.unlock()`
8. Se falha: exibir erro, retry ou fallback

**Testes**:
- [ ] Howdy inicia ao selecionar Face
- [ ] Feedback visual durante scanning
- [ ] Unlock funciona com face reconhecida
- [ ] Fallback para senha funciona
- [ ] Timeout funciona corretamente
- [ ] PIN mode usa PAM passwd

---

### Fase 6: AuthConfig e Persistência (Dia 5-6)
**Objetivo**: Configurações persistentes

**Componente**: `modules/lock/AuthConfig.qml`

```qml
// Adicionar ao Config.qml
AuthConfig {
    enableFaceAuth: true
    enablePinAuth: true
    defaultAuthMethod: "face" // "face", "pin", "password"
    
    faceAuthTimeout: 5000 // ms
    maxFaceRetries: 3
    
    pinLength: 4 // 4-8
    pinAutoSubmit: true // Auto-submit quando length atingido
    
    rateLimitDelay: 2000 // ms entre tentativas após falha
    lockoutAfterTries: 5
    lockoutDuration: 30000 // 30s
}
```

**Persistência em `~/.config/caelestia/shell.json`**:
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
      "faceAuthTimeout": 5000,
      "maxFaceRetries": 3,
      "pinLength": 4,
      "pinAutoSubmit": true,
      "rateLimitDelay": 2000,
      "lockoutAfterTries": 5,
      "lockoutDuration": 30000
    }
  }
}
```

**Lógica de Rate Limiting**:
```qml
// Em AuthManager.qml (novo)
property int failedAttempts: 0
property bool lockedOut: false

Timer {
    id: lockoutTimer
    interval: Config.lock.auth.lockoutDuration
    onTriggered: {
        lockedOut = false
        failedAttempts = 0
    }
}

function onAuthFailed() {
    failedAttempts++
    
    if (failedAttempts >= Config.lock.auth.lockoutAfterTries) {
        lockedOut = true
        lockoutTimer.start()
    } else {
        // Rate limit delay
        rateLimitTimer.start()
    }
}
```

**Testes**:
- [ ] Configurações carregam de shell.json
- [ ] Valores default funcionam se não configurado
- [ ] Rate limiting funciona
- [ ] Lockout após N tentativas
- [ ] Lockout reset após duração

---

### Fase 7: Polimento e Testes (Dia 6-7)
**Objetivo**: Refinar UX e testar todos os cenários

**Melhorias UX**:
- [ ] Transições suaves entre estados
- [ ] Feedback háptico (vibração) em falhas (se suportado)
- [ ] Sons de feedback (opcional, via PipeWire)
- [ ] Acessibilidade: screen reader support
- [ ] Teclado: atalhos (F para Face, P para PIN)

**Cenários de Teste**:
1. **Happy Path - Face**:
   - [ ] Lock screen aparece
   - [ ] Face selecionado por padrão
   - [ ] Howdy reconhece face
   - [ ] Unlock imediato

2. **Happy Path - PIN**:
   - [ ] User seleciona PIN
   - [ ] Digita PIN correto
   - [ ] Unlock imediato

3. **Fallback - Face Fail → Password**:
   - [ ] Howdy falha 3x
   - [ ] Exibe opção de senha
   - [ ] Senha funciona

4. **Fallback - PIN Fail → Password**:
   - [ ] PIN incorreto 3x
   - [ ] Exibe opção de senha
   - [ ] Senha funciona

5. **Edge Cases**:
   - [ ] Câmera não disponível → auto-select PIN
   - [ ] Howdy não instalado → auto-select PIN
   - [ ] Timeout em face auth → retry ou fallback
   - [ ] Lockout após N tentativas
   - [ ] Múltiplos monitores (lock em todos)

6. **Performance**:
   - [ ] Renderização < 16ms (60fps)
   - [ ] Face auth latência < 2s
   - [ ] PIN input responsivo (< 50ms)
   - [ ] Transições suaves sem lag

**Logs e Debug**:
- [ ] Log em journal: tentativas, falhas, método usado
- [ ] Debug mode: exibir estado PAM
- [ ] Erro handling: mensagens claras

---

### Fase 8: Documentação e Integração (Dia 7)
**Objetivo**: Documentar e integrar no caelestia-arch-setup

**Documentação**:
1. [ ] Atualizar `README.md` do fork
2. [ ] Criar `HOWDY_SETUP.md`: guia de configuração
3. [ ] Adicionar screenshots/GIFs de demo
4. [ ] Documentar opções de config em `shell.json`
5. [ ] Changelog com novos recursos

**Integração em caelestia-arch-setup**:
1. [ ] Criar script de instalação: `scripts/stage3/35-caelestia-fork-install.sh`
2. [ ] Atualizar documentação: `docs/02-arquitetura.md`
3. [ ] Adicionar troubleshooting: `docs/07-troubleshooting.md`
4. [ ] Referências em `docs/03-configuracao.md`

**Script de Instalação** (pseudocódigo):
```bash
#!/usr/bin/env bash
# scripts/stage3/35-caelestia-fork-install.sh

# Desinstalar caelestia-shell oficial
paru -R --noconfirm caelestia-shell

# Clonar fork
git clone https://github.com/pereiraoc/caelestia-arch-pereiraoc.git /tmp/caelestia-fork

# Build e install
cd /tmp/caelestia-fork
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build

# Configurar shell.json com defaults
jq '.lock.auth = {
  "enableFaceAuth": true,
  "enablePinAuth": true,
  "defaultMethod": "face"
}' ~/.config/caelestia/shell.json > /tmp/shell.json
mv /tmp/shell.json ~/.config/caelestia/shell.json

# Reiniciar shell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

**Testes de Integração**:
- [ ] Script de instalação funciona
- [ ] Configurações aplicam corretamente
- [ ] Hyprland binds funcionam (Super+L)
- [ ] Idle timeout funciona
- [ ] Suspend/hibernate preservam lock

---

## 📊 Cronograma

### Semana 1 (7 dias)
| Dia | Fase | Horas | Status |
|-----|------|-------|--------|
| 1   | Fase 1: Preparação | 4h | ⏳ Em progresso |
| 1-2 | Fase 2: AuthMethodSelector | 6h | ⏱️ Pendente |
| 2-3 | Fase 3: PinKeyboard | 8h | ⏱️ Pendente |
| 3-4 | Fase 4: FaceAuthIndicator | 6h | ⏱️ Pendente |
| 4-5 | Fase 5: PAM/Howdy Integration | 10h | ⏱️ Pendente |
| 5-6 | Fase 6: Config e Persistência | 6h | ⏱️ Pendente |
| 6-7 | Fase 7: Polimento e Testes | 8h | ⏱️ Pendente |
| 7   | Fase 8: Documentação | 4h | ⏱️ Pendente |

**Total**: ~52 horas (~7-8 dias de trabalho intenso)

---

## 🔒 Considerações de Segurança

### Princípios
1. **Defense in Depth**: Múltiplas camadas de auth
2. **Fail Secure**: Falhas devem travar, não desbloquear
3. **Audit Trail**: Log de todas tentativas
4. **Rate Limiting**: Prevenir brute force
5. **Least Privilege**: Processos com mínimos privilégios

### Ameaças e Mitigações

| Ameaça | Mitigação |
|--------|-----------|
| Brute force PIN | Rate limiting + lockout |
| Photo spoofing (Howdy) | Liveness detection (Howdy config) + fallback |
| Replay attack | PAM session tokens únicos |
| Timing attack | Constant-time string comparison |
| Privilege escalation | PAM policies isoladas |
| Denial of Service | Lockout temporário, não permanente |

### Howdy Security
- **Liveness Detection**: Configurar em `/lib/security/howdy/config.ini`
  ```ini
  [video]
  # Evitar fotos estáticas
  motion_detection = true
  motion_threshold = 20
  ```
- **Multiple Models**: Encorajar usuário a adicionar modelos em diferentes condições
- **Threshold Balanceado**: `certainty = 3.5` (default, ajustar se necessário)

### PIN Security
- **Não Armazenar PIN**: Usar PAM password diretamente
- **Obscurecer Entrada**: Dots ao invés de números
- **Auto-clear**: Limpar buffer após falha
- **No Screen Recording**: Flags de segurança no window

### Logs
```bash
# Logs em /var/log/auth.log
journalctl -u sddm --since today | grep "pam_python\|howdy"
```

---

## 🧪 Estratégia de Testes

### Testes Unitários (QML)
- [ ] AuthMethodSelector: state transitions
- [ ] PinKeyboard: digit input
- [ ] PinInputField: display logic
- [ ] FaceAuthIndicator: animation states

### Testes de Integração
- [ ] Pam.qml ↔ Howdy: face auth
- [ ] Pam.qml ↔ passwd: PIN/password auth
- [ ] Config loading: shell.json
- [ ] Rate limiting logic

### Testes de Sistema
- [ ] Lock screen appearance (Super+L)
- [ ] Idle timeout → auto-lock
- [ ] Unlock com cada método
- [ ] Fallback scenarios
- [ ] Multi-monitor setup
- [ ] Performance (fps, latency)

### Testes de Usabilidade
- [ ] First-time user: intuitivo?
- [ ] Feedback claro em falhas?
- [ ] Transições suaves?
- [ ] Acessibilidade (keyboard-only, screen reader)

### Test Checklist
```bash
# Manual testing
./scripts/test-lock-screen.sh

# Test cases:
# 1. Lock via Super+L
# 2. Select Face, wait for recognition
# 3. Select PIN, enter correct PIN
# 4. Trigger lockout (5 failed attempts)
# 5. Test fallback to password
# 6. Test on external monitor
# 7. Test idle timeout
```

---

## 📚 Referências

### Código Base
- **Este Patch**: https://github.com/pereiraoc/caelestia-shell-pereiraoc-patch
- **Caelestia Shell Upstream**: https://github.com/caelestia-dots/shell
- **Quickshell**: https://quickshell.outfoxxed.me
- **Quickshell PAM**: https://quickshell.outfoxxed.me/docs/stable/modules/quickshell-io/pam/

### Howdy
- **Howdy GitHub**: https://github.com/boltgolt/howdy
- **Arch Wiki (JP)**: https://wiki.archlinux.jp/index.php/Howdy
- **PAM Integration**: https://wiki.archlinux.org/title/PAM

### Design
- **Material Design 3**: https://m3.material.io/
- **Caelestia Design System**: Ver `components/` no repo
- **Qt Quick Layouts**: https://doc.qt.io/qt-6/qtquicklayouts-index.html

### Segurança
- **OWASP Auth Cheatsheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- **PAM Documentation**: http://www.linux-pam.org/Linux-PAM-html/
- **Face Auth Best Practices**: https://pages.nist.gov/fido2/

---

## 🎯 Critérios de Sucesso

### Funcional
- [x] Repositório criado e inicializado
- [ ] Lock screen exibe botões Face/PIN
- [ ] Face auth funciona com Howdy
- [ ] PIN auth funciona
- [ ] Fallback para senha funciona
- [ ] Configurações persistem em shell.json
- [ ] Integrado no caelestia-arch-setup

### Performance
- [ ] Renderização 60fps
- [ ] Face auth < 2s latency
- [ ] PIN input < 50ms latency
- [ ] Transições suaves (< 200ms)

### Segurança
- [ ] Rate limiting funciona
- [ ] Lockout após N tentativas
- [ ] Logs em journal
- [ ] Sem vazamento de senha/PIN

### UX
- [ ] Intuitivo para novo usuário
- [ ] Feedback claro em erros
- [ ] Acessibilidade via teclado
- [ ] Design consistente com Caelestia

### Documentação
- [ ] README.md atualizado
- [ ] HOWDY_SETUP.md criado
- [ ] Screenshots/GIFs adicionados
- [ ] Integrado na doc do caelestia-arch-setup

---

## 🚀 Próximos Passos (Após MVP)

### Melhorias Futuras (V2)
- [ ] Suporte para fingerprint reader (fprintd real)
- [ ] Biometria múltipla (face + fingerprint)
- [ ] PIN armazenado em keyring (gnome-keyring/kwallet)
- [ ] Smart card support (PKCS#11)
- [ ] OTP/2FA integration (TOTP)
- [ ] NFC badge unlock
- [ ] Bluetooth proximity unlock

### Otimizações
- [ ] Cache de modelos Howdy em RAM
- [ ] Lazy loading de componentes QML
- [ ] GPU acceleration para face detection
- [ ] Pré-carregamento de texturas

### Configurações Avançadas
- [ ] GUI para config (via Control Center)
- [ ] Profiles (home, work, travel)
- [ ] Time-based rules (face em casa, PIN em público)
- [ ] Location-based rules (GPS)

---

## 📝 Notas de Desenvolvimento

### Decisões Arquiteturais

#### Por que não usar hyprlock?
- Hyprlock não integra bem com Quickshell/Caelestia
- Queremos manter consistência visual com o shell
- Necessidade de customização profunda (Face/PIN)
- Quickshell já tem `WlSessionLock` e PAM integration

#### Por que PIN ao invés de apenas Face?
- Backup quando câmera não funciona (baixa luz, ângulo)
- Mais rápido em alguns contextos (teclado numérico)
- Opção mais privada (sem câmera)
- Acessibilidade (usuários com deficiência visual podem preferir)

#### Por que não substituir senha tradicional?
- Segurança: sempre manter fallback
- Compatibilidade: outros PAM services (sudo, SSH)
- LUKS unlock: não suporta face/PIN

### Desafios Conhecidos

1. **Qt6 QML Crashes**: Já documentado no caelestia-arch-setup
   - Workaround: evitar file watching, usar incubation synchronous
   
2. **Howdy Latência**: Pode variar (1-5s dependendo de hardware)
   - Solução: feedback visual durante scanning
   
3. **Multi-monitor**: Lock em todos os monitores
   - Quickshell `WlSessionLock` já trata isso
   
4. **Idle Detection**: Integrar com hypridle
   - Já existe `IdleMonitors.qml`, usar esse

### Convenções de Código

- **QML Naming**: PascalCase para componentes
- **Properties**: camelCase
- **Signals**: camelCase com prefixo (ex: `onDigitPressed`)
- **Colors**: Usar `Colours.palette.*` do Caelestia
- **Spacing/Sizing**: Usar `Appearance.*` do Caelestia
- **Animations**: Usar `Anim {}` wrapper do Caelestia

---

## 🤝 Contribuição

Este é um fork pessoal, mas contribuições são bem-vindas!

### Como Contribuir
1. Fork este repositório
2. Crie branch: `git checkout -b feature/minha-feature`
3. Commit: `git commit -m "feat: minha feature"`
4. Push: `git push origin feature/minha-feature`
5. Abra Pull Request

### Commits Semânticos
- `feat:` Nova funcionalidade
- `fix:` Bug fix
- `docs:` Documentação
- `style:` Formatação
- `refactor:` Refatoração
- `test:` Testes
- `chore:` Manutenção

---

## 📄 Licença

Mesmo que upstream: GPLv3 (ver LICENSE)

---

## 📞 Contato

**Mantenedor**: @pereiraoc
**Baseado em**: caelestia-dots/shell by @soramane

---

## 📌 Status do Projeto

**Versão**: 0.1.0-alpha
**Status**: 🟡 Em Desenvolvimento
**Última Atualização**: 2026-01-19

### Progresso

```
[████████░░░░░░░░░░░░░░] 30% - Fase 1 em andamento
```

**Concluído**:
- ✅ Fork do repositório
- ✅ Git setup
- ✅ Planejamento completo

**Em Progresso**:
- ⏳ Setup de build local
- ⏳ Estrutura de componentes

**Próximo**:
- 📋 AuthMethodSelector
- 📋 PinKeyboard
- 📋 Integração PAM/Howdy

---

**Fim do Planejamento - Revisão 1**
