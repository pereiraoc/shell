import QtQuick
import QtTest
import "../../modules/nexus/pages/server/homenet.js" as H

// Mapa da rede de casa (Network > Home): amostra recortada de um
// `caelestia-nas network --all --json` real (03/11).
TestCase {
    name: "HomeNet"

    readonly property real now: Date.parse("2026-11-03T03:00:00")
    readonly property var devs: [
        { mac: "internet", name: "152-243-166-213.user.vivozap.com.br", ip: "152.243.166.213", type: "Gateway", new: false, online: true, parent: "null", port: "" },
        { mac: "d8:c6:78:12:ac:88", name: "Roteador principal (Vivo, MitraStar)", ip: "192.168.15.1", type: "Router", new: false, online: true, parent: "internet", port: "" },
        { mac: "02:ca:e1:00:00:01", name: "Switch Ethernet (sala)", ip: "", vendor: "", type: "Switch", new: false, online: false, parent: "d8:c6:78:12:ac:88", port: "1" },
        { mac: "d8:77:8b:21:04:d0", name: "AP auxiliar (Intelbras ACtion RF1200, Cafofo 115 AUX)", ip: "192.168.15.3", type: "AP", new: false, online: true, parent: "02:ca:e1:00:00:01", port: "" },
        { mac: "40:ed:00:5e:e2:81", name: "Roteador VR (TP-Link Archer AX53 em NAT)", ip: "192.168.15.100", type: "Router", new: false, online: true, parent: "02:ca:e1:00:00:01", port: "" },
        { mac: "6c:1f:f7:a9:a8:8f", name: "NAS (DXP4800 Plus, NixOS)", ip: "192.168.15.129", type: "NAS", new: false, online: true, parent: "02:ca:e1:00:00:01", port: "2", conn: { kind: "ethernet", link_mbps: 1000, source: "ethtool", at: "2026-11-03T00:22:26" } },
        { mac: "d4:f5:47:97:7f:db", name: "Nest Mini (Caixa do Quarto)", ip: "192.168.15.169", type: "Speaker", new: false, online: true, parent: "d8:77:8b:21:04:d0", port: "wifi", conn: { kind: "wifi", via: "d8:77:8b:21:04:d0", band: "5G", signal_dbm: -59, rate_mbps: 6.5, source: "cast", at: "2026-11-03T00:22:26", survey_at: "2026-11-03T00:21:44" } },
        { mac: "d4:f5:47:06:53:c4", name: "Nest Mini (Caixa da Sala)", ip: "192.168.15.120", type: "Speaker", new: false, online: true, parent: "d8:c6:78:12:ac:88", port: "wifi", conn: { kind: "wifi", via: "d8:c6:78:12:ac:88", band: "5G", source: "cast" } },
        { mac: "a0:29:42:70:51:5c", name: "Laptop (Wi-Fi)", ip: "192.168.15.150", type: "Laptop", new: false, online: false, parent: "d8:c6:78:12:ac:88", port: "wifi" },
        { mac: "38:6b:1c:3b:4b:f8", name: "AP IoT (Mercusys MW301R)", ip: "192.168.15.2", type: "AP", new: false, online: true, parent: "d8:c6:78:12:ac:88", port: "" },
        { mac: "24:a1:60:0c:c3:95", name: "IoT Espressif (.124)", ip: "192.168.15.124", type: "IoT", new: false, online: true, parent: "38:6b:1c:3b:4b:f8", port: "wifi" },
        { mac: "24:a1:60:0d:76:19", name: "IoT Espressif (.167)", ip: "192.168.15.167", type: "IoT", new: false, online: true, parent: "38:6b:1c:3b:4b:f8", port: "wifi" },
        { mac: "9a:93:b9:30:39:57", name: "(name not found)", hostname: "Redmi-Note-13-Pro-5G", ip: "192.168.15.163", vendor: "(Unknown: locally administered)", type: "", new: true, online: true, first_seen: "2026-11-03 01:30:26", parent: "", port: "", conn: { kind: "wifi", via: "d8:77:8b:21:04:d0", band: "5G", signal_dbm: -73, rate_mbps: null, survey_at: "2026-11-03T00:21:44" } },
        { mac: "f2:8e:10:36:16:ed", name: "(name not found)", ip: "192.168.15.187", vendor: "(Unknown: locally administered)", type: "", new: true, online: false, first_seen: "2026-11-03 01:35:44", parent: "", port: "", conn: { kind: "wifi", via: "d8:77:8b:21:04:d0", band: "5G", signal_dbm: -49 } },
        { mac: "34:7d:e4:25:fc:ff", name: "(name not found)", hostname: "", ip: "192.168.15.189", vendor: "SHENZHEN BILIAN", type: "", new: true, online: true, first_seen: "2026-11-03 01:30:26", parent: "", port: "", conn: { ip: "192.168.15.189" } }
    ]
    readonly property var byMac: H.indexByMac(devs)

    function dev(mac) {
        return byMac[mac];
    }

    function keys(rows) {
        return rows.map(r => r.key);
    }

    function test_bestName() {
        compare(H.bestName(dev("d4:f5:47:97:7f:db")), "Nest Mini (Caixa do Quarto)");
        compare(H.bestName(dev("9a:93:b9:30:39:57")), "Redmi-Note-13-Pro-5G");
        compare(H.bestName(dev("34:7d:e4:25:fc:ff")), "SHENZHEN BILIAN");
        compare(H.bestName(dev("f2:8e:10:36:16:ed")), "f2:8e:10:36:16:ed");
        compare(H.shortName(dev("d8:77:8b:21:04:d0")), "AP auxiliar");
        compare(H.nickname(dev("9a:93:b9:30:39:57")), "");
    }

    function test_typeIcon() {
        compare(H.typeIcon("Phone"), "smartphone");
        compare(H.typeIcon("Singleboard Computer (SBC)"), "memory");
        compare(H.typeIcon(""), "help");
        compare(H.typeIcon("Weird"), "devices_other");
        compare(H.TYPES.length, 16);
        compare(H.typeLabel("Singleboard Computer (SBC)"), "SBC");
    }

    function test_fmtSpeed() {
        compare(H.fmtSpeed(1000), "1 Gb/s");
        compare(H.fmtSpeed(2500), "2.5 Gb/s");
        compare(H.fmtSpeed(100), "100 Mb/s");
        compare(H.fmtSpeed(6.5), "6.5 Mb/s");
        compare(H.fmtSpeed(null), "");
        compare(H.fmtSpeed(0), "");
    }

    function test_link() {
        compare(H.linkOf(dev("6c:1f:f7:a9:a8:8f"), byMac).medium, "cable");
        // Pendurado no switch sem conn: cabo (switch so tem cabo)
        compare(H.linkOf(dev("d8:77:8b:21:04:d0"), byMac).medium, "cable");
        // port "1" numerada: cabo
        compare(H.linkOf(dev("02:ca:e1:00:00:01"), byMac).medium, "cable");
        // port wifi sem faixa
        const lw = H.linkOf(dev("a0:29:42:70:51:5c"), byMac);
        compare(lw.medium, "wifi");
        compare(lw.band, "");
        // conn.via vence o parent vazio
        const lr = H.linkOf(dev("9a:93:b9:30:39:57"), byMac);
        compare(lr.up, "d8:77:8b:21:04:d0");
        compare(lr.band, "5G");
        // nada conhecido
        compare(H.linkOf(dev("38:6b:1c:3b:4b:f8"), byMac).medium, "unknown");
        compare(H.linkOf(dev("34:7d:e4:25:fc:ff"), byMac).up, "");
    }

    function test_chip() {
        compare(H.chip(dev("f2:8e:10:36:16:ed"), byMac).text, "Wi-Fi 5G · AP auxiliar · −49 dBm");
        compare(H.chip(dev("d4:f5:47:97:7f:db"), byMac).text, "Wi-Fi 5G · AP auxiliar · −59 dBm · 6.5 Mb/s");
        compare(H.chip(dev("6c:1f:f7:a9:a8:8f"), byMac).text, "Cable · 1 Gb/s");
        compare(H.chip(dev("d8:77:8b:21:04:d0"), byMac).text, "Cable");
        compare(H.chip(dev("34:7d:e4:25:fc:ff"), byMac).text, "Unknown");
        compare(H.chip(dev("9a:93:b9:30:39:57"), byMac).weak, true);
        compare(H.chip(dev("34:7d:e4:25:fc:ff"), byMac, { wifi: "W", cable: "C", unknown: "?" }).text, "?");
    }

    function test_source() {
        compare(H.sourceOf(dev("6c:1f:f7:a9:a8:8f")), "ethtool");
        compare(H.sourceOf(dev("9a:93:b9:30:39:57")), "survey");
        compare(H.sourceOf(dev("d8:77:8b:21:04:d0")), "map");
        compare(H.sourceOf(dev("34:7d:e4:25:fc:ff")), "");
    }

    function test_summary() {
        const s = H.summary(devs);
        compare(s.total, 14);
        compare(s.fresh, 3);
        compare(s.online, 11);
        compare(s.reads.router, "");
        compare(s.reads.survey, "2026-11-03T00:21:44");
        compare(s.reads.ethtool, "2026-11-03T00:22:26");
        compare(H.minutesSince("2026-11-03T02:30:00", now), 30);
        // NetAlertX (espaco) e UTC: 05:30Z = 02:30 em -03 so se o fuso for -03; compara pela diferenca
        compare(H.parseTime("2026-11-03 02:30:00"), Date.parse("2026-11-03T02:30:00Z"));
        compare(H.minutesSince("", now), null);
    }

    function test_unknown() {
        const u = H.unknownDevices(devs).map(d => d.mac);
        compare(u, ["9a:93:b9:30:39:57", "34:7d:e4:25:fc:ff", "f2:8e:10:36:16:ed"]);
    }

    function test_mapShape() {
        const rows = H.buildMap(devs, { showOffline: true });
        compare(rows[0].kind, "wan");
        compare(rows[1].key, "d:d8:c6:78:12:ac:88");
        const k = keys(rows);
        // Cabo do roteador: o switch; dentro dele, cabo com AP, NAS, VR
        verify(k.indexOf("l:d8:c6:78:12:ac:88:cable") < k.indexOf("d:02:ca:e1:00:00:01"));
        verify(k.indexOf("d:02:ca:e1:00:00:01") < k.indexOf("l:02:ca:e1:00:00:01:cable"));
        // Wi-Fi 5G do AP auxiliar com os dois desconhecidos e o Nest do quarto
        const wi = rows.find(r => r.key === "l:d8:77:8b:21:04:d0:wifi:5G");
        compare(wi.count, 3);
        // grupos do roteador na ordem: cabo, 5G, Wi-Fi sem faixa, sem meio, sem conexao
        const groups = rows.filter(r => r.kind === "link" && r.depth === 2).map(r => r.medium + ":" + r.band);
        compare(groups, ["cable:", "wifi:5G", "wifi:", "unknown:", "none:"]);
        compare(rows[rows.length - 1].dev.mac, "34:7d:e4:25:fc:ff");
        // notas: switch sem gerencia e roteador em NAT
        verify(rows.some(r => r.kind === "note" && r.note === "switch"));
        const nat = rows.find(r => r.kind === "note" && r.note === "nat");
        verify(!!nat);
        compare(rows[rows.indexOf(nat) - 1].dev.mac, "40:ed:00:5e:e2:81");
        // cabecalho de tipo so com 2+ do mesmo tipo
        verify(rows.some(r => r.kind === "type" && r.type === "IoT" && r.count === 2));
        verify(!rows.some(r => r.kind === "type" && r.type === "NAS"));
    }

    function test_mapRails() {
        const rows = H.buildMap(devs, { showOffline: true });
        const root = rows[1];
        compare(root.depth, 1);
        compare(root.rails, []);
        const last = rows.filter(r => r.kind === "link" && r.depth === 2);
        compare(last[last.length - 1].last, true);
        compare(last[0].last, false);
        // filho do grupo de cabo (nao e o ultimo grupo): coluna 1 continua
        const sw = rows.find(r => r.key === "d:02:ca:e1:00:00:01");
        compare(sw.depth, 3);
        compare(sw.rails, [false, true]);
    }

    function test_hideOffline() {
        const rows = H.buildMap(devs, { showOffline: false });
        const k = keys(rows);
        verify(k.indexOf("d:a0:29:42:70:51:5c") < 0);
        verify(k.indexOf("d:f2:8e:10:36:16:ed") < 0);
        // o switch (sem IP) fica, e o grupo Wi-Fi sem faixa some
        verify(k.indexOf("d:02:ca:e1:00:00:01") >= 0);
        verify(!rows.some(r => r.kind === "link" && r.medium === "wifi" && r.band === "" && r.depth === 2));
    }

    function test_noCycle() {
        const loop = [
            { mac: "aa:aa:aa:aa:aa:01", name: "R", type: "Router", parent: "internet", online: true },
            { mac: "aa:aa:aa:aa:aa:02", name: "A", type: "AP", parent: "aa:aa:aa:aa:aa:03", port: "1", online: true },
            { mac: "aa:aa:aa:aa:aa:03", name: "B", type: "AP", parent: "aa:aa:aa:aa:aa:02", port: "1", online: true }
        ];
        const rows = H.buildMap(loop, {});
        verify(rows.length >= 2);
    }

    function test_pending() {
        const ops = [{ verb: "name", mac: "9A:93:B9:30:39:57", value: "Phone of Bia" }, { verb: "type", mac: "9a:93:b9:30:39:57", value: "Phone" }, { verb: "known", mac: "9a:93:b9:30:39:57" }];
        const v = H.applyPending(devs, ops);
        const d = v.find(x => x.mac === "9a:93:b9:30:39:57");
        compare(d.name, "Phone of Bia");
        compare(d.type, "Phone");
        compare(d.new, false);
        compare(dev("9a:93:b9:30:39:57").new, true);
        compare(H.unknownDevices(v).length, 2);
    }

    function test_queue() {
        let q = H.enqueueOp([], { verb: "name", mac: "aa:bb:cc:dd:ee:ff", value: "x" });
        q = H.enqueueOp(q, { verb: "type", mac: "aa:bb:cc:dd:ee:ff", value: "TV" });
        q = H.enqueueOp(q, { verb: "type", mac: "aa:bb:cc:dd:ee:ff", value: "Phone" });
        compare(q.length, 2);
        compare(q[1].value, "Phone");
        q = H.enqueueOp(q, { verb: "name", mac: "aa:bb:cc:dd:ee:ff", value: "x" });
        compare(q.length, 2);
        compare(H.opArgs({ verb: "name", mac: "aa:bb:cc:dd:ee:ff", value: "Sala TV" }), ["network", "name", "AA:BB:CC:DD:EE:FF", "Sala TV", "--json"]);
        compare(H.opArgs({ verb: "known", mac: "aa:bb:cc:dd:ee:ff" }), ["network", "known", "AA:BB:CC:DD:EE:FF", "--json"]);
        verify(H.busyFor(q, "AA:BB:CC:DD:EE:FF"));
        verify(!H.busyFor(q, "11:22:33:44:55:66"));
        verify(H.isEditable(dev("02:ca:e1:00:00:01")));
        verify(!H.isEditable(dev("internet")));
    }
}
