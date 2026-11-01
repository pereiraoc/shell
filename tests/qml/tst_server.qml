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
