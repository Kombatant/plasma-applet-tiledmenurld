.pragma library

function _propName(configKey) {
	return configKey ? "cfg_" + configKey : ""
}

function getRootKcm(item) {
	// Check the item itself first — in Plasma's native config model,
	// the page root has configurationChanged injected directly on it.
	if (item && typeof item.configurationChanged === "function") {
		return item
	}
	var root = item
	while (root && root.parent) {
		root = root.parent
		if (root && typeof root.configurationChanged === "function") {
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
	if (rootKcm) {
		rootKcm.configurationChanged()
	}
}

function setPendingValue(item, configKey, value, markDirty) {
	var rootKcm = getRootKcm(item)
	var propName = _propName(configKey)
	if (!rootKcm || !propName || typeof rootKcm[propName] === "undefined") {
		if (configKey && !valuesEqual(plasmoid.configuration[configKey], value)) {
			plasmoid.configuration[configKey] = cloneValue(value)
		}
		return
	}

	var nextValue = cloneValue(value)
	if (valuesEqual(rootKcm[propName], nextValue)) {
		return
	}

	rootKcm[propName] = nextValue
	if (markDirty !== false) {
		markConfigurationChanged(item)
	}
}
