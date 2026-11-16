'use strict';
'require view';
'require rpc';
'require uci';
'require fs';

var callInfo = rpc.declare({ object: 'system', method: 'info' });
var callBoard = rpc.declare({ object: 'system', method: 'board' });
var callServices = rpc.declare({ object: 'service', method: 'list', params: { verbose: true } });
var wifiStatus = function() {
	return fetch('/cgi-bin/wifi-status', { cache: 'no-store' })
		.then(function(r) { return r.json(); }).catch(function() { return {}; });
};

var CSS = ''
+ '.rt{max-width:1080px;margin:0 auto;font:14px/1.55 system-ui,sans-serif;color:var(--text-color,#e6edf3)}'
+ '.rt h1{font-size:22px;margin:0 0 4px}.rt .sub{color:#8b98a9;font-size:13px;margin-bottom:16px}'
+ '.rt .chips span{display:inline-block;margin:0 8px 6px 0;padding:2px 9px;border:1px solid #2d3a55;border-radius:99px;font-size:12px;color:#9fc4ff}'
+ '.rt .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:12px;margin:14px 0}'
+ '.rt .c{background:#171b24;border:1px solid #242a38;border-radius:12px;padding:12px 14px}'
+ '.rt .c h3{margin:0 0 6px;font-size:14px;color:#dfe6ef}.rt .c p{margin:0;color:#9aa4b2;font-size:13px}'
+ '.rt .ok{color:#3fb950}.rt .off{color:#d29922}.rt code{background:#0f131a;border:1px solid #242a38;border-radius:5px;padding:1px 5px;font-size:12px}'
+ '.rt a{color:#58a6ff;text-decoration:none}.rt a:hover{text-decoration:underline}'
+ '.rt .qr{background:#fff;padding:8px;border-radius:8px;display:inline-block}.rt .qr svg{display:block;width:150px;height:150px}'
+ '.rt .f{margin-top:18px;padding-top:10px;border-top:1px solid #242a38;color:#8b98a9;font-size:12px}';

function esc(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function(c) {
	return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]; }); }

function svc(list, name) {
	return (list && list[name]) || null;
}

function svcRunning(v) {
	var inst = (v && v.instances) || {};
	return Object.keys(inst).some(function(k) { return inst[k] && inst[k].running; });
}

function wifiUp(wifi, radio) {
	var r = (wifi && wifi[radio]) || null;
	if (!r || r.up === false) return false;
	return !!(r.interfaces && r.interfaces.length);
}

function dur(sec) {
	var d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60);
	return (d ? d + 'd ' : '') + h + 'h ' + m + 'm';
}

