.pragma library

// Pure helpers for the automatic "Popular" tab. Kept free of
// Kicker/QML dependencies so tests/tst_most_used.qml can exercise them.

var TILE_SIZE = 2

// Pick up to `limit` launchers from KDE's popularity ranking.
// rankedIds: favoriteIds in popularity order (may contain duplicates/blanks).
// options.normalize(id) -> canonical id or "" to drop it.
// options.isInstalled(id) -> false drops launchers that are hidden/removed.
// options.categoryOf(id) -> category label, "" when the app has none.
// options.exclude: ids to skip without counting them against the limit.
// Returns [{favoriteId, category}] in ranking order.
function selectEntries(rankedIds, options) {
	options = options || {}
	var limit = Math.max(0, Math.floor(options.limit || 0))
	var normalize = options.normalize || function(id) { return id ? ("" + id) : "" }
	var isInstalled = options.isInstalled || function() { return true }
	var categoryOf = options.categoryOf || function() { return "" }
	var excluded = {}
	var exclude = options.exclude || []
	for (var e = 0; e < exclude.length; e++) {
		excluded[exclude[e]] = true
	}
	var out = []
	var seen = {}
	var list = rankedIds || []
	for (var i = 0; i < list.length && out.length < limit; i++) {
		var id = normalize(list[i])
		if (!id || seen[id] || excluded[id]) {
			continue
		}
		seen[id] = true
		if (!isInstalled(id)) {
			continue
		}
		out.push({ favoriteId: id, category: categoryOf(id) || "" })
	}
	return out
}

// Group entries by category. Groups are ordered by their best-ranked app;
// apps without a category go to a trailing `otherLabel` group. An optional
// leadingGroup {label, favoriteIds} (the "Most Recent" group) goes first.
function groupEntries(entries, otherLabel, leadingGroup) {
	var groups = []
	if (leadingGroup && leadingGroup.favoriteIds && leadingGroup.favoriteIds.length) {
		groups.push({ label: leadingGroup.label || "", favoriteIds: leadingGroup.favoriteIds.slice() })
	}
	var byLabel = {}
	var other = null
	for (var i = 0; i < (entries || []).length; i++) {
		var entry = entries[i]
		var label = entry.category || ""
		var group
		if (!label) {
			if (!other) {
				other = { label: otherLabel || "", favoriteIds: [] }
			}
			group = other
		} else {
			group = byLabel[label]
			if (!group) {
				group = { label: label, favoriteIds: [] }
				byLabel[label] = group
				groups.push(group)
			}
		}
		group.favoriteIds.push(entry.favoriteId)
	}
	if (other) {
		groups.push(other)
	}
	return groups
}

// Shelf-pack groups side by side within `columns` grid cells. Each group is
// as wide as its tiles (up to the column budget) with a one-row header;
// groups that don't fit on the current band wrap to a new one.
function layoutGroups(groups, columns) {
	var cols = Math.max(TILE_SIZE, Math.floor(columns || 0))
	var maxPerRow = Math.max(1, Math.floor(cols / TILE_SIZE))
	var tiles = []
	var cursorX = 0
	var bandY = 0
	var bandH = 0
	for (var g = 0; g < (groups || []).length; g++) {
		var ids = groups[g].favoriteIds || []
		if (!ids.length) {
			continue
		}
		var perRow = Math.min(maxPerRow, ids.length)
		var w = perRow * TILE_SIZE
		if (cursorX > 0 && cursorX + w > cols) {
			cursorX = 0
			bandY += bandH
			bandH = 0
		}
		tiles.push({
			tileType: "group",
			label: groups[g].label,
			hideCount: true,
			x: cursorX,
			y: bandY,
			w: w,
			h: 1,
		})
		for (var i = 0; i < ids.length; i++) {
			var id = ids[i]
			tiles.push({
				x: cursorX + (i % perRow) * TILE_SIZE,
				y: bandY + 1 + Math.floor(i / perRow) * TILE_SIZE,
				w: TILE_SIZE,
				h: TILE_SIZE,
				url: id,
				favoriteId: id,
				launchUrl: "applications:" + id,
			})
		}
		var rows = Math.ceil(ids.length / perRow)
		bandH = Math.max(bandH, 1 + rows * TILE_SIZE)
		cursorX += w
	}
	return tiles
}

function buildTiles(entries, columns, otherLabel, leadingGroup) {
	return layoutGroups(groupEntries(entries, otherLabel, leadingGroup), columns)
}

// Ordered favoriteIds of the generated tiles, used to skip no-op rebuilds.
function entriesKey(entries, recentIds) {
	var parts = []
	for (var i = 0; i < (entries || []).length; i++) {
		parts.push(entries[i].favoriteId + "\u0001" + entries[i].category)
	}
	return parts.join("\u0002") + "\u0003" + (recentIds || []).join("\u0002")
}
