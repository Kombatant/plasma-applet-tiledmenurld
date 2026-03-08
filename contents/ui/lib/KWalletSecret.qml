import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

Item {
	id: root
	visible: false

	readonly property string appId: "org.github.kombatant.tiled_rld"
	property string folderName: "org.github.kombatant.tiled_rld"
	property string entryName: "aiApiKey"

	property string secret: ""
	property string lastError: ""
	property string availabilityMessage: ""
	property bool loading: false
	property bool saving: false
	property bool loadedOnce: false
	property bool checkedAvailability: false
	property bool walletAvailable: false
	readonly property bool secureStorageAvailable: walletAvailable
	property string activeWallet: ""

	property var _pendingOps: ({})
	signal loaded(bool success)
	signal saved(bool success)
	signal cleared(bool success)

	// --- D-Bus constants ---
	readonly property string _svc: "org.kde.kwalletd6"
	readonly property string _path: "/modules/kwalletd6"
	readonly property string _iface: "org.kde.KWallet"

	function _shellQuote(value) {
		var s = value === null || typeof value === "undefined" ? "" : ("" + value)
		return "'" + s.replace(/'/g, "'\"'\"'") + "'"
	}

	function _trimOutput(value) {
		return ("" + (value || "")).replace(/\r?\n$/, "")
	}

	function _runScript(operation, script, callback) {
		var source = "sh -c " + _shellQuote(script)
		_pendingOps[source] = {
			op: operation,
			cb: callback,
		}
		exec.connectSource(source)
	}

	function _qdbus(method, args, callback) {
		var cmd = "qdbus " + _shellQuote(_svc) + " " + _shellQuote(_path) + " " + _shellQuote(_iface + "." + method)
		for (var i = 0; i < args.length; i++) {
			cmd += " " + _shellQuote("" + args[i])
		}
		_runScript("qdbus-" + method, cmd, callback)
	}

	// --- Availability ---

	function inspectAvailability(callback) {
		availabilityMessage = ""
		_runScript("check-qdbus", "command -v qdbus >/dev/null 2>&1", function(exitCode) {
			if (exitCode !== 0) {
				walletAvailable = false
				checkedAvailability = true
				availabilityMessage = i18n("Secure storage is unavailable because qdbus is not installed.")
				if (typeof callback === "function") {
					callback(false)
				}
				return
			}
			_qdbus("wallets", [], function(exitCode2, stdout) {
				if (exitCode2 !== 0 || !_trimOutput(stdout)) {
					walletAvailable = false
					checkedAvailability = true
					availabilityMessage = i18n("Secure storage is unavailable because no KWallet wallet was found. Create or enable a wallet in KDE Wallet settings.")
					if (typeof callback === "function") {
						callback(false)
					}
					return
				}
				var allWallets = _trimOutput(stdout).split(/\r?\n/).map(function(s) { return s.trim() }).filter(Boolean)
				if (!allWallets.length) {
					walletAvailable = false
					checkedAvailability = true
					availabilityMessage = i18n("Secure storage is unavailable because no KWallet wallet was found. Create or enable a wallet in KDE Wallet settings.")
					if (typeof callback === "function") {
						callback(false)
					}
					return
				}
				// Prefer the user's configured default local wallet
				_qdbus("localWallet", [], function(exitCode3, lwOut) {
					var localWallet = exitCode3 === 0 ? _trimOutput(lwOut) : ""
					if (localWallet && allWallets.indexOf(localWallet) >= 0) {
						activeWallet = localWallet
					} else {
						activeWallet = allWallets[0]
					}
					walletAvailable = true
					checkedAvailability = true
					availabilityMessage = ""
					if (typeof callback === "function") {
						callback(true)
					}
				})
			})
		})
	}

	// --- Open / Close helpers ---

	function _openWallet(walletName, callback) {
		_qdbus("open", [walletName, "0", appId], function(exitCode, stdout) {
			var handle = parseInt(_trimOutput(stdout), 10)
			if (exitCode !== 0 || isNaN(handle) || handle < 0) {
				callback(-1)
				return
			}
			callback(handle)
		})
	}

	function _closeWallet(handle) {
		if (handle >= 0) {
			_qdbus("close", [handle, "false", appId], function() {})
		}
	}

	// --- Read ---

	function _doRead(walletName, callback) {
		_openWallet(walletName, function(handle) {
			if (handle < 0) {
				callback(false, "")
				return
			}
			_qdbus("readPassword", [handle, folderName, entryName, appId], function(exitCode, stdout) {
				_closeWallet(handle)
				if (exitCode !== 0) {
					callback(false, "")
					return
				}
				callback(true, _trimOutput(stdout))
			})
		})
	}

	// --- Write ---

	function _doWrite(walletName, value, callback) {
		_openWallet(walletName, function(handle) {
			if (handle < 0) {
				callback(false)
				return
			}
			_qdbus("writePassword", [handle, folderName, entryName, value, appId], function(exitCode) {
				_closeWallet(handle)
				callback(exitCode === 0)
			})
		})
	}

	// --- Remove ---

	function _doRemove(walletName, callback) {
		_openWallet(walletName, function(handle) {
			if (handle < 0) {
				callback(false)
				return
			}
			_qdbus("removeEntry", [handle, folderName, entryName, appId], function(exitCode) {
				_closeWallet(handle)
				callback(exitCode === 0)
			})
		})
	}

	// --- Public API ---

	function readSecret() {
		loading = true
		lastError = ""
		inspectAvailability(function(available) {
			if (!available) {
				loading = false
				loadedOnce = true
				lastError = availabilityMessage
				loaded(false)
				return
			}
			_doRead(activeWallet, function(success, value) {
				loading = false
				loadedOnce = true
				if (success) {
					secret = value
					lastError = ""
				} else {
					secret = ""
					lastError = ""
				}
				loaded(true)
			})
		})
	}

	function saveSecret(value) {
		saving = true
		lastError = ""
		inspectAvailability(function(available) {
			if (!available) {
				saving = false
				lastError = availabilityMessage
				saved(false)
				return
			}
			_doWrite(activeWallet, "" + (value || ""), function(success) {
				saving = false
				if (success) {
					secret = "" + (value || "")
					lastError = ""
				} else {
					lastError = i18n("Could not write API key to KWallet.")
				}
				saved(success)
			})
		})
	}

	function clearSecret() {
		saving = true
		lastError = ""
		inspectAvailability(function(available) {
			if (!available) {
				saving = false
				lastError = availabilityMessage
				cleared(false)
				return
			}
			_doRemove(activeWallet, function(success) {
				saving = false
				if (success) {
					secret = ""
					lastError = ""
				} else {
					lastError = i18n("Could not remove API key from KWallet.")
				}
				cleared(success)
			})
		})
	}

	function migrateLegacy(legacyValue, callback) {
		var legacy = ("" + (legacyValue || "")).trim()
		if (!legacy) {
			if (typeof callback === "function") {
				callback(false)
			}
			return
		}
		if (secret && secret !== legacy) {
			if (typeof callback === "function") {
				callback(false)
			}
			return
		}
		saving = true
		lastError = ""
		inspectAvailability(function(available) {
			if (!available) {
				saving = false
				lastError = availabilityMessage
				if (typeof callback === "function") {
					callback(false)
				}
				return
			}
			_doWrite(activeWallet, legacy, function(success) {
				saving = false
				if (success) {
					secret = legacy
					lastError = ""
				}
				if (typeof callback === "function") {
					callback(success)
				}
			})
		})
	}

	Plasma5Support.DataSource {
		id: exec
		engine: "executable"
		connectedSources: []
		onNewData: function(sourceName, data) {
			disconnectSource(sourceName)
			var pending = root._pendingOps[sourceName]
			delete root._pendingOps[sourceName]
			if (!pending || typeof pending.cb !== "function") {
				return
			}
			var exitCode = data && typeof data["exit code"] !== "undefined" ? data["exit code"] : 0
			var stdout = data && typeof data.stdout !== "undefined" ? ("" + data.stdout) : ""
			var stderr = data && typeof data.stderr !== "undefined" ? ("" + data.stderr) : ""
			if (exitCode !== 0 && stderr) {
				lastError = stderr.trim()
			}
			pending.cb(exitCode, stdout, stderr)
		}
	}
}