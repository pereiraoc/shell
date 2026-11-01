import QtQuick
import QtTest
import "../../modules/nexus/pages/server/server.js" as S

TestCase {
    name: "Server"

    readonly property var acts: [{ id: "stop:immich" }, { id: "restart:immich" }, { id: "start:jellyfin" }, { id: "open:immich" }, { id: "browse:shared" }, { id: "shell" }]
    readonly property real now: Date.parse("2026-11-01T10:00:00")

    function test_fmtBytes() {
        compare(S.fmtBytes(0), "0 B");
        compare(S.fmtBytes(1536), "1.5 KB");
        compare(S.fmtBytes(4000787030016), "3.6 TB");
        compare(S.fmtBytes(null), "?");
    }

    function test_fmtUptime() {
        compare(S.fmtUptime(90), "1 min");
        compare(S.fmtUptime(3661), "1 h 1 min");
        compare(S.fmtUptime(90000), "1 d 1 h");
        compare(S.fmtUptime(undefined), "?");
    }

    function test_fmtAgo() {
        compare(S.fmtAgo("2026-11-01T09:30:00", now), "30 min ago");
        compare(S.fmtAgo("2026-11-01T03:30:00", now), "6 h ago");
        compare(S.fmtAgo("2026-10-20T03:30:00", now), "12 d ago");
        compare(S.fmtAgo(null, now), "");
        compare(S.fmtAgo("garbage", now), "");
    }

    function test_state() {
        compare(S.stateKey("active"), "on");
        compare(S.stateKey("inactive"), "off");
        compare(S.stateKey("activating"), "starting");
        compare(S.stateKey("failed"), "failed");
        compare(S.stateIcon("on"), "check_circle");
        compare(S.stateIcon("weird"), "help");
    }

    function test_actions() {
        compare(S.pickActions(acts, "open:").map(a => a.id), ["open:immich"]);
        compare(S.stackActions(acts, "immich").map(a => a.id), ["stop:immich", "restart:immich"]);
        compare(S.stackActions(acts, "jellyfin").map(a => a.id), ["start:jellyfin"]);
        compare(S.actionById(acts, "shell").id, "shell");
        compare(S.actionById(acts, "nope"), null);
        compare(S.pickActions(null, "x"), []);
    }

    function test_reach_units_storage() {
        compare(S.reachKey({ online: true, reach: "lan" }), "lan");
        compare(S.reachKey({ online: true }), "ssh");
        compare(S.reachKey({ online: false }), "offline");
        compare(S.reachKey(null), "offline");
        const d = { stacks: [{ unit: "stack-immich.service", name: "immich" }], services: [{ unit: "caddy.service" }, { unit: "nas-backup.timer" }] };
        compare(S.unitsForLogs(d).map(u => u.value), ["stack-immich.service", "caddy.service", "nas-backup.timer"]);
        compare(S.unitsForLogs(d)[2].label, "nas-backup");
        compare(S.unitsForLogs(null), []);
        compare(S.storageFs({ filesystems: [{ mount: "/" }, { mount: "/srv/storage", pct: 42 }] }, "/srv/storage").pct, 42);
        compare(S.storageFs({}, "/x"), null);
        compare(S.pct({ pct: 42 }), 0.42);
        compare(S.pct(null), 0);
    }

    function test_silhouette() {
        const disks = [
            { dev: "nvme0n1", kind: "ssd", bus: "nvme", bay: null, size: 128035676160, model: "TWSC", smart: "PASSED", temp: 41 },
            { dev: "sda", kind: "hdd", bus: "ata", bay: 2, size: 4000787030016, model: "ST4000VN006", smart: "PASSED", temp: 33 },
            { dev: "sdb", kind: "hdd", bus: "ata", bay: 1, size: 4000787030016, model: "ST4000VN006", smart: "FAILED", temp: 51 }
        ];
        const bays = S.bayMap(disks);
        compare(bays[1].dev, "sdb");
        compare(bays[2].dev, "sda");
        compare(bays[3], undefined);
        compare(S.bayMap([{ dev: "sda", kind: "hdd" }, { dev: "sdb", kind: "hdd" }])[2].dev, "sdb");  // sem `bay`: pela ordem
        compare(S.m2Slots(disks).map(d => d.dev), ["nvme0n1"]);
        const net = [{ iface: "enp1s0", driver: "atlantic", up: true, speed_mbps: 1000, ip: "192.168.15.129" }, { iface: "enp4s0", driver: "igc", up: false, speed_mbps: -1, ip: null }];
        compare(S.lanPort(net, "igc").iface, "enp4s0");
        compare(S.lanPort(null, "igc"), null);
        const info = { online: true, uptime_s: 7200, disks, net, fans: { case_rpm: 655, case_mode: "manual", cpu_rpm: 867, cpu_mode: "auto" } };
        compare(S.spotLegend("bay-1", info), "Bay 1 · sdb ST4000VN006 · 3.6 TB · SMART FAILED · 51 °C");
        compare(S.spotLegend("bay-4", info), "Bay 4 · empty");
        compare(S.spotLegend("m2-2", info), "M.2 slot 2 · empty (Lexar NM790 pending)");
        compare(S.spotLegend("m2-1", info), "M.2 slot 1 · nvme0n1 TWSC · 119.2 GB · SMART PASSED · 41 °C · system");
        compare(S.spotLegend("power", info), "Power · on, up for 2 h 0 min");
        compare(S.spotLegend("power", { online: false }), "Power · out of reach");
        compare(S.spotLegend("fan", info), "Fan · case 655 rpm (manual) · CPU 867 rpm (auto)");
        compare(S.spotLegend("lan-10g", info), "LAN 2 · 10 GbE (enp1s0) · link 1000 Mb/s · 192.168.15.129");
        compare(S.spotLegend("lan-2g5", info), "LAN 1 · 2.5 GbE (enp4s0) · no cable");
        compare(S.spotLegend("ram-1", { mem: { total: 7887 } }), "Memory slot 1 · 8 GB installed");
        compare(S.spotLegend("ram-2", {}), "Memory slot 2 · empty (ADATA 16 GB pending)");
        compare(S.spotTab("ram-2"), "system");
        compare(S.spotTab("bay-2"), "storage");
        compare(S.spotTab("m2-1"), "storage");
        compare(S.spotTab("fan"), "system");
    }

    function test_levels() {
        compare(S.fsLevel({ pct: 10 }), "ok");
        compare(S.fsLevel({ pct: 80 }), "warn");
        compare(S.fsLevel({ pct: 95 }), "error");
        compare(S.fsLevel({ pct: 10, btrfs: { scrub: { errors: 2 } } }), "error");
        compare(S.backupLevel(null, now), "ok");
        compare(S.backupLevel({ last_result: "failed" }, now), "error");
        compare(S.backupLevel({ last_result: "success", last_start: "2026-11-01T03:30:00" }, now), "ok");
        compare(S.backupLevel({ last_result: "success", last_start: "2026-10-29T03:30:00" }, now), "warn");
        compare(S.backupLevel({ last_result: "success", last_start: "2026-11-01T03:30:00", alert: true }, now), "warn");
    }
}
