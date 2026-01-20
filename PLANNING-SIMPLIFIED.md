# Caelestia Lock Screen - Plano Simplificado
## Adicionar Seleção de Método de Autenticação

**Objetivo**: Manter o lock screen bonito do Caelestia e apenas adicionar:
1. Método default: Face (ao invés de senha/fingerprint)
2. Botões para escolher: Face, PIN, ou Senha

---

## 🎯 Escopo Reduzido

### O Que NÃO Vamos Mudar
- ✅ Layout existente (3 colunas com widgets laterais)
- ✅ Animações de entrada/saída
- ✅ Campo de input (InputField.qml)
- ✅ Relógio e data
- ✅ Foto de perfil
- ✅ Mensagens de erro
- ✅ Weather, Media, Resources, NotifDock

### O Que Vamos Adicionar
- 🆕 **AuthMethodSelector** acima do campo de input
- 🆕 Lógica para alternar entre Face/PIN/Senha
- 🆕 Config: defaultMethod = "face"

---

## 📍 Onde Adicionar

### Estrutura Atual
```
Center.qml
├── Relógio
├── Data
├── Foto perfil
├── Campo de input  ← AQUI vamos adicionar os botões ACIMA
└── Mensagens
```

### Estrutura Nova
```
Center.qml
├── Relógio
├── Data
├── Foto perfil
├── AuthMethodSelector  ← NOVO (3 botões)
├── Campo de input      ← Mantém como está
└── Mensagens           ← Mantém como está
```

---

## 🎨 Design dos Botões

### Layout Visual
```
┌─────────────────────────────────────┐
│           14:32                     │
│      Monday, 20 January             │
│                                     │
│           [👤 Avatar]               │
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐          │
│  │ 👤  │ │ 🔢  │ │ 🔒  │          │ ← NOVO
│  │Face │ │ PIN │ │Pass │          │
│  └─────┘ └─────┘ └─────┘          │
│      ↑ ativo                       │
│                                     │
│  ┌──────────────────────────┐      │
│  │ [🔓] •••••• [→]          │      │ ← Mantém
│  └──────────────────────────┘      │
│                                     │
│  [mensagem de erro]                │
└─────────────────────────────────────┘
```

---

## 🔧 Implementação

### Passo 1: Criar AuthMethodSelector.qml
```qml
// modules/lock/AuthMethodSelector.qml
import qs.components
import qs.components.controls
import qs.services
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    
    property string selectedMethod: Config.lock.auth.defaultMethod
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
        
        ToolTip.text: root.faceEnabled ? 
            qsTr("Unlock with face recognition") : 
            qsTr("Face disabled. Use PIN or Password.")
    }
    
    // Botão PIN
    ToggleButton {
        text: qsTr("PIN")
        icon: "dialpad"
        enabled: root.pinEnabled
        checked: root.selectedMethod === "pin"
        onClicked: root.selectedMethod = "pin"
        
        ToolTip.text: root.pinEnabled ? 
            qsTr("Unlock with PIN") : 
            qsTr("PIN disabled. Use Face or Password.")
    }
    
    // Botão Password (sempre disponível)
    ToggleButton {
        text: qsTr("Password")
        icon: "password"
        checked: root.selectedMethod === "password"
        onClicked: root.selectedMethod = "password"
        
        ToolTip.text: qsTr("Unlock with password")
    }
}
```

### Passo 2: Integrar no Center.qml

**Localização**: Após foto de perfil, antes do campo de input

```qml
// Adicionar após linha 109 (foto de perfil)

AuthMethodSelector {
    id: authSelector
    
    Layout.topMargin: Appearance.spacing.large
    Layout.alignment: Qt.AlignHCenter
    
    selectedMethod: "face"  // Default
    
    // Estados de disponibilidade
    faceEnabled: root.lock.pam.faceEnabled
    pinEnabled: root.lock.pam.pinEnabled
    
    onSelectedMethodChanged: {
        root.lock.pam.currentMode = selectedMethod
    }
}
```

### Passo 3: Atualizar Pam.qml

Adicionar propriedades para controlar métodos:

```qml
// Em Pam.qml
property string currentMode: "face"  // "face", "pin", "password"
property bool faceEnabled: true
property bool pinEnabled: true

property int faceFailedAttempts: 0
property int pinFailedAttempts: 0

function onFaceAuthFailed() {
    faceFailedAttempts++
    if (faceFailedAttempts >= Config.lock.auth.maxFaceRetries) {
        faceEnabled = false
    }
}

function onPinAuthFailed() {
    pinFailedAttempts++
    if (pinFailedAttempts >= Config.lock.auth.maxPinRetries) {
        pinEnabled = false
    }
}

function onUnlockSuccess() {
    faceFailedAttempts = 0
    pinFailedAttempts = 0
    faceEnabled = true
    pinEnabled = true
}
```

### Passo 4: Adaptar handleKey para PIN

