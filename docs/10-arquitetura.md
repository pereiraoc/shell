# 🏗️ Arquitetura do Caelestia Shell - Pereiraoc Patch

**Última Atualização**: 2026-01-23

---

## 📊 Visão Geral

Este documento descreve as modificações arquiteturais implementadas neste patch do Caelestia Shell, comparando com o upstream original e explicando as limitações e decisões de design.

---

## 🆚 Comparação com Upstream

### Sistema de Lock Screen

#### Upstream Original
```
Lock Screen (WlSessionLock)
├── Pam.qml (PAM integration)
│   ├── Password authentication (default)
│   └── Fingerprint (optional, via fprintd)
├── Center.qml (layout central)
│   ├── Clock + Date
│   ├── User avatar
│   ├── InputField (password)
│   └── Error messages
└── Widgets laterais (Weather, Media, Resources)
```

#### Este Patch
```
Lock Screen (WlSessionLock)
├── Pam.qml (PAM integration) ✨ MODIFICADO
│   ├── currentMode: face/pin/password
│   ├── Face authentication (via Howdy/pam_python)
│   ├── PIN authentication (numeric only)
│   └── Password authentication (fallback)
├── Center.qml ✨ MODIFICADO
│   ├── Clock + Date
│   ├── User avatar
│   ├── AuthMethodSelector ✨ NOVO
│   │   ├── Face button
│   │   ├── PIN button
│   │   └── Password button
│   ├── InputField (mantido)
│   └── Error messages
└── Widgets laterais (inalterados)
```

### Estrutura de Módulos

| Módulo | Upstream | Este Patch | Motivo |
|--------|----------|------------|--------|
| `modules/lock/Lock.qml` | Inalterado | Inalterado | Entry point - não necessita mudança |
| `modules/lock/LockSurface.qml` | Inalterado | Inalterado | Surface Wayland - não necessita mudança |
| `modules/lock/Pam.qml` | Básico | +60 linhas | Adiciona lógica de múltiplos métodos |
| `modules/lock/Center.qml` | Básico | +14 linhas | Integra AuthMethodSelector |
| `modules/lock/InputField.qml` | Inalterado | Inalterado | Mantém funcionamento original |
| `modules/lock/AuthMethodSelector.qml` | N/A | **NOVO** (192 linhas) | Seletor de método de auth |
| `config/LockConfig.qml` | Básico | +10 linhas | Adiciona seção `auth` |

---

## 🎯 Decisões de Design

### 1. Por Que Não Substituir o Lock Screen Inteiro?

**Decisão**: Manter 100% do design existente, apenas adicionar botões

**Razões**:
- ✅ Design do Caelestia é bonito e funcional
- ✅ Minimiza risco de quebrar funcionalidades
- ✅ Facilita merge de atualizações do upstream
- ✅ Menos código = menos bugs

**Alternativas Rejeitadas**:
- ❌ Usar hyprlock: não integra com Quickshell/Caelestia
- ❌ Reescrever do zero: muito trabalho, desnecessário
- ❌ Fork completo: dificulta manutenção

### 2. Por Que Howdy ao Invés de fprintd?

**Decisão**: Usar Howdy (face recognition) como método biométrico principal

**Razões**:
- ✅ Hardware disponível: laptops têm webcam, nem todos têm fingerprint
- ✅ Mais conveniente: não precisa tocar no laptop
- ✅ Howdy funciona bem via PAM (pam_python.so)
- ✅ Fallback fácil: se falhar, usa PIN ou senha

**Limitações do Howdy**:
- ⚠️ Baixa luz: pode não funcionar
- ⚠️ Ângulo: precisa estar de frente
- ⚠️ Fotos: possível spoofing (mitigado por liveness detection)
- ⚠️ Latência: 1-3s para reconhecer

### 3. Por Que PIN Não É Separado da Senha?

**Decisão**: PIN valida contra a senha do sistema (não armazena PIN separado)

**Razões**:
- ✅ Segurança: não armazena credencial adicional
- ✅ Simplicidade: reutiliza PAM passwd
- ✅ Consistência: mesma senha para login/sudo/lock

