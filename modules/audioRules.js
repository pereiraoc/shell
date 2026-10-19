.pragma library

// Motor das regras de audio (modules/AudioRules.qml): o que conta como "um
// app esta usando o microfone". Mesmo criterio do caelestia-sound
// (IGNORED_APPS): streams de captura que nao sejam do proprio shell (cava,
// quickshell) nem dos nos de processamento (echo-cancel, filter-chain).
// Sem Qt: testavel com qmltestrunner (tests/qml/tst_audio_rules.qml).

var IGNORED = ["cava", "quickshell", "caelestia", "qs"];

function ignoredName(n) {
    if (!n)
        return false;
    const s = String(n).toLowerCase();
    return IGNORED.includes(s) || s.startsWith("quickshell") || s.startsWith("caelestia");
}

// streams: [{ name, app, bin }]; isProcessing(name) = no de filtro do caelestia
function micOpen(streams, isProcessing) {
    return streams.some(s => !isProcessing(s.name) && !ignoredName(s.name) && !ignoredName(s.app) && !ignoredName(s.bin));
}

// Apps que estao usando o mic (para a notificacao), sem repetir
function micApps(streams, isProcessing) {
    const out = [];
    for (const s of streams) {
        if (isProcessing(s.name) || ignoredName(s.name) || ignoredName(s.app) || ignoredName(s.bin))
            continue;
        const label = s.app || s.bin || s.name;
        if (label && !out.includes(label))
            out.push(label);
    }
    return out;
}

// Texto da notificacao: "Headset · Spatial" (+ " — cs2")
function summary(mode, scene, cls, modeLabels, sceneLabels) {
    const parts = [modeLabels[mode] ?? mode, sceneLabels[scene] ?? scene];
    return parts.join(" · ") + (cls ? " — " + cls : "");
}
