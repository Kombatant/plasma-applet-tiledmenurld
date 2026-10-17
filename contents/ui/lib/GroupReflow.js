.pragma library

// Make-room placement for dragging a group onto occupied cells, in the
// spirit of Android launchers: whatever the moved block lands on moves to
// the nearest free spot instead of the drop being refused. Kept free of QML
// so tests/tst_group_reflow.qml can exercise it.
//
// A unit is a block of cells that moves as one: a group with every tile in
// its area, or a loose tile.

function _overlaps(a, b) {
	return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h
}

function _isFree(rect, placed) {
	for (var i = 0; i < placed.length; i++) {
		if (_overlaps(rect, placed[i])) {
			return false
		}
	}
	return true
}

// Free spot closest to the unit's current cell (Manhattan distance) within
// `cols` columns. Equal distances go to the spot not above the unit, then the
// first in reading order. Below every placed block there is always room, so
// this never fails.
function nearestFreeSpot(unit, placed, cols) {
	var bottom = unit.y
	for (var i = 0; i < placed.length; i++) {
		bottom = Math.max(bottom, placed[i].y + placed[i].h)
	}
	var maxX = Math.max(0, cols - unit.w)
	var best = null
	var bestCost = Infinity
	for (var y = 0; y <= bottom; y++) {
		for (var x = 0; x <= maxX; x++) {
			var cost = Math.abs(x - unit.x) + Math.abs(y - unit.y) + (y < unit.y ? 0.1 : 0)
			if (cost >= bestCost) {
				continue
			}
			var rect = { x: x, y: y, w: unit.w, h: unit.h }
			if (_isFree(rect, placed)) {
				best = rect
				bestCost = cost
			}
		}
	}
	return best
}

function _rectAt(list, pos, i) {
	return { x: pos[i].x, y: pos[i].y, w: list[i].w, h: list[i].h }
}

// Each unit the moved one lands on goes, top to bottom, to the nearest free
// spot; everything else stays put.
function _nearestArrangement(list, movedIndex, movedRect, cols) {
	var pos = list.map(function(u) { return { x: u.x, y: u.y } })
	pos[movedIndex] = { x: movedRect.x, y: movedRect.y }
	var placed = [movedRect]
	var displaced = []
	for (var j = 0; j < list.length; j++) {
		if (j === movedIndex) {
			continue
		}
		var rect = _rectAt(list, pos, j)
		if (_overlaps(rect, movedRect)) {
			displaced.push(j)
		} else {
			placed.push(rect)
		}
	}
	displaced.sort(function(a, b) {
		return (list[a].y - list[b].y) || (list[a].x - list[b].x) || (a - b)
	})
	for (var d = 0; d < displaced.length; d++) {
		var spot = nearestFreeSpot(list[displaced[d]], placed, cols)
		pos[displaced[d]] = { x: spot.x, y: spot.y }
		placed.push(spot)
	}
	return pos
}

// Pushes every unit the moved one lands on just far enough in `dir`
// ("down", "right", "left", "up") to clear it, and whatever those land on in
// turn, so neighbours move as a chain and keep their order. Returns null
// when the chain would leave the grid or can't settle.
function _pushArrangement(list, movedIndex, movedRect, dir, cols) {
	var pos = list.map(function(u) { return { x: u.x, y: u.y } })
	pos[movedIndex] = { x: movedRect.x, y: movedRect.y }
	var changed = {}
	changed[movedIndex] = true
	var queue = [movedIndex]
	var guard = list.length * list.length * 4 + 16
	while (queue.length) {
		if (--guard < 0) {
			return null
		}
		var a = queue.shift()
		var ra = _rectAt(list, pos, a)
		for (var b = 0; b < list.length; b++) {
			if (b === a || b === movedIndex) {
				continue
			}
			var rb = _rectAt(list, pos, b)
			if (!_overlaps(ra, rb)) {
				continue
			}
			if (dir === "down") {
				pos[b].y = ra.y + ra.h
			} else if (dir === "up") {
				pos[b].y = ra.y - rb.h
			} else if (dir === "right") {
				pos[b].x = ra.x + ra.w
			} else {
				pos[b].x = ra.x - rb.w
			}
			if (pos[b].y < 0 || pos[b].x < 0 || (dir === "right" && pos[b].x + rb.w > cols)) {
				return null
			}
			changed[b] = true
			queue.push(b)
		}
	}
	// Units that moved must not overlap anything.
	for (var i = 0; i < list.length; i++) {
		if (!changed[i]) {
			continue
		}
		var ri = _rectAt(list, pos, i)
		for (var k = 0; k < list.length; k++) {
			if (k !== i && _overlaps(ri, _rectAt(list, pos, k))) {
				return null
			}
		}
	}
	return pos
}

