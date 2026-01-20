# Caelestia Shell - Pereiraoc Patch
## caelestia-shell-pereiraoc-patch

[![Status](https://img.shields.io/badge/status-alpha-yellow?style=for-the-badge)](https://github.com/pereiraoc/caelestia-shell-pereiraoc-patch)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue?style=for-the-badge)](LICENSE)
[![Based on](https://img.shields.io/badge/based%20on-caelestia--shell-9ccbfb?style=for-the-badge)](https://github.com/caelestia-dots/shell)

---

## 🎯 Sobre Este Fork

Este é um fork personalizado do [Caelestia Shell](https://github.com/caelestia-dots/shell) criado para adicionar **autenticação biométrica e por PIN no lock screen**.

### ✨ Novos Recursos

- **🔐 Autenticação Facial (Howdy)**: Reconhecimento facial via câmera
- **🔢 Autenticação por PIN**: Teclado numérico para entrada rápida de código
- **🎨 Seletor Visual**: Botões para escolher entre Face, PIN ou Senha
- **🔄 Fallback Inteligente**: Sempre mantém senha tradicional como backup
- **⚡ Rate Limiting**: Proteção contra brute force com lockout temporário
- **📊 Feedback Visual**: Animações e indicadores durante autenticação

### 🆚 Diferenças do Upstream

| Recurso | Upstream | Este Fork |
|---------|----------|-----------|
| Lock Screen Auth | Senha + Fingerprint | Senha + Face (Howdy) + PIN |
| Auth Method Selector | Não | ✅ Botões visuais |
| PIN Keyboard | Não | ✅ Teclado numérico |
| Face Auth Feedback | Não | ✅ Indicador visual |
| Rate Limiting | Básico | ✅ Avançado + lockout |

---

## 📸 Screenshots

> 🚧 Em desenvolvimento - screenshots serão adicionados em breve

---

## 📦 Instalação

### Pré-requisitos

**Dependências do Caelestia Shell original**:
```bash
# Ver lista completa em:
# https://github.com/caelestia-dots/shell#manual-installation
```

**Dependências Adicionais deste Fork**:
```bash
# Howdy (reconhecimento facial)
paru -S howdy-git

# V4L Utils (acesso à câmera)
sudo pacman -S v4l-utils

# Python OpenCV (detecção facial)
sudo pacman -S python-opencv
```

### Instalação Manual

```bash
# 1. Clonar este patch
cd ~/.config/quickshell
git clone https://github.com/pereiraoc/caelestia-shell-pereiraoc-patch.git caelestia

# 2. Build e instalação
cd caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build
sudo cmake --install build

# 3. Configurar Howdy
sudo howdy add  # Adicionar seu rosto
sudo howdy test # Testar reconhecimento

# 4. Reiniciar shell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

### Instalação via caelestia-arch-setup

Se você usa o [caelestia-arch-setup](https://github.com/pereiraoc/caelestia-arch-setup):

```bash
# Script de instalação automática (em breve)
bash scripts/stage3/35-caelestia-fork-install.sh
```

---

## ⚙️ Configuração

### Configuração Básica

Edite `~/.config/caelestia/shell.json`:

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

### Opções de Configuração

#### Face Authentication
- `enableFaceAuth`: Habilitar reconhecimento facial (padrão: `true`)
- `faceAuthTimeout`: Timeout em ms (padrão: `5000`)
- `maxFaceRetries`: Falhas antes de desabilitar Face (padrão: `5`)

**Comportamento**: Após 5 falhas, Face é desabilitado até próximo unlock bem-sucedido.

#### PIN Authentication
- `enablePinAuth`: Habilitar autenticação por PIN (padrão: `true`)
- `pinLength`: Tamanho do PIN (4-8 dígitos, padrão: `4`)
- `pinAutoSubmit`: Auto-enviar quando atingir pinLength (padrão: `true`)
- `maxPinRetries`: Falhas antes de desabilitar PIN (padrão: `10`)

**Comportamento**: Após 10 falhas, PIN é desabilitado até próximo unlock bem-sucedido.

#### Password Authentication
- `maxPasswordRetries`: Falhas antes de lockout total (padrão: `30`)

**Comportamento**: Senha sempre disponível. Lockout total apenas após 30 falhas.

#### Default Method
- `defaultMethod`: Método padrão ao abrir lock screen
  - `"face"`: Face authentication (padrão)
  - `"pin"`: PIN numpad
  - `"password"`: Senha tradicional

**Lógica de Auto-Desabilitação**:
- Face desabilitado → Default muda para PIN (se disponível) ou Password
- PIN desabilitado → Default muda para Face (se disponível) ou Password
- Ambos desabilitados → Default muda para Password
- Unlock bem-sucedido → Todos métodos reativam e default volta ao configurado

---

## 🚀 Uso

### Lock Screen

**Trancar sessão**:
```bash
# Via atalho Hyprland
Super + L

# Via comando
loginctl lock-session

# Via IPC
caelestia shell lock lock
```

### Métodos de Autenticação

#### 1. Face Recognition
1. Lock screen aparece
2. Clique no botão "Face Recognition" (ou aguarde, se for padrão)
3. Posicione seu rosto na câmera
4. Aguarde reconhecimento (~2s)
5. Unlock automático se reconhecido

#### 2. PIN
1. Lock screen aparece
2. Clique no botão "PIN"
3. Digite seu PIN no teclado numérico
4. Pressione Enter (ou auto-submit se configurado)
5. Unlock se PIN correto

#### 3. Password (Fallback)
1. Pressione qualquer tecla alfabética
2. Digite sua senha tradicional
3. Pressione Enter
4. Unlock se senha correta

### Atalhos de Teclado

- `F`: Mudar para Face authentication
- `P`: Mudar para PIN authentication
- `Enter`: Tentar autenticação
- `Backspace`: Apagar último dígito (PIN) ou caractere (senha)
- `Ctrl+Backspace`: Limpar tudo
- `Esc`: Cancelar tentativa atual

---

## 🔒 Segurança

### Considerações Importantes

⚠️ **Howdy não é tão seguro quanto senha**:
- Pode ser enganado por fotos em alguns casos
- Depende de iluminação e ângulo
- Use como conveniência, não como única linha de defesa

✅ **Práticas Recomendadas**:
- Sempre mantenha senha forte como fallback
- Adicione múltiplos modelos faciais (diferentes ângulos/iluminação)
- Configure `motion_detection` no Howdy para evitar fotos estáticas
- Use PIN como backup quando câmera não disponível
- **Não use para**: unlock de LUKS, disk encryption

### Estratégia de Auto-Desabilitação

**Filosofia**: Sem lockout temporal frustrante. Métodos se auto-desabilitam após abuse, mas sempre mantém alternativas.

#### Face Authentication
- **5 falhas**: Face desabilitado temporariamente
- **Reativação**: Unlock bem-sucedido via PIN ou Senha
- **Feedback**: Botão Face fica grayed out com mensagem clara

#### PIN Authentication
- **10 falhas**: PIN desabilitado temporariamente  
- **Reativação**: Unlock bem-sucedido via Face ou Senha
- **Feedback**: Botão PIN fica grayed out com mensagem clara

#### Password (Senha Tradicional)
- **Sempre disponível**: Último recurso
- **30 falhas**: Lockout total (todos métodos bloqueados)
- **Escape**: TTY sempre disponível (Ctrl+Alt+F2)

### Cenários de Falha

```
Cenário 1: Face falha 5x
  → Face desabilitado
  → PIN e Senha disponíveis
  → User usa PIN → Unlock → Face reativa

Cenário 2: PIN falha 10x
  → PIN desabilitado
  → Face e Senha disponíveis
  → User usa Face → Unlock → PIN reativa

Cenário 3: Face falha 5x, PIN falha 10x
  → Ambos desabilitados
  → Apenas Senha disponível
  → User usa Senha → Unlock → Ambos reativam

Cenário 4: Senha falha 30x
  → Lockout total
  → Apenas TTY disponível (Ctrl+Alt+F2)
  → Login via TTY → Todos métodos reativam
```

**Vantagem**: User nunca fica esperando countdown. Sempre há alternativa disponível.

---

## 🐛 Troubleshooting

### Howdy não funciona

```bash
# 1. Verificar câmera
ls /dev/video*

# 2. Testar Howdy
sudo howdy test

# 3. Verificar config
sudo cat /lib/security/howdy/config.ini | grep device_path

# 4. Checar logs
sudo journalctl -xe | grep howdy
```

### PIN não aceita

- Verifique que está usando sua senha do sistema (não um PIN separado)
- PIN é apenas um método de entrada, valida contra senha PAM
- Para usar PIN dedicado, configure keyring (futuro)

### Lock screen não aparece

```bash
# Reiniciar shell
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize

# Verificar erros
journalctl --user -u quickshell -f
```

### Camera access denied

```bash
# Adicionar user ao grupo video
sudo usermod -aG video $USER

# Logout e login novamente
```

---

## 📝 Desenvolvimento

### Build Local

```bash
# Desenvolvimento
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Watch mode (rebuild on changes)
while inotifywait -r -e modify,create,delete modules/ components/; do
  cmake --build build
  killall quickshell
  XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
done
```

### Estrutura de Arquivos (Novos)

```
modules/lock/
├── AuthMethodSelector.qml     # Botões Face/PIN/Password
├── PinKeyboard.qml            # Teclado numérico
├── PinInputField.qml          # Display do PIN (dots)
├── FaceAuthIndicator.qml      # Indicador de face scanning
├── AuthFeedback.qml           # Mensagens de erro/sucesso
└── AuthConfig.qml             # Configurações de autenticação
```

### Roadmap

**v0.1.0-alpha** (Em andamento):
- [x] Fork do repositório
- [x] Planejamento detalhado
- [ ] AuthMethodSelector component
- [ ] PinKeyboard component
- [ ] Face authentication integration
- [ ] Rate limiting & lockout
- [ ] Documentação básica

**v0.2.0-beta**:
- [ ] GUI para configurações
- [ ] Fingerprint real (fprintd)
- [ ] Smart card support
- [ ] PIN dedicado (keyring)

**v1.0.0**:
- [ ] Testes completos
- [ ] Performance otimizada
- [ ] Documentação completa
- [ ] Integração CI/CD

Ver [PLANNING.md](PLANNING.md) para roadmap detalhado.

---

## 🤝 Contribuição

Contribuições são bem-vindas! Este é um projeto pessoal, mas aceito PRs.

### Como Contribuir

1. Fork este repositório
2. Crie branch: `git checkout -b feature/minha-feature`
3. Commit: `git commit -m "feat: minha feature"`
4. Push: `git push origin feature/minha-feature`
5. Abra Pull Request

### Convenções

- **Commits**: Semantic commits (feat/fix/docs/style/refactor/test/chore)
- **QML**: PascalCase para componentes, camelCase para properties
- **Código**: Seguir estilo do Caelestia upstream
- **Testes**: Adicionar testes para novos recursos

---

## 📚 Documentação

- **[PLANNING.md](PLANNING.md)**: Plano detalhado de implementação
- **[HOWDY_SETUP.md](HOWDY_SETUP.md)**: Guia de setup do Howdy (em breve)
- **[CHANGELOG.md](CHANGELOG.md)**: Histórico de mudanças (em breve)
- **[Upstream Docs](https://github.com/caelestia-dots/shell)**: Documentação original do Caelestia

---

## 🙏 Créditos

### Base
- **[Caelestia Shell](https://github.com/caelestia-dots/shell)** by [@soramane](https://github.com/soramane)
- **[Quickshell](https://quickshell.outfoxxed.me)** by [@outfoxxed](https://github.com/outfoxxed)

### Autenticação
- **[Howdy](https://github.com/boltgolt/howdy)** - Linux face authentication

### Inspiração
- **Windows Hello**: Face + PIN UI/UX
- **macOS Touch ID**: Biometric fallback patterns
- **Android Smart Lock**: Multiple auth methods

---

## 📄 Licença

GPLv3 - Ver [LICENSE](LICENSE) para detalhes.

Este fork mantém a mesma licença do upstream.

---

## 📞 Contato

**Mantenedor**: @pereiraoc  
**Projeto Principal**: [caelestia-arch-setup](https://github.com/pereiraoc/caelestia-arch-setup)  
**Upstream**: [caelestia-dots/shell](https://github.com/caelestia-dots/shell)

---

## ⭐ Star History

Se este fork foi útil, considere dar uma estrela!

---

<div align="center">

**Made with ❤️ for Arch Linux + Hyprland**

</div>