**Alternativas Futuras**:
- 🔮 PIN dedicado armazenado em gnome-keyring/kwallet
- 🔮 PIN temporário (válido apenas na sessão atual)
- 🔮 Múltiplos PINs para diferentes contextos

### 4. Por Que Auto-Desabilitação ao Invés de Lockout Temporal?

**Decisão**: Métodos desabilitam após N falhas, mas sempre mantém alternativas

**Razões**:
- ✅ UX: não frustra usuário com countdown
- ✅ Segurança: impede brute force no método específico
- ✅ Flexibilidade: sempre há outro método disponível
- ✅ Reativação: unlock bem-sucedido reativa tudo

**Estratégia**:
```
Face: 5 falhas → disabled (use PIN/Password)
PIN: 10 falhas → disabled (use Face/Password)
Password: 30 falhas → lockout total (use TTY)
```

---

## 🔧 Modificações Técnicas

### Arquivo: `modules/lock/Pam.qml`

**Mudanças**:
```qml
// ADICIONADO:
property string currentMode: "face"  // "face", "pin", "password"
property bool faceEnabled: true
property bool pinEnabled: true
property int faceFailedAttempts: 0
property int pinFailedAttempts: 0

function onFaceAuthFailed() { ... }
function onPinAuthFailed() { ... }
function onUnlockSuccess() { ... }
```

**Lógica de handleKey()**:
```qml
function handleKey(event: KeyEvent): void {
    // NOVO: Se modo PIN, aceita apenas números
    if (currentMode === "pin") {
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            buffer += event.text
        }
        // ...
        return
    }
    
    // Lógica original para password
    // ...
}
```

### Arquivo: `modules/lock/Center.qml`

**Mudanças**:
```qml
// ADICIONADO após linha 109 (foto de perfil):
AuthMethodSelector {
    id: authSelector
    
    Layout.topMargin: Appearance.spacing.large
    Layout.alignment: Qt.AlignHCenter
    
    selectedMethod: "face"
    faceEnabled: root.lock.pam.faceEnabled
    pinEnabled: root.lock.pam.pinEnabled
    
    onSelectedMethodChanged: {
        root.lock.pam.currentMode = selectedMethod
    }
}
```

### Arquivo: `config/LockConfig.qml`

**Mudanças**:
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

## 📦 Dependências Adicionadas

### Howdy (Face Recognition)

**Pacote**: `howdy-git` (AUR)

**Configuração**: `/lib/security/howdy/config.ini`

**PAM Integration**:
```
# /etc/pam.d/system-local-login (ou equivalente)
auth sufficient pam_python.so /lib/security/howdy/pam.py
auth required   pam_unix.so try_first_pass nullok
```

**Limitações**:
- Requer câmera IR ou RGB
- Precisa de modelos treinados: `sudo howdy add`
- Não funciona em console (TTY)

### Nenhuma Dependência Adicional de QML

O patch **não adiciona** novas dependências do Quickshell/Qt. Usa apenas:
- Componentes existentes do Caelestia
- Qt Quick/Layouts (já presente)
- PAM integration (já presente)

---

## 🚧 Limitações Conhecidas

### 1. Howdy Não Funciona em Todos os Cenários

**Problemas**:
- ❌ Baixa luminosidade
- ❌ Ângulos extremos
- ❌ Óculos escuros
- ❌ Mudança de aparência (barba, penteado)

**Mitigação**: Sempre mantém PIN e Password disponíveis

### 2. PIN Não É Realmente PIN

**Problema**: Valida contra senha do sistema (não PIN dedicado)

**Impacto**: User precisa digitar senha completa como "PIN"

**Workaround Futuro**: Adicionar suporte a PIN dedicado via keyring

### 3. Sem Teclado Numérico Visual (Ainda)

**Problema**: PIN usa teclado físico, não tem numpad visual na tela

**Impacto**: Em tablets/touch sem teclado físico, fica difícil

**Status**: Planejado para v0.2.0

### 4. Sem Integração com Fingerprint Reader

**Problema**: Se hardware tem leitor de digital, não usa

