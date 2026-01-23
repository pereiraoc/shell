#!/bin/bash
# Script para instalar Caelestia Patched de forma limpa
# Remove versões duplicadas e instala em /etc/xdg/quickshell/caelestia/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="/etc/xdg/quickshell/caelestia"

echo "=== Instalação Limpa do Caelestia Patched ==="
echo "Fonte: $PROJECT_DIR"
echo "Destino: $TARGET_DIR"
echo ""

# Remover instalação duplicada em /usr/local se existir
if [ -d "/usr/local/etc/xdg/quickshell/caelestia" ]; then
    echo "Removendo versão duplicada em /usr/local/etc/xdg/quickshell/caelestia..."
    sudo rm -rf /usr/local/etc/xdg/quickshell/caelestia
fi

# Fazer backup da versão atual se existir
if [ -d "$TARGET_DIR" ]; then
    echo "Removendo versão antiga em $TARGET_DIR..."
    sudo rm -rf "$TARGET_DIR"
fi

# Criar diretório destino
sudo mkdir -p "$TARGET_DIR"

# Copiar arquivos (excluindo .git, build, etc)
echo "Copiando arquivos..."
sudo rsync -av --delete \
    --exclude='.git' \
    --exclude='build' \
    --exclude='.vscode' \
    --exclude='*.md' \
    --exclude='.envrc' \
    --exclude='.github' \
    --exclude='nix' \
    --exclude='flake.lock' \
    --exclude='flake.nix' \
    --exclude='scripts' \
    "$PROJECT_DIR/" "$TARGET_DIR/"

# Ajustar permissões
sudo chown -R root:root "$TARGET_DIR"
sudo chmod -R 755 "$TARGET_DIR"

echo ""
echo "=== Instalação concluída ==="
echo ""
echo "Reinicie o Caelestia com: Super+Shift+R"
echo "Ou execute: killall quickshell && quickshell -c caelestia --daemonize"
