.pragma library

function _propName(configKey) {
	return configKey ? "cfg_" + configKey : ""
}

function _looksLikeKcm(obj) {
	if (!obj) return false
	// Plasma's config dialog injects cfg_* properties + a configurationChanged
	// signal onto the page root. `typeof signal` is "function" in modern Qt,
	// but historically it reports "object" — accept either. Fall back to
	// detecting any cfg_ property as evidence we are at the page root.
	var t = typeof obj.configurationChanged
	if (t === "function" || t === "object") {
		return true
	}
	for (var k in obj) {
		if (k.indexOf("cfg_") === 0) {
			return true
		}
	}
	return false
}

function getRootKcm(item) {
	if (_looksLikeKcm(item)) {
		return item
	}
	var root = item
	while (root && root.parent) {
		root = root.parent
		if (_looksLikeKcm(root)) {
			return root
		}
	}
	return null
}

function cloneValue(value) {
	if (Array.isArray(value)) {
		return value.slice()
	}
	if (value && typeof value === "object") {
		try {
			return JSON.parse(JSON.stringify(value))
		} catch (e) {
			return value
		}
	}
	return value
}

function hasPendingValue(item, configKey) {
	var rootKcm = getRootKcm(item)
	var propName = _propName(configKey)
	return !!(rootKcm && propName && typeof rootKcm[propName] !== "undefined")
}

function pendingValue(item, configKey, fallbackValue) {
	var rootKcm = getRootKcm(item)
	var propName = _propName(configKey)
	if (rootKcm && propName && typeof rootKcm[propName] !== "undefined") {
		return rootKcm[propName]
	}
	return fallbackValue
}

function valuesEqual(a, b) {
	if (a === b) {
		return true
	}
	if (Array.isArray(a) || Array.isArray(b)) {
		return JSON.stringify(a || []) === JSON.stringify(b || [])
	}
	if (a && typeof a === "object" && b && typeof b === "object") {
		return JSON.stringify(a) === JSON.stringify(b)
	}
	return false
}

function markConfigurationChanged(item) {
	var rootKcm = getRootKcm(item)
	if (!rootKcm) {
		return
	}
	// In Plasma's config dialog, writing a cfg_* property already marks the
	// page dirty. Some configurationChanged bindings are signals (callable),
	// others are injected as plain properties — only invoke when callable.
	if (typeof rootKcm.configurationChanged === "function") {
		rootKcm.configurationChanged()
	}
}

// Subscribe `handler` to both the KCM's cfg_<key>Changed signal and the
// plasmoid configuration's <key>Changed signal. Returns a teardown function
// the caller can invoke to disconnect. Using explicit signal connections
// avoids Qt's "non-bindable property" warnings triggered when QML expressions
// read plasmoid.configuration[configKey] via dynamic subscript.
function connectConfigChange(item, configKey, handler) {
	if (!configKey || !handler) {
		return function () {}
	}
	var disconnects = []

	var rootKcm = getRootKcm(item)
	if (rootKcm) {
		var cfgSigName = "cfg_" + configKey + "Changed"
		var cfgSignal = rootKcm[cfgSigName]
		if (cfgSignal && typeof cfgSignal.connect === "function") {
			cfgSignal.connect(handler)
			disconnects.push(function () {
				try { cfgSignal.disconnect(handler) } catch (e) {}
			})
		}
	}

	var cfg = (typeof plasmoid !== "undefined" && plasmoid) ? plasmoid.configuration : null
	if (cfg) {
		var plasSigName = configKey + "Changed"
		var plasSignal = cfg[plasSigName]
		if (plasSignal && typeof plasSignal.connect === "function") {
			plasSignal.connect(handler)
			disconnects.push(function () {
				try { plasSignal.disconnect(handler) } catch (e) {}
			})
		}
	}

	return function () {
		for (var i = 0; i < disconnects.length; i++) {
			disconnects[i]()
		}
	}
}

function setPendingValue(item, configKey, value, markDirty) {
	var rootKcm = getRootKcm(item)
	var propName = _propName(configKey)
	var nextValue = cloneValue(value)
	if (!rootKcm || !propName || typeof rootKcm[propName] === "undefined") {
		var cfg = (typeof plasmoid !== "undefined" && plasmoid) ? plasmoid.configuration : null
		if (cfg && configKey && typeof cfg[configKey] !== "undefined") {
			if (!valuesEqual(cfg[configKey], nextValue)) {
				cfg[configKey] = nextValue
			}
			return
		}
		console.warn("[ConfigUtils] cfg_" + configKey + " not available on KCM root; skip write")
		return
	}

	if (valuesEqual(rootKcm[propName], nextValue)) {
		return
	}

	rootKcm[propName] = nextValue
	if (markDirty !== false) {
		markConfigurationChanged(item)
	}
}
