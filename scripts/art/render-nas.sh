#!/usr/bin/env bash
# Renderiza OFFSCREEN (sem janela na tela, sem mexer no shell vivo) a silhueta
# do NAS: ServerDiagram (frente + tras, k = 2) e a miniatura NasFrontArt do
# Home, para comparar com as fotos em caelestia-assets/UGREEN DXP4800 Plus *.png.
#   bash scripts/art/render-nas.sh [pasta-de-saida]   -> nas.png, nas-mini.png
# Como: copia os dois QML + server.js para uma pasta temporaria trocando
# `import qs.services` por um stub de Colours (paleta lida do scheme.json vivo;
# o modulo qs.services inteiro nao carrega em offscreen porque Audio/Brightness
# precisam de Wayland) e roda `qs -p` com QT_QPA_PLATFORM=offscreen, pegando a
# imagem com grabToImage de uma Window. Caelestia.Config (Tokens) carrega normal.
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT="$(realpath -m "${1:-/tmp/caelestia-render-nas}")"
R="$(mktemp -d)"
trap 'rm -rf "$R"' EXIT
mkdir -p "$OUT" "$R/stubs"
python3 - "$R/stubs" <<'PY'
import json, sys
from pathlib import Path
c = json.load(open(Path.home() / ".local/state/caelestia/scheme.json"))["colours"]
names = ["primary", "tertiary", "error", "onSurface", "onSurfaceVariant", "outline", "outlineVariant", "surface", "surfaceContainerHighest"]
props = "\n".join(f'        readonly property color m3{n}: "#{c[n]}"' for n in names if n in c)
Path(sys.argv[1], "Colours.qml").write_text("pragma Singleton\nimport QtQuick\n\nQtObject {\n    readonly property bool light: false\n    readonly property QtObject palette: QtObject {\n" + props + "\n    }\n}\n")
Path(sys.argv[1], "qmldir").write_text("singleton Colours 1.0 Colours.qml\n")
PY
F=modules/nexus/pages
sed -e '/^import qs.components$/d' -e 's/^import qs.services$/import "stubs"/' "$F/server/ServerDiagram.qml" > "$R/ServerDiagram.qml"
sed -e 's/^import qs.services$/import "stubs"/' -e 's#import "../server/server.js" as S#import "server.js" as S#' "$F/home/NasFrontArt.qml" > "$R/NasFrontArt.qml"
cp "$F/server/server.js" "$R/server.js"
cat > "$R/probe.qml" <<QML
import QtQuick
import QtQuick.Window
import Quickshell

ShellRoot {
    Window {
        visible: true
        width: 1520
        height: 1900
        color: "#141318"

        ServerDiagram {
            id: d
            width: 1520
            info: ({ online: true, disks: [{ bus: "ata", kind: "hdd", bay: 1, size: 4e12, smart: "PASSED" }, { bus: "ata", kind: "hdd", bay: 2, size: 4e12, smart: "PASSED" }], net: [{ driver: "igc", up: true }], fans: { case_rpm: 900 }, mem: {} })
        }

        NasFrontArt {
            id: mini
            x: 20
            y: d.implicitHeight + 40
            width: 84
            height: 84
            online: true
            info: ({ online: true, disks: [{ bus: "ata", kind: "hdd", bay: 1 }, { bus: "ata", kind: "hdd", bay: 2 }], net: [{ up: true }] })
        }

        Timer {
            interval: 1500
            running: true
            onTriggered: d.grabToImage(r => {
                console.log("saved", r.saveToFile("$OUT/nas.png"));
                mini.grabToImage(m => { console.log("saved mini", m.saveToFile("$OUT/nas-mini.png")); Qt.quit(); });
            })
        }
    }
}
QML
QT_QPA_PLATFORM=offscreen timeout 40 qs -p "$R/probe.qml" 2>&1 | grep -i "saved\|error\|fail" | grep -iv "textinput" || true
echo "-> $OUT/nas.png  $OUT/nas-mini.png"