```qml
function handleKey(event: KeyEvent): void {
    // Se modo PIN, só aceita números
    if (currentMode === "pin") {
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            buffer += event.text
        } else if (event.key === Qt.Key_Backspace) {
            buffer = buffer.slice(0, -1)
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start()
        }
        return
    }
    
    // Lógica existente para password
    // ...
}
```

### Passo 5: Atualizar Config

```json
// ~/.config/caelestia/shell.json
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

---

## 📝 Arquivos a Modificar

1. **Criar Novo**:
   - `modules/lock/AuthMethodSelector.qml` (80 linhas)

2. **Modificar Existentes**:
   - `modules/lock/Center.qml` (+10 linhas)
   - `modules/lock/Pam.qml` (+50 linhas)
   - `config/LockConfig.qml` (+10 linhas)

**Total**: ~150 linhas de código novo

---

## 🎯 Fluxo de Funcionamento

### Inicialização
```
1. Lock screen abre
2. AuthMethodSelector renderiza com "Face" selecionado
3. Howdy inicia automaticamente (fprint.checkAvail())
4. User vê botões: [Face (ativo)] [PIN] [Password]
```

### Mudança de Método
```
1. User clica em "PIN"
2. AuthMethodSelector.selectedMethod = "pin"
3. Pam.currentMode = "pin"
4. handleKey() passa a aceitar apenas números
5. Ícone muda de 🔓 para 🔢
```

### Face Falha 5x
```
1. Howdy falha 5x
2. Pam.onFaceAuthFailed() → faceEnabled = false
3. AuthMethodSelector recebe faceEnabled = false
4. Botão Face fica grayed out
5. Tooltip: "Face disabled. Use PIN or Password."
6. Default muda automaticamente para PIN (ou Password se PIN disabled)
```

---

## 🎨 Estilos dos Botões

### Estado Normal
```qml
StyledRect {
    color: Colours.tPalette.m3surfaceContainer
    radius: Appearance.rounding.small
    
    // Hover
    StateLayer {
        color: Colours.palette.m3primary
    }
}
```

### Estado Ativo
```qml
StyledRect {
    color: Colours.palette.m3primaryContainer
    border.color: Colours.palette.m3primary
    border.width: 2
}
```

### Estado Desabilitado
```qml
StyledRect {
    color: Colours.tPalette.m3surfaceContainer
    opacity: 0.5
    enabled: false
}
```

---

## ✅ Checklist de Implementação

### Fase 1: Setup (1h)
- [ ] Criar `AuthMethodSelector.qml`
- [ ] Definir properties (selectedMethod, faceEnabled, pinEnabled)
- [ ] Criar 3 botões (Face, PIN, Password)
- [ ] Adicionar tooltips

### Fase 2: Integração Center.qml (30min)
- [ ] Adicionar AuthMethodSelector após foto de perfil
- [ ] Conectar com Pam.qml
- [ ] Testar renderização

### Fase 3: Lógica Pam.qml (2h)
- [ ] Adicionar property currentMode
- [ ] Adicionar contadores de falhas
- [ ] Modificar handleKey() para PIN
- [ ] Adicionar onFaceAuthFailed/onPinAuthFailed
- [ ] Adicionar onUnlockSuccess (reativa métodos)

### Fase 4: Config (30min)
- [ ] Adicionar LockConfig.auth {}
- [ ] Valores default (face, 5, 10, 30)
- [ ] Testar carregamento de config

### Fase 5: Testes (1h)
- [ ] Lock screen abre com Face selecionado
- [ ] Botões mudam visual ao clicar
- [ ] Face auth funciona (Howdy)
- [ ] PIN mode aceita apenas números
- [ ] Password mode aceita texto
- [ ] Face desabilita após 5 falhas
- [ ] PIN desabilita após 10 falhas
- [ ] Unlock reativa todos métodos

**Total**: ~5 horas de implementação

---

## 🔄 Comparação: Antes vs Depois

### Antes
```
Lock Screen
    ↓
Campo input (aceita senha)
Ícone fingerprint (se disponível)
    ↓
Tenta fingerprint automaticamente
Se falhar → digita senha
```

### Depois
```
Lock Screen
    ↓
Botões: [Face] [PIN] [Password]
Default: Face selecionado
    ↓
Face mode → Howdy automático
PIN mode → Aceita apenas números
Password mode → Aceita texto
    ↓
Falhas → Desabilita método
Unlock → Reativa todos
```

---

## 🎯 Vantagens

1. **Mínima Invasão**: Apenas ~150 linhas novas
2. **Mantém Design**: Lock screen continua bonito
3. **Simples**: 1 componente novo + pequenas modificações
4. **Rápido**: ~5h de implementação vs ~52h original

---

## 📊 Status

**Decisão**: Implementação simplificada ✅
**Escopo**: Apenas botões de seleção
**Mantém**: Todo o design atual do Caelestia
**Tempo**: ~5 horas (vs 52h do plano original)

---

**Próximo**: Começar Fase 1 (criar AuthMethodSelector.qml) quando quiser! 🚀
