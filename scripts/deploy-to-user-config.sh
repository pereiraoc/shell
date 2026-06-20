#!/bin/bash
# Deploy do caelestia-shell-pereiraoc-patch para ~/.config/quickshell/caelestia/
# Este é o caminho que o quickshell efetivamente carrega (XDG_CONFIG_HOME tem
# precedência sobre /etc/xdg). Para deploy system-wide use install-clean.sh.
#
# Uso:
#   bash scripts/deploy-to-user-config.sh           # deploy
#   bash scripts/deploy-to-user-config.sh --dry-run # mostra sem aplicar

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$HOME/.config/quickshell/caelestia"
SNAPSHOT_DIR="$HOME/.config/quickshell/caelestia.snapshot-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=""
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN="--dry-run"

echo "=== Deploy Caelestia Shell para ~/.config/ ==="
echo "Fonte:    $PROJECT_DIR"
echo "Destino:  $TARGET_DIR"
[[ -n "$DRY_RUN" ]] && echo "Modo:     DRY-RUN (sem aplicar)"
echo ""

# Snapshot do estado atual (se existir e não for dry-run) — rollback fácil
if [[ -z "$DRY_RUN" ]] && [[ -d "$TARGET_DIR" ]]; then
    echo "Snapshot do estado atual: $SNAPSHOT_DIR"
    cp -a "$TARGET_DIR" "$SNAPSHOT_DIR"
    # Rotação: mantém só os N snapshots mais recentes (evita crescimento ilimitado)
    KEEP="${CAELESTIA_SNAPSHOT_KEEP:-10}"
    ls -dt "$HOME/.config/quickshell/"caelestia.snapshot-* 2>/dev/null | tail -n +$((KEEP+1)) | while read -r old; do rm -rf "$old"; done
    echo ""
fi

# Criar diretório destino
mkdir -p "$TARGET_DIR"

# Sync (sem --delete para preservar arquivos pessoais .bak etc.)
# Excludes idênticos ao install-clean.sh + plugin/ (C++ source não vai)
echo "Sincronizando arquivos..."
rsync -av $DRY_RUN \
    --exclude='.git' \
    --exclude='build' \
    --exclude='.vscode' \
    --exclude='*.md' \
    --exclude='.envrc' \
    --exclude='.github' \
    --exclude='nix' \
    --exclude='flake.lock' \
    --exclude='flake.nix' \
    --exclude='/scripts' \
    --exclude='/docs' \
    --exclude='/development' \
    --exclude='/plugin' \
    --exclude='.snapshot-*' \
    "$PROJECT_DIR/" "$TARGET_DIR/"

if [[ -z "$DRY_RUN" ]]; then
    # Carimbo de proveniência — rastreia de qual commit/tag veio este deploy
    # (o ~/.config/.../caelestia é uma cópia, não um checkout git).
    PROV_SHA="$(git -C "$PROJECT_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
    PROV_DESC="$(git -C "$PROJECT_DIR" describe --tags --dirty --always 2>/dev/null || echo unknown)"
    printf '%s  %s  deploy=%s  src=%s\n' \
        "$PROV_DESC" "$PROV_SHA" "$(date +%Y-%m-%d\ %H:%M:%S)" "$PROJECT_DIR" \
        > "$TARGET_DIR/.caelestia-provenance"

    echo ""
    echo "=== Deploy concluído ==="
    echo ""
    echo "Proveniência: $(cat "$TARGET_DIR/.caelestia-provenance")"
    echo "Snapshot anterior: $SNAPSHOT_DIR"
    echo "Reverter:  rm -rf '$TARGET_DIR' && mv '$SNAPSHOT_DIR' '$TARGET_DIR'"
    echo "Restart:   Super+Shift+R   (ou: hyprctl dispatch exec 'quickshell -c caelestia --daemonize')"
else
    echo ""
    echo "=== DRY-RUN — nada foi aplicado ==="
fi
