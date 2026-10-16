.pragma library

// Pure helpers for tile tab descriptors:
// {id, name, icon, kind?: "mostUsed", tiles}. A missing kind means a manual
// tab. The automatic "mostUsed" tab is identified by kind, never by name;
// only one may exist and it is always stored with tiles: [].

function normalizeKind(kind) {
	return kind === "mostUsed" ? "mostUsed" : "manual"
}

function isMostUsed(tab) {
	return !!tab && tab.kind === "mostUsed"
}

// Shallow copy of a descriptor with overrides, so fields this code doesn't
// know about (kind, future additions) survive rename/icon edits.
function copyTab(tab, overrides) {
	var out = {}
	var keys = Object.keys(tab || {})
	for (var i = 0; i < keys.length; i++) {
		out[keys[i]] = tab[keys[i]]
	}
	var overrideKeys = Object.keys(overrides || {})
	for (var j = 0; j < overrideKeys.length; j++) {
		out[overrideKeys[j]] = overrides[overrideKeys[j]]
	}
	return out
}

// Sanitize tabs loaded from config: drop unknown kinds, keep only the first
// automatic tab (and strip any tiles stored on it), and give empty or
// duplicate ids a fresh "tab_N". idCounter is raised past the highest saved
// tab_N so new tabs never reuse an existing id.
// Mutates the descriptors; returns {tabs, changed, idCounter}.
function sanitizeTabs(tabs, idCounter) {
	var changed = false
	var counter = Math.max(0, idCounter || 0)
	var list = tabs || []
	for (var i = 0; i < list.length; i++) {
		var match = /^tab_(\d+)$/.exec("" + (list[i] && list[i].id || ""))
		if (match) {
			counter = Math.max(counter, parseInt(match[1], 10))
		}
	}
	var out = []
	var seenIds = {}
	var hasMostUsed = false
	for (var j = 0; j < list.length; j++) {
		var tab = list[j]
		if (!tab || typeof tab !== "object") {
			changed = true
			continue
		}
		if (typeof tab.kind !== "undefined" && tab.kind !== "mostUsed") {
			delete tab.kind
			changed = true
		}
		if (isMostUsed(tab)) {
			if (hasMostUsed) {
				changed = true
				continue
			}
			hasMostUsed = true
			if (tab.tiles && tab.tiles.length) {
				changed = true
			}
			tab.tiles = []
		}
		var id = (typeof tab.id === "undefined" || tab.id === null) ? "" : ("" + tab.id)
		if (!id || seenIds[id]) {
			counter++
			tab.id = "tab_" + counter
			changed = true
		}
		seenIds[tab.id] = true
		out.push(tab)
	}
	return { tabs: out, changed: changed, idCounter: counter }
}

// Normalize descriptors for import/export: string fields, kind only for the
// automatic tab (first one wins), no persisted tiles on it.
function normalizeForExport(tabs) {
	var out = []
	var hasMostUsed = false
	var list = tabs || []
	for (var i = 0; i < list.length; i++) {
		var tab = list[i]
		if (!tab || typeof tab !== "object") {
			continue
		}
		var kind = normalizeKind(tab.kind)
		if (kind === "mostUsed") {
			if (hasMostUsed) {
				continue
			}
			hasMostUsed = true
		}
		var normalized = {
			id: (typeof tab.id === "undefined" || tab.id === null) ? "" : ("" + tab.id),
			name: (typeof tab.name === "undefined" || tab.name === null) ? "" : ("" + tab.name),
			icon: (typeof tab.icon === "undefined" || tab.icon === null) ? "" : ("" + tab.icon),
			tiles: (kind === "manual" && Array.isArray(tab.tiles)) ? tab.tiles : [],
		}
		if (kind !== "manual") {
			normalized.kind = kind
		}
		out.push(normalized)
	}
	return out
}
