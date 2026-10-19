import QtQuick
import QtTest
import "../../modules/audioRules.js" as R

TestCase {
    name: "AudioRules"

    readonly property var isProcessing: n => n.startsWith("caelestia_ec_") || n.startsWith("echo-cancel-")

    function test_micOpen() {
        // so o shell e os nos de processamento capturando: mic fechado
        const own = [{ name: "cava", app: "cava", bin: "cava" }, { name: "caelestia_ec_capture", app: "", bin: "" }, { name: "echo-cancel-capture", app: "PipeWire", bin: "pipewire" }];
        verify(!R.micOpen(own, isProcessing));
        compare(R.micApps(own, isProcessing).length, 0);
        // um app de verdade: aberto, e aparece pelo nome do app
        const withDiscord = own.concat([{ name: "Discord", app: "Discord", bin: "Discord" }, { name: "cs2", app: "cs2", bin: "cs2" }]);
        verify(R.micOpen(withDiscord, isProcessing));
        compare(R.micApps(withDiscord, isProcessing).join(","), "Discord,cs2");
        verify(!R.micOpen([], isProcessing));
    }

    function test_summary() {
        const m = { headphone: "Headphones", headset: "Headset" }, s = { normal: "Normal", custom: "Spatial" };
        compare(R.summary("headset", "custom", "cs2", m, s), "Headset · Spatial — cs2");
        compare(R.summary("headphone", "normal", "", m, s), "Headphones · Normal");
    }
}
