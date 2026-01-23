# 🔧 Troubleshooting Transversal

**Última Atualização**: 2026-01-22

> **Nota**: Este arquivo contém apenas problemas **transversais** que afetam o repositório como um todo.
> 
> Para problemas específicos de features, veja a seção "Troubleshooting" no respectivo arquivo `plan-and-implementation/2X-nome.md`.

---

## 🛠️ Ferramentas de Debug

### Ver Logs do Quickshell

```bash
# Últimas 100 linhas
tail -100 /run/user/1000/quickshell/by-id/*/log.qslog

# Seguir em tempo real
tail -f /run/user/1000/quickshell/by-id/*/log.qslog

# Filtrar erros
tail -100 /run/user/1000/quickshell/by-id/*/log.qslog | grep -i error

# Limpar caracteres binários
tail -100 /run/user/1000/quickshell/by-id/*/log.qslog | strings
```

### Verificar Processo

```bash
# Quickshell rodando?
ps aux | grep quickshell

# Uso de recursos
htop -p $(pgrep quickshell)

# Sessões de login
loginctl list-sessions
```

### Validar Config

```bash
# Validar JSON
jq empty ~/.config/caelestia/shell.json

# Ver config completo
cat ~/.config/caelestia/shell.json | jq

# Ver seção específica
jq '.lock' ~/.config/caelestia/shell.json
```

---

## 🚫 Quickshell Não Inicia

### Sintomas
- `quickshell` comando não encontrado
- Processo não aparece em `ps aux`

### Diagnóstico

```bash
# Verificar instalação
which quickshell

# Verificar versão
quickshell --version

# Tentar rodar
quickshell -c caelestia
```

### Soluções

#### Não Instalado

```bash
# Instalar via AUR
paru -S quickshell-git
```

#### Path Incorreto

```bash
# Adicionar ao PATH
export PATH="$HOME/.local/bin:$PATH"

# Ou usar path completo
$HOME/.local/bin/quickshell -c caelestia --daemonize
```

#### Config Inválido

```bash
# Testar sem daemonize para ver erros
quickshell -c caelestia

# Verificar logs
journalctl --user -xe | grep quickshell
```

---

## 💥 Quickshell Crashando

### Sintomas
- Quickshell fecha inesperadamente
- Volta para TTY ou tela preta
- Segmentation fault nos logs

### Diagnóstico

```bash
# Logs do sistema
journalctl --user -u quickshell -n 100

# Core dump
coredumpctl list quickshell
coredumpctl info quickshell

# Últimos logs antes do crash
tail -200 /run/user/1000/quickshell/by-id/*/log.qslog
```

### Causa: Qt6 QML Crashes (Conhecido)

**Problema conhecido** do Caelestia/Quickshell com Qt6.

**Workarounds**:
- Evitar `FileView` com `watch: true`
- Usar `Component.incubateObject()` com `Component.Synchronous`
- Não fazer operações pesadas no main thread

**Referência**: Documentado no caelestia-arch-setup

### Causa: Memória Insuficiente

```bash
# Verificar memória
free -h

# Ver uso do Quickshell
htop -p $(pgrep quickshell)
```

### Causa: Conflito de Bibliotecas

```bash
# Ver libs do Quickshell
ldd $(which quickshell) | grep -i qt

# Reinstalar
paru -S quickshell-git --rebuild
```

---

## 🔨 Problemas de Build

### CMake Não Encontra Dependências

```bash
# Instalar dependências básicas
sudo pacman -S cmake ninja qt6-base qt6-declarative

# Limpar build
rm -rf build/
cmake -B build -G Ninja
```

### Erro ao Compilar

```bash
# Ver erro completo
cmake --build build 2>&1 | less

# Rebuild completo
cmake --build build --clean-first
```

### Erro ao Instalar

```bash
# Permissões
sudo cmake --install build

# Verificar destino
cmake --install build --prefix ~/.local
```

---

## 📝 Config Não Carrega

### Sintomas
- Mudanças em `shell.json` não aplicam
- Sempre usa valores default