return view.extend({
	load: function() {
		return Promise.all([
			L.resolveDefault(callInfo(), {}),
			L.resolveDefault(callBoard(), {}),
			L.resolveDefault(callServices(), {}),
			L.resolveDefault(wifiStatus(), {}),
			uci.load('wireless').catch(function() {})
		]);
	},

	render: function(data) {
		var info = data[0] || {}, board = data[1] || {}, services = data[2] || {};
		var wifi = data[3] || {};
		var radios = [], i;

		for (i = 0; ; i++) {
			var r = uci.get('wireless', 'radio' + i, 'disabled');
			if (r == null) break;
			var ssid = uci.get('wireless', 'default_radio' + i, 'ssid') || '';
			var key = uci.get('wireless', 'default_radio' + i, 'key') || '';
			radios.push({ name: 'radio' + i, off: (r == '1'), ssid: ssid, key: key,
				band: (uci.get('wireless', 'radio' + i, 'band') || '') });
		}

		var radioOn = radios.some(function(x) { return wifiUp(wifi, x.name); });
		var mem = info.memory || {};
		var l1 = Number(info.load && info.load[0] || 0) / 65536;
		var l2 = Number(info.load && info.load[1] || 0) / 65536;
		var l3 = Number(info.load && info.load[2] || 0) / 65536;
		var ramUsed = Math.round((Number(mem.total || 0) - Number(mem.free || 0)) / 1048576);
		var ramTotal = Math.round(Number(mem.total || 0) / 1048576);
		var html = [];

		html.push('<h1>' + esc(board.model || 'OpenWrt router') + ' · OpenWrt homelab</h1>');
		html.push('<div class="sub">' + esc(board.model || 'OpenWrt router') + ' — ' +
			esc((board.release && board.release.description) || 'OpenWrt') + '</div>');
		html.push('<div class="chips"><span>uptime ' + dur(info.uptime || 0) + '</span>' +
			'<span>load ' + l1.toFixed(2) + ' / ' + l2.toFixed(2) + ' / ' + l3.toFixed(2) + '</span>' +
			'<span>RAM ' + ramUsed + ' / ' + ramTotal + ' MB</span>' +
			'<span>radios ' + (radioOn ? 'ON' : 'OFF') + '</span></div>');

		/* radios */
		html.push('<div class="grid">');
		html.push('<div class="c"><h3>Radios</h3>');
		if (!radios.length)
			html.push('<p>No wireless configuration yet; <code>wifi config</code> writes one.</p>');
		radios.forEach(function(x) {
			var up = wifiUp(wifi, x.name);
			html.push('<p>' + esc(x.name) + ' (' + esc(x.band || '?') + '): <b class="' +
				(up ? 'ok' : 'off') + '">' + (up ? 'on' : 'off') + '</b>' +
				(up && x.ssid ? ' — ' + esc(x.ssid) : '') + '</p>');
		});
		html.push('<p style="margin-top:6px">On demand: <code>wifi-radio on</code> / <code>off</code> / <code>status</code></p>');
		html.push('<div id="rt-qr" style="margin-top:10px"></div>');
		html.push('</div>');

		var boardName = (board.board_name || '');
		if (boardName.indexOf('r7000') >= 0) {
			html.push('<div class="c"><h3>Hardware</h3>' +
				'<p>BCM4709A0 + 2× BCM4360 (d11 rev 42, AC-PHY rev 1, <code>b43-next</code>).</p>' +
				'<p>PCIe: <code>0000:01.0</code> 2.4G @0x08000000, <code>0001:01.0</code> 5G @0x40000000</p>' +
				'<p>No VFP on this A9 (CPU part 0xc09): ARM binaries must be soft-float.</p></div>');
			html.push('<div class="c"><h3>Internal storage</h3>' +
				'<p>122 MB UBI replaces the vendor area — one <code>rootfs_data</code> overlay of ~87 MB.</p>' +
				'<p>AdGuard Home and Tailscale live in <code>/opt</code> on that overlay; no separate volume needed.</p></div>');
			html.push('<div class="c"><h3>Recovery &amp; updates</h3>' +
				'<p>CFE <code>boot_wait=on</code>; back up <code>mtd0</code> (CFE) and <code>mtd1</code> (nvram) before your first flash. Serial 115200 8N1 + TFTP initramfs recovers a bad flash.</p>' +
				'<p>Updates: <code>sysupgrade -n image.chk</code>; from stock, the web updater needs <code>Expect:</code> stripped.</p></div>');
		} else {
			html.push('<div class="c"><h3>Hardware</h3>' +
				'<p>BCM47094 + 2× BCM4360 (d11 rev 42, AC-PHY rev 1, radio 0x2069 rev 4).</p>' +
				'<p>femctrl <b>6</b> on both radios · PHY traffic captured, <a href="https://github.com/aleferri/b43-ac-wip/issues/50" target="_blank" rel="noopener">issue #50</a></p>' +
				'<p>PCIe: <code>0001:01.0</code> 2.4G @0x08000000, <code>0002:01.0</code> 5G @0x20000000</p></div>');
			html.push('<div class="c"><h3>Recovery &amp; updates</h3>' +
				'<p><b>Recovery mode</b>: power off, hold <b>reset</b>, power on, release when the power LED blinks slowly, then open <code>http://192.168.1.1/</code> and upload the <code>.trx</code> — or use ASUS <b>Firmware Restoration</b> with the same file.</p>' +
				'<p><b>Clear NVRAM</b>: power off, hold <b>WPS</b>, power on, keep held ~10 s.</p>' +
				'<p><b>Updates</b>: this board has no sysupgrade image; every update is a <code>.trx</code> written from recovery.</p></div>');
		}

		html.push('<div class="c"><h3>Quick start</h3>' +
			'<p><b>1. Secure it</b> — <code>passwd</code> (ships <code>changeme</code>).<br>' +
			'<b>2. Radios</b> — off by default; <code>wifi-radio on</code> when you want Wi-Fi.<br>' +
			'<b>3. DNS</b> — dnsmasq on <code>:53</code>; installing AdGuard Home takes over DNS (<code>:53</code>, UI <code>:3000</code>) — set <code>dhcp.@dnsmasq[0].port=0</code> so dnsmasq releases :53; config <code>/opt/adguard/AdGuardHome.yaml</code>.<br>' +
			'<b>4. Disks</b> — plug a USB disk, then <i>Network Shares</i> (ksmbd) or aria2.</p></div>');
		html.push('</div>');

		/* services */
		var names = (boardName.indexOf('r7000') >= 0)
			? [['adguard-hl','AdGuard Home'],['tailscale-hl','Tailscale'],['ksmbd','ksmbd (SMB3)'],
			   ['aria2','aria2'],['nlbwmon','nlbwmon'],['vnstat','vnstat'],['banip','banip'],
			   ['ttyd','ttyd'],['sqm','SQM'],['wifi_schedule','Wi-Fi schedule'],
			   ['watchcat','watchcat'],['wol','Wake-on-LAN']]
			: [['adguardhome','AdGuard Home'],['tailscale','Tailscale'],['sqm','SQM'],
			   ['ksmbd','ksmbd (SMB3)'],['aria2','aria2'],['nlbwmon','nlbwmon'],['vnstat','vnstat'],
			   ['banip','banip'],['mwan3','mwan3'],['ser2net','ser2net'],['p910nd','p910nd'],
			   ['usbip','usbip'],['ttyd','ttyd'],['udpxy','udpxy'],['wifi_schedule','Wi-Fi schedule'],
			   ['watchcat','watchcat'],['smartdns','smartdns'],['mosquitto','mosquitto'],
			   ['nut-server','NUT (UPS)'],['adguard-hl','AdGuard Home (opt)'],
			   ['tailscale-hl','Tailscale (opt)']];
		html.push('<h3 style="font-size:15px;margin:18px 0 4px">Services</h3>' +
			'<div class="sub" style="margin:0 0 8px">opt-in services stay off until installed; state is live from procd</div><div class="grid">');
		names.forEach(function(n) {
			var s = svc(services, n[0]);
			var running = svcRunning(s);
			var state = !s ? 'off (no instance)' : (running ? 'running' : (s.enabled ? 'enabled, stopped' : 'off'));
			var cls = !s ? 'off' : (running ? 'ok' : 'off');
			html.push('<div class="c"><h3>' + n[1] + '</h3><p class="' + cls + '">' + state + '</p></div>');
		});
		html.push('</div>');

		var repo = (board.board_name || '').indexOf('r7000') >= 0
			? ['https://github.com/ImAthanasia/netgear-r7000-modern-openwrt', 'netgear-r7000-modern-openwrt']
			: ['https://github.com/ImAthanasia/rt-ac68u-v3-openwrt', 'rt-ac68u-v3-openwrt'];
		html.push('<p class="f">Project and packaging by <b>ImAthanasia</b> · repo <a href="' + repo[0] + '" target="_blank" rel="noopener">' + repo[1] + '</a> ' +
			'· radios are off unless you start them · built-in page served by LuCI (login required)</p>');

		var node = E('div', { 'class': 'rt' }, [
			E('style', {}, CSS),
			E('div', { 'id': 'rt-body' })
		]);
		node.querySelector('#rt-body').innerHTML = html.join('');

		/* Wi-Fi QR, only when a radio is on and qrencode exists */
		var on = radios.filter(function(x) { return wifiUp(wifi, x.name) && x.ssid; })[0];
		if (on) {
			var payload = 'WIFI:T:WPA;S:' + on.ssid + ';P:' + (on.key || '') + ';;';
			fs.exec('/usr/bin/qrencode', [ '-t', 'SVG', '-o', '-', '-l', 'M', payload ])
				.then(function(res) {
					var box = node.querySelector('#rt-qr');
					if (box && res && res.stdout)
						box.innerHTML = '<span class="qr">' + res.stdout + '</span>' +
							'<div class="sub" style="margin:6px 0 0">scan to join ' + esc(on.ssid) + '</div>';
				})
				.catch(function() { /* qrencode or ACL unavailable: stay quiet */ });
		}

		return node;
	},

	handleSaveApply: null, handleSave: null, handleReset: null
});
