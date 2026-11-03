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

    // ------------------------------------------------------------ grupos (03/11)
    readonly property var phone: ({ mac: "f2:8e:10:36:16:ed", name: "OP's Phone", ip: "192.168.15.187", type: "Phone", new: false, online: true, hostname: "OP-s-Phone", last_seen: "2026-11-03 13:15:48", conn: { kind: "wifi", band: "5G", via: "d8:77:8b:21:04:d0", ssid: "Cafofo 115 - 5G AUX" }, active_mac: "f2:8e:10:36:16:ed", macs: [
            { mac: "f2:8e:10:36:16:ed", ip: "192.168.15.187", online: true, last_seen: "2026-11-03 13:15:48", hostname: "OP-s-Phone", ssid: "Cafofo 115 - 5G AUX", band: "5G", kind: "wifi" },
            { mac: "3a:a1:f1:b4:7c:9f", ip: "192.168.15.136", online: false, last_seen: "2026-11-03 12:50:26", hostname: null, ssid: null, band: null, kind: null },
            { mac: "4e:5d:25:f3:a9:70", ip: "", online: false, last_seen: "2026-11-03 13:18:31", hostname: null, ssid: null, band: null, kind: null }
        ] })
    readonly property var stranger: ({ mac: "aa:11:22:33:44:55", name: "(name not found)", hostname: "OP-s-Phone", ip: "192.168.15.200", type: "", new: true, online: true, first_seen: "2026-11-03 13:00:00", suggest: { mac: "f2:8e:10:36:16:ed", name: "OP's Phone" } })
    readonly property var gdevs: devs.filter(d => d.mac !== "f2:8e:10:36:16:ed").concat([phone, stranger])

    function test_groupOneRow() {
        const s = H.summary(gdevs);
        compare(s.total, 15);
        const rows = H.buildMap(gdevs, { showOffline: true });
        compare(rows.filter(r => r.kind === "device" && r.dev.mac === "f2:8e:10:36:16:ed").length, 1);
        verify(!rows.some(r => r.kind === "device" && r.dev.mac === "3a:a1:f1:b4:7c:9f"));
        // um endereco extra no indice aponta para o aparelho, sem trocar linhas proprias
        const idx = H.indexByMac(gdevs);
        compare(idx["3a:a1:f1:b4:7c:9f"].mac, "f2:8e:10:36:16:ed");
        compare(idx["d8:77:8b:21:04:d0"].type, "AP");
        // pendurado num endereco extra: vai para o principal
        const child = { mac: "bb:00:00:00:00:01", name: "Tethered", online: true, parent: "3a:a1:f1:b4:7c:9f", port: "wifi" };
        const r2 = H.buildMap(gdevs.concat([child]), {});
        const at = r2.findIndex(r => r.key === "d:f2:8e:10:36:16:ed");
        verify(r2.findIndex(r => r.key === "d:bb:00:00:00:00:01") > at);
        verify(r2.some(r => r.key === "l:f2:8e:10:36:16:ed:wifi:"));
    }

    function test_groupAddrs() {
        compare(H.groupAddrs(phone).length, 3);
        compare(H.groupAddrs(dev("6c:1f:f7:a9:a8:8f")), []);
        compare(H.addrsOf(dev("d4:f5:47:97:7f:db"))[0].band, "5G");
        verify(H.isActive(phone, "F2:8E:10:36:16:ED"));
        verify(!H.isActive(phone, "3a:a1:f1:b4:7c:9f"));
        verify(H.isPrimary(phone, "f2:8e:10:36:16:ed"));
        compare(H.addrNetwork(phone.macs[0]), "Cafofo 115 - 5G AUX · 5G");
        compare(H.addrNetwork(phone.macs[1]), "");
        compare(H.addrNetwork({ kind: "wifi", band: "2.4G" }), "Wi-Fi 2.4G");
        compare(H.addrNetwork({ kind: "ethernet" }, { wifi: "W", cable: "C" }), "C");
    }

    function test_suggest() {
        const idx = H.indexByMac(gdevs);
        const s = H.suggestionFor(stranger, idx);
        compare(s.mac, "f2:8e:10:36:16:ed");
        compare(s.name, "OP's Phone");
        // conhecido: sem sugestao (nunca aplicada sozinha)
        compare(H.suggestionFor(Object.assign({}, stranger, { new: false }), idx), null);
        compare(H.suggestionFor(phone, idx), null);
        compare(H.unknownDevices(gdevs).some(d => d.mac === stranger.mac), true);
    }

    function test_candidates() {
        const c = H.groupCandidates(gdevs, stranger);
        compare(c[0].dev.mac, "f2:8e:10:36:16:ed");
        compare(c[0].sameHost, true);
        compare(c[1].sameHost, false);
        verify(c[1].dev.new);
        verify(!c.some(x => x.dev.mac === "internet" || x.dev.mac === stranger.mac || x.dev.mac === "02:ca:e1:00:00:01"));
        // do lado do grupo: o desconhecido de mesmo hostname primeiro
        compare(H.groupCandidates(gdevs, phone)[0].dev.mac, stranger.mac);
    }

    function test_groupOp() {
        // novo com conhecido: o conhecido fica de principal
        const op = H.groupOp(stranger, phone);
        compare(op.mac, "f2:8e:10:36:16:ed");
        compare(op.value, ["aa:11:22:33:44:55"]);
        compare(H.groupOp(phone, stranger).mac, "f2:8e:10:36:16:ed");
        // principal de outro grupo leva o grupo inteiro
        const op2 = H.groupOp(dev("6c:1f:f7:a9:a8:8f"), phone);
        compare(op2.value, ["f2:8e:10:36:16:ed", "3a:a1:f1:b4:7c:9f", "4e:5d:25:f3:a9:70"]);
        compare(H.opArgs(op), ["network", "group", "F2:8E:10:36:16:ED", "AA:11:22:33:44:55", "--json"]);
        compare(H.opArgs({ verb: "ungroup", mac: "3a:a1:f1:b4:7c:9f" }), ["network", "ungroup", "3A:A1:F1:B4:7C:9F", "--json"]);
        compare(H.opArgs({ verb: "delete", mac: "3a:a1:f1:b4:7c:9f" }), ["network", "delete", "3A:A1:F1:B4:7C:9F", "--json"]);
    }

    function test_pendingGroup() {
        const v = H.applyPending(gdevs, [H.groupOp(stranger, phone)]);
        verify(!v.some(d => d.mac === stranger.mac));
        const p = v.find(d => d.mac === phone.mac);
        compare(p.macs.length, 4);
        compare(p.macs[3].mac, stranger.mac);
        compare(H.unknownDevices(v).some(d => d.mac === stranger.mac), false);
        compare(H.summary(v).total, 14);
        // a entrada nao muda
        compare(phone.macs.length, 3);
        verify(gdevs.some(d => d.mac === stranger.mac));
        // um aparelho comum vira grupo
        const v2 = H.applyPending(gdevs, [{ verb: "group", mac: "6c:1f:f7:a9:a8:8f", value: ["aa:11:22:33:44:55"] }]);
        compare(v2.find(d => d.mac === "6c:1f:f7:a9:a8:8f").macs.map(a => a.mac), ["6c:1f:f7:a9:a8:8f", "aa:11:22:33:44:55"]);
        // endereco tirado de outro grupo
        const v3 = H.applyPending(gdevs, [{ verb: "group", mac: "6c:1f:f7:a9:a8:8f", value: ["3a:a1:f1:b4:7c:9f"] }]);
        compare(v3.find(d => d.mac === phone.mac).macs.length, 2);
        compare(v3.find(d => d.mac === "6c:1f:f7:a9:a8:8f").macs[1].ip, "192.168.15.136");
    }

    function test_pendingUngroupDelete() {
        const v = H.applyPending(gdevs, [{ verb: "ungroup", mac: "3A:A1:F1:B4:7C:9F" }]);
        compare(v.find(d => d.mac === phone.mac).macs.length, 2);
        const v2 = H.applyPending(v, [{ verb: "ungroup", mac: "4e:5d:25:f3:a9:70" }]);
        compare(v2.find(d => d.mac === phone.mac).macs, undefined);
        compare(phone.macs.length, 3);
        const v3 = H.applyPending(gdevs, [{ verb: "delete", mac: "a0:29:42:70:51:5c" }]);
        compare(v3.length, gdevs.length - 1);
        const v4 = H.applyPending(gdevs, [{ verb: "delete", mac: "4e:5d:25:f3:a9:70" }]);
        compare(v4.find(d => d.mac === phone.mac).macs.length, 2);
    }

    function test_queueGroup() {
        let q = H.enqueueOp([], { verb: "name", mac: "aa:bb:cc:dd:ee:ff", value: "x" });
        q = H.enqueueOp(q, { verb: "group", mac: "aa:bb:cc:dd:ee:ff", value: ["11:22:33:44:55:66"] });
        q = H.enqueueOp(q, { verb: "group", mac: "aa:bb:cc:dd:ee:ff", value: ["22:22:33:44:55:66"] });
        compare(q.length, 3);
        q = H.enqueueOp(q, { verb: "group", mac: "aa:bb:cc:dd:ee:ff", value: ["22:22:33:44:55:66"] });
        compare(q.length, 3);
        verify(H.busyFor(q, "11:22:33:44:55:66"));
        verify(H.busyForDev([{ verb: "ungroup", mac: "3a:a1:f1:b4:7c:9f" }], phone));
        verify(!H.busyForDev([{ verb: "ungroup", mac: "3a:a1:f1:b4:7c:9f" }], stranger));
    }
}