### Diagnóstico

```bash
# Validar JSON
jq empty ~/.config/caelestia/shell.json

# Verificar se existe
ls -la ~/.config/caelestia/shell.json

# Ver se Quickshell está lendo
strace -e open,read -p $(pgrep quickshell) 2>&1 | grep shell.json
```

### Soluções

#### JSON Inválido

```bash
# Verificar erro
jq empty ~/.config/caelestia/shell.json
# parse error: ...

# Restaurar backup
cp ~/.config/caelestia/shell.json.backup ~/.config/caelestia/shell.json
```

#### Quickshell Não Reiniciou

```bash
# SEMPRE reiniciar após mudar config
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

#### Permissões

```bash
# Verificar
ls -la ~/.config/caelestia/shell.json

# Corrigir
chmod 644 ~/.config/caelestia/shell.json
```

---

## 🔄 Git: Conflitos com Upstream

### Sintomas
- `git merge upstream/main` tem conflitos
- Arquivos modificados pelo patch conflitam

### Estratégia

**Arquivos que vamos modificar frequentemente**:
- `modules/lock/Pam.qml`
- `modules/lock/Center.qml`
- `config/LockConfig.qml`

**Como resolver**:

```bash
# Fetch upstream
git remote add upstream https://github.com/caelestia-dots/shell.git
git fetch upstream

# Ver diferenças
git diff upstream/main...HEAD

# Merge com cuidado
git merge upstream/main

# Se conflito:
# 1. Resolver manualmente
# 2. git add <arquivo>
# 3. git merge --continue
```

**Dica**: Manter patches mínimos facilita merge!

---

## 🔁 Reset Total

Se tudo falhar, reset completo:

```bash
# 1. Backup
mkdir -p ~/caelestia-backup-$(date +%Y%m%d)
cp -r ~/.config/caelestia ~/caelestia-backup-$(date +%Y%m%d)/
cp -r ~/.local/share/caelestia ~/caelestia-backup-$(date +%Y%m%d)/

# 2. Limpar
rm -rf ~/.config/caelestia
rm -rf ~/.local/share/caelestia
rm -rf /run/user/1000/quickshell

# 3. Reinstalar
cd /data/projects/caelestia-shell-pereiraoc-patch
cmake --build build --clean-first
sudo cmake --install build

# 4. Recriar config mínimo
mkdir -p ~/.config/caelestia
cat > ~/.config/caelestia/shell.json << 'EOF'
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
EOF

# 5. Reiniciar
killall quickshell
XDG_DATA_DIRS=$HOME/.local/share:$XDG_DATA_DIRS quickshell -c caelestia --daemonize
```

---

## 📞 Reportar Bugs

### Antes de Reportar

1. ✅ Consultou este arquivo
2. ✅ Consultou troubleshooting da feature específica
3. ✅ Tentou reset/reinstalar
4. ✅ Coletou logs

### Informações Necessárias

```bash
# Coletar info do sistema
cat > bug-report.txt << 'EOF'
=== System ===
EOF
uname -a >> bug-report.txt
echo "" >> bug-report.txt

echo "=== Quickshell Version ===" >> bug-report.txt
quickshell --version >> bug-report.txt
echo "" >> bug-report.txt

echo "=== Config ===" >> bug-report.txt
cat ~/.config/caelestia/shell.json >> bug-report.txt
echo "" >> bug-report.txt

echo "=== Logs ===" >> bug-report.txt
tail -200 /run/user/1000/quickshell/by-id/*/log.qslog >> bug-report.txt
```

### O Que Incluir

- **O que tentou fazer**: "Tentei abrir o lock screen com Super+L"
- **O que esperava**: "Deveria aparecer os 3 botões Face/PIN/Password"
- **O que aconteceu**: "Tela preta, nada apareceu"
- **Logs**: Anexar `bug-report.txt`
- **Steps para reproduzir**: Lista numerada

---

**Lembre-se**: Problemas específicos de features têm troubleshooting próprio nos respectivos `plan-and-implementation/2X-nome.md`!