// Dropped exactly onto one unit of the same size: that unit takes the
// moved unit's old spot, if it is inside the grid and free. Returns null
// otherwise.
function _swapArrangement(list, movedIndex, movedRect, cols) {
	var moved = list[movedIndex]
	var other = -1
	for (var j = 0; j < list.length; j++) {
		if (j !== movedIndex && _overlaps(list[j], movedRect)) {
			if (other >= 0) {
				return null
			}
			other = j
		}
	}
	if (other < 0) {
		return null
	}
	var o = list[other]
	if (o.x !== movedRect.x || o.y !== movedRect.y || o.w !== movedRect.w || o.h !== movedRect.h) {
		return null
	}
	var vacated = { x: moved.x, y: moved.y, w: o.w, h: o.h }
	if (vacated.x < 0 || vacated.y < 0 || vacated.x + vacated.w > cols || _overlaps(vacated, movedRect)) {
		return null
	}
	for (var k = 0; k < list.length; k++) {
		if (k !== movedIndex && k !== other && _overlaps(vacated, list[k])) {
			return null
		}
	}
	var pos = list.map(function(u) { return { x: u.x, y: u.y } })
	pos[movedIndex] = { x: movedRect.x, y: movedRect.y }
	pos[other] = { x: moved.x, y: moved.y }
	return pos
}

function _rowsOverlap(a, b) {
	return a.y < b.y + b.h && b.y < a.y + a.h
}

function _colsOverlap(a, b) {
	return a.x < b.x + b.w && b.x < a.x + a.w
}

// How disruptive an arrangement is for everything except the moved unit:
// swapped neighbours (one was above/left of the other and now is
// below/right of it) weigh most, then rows the layout grows by, then how
// many units moved, then how far.
function arrangementCost(list, movedIndex, pos) {
	var inversions = 0
	var movedCount = 0
	var distance = 0
	var oldBottom = 0
	var newBottom = 0
	for (var i = 0; i < list.length; i++) {
		oldBottom = Math.max(oldBottom, list[i].y + list[i].h)
		newBottom = Math.max(newBottom, pos[i].y + list[i].h)
		if (i === movedIndex) {
			continue
		}
		var dx = Math.abs(pos[i].x - list[i].x)
		var dy = Math.abs(pos[i].y - list[i].y)
		if (dx || dy) {
			movedCount++
			distance += dx + dy
		}
		for (var j = i + 1; j < list.length; j++) {
			if (j === movedIndex) {
				continue
			}
			var a = list[i], b = list[j]
			var na = _rectAt(list, pos, i), nb = _rectAt(list, pos, j)
			if ((_colsOverlap(a, b) && a.y + a.h <= b.y && nb.y + nb.h <= na.y)
					|| (_colsOverlap(a, b) && b.y + b.h <= a.y && na.y + na.h <= nb.y)
					|| (_rowsOverlap(a, b) && a.x + a.w <= b.x && nb.x + nb.w <= na.x)
					|| (_rowsOverlap(a, b) && b.x + b.w <= a.x && na.x + na.w <= nb.x)) {
				inversions++
			}
		}
	}
	return inversions * 10 + Math.max(0, newBottom - oldBottom) * 3 + movedCount * 2 + distance
}

// units: [{x, y, w, h}] cell rects. Moves units[movedIndex] to
// (targetX, targetY), clamped into `columns`, and makes room for it.
// Dropping exactly onto a same-size unit swaps the two when the old spot is
// free. Otherwise candidate arrangements (nearest free spot per unit, or
// pushing a chain of neighbours down/right/left/up) are compared with
// arrangementCost; the cheapest wins, earlier candidates on ties.
// Returns [{x, y}] per unit (the new top-left cell).
function resolve(units, movedIndex, targetX, targetY, columns) {
	var list = units || []
	var moved = list[movedIndex]
	if (!moved) {
		return list.map(function(u) { return { x: u.x, y: u.y } })
	}
	var cols = Math.max(1, Math.floor(columns || 0))
	var movedRect = {
		x: Math.max(0, Math.min(Math.floor(targetX), cols - moved.w)),
		y: Math.max(0, Math.floor(targetY)),
		w: moved.w,
		h: moved.h,
	}
	var swap = _swapArrangement(list, movedIndex, movedRect, cols)
	if (swap) {
		return swap
	}
	var best = _nearestArrangement(list, movedIndex, movedRect, cols)
	var bestCost = arrangementCost(list, movedIndex, best)
	var dirs = ["down", "right", "left", "up"]
	for (var d = 0; d < dirs.length && bestCost > 0; d++) {
		var candidate = _pushArrangement(list, movedIndex, movedRect, dirs[d], cols)
		if (!candidate) {
			continue
		}
		var cost = arrangementCost(list, movedIndex, candidate)
		if (cost < bestCost) {
			best = candidate
			bestCost = cost
		}
	}
	return best
}
