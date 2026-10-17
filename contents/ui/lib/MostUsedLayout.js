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
// Each group carries a stable `key` for saved positions: "recent", "other"
// or "category/<label>".
function groupEntries(entries, otherLabel, leadingGroup) {
	var groups = []
	if (leadingGroup && leadingGroup.favoriteIds && leadingGroup.favoriteIds.length) {
		groups.push({ key: "recent", label: leadingGroup.label || "", favoriteIds: leadingGroup.favoriteIds.slice() })
	}
	var byLabel = {}
	var other = null
	for (var i = 0; i < (entries || []).length; i++) {
		var entry = entries[i]
		var label = entry.category || ""
		var group
		if (!label) {
			if (!other) {
				other = { key: "other", label: otherLabel || "", favoriteIds: [] }
			}
			group = other
		} else {
			group = byLabel[label]
			if (!group) {
				group = { key: "category/" + label, label: label, favoriteIds: [] }
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

function _overlaps(a, b) {
	return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

function _firstOverlap(rect, placed) {
	for (var i = 0; i < placed.length; i++) {
		if (_overlaps(rect, placed[i])) {
			return placed[i]
		}
	}
	return null
}

// Shelf-pack groups side by side within `columns` grid cells. Each group is
// as wide as its tiles (up to the column budget) with a one-row header;
// groups that don't fit on the current band wrap to a new one.
// positions: optional {groupKey: {x, y}} saved by dragging groups. Saved
// groups keep their cell (clamped into the columns, pushed down past any
// group above that grew into them); the rest take the first free spot.
// Without saved positions the plain shelf packing applies.
function layoutGroups(groups, columns, positions) {
	var cols = Math.max(TILE_SIZE, Math.floor(columns || 0))
	var maxPerRow = Math.max(1, Math.floor(cols / TILE_SIZE))
	var saved = positions || {}
	var specs = []
	var anySaved = false
	for (var g = 0; g < (groups || []).length; g++) {
		var ids = groups[g].favoriteIds || []
		if (!ids.length) {
			continue
		}
		var perRow = Math.min(maxPerRow, ids.length)
		var pos = groups[g].key && saved.hasOwnProperty(groups[g].key) ? saved[groups[g].key] : null
		if (pos && !(isFinite(pos.x) && isFinite(pos.y))) {
			pos = null
		}
		anySaved = anySaved || !!pos
		specs.push({
			group: groups[g],
			ids: ids,
			perRow: perRow,
			order: specs.length,
			saved: pos,
			w: perRow * TILE_SIZE,
			h: 1 + Math.ceil(ids.length / perRow) * TILE_SIZE,
			x: 0,
			y: 0,
		})
	}

	if (!anySaved) {
		var cursorX = 0
		var bandY = 0
		var bandH = 0
		for (var s = 0; s < specs.length; s++) {
			if (cursorX > 0 && cursorX + specs[s].w > cols) {
				cursorX = 0
				bandY += bandH
				bandH = 0
			}
			specs[s].x = cursorX
			specs[s].y = bandY
			bandH = Math.max(bandH, specs[s].h)
			cursorX += specs[s].w
		}
	} else {
		var placed = []
		// Top-down, so a group that grew pushes the ones below it.
		var pinned = specs.filter(function(spec) { return !!spec.saved })
		pinned.sort(function(a, b) {
			return (a.saved.y - b.saved.y) || (a.saved.x - b.saved.x) || (a.order - b.order)
		})
		for (var p = 0; p < pinned.length; p++) {
			var spec = pinned[p]
			spec.x = Math.max(0, Math.min(Math.floor(spec.saved.x), cols - spec.w))
			spec.y = Math.max(0, Math.floor(spec.saved.y))
			var hit
			while ((hit = _firstOverlap(spec, placed))) {
				spec.y = hit.y + hit.h
			}
			placed.push(spec)
		}
		for (var u = 0; u < specs.length; u++) {
			var free = specs[u]
			if (free.saved) {
				continue
			}
			var bottom = 0
			for (var b = 0; b < placed.length; b++) {
				bottom = Math.max(bottom, placed[b].y + placed[b].h)
			}
			var found = false
			for (var fy = 0; fy <= bottom && !found; fy++) {
				for (var fx = 0; fx + free.w <= cols && !found; fx++) {
					free.x = fx
					free.y = fy
					found = !_firstOverlap(free, placed)
				}
			}
			placed.push(free)
		}
	}

	var tiles = []
	for (var t = 0; t < specs.length; t++) {
		var item = specs[t]
		tiles.push({
			tileType: "group",
			label: item.group.label,
			groupKey: item.group.key || "",
			hideCount: true,
			x: item.x,
			y: item.y,
			w: item.w,
			h: 1,
		})
		for (var i = 0; i < item.ids.length; i++) {
			var id = item.ids[i]
			tiles.push({
				x: item.x + (i % item.perRow) * TILE_SIZE,
				y: item.y + 1 + Math.floor(i / item.perRow) * TILE_SIZE,
				w: TILE_SIZE,
				h: TILE_SIZE,
				url: id,
				favoriteId: id,
				launchUrl: "applications:" + id,
			})
		}
	}
	return tiles
}

function buildTiles(entries, columns, otherLabel, leadingGroup, positions) {
	return layoutGroups(groupEntries(entries, otherLabel, leadingGroup), columns, positions)
}

// Ordered favoriteIds of the generated tiles, used to skip no-op rebuilds.
function entriesKey(entries, recentIds) {
	var parts = []
	for (var i = 0; i < (entries || []).length; i++) {
		parts.push(entries[i].favoriteId + "\u0001" + entries[i].category)
	}
	return parts.join("\u0002") + "\u0003" + (recentIds || []).join("\u0002")
}
