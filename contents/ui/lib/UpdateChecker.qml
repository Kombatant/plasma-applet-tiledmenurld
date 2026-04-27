import QtQuick
import "Requests.js" as Requests

QtObject {
	id: updateChecker

	property string remoteUrl: "https://raw.githubusercontent.com/Kombatant/plasma-applet-tiledmenurld/master/metadata.json"

	property string localVersion: ""
	property string latestVersion: ""
	property bool updateAvailable: false
	property bool checked: false
	property bool checking: false
	property bool failed: false

	function _cmp(a, b) {
		var pa = ("" + (a || "0")).split(".").map(function(x) { return parseInt(x, 10) || 0 })
		var pb = ("" + (b || "0")).split(".").map(function(x) { return parseInt(x, 10) || 0 })
		var n = Math.max(pa.length, pb.length)
		for (var i = 0; i < n; i++) {
			var d = (pa[i] || 0) - (pb[i] || 0)
			if (d !== 0) return d
		}
		return 0
	}

	function check(force) {
		if (checking) return
		if (checked && !force) return
		if (!localVersion) return
		checking = true
		failed = false
		Requests.getJSON({ url: remoteUrl }, function(err, data) {
			checking = false
			checked = true
			if (err || !data || !data.KPlugin || !data.KPlugin.Version) {
				failed = true
				updateAvailable = false
				console.warn("UpdateChecker: failed to fetch remote metadata:", err)
				return
			}
			latestVersion = "" + data.KPlugin.Version
			updateAvailable = _cmp(latestVersion, localVersion) > 0
		})
	}

	Component.onCompleted: check(false)
}