**Impacto**: Desperdiça hardware disponível

**Status**: Planejado para v0.2.0 (via fprintd)

---

## 🔮 Roadmap de Melhorias

### Versão 0.1.x (Atual)
- ✅ Seletor de método (Face/PIN/Password)
- ✅ Integração com Howdy
- ✅ Auto-desabilitação inteligente
- ⏱️ Teclado numérico visual
- ⏱️ Feedback visual de Face auth

### Versão 0.2.0 (Futuro)
- 🔮 GPU Mode Selector (supergfxctl integration) - **PLANEJADO** ⭐
- 🔮 Suporte a fingerprint reader (fprintd)
- 🔮 PIN dedicado (via keyring)
- 🔮 Customizações adicionais (ver 99-pendencias.md)

### Versão 0.3.0 (Longo Prazo)
- 🔮 Smart card (PKCS#11)
- 🔮 OTP/2FA
- 🔮 Bluetooth proximity unlock
- 🔮 NFC badge

---

## 📖 Referências aos Planos de Implementação

Para detalhes de implementação de cada feature, veja:

### Lock Screen (Implementado)
- **21-lock-screen-auth-selector.md**: Plano completo do seletor de autenticação

### GPU Management (Planejado)
- **32-gpu-mode-selector.md**: Integração com supergfxctl para switching Intel/Hybrid/Dedicated

### Outras Customizações (Planejadas)
- **22-tray-system-icons.md**: Corrigir tray (Steam/Spotify)
- **23-assets-customization.md**: Trocar GIFs
- **24-workspace-visual-grouping.md**: Agrupar janelas por workspace
- **25-gaps-configuration.md**: Configurar gaps via UI
- **26-shortcuts-widget.md**: Widget de atalhos
- **27-games-widget.md**: Widget de jogos Steam
- **28-help-modal.md**: Modal de ajuda
- **29-apps-integration.md**: Integrar apps no Control Center
- **30-launcher-customization.md**: Editar ícones/nomes de apps
- **31-theme-customization.md**: Tema preto/amarelo

---

## 🎯 Filosofia do Patch

### Princípios de Design

1. **Mínima Invasão**: Modificar o mínimo possível do código original
2. **Máxima Compatibilidade**: Facilitar merge de atualizações upstream
3. **Zero Dependências Novas**: Usar apenas o que Caelestia já tem
4. **Design Consistente**: Seguir 100% o Material Design 3 do Caelestia
5. **Fallback Sempre**: Nunca deixar user sem opção de unlock

### Estratégia de Manutenção

```bash
# Sync regular com upstream
git remote add upstream https://github.com/caelestia-dots/shell.git
git fetch upstream
git merge upstream/main  # Resolver conflitos se necessário
```

**Arquivos Modificados** (poucos):
- `modules/lock/Pam.qml`
- `modules/lock/Center.qml`
- `config/LockConfig.qml`

**Arquivos Novos** (isolados):
- `modules/lock/AuthMethodSelector.qml`

**Conflitos Esperados**: Mínimos, pois modificamos poucos arquivos do upstream

---

## 🔐 Considerações de Segurança

### Superfície de Ataque

**Não Aumenta Risco**:
- ✅ PIN valida via PAM (mesma senha)
- ✅ Face valida via Howdy/PAM
- ✅ Fallback para senha tradicional

**Proteções Adicionadas**:
- ✅ Rate limiting por método
- ✅ Auto-desabilitação após falhas
- ✅ Logs de tentativas (via PAM)

### Comparação com Upstream

| Aspecto | Upstream | Este Patch | Risco |
|---------|----------|------------|-------|
| Password auth | ✅ PAM | ✅ PAM (inalterado) | Sem mudança |
| Biometric auth | ⚠️ fprintd (opcional) | ⚠️ Howdy (opcional) | Similar |
| Rate limiting | Básico | Avançado | ✅ Melhora |
| Fallback | Senha | Múltiplos métodos | ✅ Melhora |

---

**Próximo**: Veja **99-pendencias.md** para ver o que ainda precisa ser feito!
