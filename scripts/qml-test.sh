#!/usr/bin/env bash
# Testes de QML/JS puros do fork (qmltestrunner, headless).
#   bash scripts/qml-test.sh            # todos em tests/qml
#   bash scripts/qml-test.sh <arquivo>  # um arquivo
set -euo pipefail
cd "$(dirname "$0")/.."
export QT_QPA_PLATFORM=offscreen
exec /usr/lib/qt6/bin/qmltestrunner -input "${1:-tests/qml}"
