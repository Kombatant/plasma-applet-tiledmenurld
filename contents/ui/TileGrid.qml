import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.private.kicker as Kicker
import "Utils.js" as Utils
import "lib/GroupReflow.js" as GroupReflow

DropArea {
	id: tileGrid

	// Shared per-grid helpers — previously instantiated once per tile,
	// multiplying grid rebuild cost for no benefit.
	readonly property alias processRunner: gridProcessRunner
	Kicker.ProcessRunner {
		id: gridProcessRunner
	}
	readonly property font tileLabelFont: Qt.font({ pixelSize: Kirigami.Theme.defaultFont.pixelSize, bold: false })
	readonly property font tileGroupLabelFont: Qt.font({
		family: Kirigami.Theme.defaultFont.family,
		pointSize: Kirigami.Theme.defaultFont.pointSize + 4,
		weight: Kirigami.Theme.defaultFont.weight,
		italic: Kirigami.Theme.defaultFont.italic
	})
	readonly property alias tileLabelMetrics: tileLabelMetricsItem
	readonly property alias tileGroupLabelMetrics: tileGroupLabelMetricsItem
	FontMetrics {
		id: tileLabelMetricsItem
		font: tileGrid.tileLabelFont
	}
	FontMetrics {
		id: tileGroupLabelMetricsItem
		font: tileGrid.tileGroupLabelFont
	}
	property int cellSize: 60 * Screen.devicePixelRatio
	property int cellMargin: Math.round(3 * Screen.devicePixelRatio)
	property real cellPushedMargin: 6 * Screen.devicePixelRatio
	property int cellBoxSize: cellMargin + cellSize + cellMargin
	property int hoverOutlineSize: 2 * Screen.devicePixelRatio
	readonly property real holographicHoverScale: 1.05
	property var hoveredTileItem: null
	property bool hoverAnimationEnabled: true
	property int maxHoverWidth: 1
	property int maxHoverHeight: 1
	readonly property int _pillMotionDuration: 420
	readonly property real groupPanelInsetX: Math.max(cellMargin, Math.round(6 * Screen.devicePixelRatio))
	readonly property real groupPanelInsetTop: Math.max(cellMargin, Math.round(5 * Screen.devicePixelRatio))
	readonly property real groupPanelInsetBottom: groupPanelInsetX
	function holographicPaddingFor(hoverWidth, hoverHeight) {
		if (plasmoid && plasmoid.configuration) {
			if (plasmoid.configuration.tileHoverEffect === "holographic") {
				var maxHoverCells = Math.max(1, hoverWidth || 1, hoverHeight || 1)
				// Each edge can grow by half the hover scale delta. Add the outline
				// width as a small glow allowance instead of reserving a fixed
				// percentage of every cell on all sides.
				var scaleOverflow = cellBoxSize * maxHoverCells * ((holographicHoverScale - 1) / 2)
				return Math.ceil(scaleOverflow + hoverOutlineSize)
			}
			// Non-holographic hover effects can clip at scroll edges; reserve a small allowance.
			return Math.ceil(hoverOutlineSize)
		}
		return 0
	}
	readonly property int _holoPad: holographicPaddingFor(maxHoverWidth, maxHoverHeight)
	// _holoPad scales with the largest tile in the CURRENT tab, so it changes
	// whenever the tab switches. Chrome aligned to the grid (the tab bar) must
	// not inherit that, or the whole bar jumps sideways on every tab change.
	// This variant reserves the same allowance for a single cell, which is
	// constant across tabs.
	readonly property int _stableHoloPad: holographicPaddingFor(1, 1)
	readonly property real contentLeftInset: _holoPad + groupPanelInsetX
	// Content-independent counterpart of contentLeftInset/contentRightInset,
	// for chrome that sits above the grid and must stay put between tabs.
	readonly property real chromeLeftInset: _stableHoloPad + groupPanelInsetX
	readonly property real chromeRightInset: _stableHoloPad + groupPanelInsetX
	readonly property real contentRightInset: Math.max(
		groupPanelInsetX,
		width - (_holoPad + columns * cellBoxSize - groupPanelInsetX)
	)

	property int minColumns: Math.floor((width - 2 * _holoPad) / cellBoxSize)
	property int minRows: Math.floor((height - 2 * _holoPad) / cellBoxSize)

	property int maxColumn: 0
	property int maxRow: 0
	property int maxWidth: 0
	property int maxHeight: 0
	// Tile model changes rebuild every delegate. Keep the carousel's UI-only
	// position outside HeroTileView so ordinary edits do not return it to page 1.
	property var _heroPageStates: []
	property var _requestedHeroPageState: null
	property int columns: Math.max(minColumns, maxColumn)
	property int rows: Math.max(minRows, maxRow, reflowPreviewRows)

	function rememberHeroPageIndex(tile, pageIndex) {
		if (!tile) return
		var nextStates = _heroPageStates.slice()
		var normalizedIndex = Math.max(0, Math.floor(pageIndex || 0))
		for (var i = 0; i < nextStates.length; i++) {
			if (nextStates[i].tile === tile) {
				nextStates[i] = { tile: tile, pageIndex: normalizedIndex }
				_heroPageStates = nextStates
				return
			}
		}
		nextStates.push({ tile: tile, pageIndex: normalizedIndex })
		_heroPageStates = nextStates
	}

	function rememberedHeroPageIndex(tile) {
		if (!tile) return 0
		for (var i = 0; i < _heroPageStates.length; i++) {
			if (_heroPageStates[i].tile === tile) {
				return _heroPageStates[i].pageIndex
			}
		}
		return 0
	}

	function requestHeroPageIndex(tile, pageIndex) {
		if (!tile) return
		var normalizedIndex = Math.max(0, Math.floor(pageIndex || 0))
		_requestedHeroPageState = {
			tile: tile,
			tileX: tile.x,
			tileY: tile.y,
			pageIndex: normalizedIndex,
		}
		showHeroPageIndex(tile, normalizedIndex)
	}

	function showHeroPageIndex(tile, pageIndex) {
		if (!tile) return false
		var normalizedIndex = Math.max(0, Math.floor(pageIndex || 0))
		rememberHeroPageIndex(tile, normalizedIndex)
		var tileIndex = (tileModel || []).indexOf(tile)
		if (tileIndex < 0) {
			for (var i = 0; i < (tileModel || []).length; i++) {
				var candidate = tileModel[i]
				if (candidate && candidate.tileType === "hero" && candidate.x === tile.x && candidate.y === tile.y) {
					tileIndex = i
					break
				}
			}
		}
		var tileDelegate = tileIndex >= 0 ? tileModelRepeater.itemAt(tileIndex) : null
		if (tileDelegate && tileDelegate.heroTileView) {
			var pageCount = tileDelegate.heroTileView.effectivePages.length
			tileDelegate.heroTileView.currentIndex = Math.max(0, Math.min(normalizedIndex, pageCount - 1))
			return true
		}
		return false
	}

	function takeHeroPageIndex(tile) {
		var request = _requestedHeroPageState
		var matchesRequest = request && tile && (request.tile === tile
			|| (request.tileX === tile.x && request.tileY === tile.y && tile.tileType === "hero"))
		if (matchesRequest) {
			_requestedHeroPageState = null
			rememberHeroPageIndex(tile, request.pageIndex)
			return request.pageIndex
		}
		return rememberedHeroPageIndex(tile)
	}

	function pruneHeroPageStates() {
		var nextStates = []
		for (var i = 0; i < _heroPageStates.length; i++) {
			if ((tileModel || []).indexOf(_heroPageStates[i].tile) !== -1) {
				nextStates.push(_heroPageStates[i])
			}
		}
		_heroPageStates = nextStates
	}


	//--- Drag and Drop properties
	property bool isDragging: false
	property var addedItem: null
	readonly property bool adding: addedItem
	property int draggedIndex: -1
	readonly property var draggedItem: draggedIndex >= 0 ? tileModel[draggedIndex] : null
	property bool editing: isDragging && draggedItem || adding
	property int dropHoverX: -1
	property int dropHoverY: -1
	readonly property int dropWidth: draggedItem ? draggedItem.w : addedItem ? addedItem.w : 0
	readonly property int dropHeight: draggedItem ? draggedItem.h : addedItem ? addedItem.h : 0
	property bool canDrop: false
	property var dropTargetHeroTile: null
	property string dropPendingUrl: ""
	property string dropPendingFavoriteId: ""
	readonly property bool hasDrag: tileGrid.editing && dropHoverX >= 0 && dropHoverY >= 0
	readonly property bool isDraggingGroup: hasDrag && draggedItem && draggedItem.tileType == "group"

	function setHoveredTileItem(item) {
		hoverAnimationEnabled = hoveredTileItem !== null
		hoveredTileItem = item
		Qt.callLater(function() {
			hoverAnimationEnabled = true
		})
	}

	function resetHoveredTileIndicator() {
		hoverAnimationEnabled = false
		hoveredTileItem = null
	}

	signal moveTileToTab(int tileIndex, string tabId)

	// Read-only grids (the automatic "Popular" tab) still launch
	// apps and show app actions, but reject every layout mutation regardless
	// of the user's tile lock. effectiveLocked folds both into one check for
	// UI controls; the mutation functions below also guard on readOnly.
	property bool readOnly: false
	readonly property bool effectiveLocked: readOnly || !!plasmoid.configuration.tilesLocked
	// Shown instead of the presets/add-tile splash when a read-only grid is empty.
	property string emptyPlaceholderText: ""
	property string emptyPlaceholderExplanation: ""
	// A read-only grid with movableGroups lets the user drag group headers
	// (not apps). The grid never moves them itself: a drop emits
	// groupMoveRequested with [{index, x, y}] for every group header and the
	// owner regenerates the layout.
	property bool movableGroups: false
	signal groupMoveRequested(var positions)
	readonly property bool _movingReadOnlyGroup: readOnly && movableGroups
		&& !!draggedItem && draggedItem.tileType === "group"

	// ── Make-room moves ──────────────────────────────────────────────────────
	// A dragged group or tile pushes whatever it lands on to the nearest free
	// spot instead of the drop being refused. Groups always move as a whole
	// (header and tiles). A tile dropped inside a group only shuffles that
	// group's tiles, growing the group downward when it runs out of room.
	// The pushes are previewed live through reflowPreview and applied on drop.
	property int reflowColumns: columns
	property var reflowPreview: []   // tileIndex -> {x, y} while previewing
	property var reflowPreviewHeights: []   // group tileIndex -> rows (header + area)
	property int reflowPreviewRows: 0
	readonly property int reflowAnimationDuration: Kirigami.Units.longDuration
	// Neighbours only step aside once the pointer rests on a target this long,
	// so sweeping across a packed area doesn't reshuffle everything passed.
	property int reflowDwellInterval: 300
	// Fraction of a cell the dragged item must move past the midpoint before
	// the target switches, so hovering on a boundary doesn't flicker.
	readonly property real reflowSnapMargin: 0.2
	property string _reflowPreviewKey: ""
	property var _pendingReflowPlan: null
	property var _lastDragPoint: null

	// Edge auto-scroll moves the content under a still pointer; retarget
	// the drag so the drop cell keeps matching what's under it.
	Connections {
		target: scrollView.flickableItem
		ignoreUnknownSignals: true
		function onContentYChanged() {
			if (tileGrid.isDragging && tileGrid.draggedItem && tileGrid._lastDragPoint) {
				tileGrid._dragItemTick(tileGrid._lastDragPoint.x, tileGrid._lastDragPoint.y)
			}
		}
	}

	Timer {
		id: reflowDwellTimer
		interval: tileGrid.reflowDwellInterval
		onTriggered: {
			if (tileGrid._pendingReflowPlan) {
				tileGrid._setReflowPreview(tileGrid._pendingReflowPlan)
				tileGrid._pendingReflowPlan = null
			}
		}
	}

	// Cell a tile is drawn at: its previewed cell during a drag.
	function previewX(tileIndex, tile) {
		var cell = reflowPreview[tileIndex]
		return cell ? cell.x : (tile ? tile.x : 0)
	}
	function previewY(tileIndex, tile) {
		var cell = reflowPreview[tileIndex]
		return cell ? cell.y : (tile ? tile.y : 0)
	}
	// Rows (header + area) a group's card spans in the preview, 0 if unchanged.
	function previewGroupRows(tileIndex) {
		return reflowPreviewHeights[tileIndex] || 0
	}

	// Splits the model into blocks that move as one: each group with the
	// tiles in its area, then every remaining tile on its own. excludeIndex
	// (a dragged tile) is left out entirely, as if already picked up.
	// Returns {units: [{x, y, w, h, members, area?}], unitOf: tileIndex -> unit};
	// group units carry their area rect and list the header first in members.
	function _reflowUnits(excludeIndex) {
		var units = []
		var unitOf = []
		for (var i = 0; i < tileModel.length; i++) {
			unitOf.push(-1)
		}
		for (var g = 0; g < tileModel.length; g++) {
			var header = tileModel[g]
			if (!header || header.tileType !== "group") {
				continue
			}
			var area = getGroupAreaRect(header)
			// The area's own height minus the excluded tile: its first row
			// (or explicit groupAreaH), then whatever its tiles cover.
			var baseRows = Math.max(1, header.groupAreaH || 0)
			var unit = {
				x1: Math.min(header.x, area.x1),
				y1: header.y,
				x2: Math.max(header.x + header.w - 1, area.x2),
				y2: Math.max(header.y + (header.h || 1) - 1, Math.min(area.y2, area.y1 + baseRows - 1)),
				members: [g],
				area: area,
			}
			unitOf[g] = units.length
			for (var m = 0; m < tileModel.length; m++) {
				var member = tileModel[m]
				if (m === excludeIndex || unitOf[m] >= 0 || !member || member.tileType === "group") {
					continue
				}
				if (tileWithin(member, area.x1, area.y1, area.x2, area.y2)) {
					unitOf[m] = units.length
					unit.members.push(m)
					unit.x1 = Math.min(unit.x1, member.x)
					unit.x2 = Math.max(unit.x2, member.x + member.w - 1)
					unit.y2 = Math.max(unit.y2, member.y + member.h - 1)
				}
			}
			units.push(unit)
		}
		for (var t = 0; t < tileModel.length; t++) {
			var tile = tileModel[t]
			if (t === excludeIndex || unitOf[t] >= 0 || !tile) {
				continue
			}
			unitOf[t] = units.length
			units.push({ x1: tile.x, y1: tile.y, x2: tile.x + tile.w - 1, y2: tile.y + tile.h - 1, members: [t] })
		}
		for (var u = 0; u < units.length; u++) {
			units[u].x = units[u].x1
			units[u].y = units[u].y1
			units[u].w = units[u].x2 - units[u].x1 + 1
			units[u].h = units[u].y2 - units[u].y1 + 1
		}
		return { units: units, unitOf: unitOf }
	}

	// New cells for moving group header `groupIndex` to (cellX, cellY).
	// Returns {cells: tileIndex -> {x, y} (moved tiles only), rows} or null.
	function planGroupMove(groupIndex, cellX, cellY) {
		var header = tileModel[groupIndex]
		if (!header || header.tileType !== "group") {
			return null
		}
		var built = _reflowUnits(-1)
		var units = built.units
		var movedUnit = built.unitOf[groupIndex]
		var moved = units[movedUnit]
		var result = GroupReflow.resolve(units, movedUnit,
			cellX - (header.x - moved.x), cellY - (header.y - moved.y), reflowColumns)
		var cells = []
		var rows = _shiftUnits(units, result, cells, -1)
		return _finishPlan(units, cells, rows, moved.members)
	}

	// Plan result: own lists the dragged block's tiles (they follow the
	// pointer at once); displaces tells whether anything else moves;
	// heights holds group cards whose size changes.
	function _finishPlan(units, cells, rows, own) {
		var ownSet = {}
		for (var o = 0; o < own.length; o++) {
			ownSet[own[o]] = true
		}
		var displaces = false
		for (var i = 0; i < cells.length; i++) {
			if (cells[i] && !ownSet[i]) {
				displaces = true
				break
			}
		}
		var heights = []
		for (var u = 0; u < units.length; u++) {
			var unit = units[u]
			if (!unit.area) {
				continue
			}
			var header = tileModel[unit.members[0]]
			if (unit.h !== (header.h || 1) + unit.area.h) {
				heights[unit.members[0]] = unit.h
			}
		}
		return { cells: cells, rows: rows, own: own, displaces: displaces, heights: heights }
	}

	// Writes the cells of every member of units moved by `result` into
	// `cells`, skipping unit skipUnit. Returns the rows the layout needs.
	function _shiftUnits(units, result, cells, skipUnit) {
		var rows = 0
		for (var u = 0; u < units.length; u++) {
			rows = Math.max(rows, result[u].y + units[u].h)
			var dx = result[u].x - units[u].x
			var dy = result[u].y - units[u].y
			if (u === skipUnit || (!dx && !dy)) {
				continue
			}
			for (var m = 0; m < units[u].members.length; m++) {
				var index = units[u].members[m]
				var base = cells[index] || tileModel[index]
				cells[index] = { x: base.x + dx, y: base.y + dy }
			}
		}
		return rows
	}

	// Group unit whose area fully holds `rect` (columns under the header,
	// top row between the header and the group's last row), or -1.
	function _groupUnitHolding(units, rect) {
		for (var u = 0; u < units.length; u++) {
			var unit = units[u]
			if (!unit.area) {
				continue
			}
			if (rect.x >= unit.area.x1 && rect.x + rect.w - 1 <= unit.area.x2
					&& rect.y >= unit.area.y1 && rect.y <= unit.y + unit.h - 1) {
				return u
			}
		}
		return -1
	}

	// New cells for moving the single tile `tileIndex` to (cellX, cellY).
	// Returns {cells: tileIndex -> {x, y} (moved tiles only), rows} or null.
	function planTileMove(tileIndex, cellX, cellY) {
		var tile = tileModel[tileIndex]
		if (!tile || tile.tileType === "group") {
			return null
		}
		var cols = reflowColumns
		var target = {
			x: Math.max(0, Math.min(Math.floor(cellX), cols - tile.w)),
			y: Math.max(0, Math.floor(cellY)),
			w: tile.w,
			h: tile.h,
		}
		var built = _reflowUnits(tileIndex)
		var units = built.units
		var cells = []
		var rows = 0
		var g = _groupUnitHolding(units, target)
		if (g >= 0) {
			// Inside a group: only its own tiles make room, within its columns
			// and below its header (coordinates relative to the area's top-left).
			var unit = units[g]
			var ox = unit.area.x1
			var oy = unit.area.y1
			var width = unit.area.x2 - unit.area.x1 + 1
			var localUnits = []
			for (var m = 1; m < unit.members.length; m++) {
				var member = tileModel[unit.members[m]]
				localUnits.push({ x: member.x - ox, y: member.y - oy, w: member.w, h: member.h })
			}
			localUnits.push({ x: tile.x - ox, y: tile.y - oy, w: tile.w, h: tile.h })
			var local = GroupReflow.resolve(localUnits, localUnits.length - 1, target.x - ox, target.y - oy, width)
			var bottom = unit.y + unit.h - 1
			for (var l = 0; l < localUnits.length; l++) {
				var index = l < localUnits.length - 1 ? unit.members[l + 1] : tileIndex
				var cell = { x: local[l].x + ox, y: local[l].y + oy }
				bottom = Math.max(bottom, cell.y + localUnits[l].h - 1)
				if (index === tileIndex || cell.x !== tileModel[index].x || cell.y !== tileModel[index].y) {
					cells[index] = cell
				}
			}
			// A group that grew pushes whatever is now in its way.
			var grownH = bottom - unit.y + 1
			var result = units.map(function(u) { return { x: u.x, y: u.y } })
			if (grownH > unit.h) {
				unit.h = grownH
				result = GroupReflow.resolve(units, g, unit.x, unit.y, cols)
			}
			rows = _shiftUnits(units, result, cells, g)
		} else {
			// Outside any group: whatever it lands on (a loose tile, or a
			// whole group when it hits a header or straddles an edge) moves.
			units.push({ x: tile.x, y: tile.y, w: tile.w, h: tile.h, members: [tileIndex] })
			var moved = GroupReflow.resolve(units, units.length - 1, target.x, target.y, cols)
			rows = _shiftUnits(units, moved, cells, -1)
		}
		return _finishPlan(units, cells, rows, [tileIndex])
	}

	function planMove(tileIndex, cellX, cellY) {
		var tile = tileModel[tileIndex]
		if (!tile) {
			return null
		}
		return tile.tileType === "group"
			? planGroupMove(tileIndex, cellX, cellY)
			: planTileMove(tileIndex, cellX, cellY)
	}

	function _updateReflowPreview() {
		var key = draggedIndex + ":" + dropHoverX + "," + dropHoverY
		if (key === _reflowPreviewKey) {
			return
		}
		_reflowPreviewKey = key
		reflowDwellTimer.stop()
		_pendingReflowPlan = null
		var plan = planMove(draggedIndex, dropHoverX, dropHoverY)
		if (!plan || !plan.displaces) {
			// Free target: show it now, and put any neighbours pushed for a
			// previous target straight back.
			_setReflowPreview(plan)
			return
		}
		// Occupied target: the dragged block goes there now, neighbours step
		// aside once the pointer rests (or on drop, which always applies).
		var ownCells = []
		for (var i = 0; i < plan.own.length; i++) {
			ownCells[plan.own[i]] = plan.cells[plan.own[i]]
		}
		_setReflowPreview({ cells: ownCells, heights: [], rows: plan.rows })
		_pendingReflowPlan = plan
		reflowDwellTimer.restart()
	}

	function _setReflowPreview(plan) {
		reflowPreview = plan ? plan.cells : []
		reflowPreviewHeights = plan ? plan.heights : []
		reflowPreviewRows = plan ? plan.rows : 0
	}

	function _clearReflowPreview() {
		_reflowPreviewKey = ""
		reflowDwellTimer.stop()
		_pendingReflowPlan = null
		if (reflowPreview.length) {
			reflowPreview = []
		}
		if (reflowPreviewHeights.length) {
			reflowPreviewHeights = []
		}
		reflowPreviewRows = 0
	}

	// Nearest cell to fractional position f, but keep `current` until f is
	// reflowSnapMargin past the midpoint between the two.
	function _snapCell(f, current) {
		var cell = Math.round(f)
		if (current >= 0 && cell !== current && Math.abs(f - current) < 0.5 + reflowSnapMargin) {
			return current
		}
		return cell
	}

	// Retargets a drag of one of our own tiles/groups. (gridX, gridY) is the
	// drag event position, which for these internal drags is the dragged
	// item's top-left (its Drag.hotSpot), not the pointer; it is mapped into
	// scrolled content coordinates and snapped to the nearest cell.
	function _dragItemTick(gridX, gridY) {
		_lastDragPoint = Qt.point(gridX, gridY)
		var p = tileGrid.mapToItem(scrollItem, gridX, gridY)
		var fx = (p.x - _holoPad) / cellBoxSize
		var fy = (p.y - _holoPad) / cellBoxSize
		var cellX = _snapCell(fx, dropHoverX)
		var cellY = _snapCell(fy, dropHoverY)
		dropHoverX = Math.max(0, Math.min(cellX, reflowColumns - dropWidth))
		dropHoverY = Math.max(0, cellY)
		canDrop = true
		_updateReflowPreview()
	}

	function applyMove(tileIndex, cellX, cellY) {
		if (readOnly) return
		var plan = planMove(tileIndex, cellX, cellY)
		if (!plan) return
		for (var i = 0; i < plan.cells.length; i++) {
			if (plan.cells[i]) {
				tileModel[i].x = plan.cells[i].x
				tileModel[i].y = plan.cells[i].y
			}
		}
		tileGrid.tileModelChanged()
	}

	function canDragTile(tile) {
		if (!readOnly) {
			return !effectiveLocked
		}
		return movableGroups && !plasmoid.configuration.tilesLocked
			&& !!tile && tile.tileType === "group"
	}

	readonly property var draggedGroupRect: {
		if (isDraggingGroup) {
			return getGroupAreaRect(draggedItem)
		} else {
			return null
		}
	}

	onEntered: drag => {
		dragTick(drag)
	}
	onPositionChanged: drag => {
		dragTick(drag)
	}
	onExited: {
		resetDragHover()
	}



		onDropped: drop => {
		if (tileGrid.readOnly) {
			if (tileGrid._movingReadOnlyGroup) {
				tileGrid.dragTick(drop)
				var plan = tileGrid.canDrop
					? tileGrid.planGroupMove(tileGrid.draggedIndex, tileGrid.dropHoverX, tileGrid.dropHoverY)
					: null
				if (plan) {
					var positions = []
					for (var gi = 0; gi < tileGrid.tileModel.length; gi++) {
						var groupTile = tileGrid.tileModel[gi]
						if (groupTile && groupTile.tileType === "group") {
							var cell = plan.cells[gi] || groupTile
							positions.push({ index: gi, x: cell.x, y: cell.y })
						}
					}
					tileGrid.groupMoveRequested(positions)
				}
			}
			tileGrid.resetDrag()
			return
		}
		 dragTick(drop)
		if (canDrop) {
		if (dropTargetHeroTile) {
			tileGrid.appendHeroPage(dropTargetHeroTile, dropPendingUrl, dropPendingFavoriteId)
			tileGrid.resetDrag()
		} else if (draggedItem) {
				tileGrid.applyMove(draggedIndex, dropHoverX, dropHoverY)
			    tileGrid.resetDrag()
			
			
			// event.accept(Qt.MoveAction)
		} else if (addedItem) {
			addedItem.x = dropHoverX
			addedItem.y = dropHoverY
			tileGrid.tileModel.push(addedItem)
			tileGrid.tileModelChanged()
			tileGrid.resetDrag()
			
		}
		}
		tileGrid.resetDrag()
		
	}


	 
	

	// Drag and Drop functions
	function resetDragHover() {
		dropHoverX = -1
		dropHoverY = -1
		_clearReflowPreview()
		scrollUpArea.containsDrag = false
		scrollDownArea.containsDrag = false
		addedItem = null
		dropTargetHeroTile = null
		dropPendingUrl = ""
		dropPendingFavoriteId = ""
	}
	function resetDrag() {
		resetDragHover()
		isDragging = false
		draggedIndex = -1
		_lastDragPoint = null
	}
	function startDrag(index) {
		draggedIndex = index
		dropHoverX = draggedItem.x
		dropHoverY = draggedItem.y
		isDragging = true
	}

	function tileWithin(tile, x1, y1, x2, y2) {
		var tileX2 = tile.x + tile.w - 1
		var tileY2 = tile.y + tile.h - 1
		return (x1 <= tileX2
			&& tile.x <= x2
			&& y1 <= tileY2
			&& tile.y <= y2
		)
	}

	// Every tile delegate resolves its parent group via getGroupAreaRect
	// (through AppObject), and each call scanned the whole model twice —
	// O(n²) per grid rebuild. Memoize per model generation. Fields of a
	// never-reassigned JS object so binding evaluation doesn't track it.
	readonly property var _groupRectCache: ({ map: null })
	function getGroupAreaRect(groupTile) {
		var cache = _groupRectCache
		if (!cache.map) {
			cache.map = {}
		}
		var key = groupTile.x + "," + groupTile.y + "," + groupTile.w + ","
			+ (typeof groupTile.h !== "undefined" ? groupTile.h : 1) + ","
			+ (typeof groupTile.groupAreaH !== "undefined" ? groupTile.groupAreaH : -1)
		var hit = cache.map[key]
		if (hit) {
			return hit
		}
		var rect = _computeGroupAreaRect(groupTile)
		cache.map[key] = rect
		return rect
	}

	function _computeGroupAreaRect(groupTile) {
		var x1 = groupTile.x
		var x2 = groupTile.x + groupTile.w - 1
		var headerH = (typeof groupTile.h !== "undefined" ? groupTile.h : 1)
		var y1 = groupTile.y + headerH
		var y2 = 2000000 // maxint

		// Scan for other groups below this group
		// and adjust y2 to above that group.
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tile.tileType == "group"
				&& tileWithin(tile, x1, y1, x2, y2)
			) {
				// We effectively use Math.min() here as we shrink the box tileWithin uses.
				y2 = tile.y - 1
			}
		}

		var lowestTileY = y1
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, x1, y1, x2, y2)) {
				lowestTileY = Math.max(lowestTileY, tile.y + tile.h - 1)
			}
		}

		// Allow an explicit minimum content area height for groups.
		// This lets the group header stay 1 cell tall while resizing affects the content area.
		var minAreaH = 0
		if (typeof groupTile.groupAreaH !== "undefined") {
			minAreaH = Math.max(0, groupTile.groupAreaH)
		}
		if (minAreaH > 0) {
			lowestTileY = Math.max(lowestTileY, y1 + minAreaH - 1)
		}

		y2 = Math.min(lowestTileY, y2)

		return {
			x1: x1,
			y1: y1,
			x2: x2,
			y2: y2,
			w: x2 - x1 + 1,
			h: y2 - y1 + 1,
		}
	}

	// QQuickDropEvent
	// https://github.com/qt/qtdeclarative/blob/a4aa8d9ade44d75cb5a1d84bd7c1773fadc73095/src/quick/items/qquickdroparea_p.h#L63
	function dragTick(event) {
		if (readOnly && !_movingReadOnlyGroup) {
			// No drop highlight or drop target on generated content.
			canDrop = false
			dropHoverX = -1
			dropHoverY = -1
			return
		}

		dropTargetHeroTile = null
		dropPendingUrl = ""
		dropPendingFavoriteId = ""

		scrollUpArea.checkContains(event)
		scrollDownArea.checkContains(event)
		if (draggedItem) {
			_dragItemTick(event.x, event.y)
			return
		}

		// External drops land on the cell under the pointer, in scrolled
		// content coordinates.
		var contentPoint = tileGrid.mapToItem(scrollItem, event.x, event.y)
		var dragX = contentPoint.x - _holoPad
		var dragY = contentPoint.y - _holoPad
		var modelX = Math.floor(dragX / cellBoxSize)
		var modelY = Math.floor(dragY / cellBoxSize)

		 //moveTile(draggedItem,dragX,dragY)

		// Hero-tile drop interception: on every tick (even when addedItem is
		// already created from an earlier tick on empty cells), if the cursor
		// is over a hero tile, route the drop to appendHeroPage instead.
		if (!draggedItem) {
			var url = ""
			var favId = ""
			if (event && event.keys && event.keys.indexOf('favoriteId') >= 0) {
				favId = event.getDataAsString('favoriteId')
				url = favId
			} else if (event && event.hasUrls && event.urls && event.urls.length > 0) {
				url = "" + event.urls[0]
			} else if (addedItem) {
				url = addedItem.launchUrl || addedItem.url || ""
				favId = addedItem.favoriteId || ""
			}

			if (url) {
				var heroTarget = findHeroTileAt(modelX, modelY)
				if (heroTarget) {
					addedItem = null
					dropTargetHeroTile = heroTarget
					dropPendingUrl = url
					dropPendingFavoriteId = favId
					dropHoverX = heroTarget.x
					dropHoverY = heroTarget.y
					canDrop = true
					return
				}
			}
		}

		if (draggedItem) {
		} else if (addedItem) {
		} else if (event && event.hasUrls && event.urls) {
			var url = ""
			var favId = ""
			if (event.keys && event.keys.indexOf('favoriteId') >= 0) {
				favId = event.getDataAsString('favoriteId')
				url = favId
			} else {
				url = "" + event.urls[0]
			}

			addedItem = newAppTile(url)
			dropHoverX = modelX
			dropHoverY = modelY

			// Firefox/Chromium url dropped
			if (event.keys && event.keys.indexOf('_NETSCAPE_URL') >= 0) {
				var netscapeUrl = event.getDataAsString('_NETSCAPE_URL')
				var tokens = netscapeUrl.split('\n')
				if (tokens.length >= 2) {
					var title = tokens[1].trim()
					if (title) {
						addedItem.label = title
						addedItem.icon = 'internet-web-browser'
					}
				}
			}
		} else {
			return
		}

		dropHoverX = Math.max(0, Math.min(modelX, columns - dropWidth))
		dropHoverY = Math.max(0, modelY)
		canDrop = !hits(dropHoverX, dropHoverY, dropWidth, dropHeight)
	}

	function countGroupTiles(groupTile) {
		if (!groupTile || groupTile.tileType !== "group") {
			return 0
		}

		var area = getGroupAreaRect(groupTile)
		var count = 0
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (!tile || tile === groupTile || tile.tileType === "group") {
				continue
			}
			if (tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
				count += 1
			}
		}
		return count
	}

	property var hitBox: [] // hitBox[y][x]
	function updateSize() {
		var c = 0;
		var r = 0;
		var w = 1;
		var h = 1;
		var hoverW = 1;
		var hoverH = 1;
		var draggedGroupArea = null
		if (draggedItem && draggedItem.tileType == "group") {
			draggedGroupArea = getGroupAreaRect(draggedItem)
		}
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			c = Math.max(c, tile.x + tile.w)
			if (tile.tileType === "group") {
				r = Math.max(r, getGroupAreaRect(tile).y2 + 1)
			} else {
				r = Math.max(r, tile.y + tile.h)
			}
			w = Math.max(w, tile.w)
			h = Math.max(h, tile.h)
			if (tile.tileType !== "group" && tile.tileType !== "hero") {
				hoverW = Math.max(hoverW, tile.w)
				hoverH = Math.max(hoverH, tile.h)
			}
		}
		// Add extra rows when dragging so we can drop scrolled down
		if (draggedItem) {
			// c += draggedItem.w
			r += draggedItem.h
		}

		// Rebuild hitBox
		var hbColumns = Math.max(minColumns, c)
		var hbRows = Math.max(minRows, r)
		var hb = new Array(hbRows)
		for (var i = 0; i < hbRows; i++) {
			hb[i] = new Array(hbColumns)
		}
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (i == draggedIndex) {
				continue;
			}
			if (draggedGroupArea && tileWithin(tile, draggedGroupArea.x1, draggedGroupArea.y1, draggedGroupArea.x2, draggedGroupArea.y2)) {
				continue;
			}
			for (var j = tile.y; j < tile.y + tile.h; j++) {
				for (var k = tile.x; k < tile.x + tile.w; k++) {
					hb[j][k] = true
				}
			}
		}

		// Update Properties
		hitBox = hb
		maxColumn = c
		maxRow = r
		maxWidth = w
		maxHeight = h
		maxHoverWidth = hoverW
		maxHoverHeight = hoverH
	}
	function update() {
		updateSize()
	}
	function refreshTileDelegates() {
		// When the config system reloads tileModel, the JS array is replaced.
		// Ensure Repeater delegates are rebuilt from the new array.
		// Panels/headers only render for group tiles — don't instantiate
		// (invisible) delegates for every tile in the grid.
		// They get tileModel indices, not tile objects: Repeater modelData is
		// a copy on Qt 6.12, so tileModel.indexOf(modelData) is always -1 and
		// the group panel/header couldn't follow the drag preview.
		var groupIndices = []
		for (var i = 0; i < (tileModel || []).length; i++) {
			if (tileModel[i] && tileModel[i].tileType === "group") {
				groupIndices.push(i)
			}
		}
		pruneHeroPageStates()
		groupPanelRepeater.model = 0
		groupPanelRepeater.model = groupIndices
		tileModelRepeater.model = 0
		tileModelRepeater.model = tileModel
		groupHeaderSeparatorRepeater.model = 0
		groupHeaderSeparatorRepeater.model = groupIndices
	}
	onDraggedItemChanged: update()
	onTileModelChanged: {
		_groupRectCache.map = null
		refreshTileDelegates()
		update()
	}
	property var tileModel: []


	function hits(x, y, w, h) {
		for (var j = y; j < y + h; j++) {
			if (j < 0 || j >= hitBox.length) {
				continue; // Should we return true when out of bounds?
			}
			for (var k = x; k < x + w; k++) {
				if (k < 0 || k >= hitBox[j].length) {
					continue; // Should we return true when out of bounds?
				}
				if (hitBox[j][k]) {
					return true
				}
			}
		}
		return false
	}

	function getTileAt(cellX, cellY) {
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, cellX, cellY, cellX, cellY)) {
				return tile
			}
		}
		return null
	}

	function getTilesInArea(area) {
		var tileList = []

		// Move tiles below group label
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
				tileList.push(tile)
			}
		}

		return tileList
	}

	function getTileLabel(tile) {
		if (tile.url) {
			var favoriteId = Utils.kickerFavoriteId(tile.favoriteId || tile.url)
			var app = favoriteId ? appsModel.getTileApp(favoriteId) : null
			var labelText = tile.label || (app ? app.display : "") || (app ? app.url : "") || tile.url || ""
			return labelText
		} else {
			return ""
		}
	}
	function sortGroupTiles(groupTile) {
		if (readOnly) return
		var area = getGroupAreaRect(groupTile)
		var tileList = getTilesInArea(area)

		var cursorX = groupTile.x
		var cursorY = groupTile.y + groupTile.h
		var rowH = 0
		tileList.sort(function(a, b) {
			var aLabel = getTileLabel(a)
			var bLabel = getTileLabel(b)
			return aLabel.localeCompare(bLabel)
		})

		for (var i = 0; i < tileList.length; i++) {
			var tile = tileList[i]
			var tileX2 = cursorX + tile.w - 1

			// If there's not enough room on this row
			if (tileX2 > area.x2) {
				// Move to the next row
				cursorX = groupTile.x
				cursorY += rowH
			}

			tile.x = cursorX
			tile.y = cursorY
			rowH = Math.max(rowH, tile.h)
			cursorX += tile.w
		}

		tileGrid.tileModelChanged()
	}

	QQC2.ScrollView {
		id: scrollView
		anchors.fill: parent
		background: Item {}
		clip: true
		contentWidth: scrollItem.width
		contentHeight: scrollItem.height
		QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
		QQC2.ScrollBar.vertical: QQC2.ScrollBar {
			parent: scrollView
			anchors.top: scrollView.top
			anchors.bottom: scrollView.bottom
			anchors.right: scrollView.right
			implicitWidth: 6
			width: 6
			padding: 0
			policy: QQC2.ScrollBar.AsNeeded
			background: Item { implicitWidth: 6 }
			contentItem: Rectangle {
				implicitWidth: 4
				width: 4
				radius: width / 2
				color: Kirigami.Theme.textColor
				opacity: parent.pressed ? 0.6 : parent.hovered ? 0.4 : 0.25
				Behavior on opacity { NumberAnimation { duration: 120 } }
			}
		}
		// Flickable becomes available after component creation; guard lookups.
		readonly property var flickableItem: contentItem ? contentItem : null
		readonly property var viewport: flickableItem ? flickableItem.contentItem : null
		readonly property int scrollTop: flickableItem ? flickableItem.contentY : 0
		readonly property int scrollHeight: flickableItem ? flickableItem.contentHeight : 0
		readonly property int scrollTopAtBottom: viewport ? scrollHeight - viewport.height : 0
		readonly property bool scrollAtTop: scrollTop == 0
		readonly property bool scrollAtBottom: scrollTop >= scrollTopAtBottom

		function scrollBy(deltaY) {
			if (flickableItem) {
				flickableItem.contentY = Math.max(0, Math.min(scrollTop + deltaY, scrollTopAtBottom))
			}
		}
		
			Item {
				id: scrollItem

				width: columns * cellBoxSize + 2 * _holoPad
				height: rows * cellBoxSize + 2 * _holoPad

				HoverHandler {
					id: tileGridHover
					target: scrollItem
					onHoveredChanged: {
						if (!hovered) {
							tileGrid.resetHoveredTileIndicator()
						}
					}
				}

				QtObject {
					id: pillHoverStyle
					property real highlightInset: 0
					property real pillRadius: tileGrid.hoveredTileItem ? tileGrid.hoveredTileItem.pillHoverFrameRadius : 0
					property color accentHighlightColor: Kirigami.Theme.highlightColor
				}

				PillHighlight {
					id: tileHoverIndicator
					z: 15
					visible: !!tileGrid.hoveredTileItem
						&& tileGrid.hoveredTileItem.usePillHoverEffect
						&& !tileGrid.hoveredTileItem.isHeroTile
					x: tileGrid.hoveredTileItem ? tileGrid.hoveredTileItem.x + tileGrid.hoveredTileItem.pillHoverFrameX : 0
					y: tileGrid.hoveredTileItem ? tileGrid.hoveredTileItem.y + tileGrid.hoveredTileItem.pillHoverFrameY : 0
					width: tileGrid.hoveredTileItem ? tileGrid.hoveredTileItem.pillHoverFrameWidth : 0
					height: tileGrid.hoveredTileItem ? tileGrid.hoveredTileItem.pillHoverFrameHeight : 0
					styleSource: pillHoverStyle
					active: false
					Behavior on x {
						enabled: tileGrid.hoverAnimationEnabled
						NumberAnimation {
							duration: tileGrid._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
					Behavior on y {
						enabled: tileGrid.hoverAnimationEnabled
						NumberAnimation {
							duration: tileGrid._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
					Behavior on width {
						enabled: tileGrid.hoverAnimationEnabled
						NumberAnimation {
							duration: tileGrid._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
					Behavior on height {
						enabled: tileGrid.hoverAnimationEnabled
						NumberAnimation {
							duration: tileGrid._pillMotionDuration
							easing.type: Easing.OutCubic
						}
					}
				}

				Repeater {
					id: cellRepeater
				readonly property int cellCount: columns * rows
				onCellCountChanged: {
					if (!isDragging) {
						model = cellCount
					}
				}
				model: 0

				Item {
					id: cellItem
					property int modelX: modelData % columns
					property int modelY: Math.floor(modelData / columns)
					x: modelX * cellBoxSize + _holoPad
					y: modelY * cellBoxSize + _holoPad
					width: cellBoxSize
					height: cellBoxSize

					readonly property bool tileHovered: (hasDrag
						&& dropHoverX <= modelX && modelX < dropHoverX + dropWidth
						&& dropHoverY <= modelY && modelY < dropHoverY + dropHeight
					)
					readonly property bool groupAreaHovered: {
						if (isDraggingGroup) {
							var groupX1 = dropHoverX
							var groupY1 = dropHoverY + dropHeight
							var groupX2 = groupX1 + draggedGroupRect.w - 1
							var groupY2 = groupY1 + draggedGroupRect.h - 1
							return groupX1 <= modelX && modelX <= groupX2
								&& groupY1 <= modelY && modelY <= groupY2
						} else {
							return false
						}
					}

					Rectangle {
						anchors.fill: parent
						anchors.margins: cellMargin
						color: {
							if (cellItem.tileHovered) {
								if (canDrop) {
									return "#88336699"
								} else {
									return "#88880000"
								}
							} else if (cellItem.groupAreaHovered) {
								return "#8848395d" // purple
							} else {
								return "transparent"
							}
						}
						border.width: 1
						border.color: tileGrid.editing ? "#44000000" : "transparent"
					}

					MouseArea {
						anchors.fill: parent
						acceptedButtons: Qt.RightButton
						onClicked: function(mouse) {
							if (mouse.button == Qt.RightButton) {
								if (tileGrid.readOnly) {
									return
								}
								cellContextMenu.cellX = cellItem.modelX
								cellContextMenu.cellY = cellItem.modelY
								var pos = mapToItem(scrollItem, mouse.x, mouse.y) // cellContextMenu is a child of scrollItem
								cellContextMenu.open(pos.x, pos.y)
							}
						}

					}
				}
			}
			PlasmaExtras.Menu {
				id: cellContextMenu
				property int cellX: -1
				property int cellY: -1

				PlasmaExtras.MenuItem {
					icon: "group-new"
					text: i18n("New Group")
					visible: !tileGrid.effectiveLocked
					onClicked: {
						var tile = tileGrid.addGroup(cellContextMenu.cellX, cellContextMenu.cellY)
						tileGrid.requestEditTile(tile)
					}
				}

				PlasmaExtras.MenuItem {
					icon: "view-presentation"
					text: i18n("New Hero Tile")
					visible: !tileGrid.effectiveLocked
					onClicked: {
						var tile = tileGrid.addHeroTile(cellContextMenu.cellX, cellContextMenu.cellY)
						tileGrid.requestEditTile(tile)
					}
				}

				TileGridPresets {
					id: tileGridPresets
					visible: !tileGrid.effectiveLocked
				}

				PlasmaExtras.MenuItem {
					icon: plasmoid.configuration.tilesLocked ? "object-unlocked" : "object-locked"
					text: plasmoid.configuration.tilesLocked ? i18n("Unlock Tiles") : i18n("Lock Tiles")
					// The global lock means nothing on generated content.
					visible: !tileGrid.readOnly
					onClicked: {
						plasmoid.configuration.tilesLocked = !plasmoid.configuration.tilesLocked
					}
				}
			}

			Repeater {
				id: groupPanelRepeater
				model: 0
				Item {
					readonly property int tileIndex: modelData
					readonly property var tile: tileGrid.tileModel[tileIndex]
					readonly property var groupArea: tile && tile.tileType === "group" ? tileGrid.getGroupAreaRect(tile) : null
					readonly property int headerH: (tile && typeof tile.h !== "undefined") ? tile.h : 1
					readonly property bool hasCustomColor: tile && typeof tile.backgroundColor !== "undefined"
					readonly property color tileColor: hasCustomColor ? tile.backgroundColor : "transparent"
					readonly property bool isCardLayout: plasmoid && plasmoid.configuration && plasmoid.configuration.tileGroupLayout === "card"
					visible: isCardLayout && !!groupArea
					z: -1
					x: tileGrid.previewX(tileIndex, tile) * cellBoxSize + _holoPad
					y: tileGrid.previewY(tileIndex, tile) * cellBoxSize + _holoPad
					Behavior on x { enabled: tileGrid.isDragging; NumberAnimation { duration: tileGrid.reflowAnimationDuration; easing.type: Easing.OutCubic } }
					Behavior on y { enabled: tileGrid.isDragging; NumberAnimation { duration: tileGrid.reflowAnimationDuration; easing.type: Easing.OutCubic } }
					width: (tile ? tile.w : 0) * cellBoxSize
					height: groupArea ? (tileGrid.previewGroupRows(tileIndex) || (headerH + groupArea.h)) * cellBoxSize : 0
					Behavior on height { enabled: tileGrid.isDragging; NumberAnimation { duration: tileGrid.reflowAnimationDuration; easing.type: Easing.OutCubic } }

					SidebarGlassCard {
						anchors.fill: parent
						anchors.leftMargin: tileGrid.groupPanelInsetX
						anchors.rightMargin: tileGrid.groupPanelInsetX
						anchors.topMargin: tileGrid.groupPanelInsetTop
						anchors.bottomMargin: tileGrid.groupPanelInsetBottom
						baseColor: parent.hasCustomColor
							? parent.tileColor
							: config.surfaceBaseColor
						contentMargins: 0
					}
				}
			}

			Repeater {
				id: tileModelRepeater
				model: 0
				
				TileItem {
					id: tileItem
				}
				
			}

			// Draw styled group headers above all tiles so they cannot be hidden by
			// sub-pixel overlap or neighboring items.
			Repeater {
				id: groupHeaderSeparatorRepeater
				model: 0
				Item {
					readonly property int tileIndex: modelData
					readonly property var tile: tileGrid.tileModel[tileIndex]
					readonly property int itemCount: tileGrid.countGroupTiles(tile)
					readonly property bool isCardLayout: plasmoid && plasmoid.configuration && plasmoid.configuration.tileGroupLayout === "card"
					visible: tile && tile.tileType === "group"
					z: 10000
					x: tileGrid.previewX(tileIndex, tile) * cellBoxSize + _holoPad + (isCardLayout ? tileGrid.groupPanelInsetX : 0)
					width: isCardLayout
						? Math.max(0, (tile ? tile.w : 0) * cellBoxSize - (tileGrid.groupPanelInsetX * 2))
						: (tile ? tile.w : 0) * cellBoxSize
					readonly property int headerH: (tile && typeof tile.h !== "undefined") ? tile.h : 1
					height: isCardLayout
						? Math.max(0, headerH * cellBoxSize - tileGrid.groupPanelInsetTop)
						: headerH * cellBoxSize
					y: tileGrid.previewY(tileIndex, tile) * cellBoxSize + _holoPad + (isCardLayout ? tileGrid.groupPanelInsetTop : 0)
					Behavior on x { enabled: tileGrid.isDragging; NumberAnimation { duration: tileGrid.reflowAnimationDuration; easing.type: Easing.OutCubic } }
					Behavior on y { enabled: tileGrid.isDragging; NumberAnimation { duration: tileGrid.reflowAnimationDuration; easing.type: Easing.OutCubic } }

					readonly property real sidePadding: isCardLayout
						? Math.round(4 * Screen.devicePixelRatio) + Kirigami.Units.smallSpacing
						: Kirigami.Units.smallSpacing
					readonly property real rowTopPadding: Math.max(0, (height - headerRow.implicitHeight) / 2)
					readonly property real separatorHeight: 2 / Screen.devicePixelRatio
							Item {
								id: headerRow
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.leftMargin: parent.sidePadding
								anchors.rightMargin: parent.sidePadding
								anchors.topMargin: parent.rowTopPadding
								implicitHeight: Math.max(titleLabel.implicitHeight, countLabel.implicitHeight)
								readonly property real separatorSpacing: Kirigami.Units.largeSpacing
								readonly property real minimumSeparatorWidth: Kirigami.Units.gridUnit * 2
								readonly property bool reversed: plasmoid.configuration.groupLabelAlignment === "right"
								readonly property real countWidth: countLabel.visible ? countLabel.implicitWidth : 0
								readonly property real titleWidth: Math.min(
									titleLabel.implicitWidth,
									parent.parent.isCardLayout
										? Math.max(0, headerRow.width - countWidth - separatorSpacing)
										: Math.max(0, headerRow.width - countWidth - (separatorSpacing * 2) - minimumSeparatorWidth)
								)

								QQC2.Label {
									id: titleLabel
									x: headerRow.reversed ? headerRow.width - width : 0
									y: (parent.height - height) / 2
									width: headerRow.titleWidth
									text: tile && tile.label ? tile.label : ""
									font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
									font.bold: true
									font.capitalization: parent.parent.isCardLayout ? Font.MixedCase : Font.AllUppercase
									color: Kirigami.Theme.textColor
									opacity: 0.92
									horizontalAlignment: headerRow.reversed ? Text.AlignRight : Text.AlignLeft
									elide: headerRow.reversed ? Text.ElideLeft : Text.ElideRight
								}

						QQC2.Label {
							id: countLabel
							visible: !(tile && tile.hideCount)
							width: visible ? implicitWidth : 0
							x: headerRow.reversed ? 0 : headerRow.width - width
							y: (parent.height - height) / 2
							text: i18np("%1 tile", "%1 tiles", parent.parent.itemCount)
							font.pointSize: Kirigami.Theme.defaultFont.pointSize
							color: Kirigami.Theme.textColor
							opacity: 0.38
						}

						Rectangle {
							id: lineRect
							visible: !parent.parent.isCardLayout && width > 0
							x: headerRow.reversed
								? countLabel.x + countLabel.width + headerRow.separatorSpacing
								: titleLabel.x + titleLabel.width + headerRow.separatorSpacing
							y: (parent.height - height) / 2
							width: headerRow.reversed
								? Math.max(0, titleLabel.x - x - headerRow.separatorSpacing)
								: Math.max(0, countLabel.x - x - headerRow.separatorSpacing)
							height: parent.parent.separatorHeight
							color: Kirigami.Theme.textColor
							opacity: 0.14
						}
					}
				}
			}
		}

	}

	// Tile delegates use MouseAreas for clicks and dragging. Handle wheel input
	// at the tile-area level so scrolling works anywhere over the grid.
	WheelHandler {
		id: tileGridWheelHandler
		target: null
		orientation: Qt.Vertical
		acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
		onWheel: function(event) {
			var dy = 0
			if (event.pixelDelta && event.pixelDelta.y) {
				dy = event.pixelDelta.y
			} else if (event.angleDelta && event.angleDelta.y) {
				dy = (event.angleDelta.y / 120) * (Kirigami.Units.gridUnit * 3)
			}
			if (dy === 0) {
				return
			}

			scrollView.scrollBy(-dy)
			event.accepted = true
		}
	}

	Loader {
		id: tileGridSplashLoader
		anchors.centerIn: parent
		active: tileModel.length == 0 && !tileGrid.editing && !tileGrid.readOnly
		visible: active && width <= parent.width
		source: "TileGridSplash.qml"
		property alias tileGridPresets: tileGridPresets
		property int maxWidth: parent.width
	}

	Kirigami.PlaceholderMessage {
		anchors.centerIn: parent
		width: parent.width - Kirigami.Units.gridUnit * 4
		visible: tileGrid.readOnly && tileModel.length == 0
		icon.name: "view-statistics"
		text: tileGrid.emptyPlaceholderText
		explanation: tileGrid.emptyPlaceholderExplanation
	}

	/* Scroll on hover with drag */
	property int scrollAreaTickDelta: cellBoxSize
	property int scrollAreaTickInterval: 200
	property int scrollAreaSize: Math.min(cellBoxSize * 1.5, scrollView.height / 5) // 20vh or 90pt

	Item {
		id: scrollUpArea
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.top: parent.top
		height: scrollAreaSize
		property bool active: !scrollView.scrollAtTop
		property bool containsDrag: false
		property bool ticking: active && containsDrag

		function checkContains(event) {
			containsDrag = scrollUpArea.contains(Qt.point(event.x, event.y))
		}

		Timer {
			id: scrollUpTicker
			interval: scrollAreaTickInterval
			repeat: true
			running: parent.ticking
			onTriggered: {
				scrollView.scrollBy(-scrollAreaTickDelta)
			}
		}

		Rectangle {
			anchors.fill: parent
			opacity: parent.ticking ? 1 : 0
			gradient: Gradient {
				GradientStop { position: 0.0; color: Kirigami.Theme.highlightColor }
				GradientStop { position: 0.3; color: "transparent" }
			}
		}
	}

	Item {
		id: scrollDownArea
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		height: scrollAreaSize
		property bool active: !scrollView.scrollAtBottom
		property bool containsDrag: false
		property bool ticking: active && containsDrag

		function checkContains(event) {
			var mouseY = event.y - (parent.height - height)
			containsDrag = scrollDownArea.contains(Qt.point(event.x, mouseY))
		}

		Timer {
			id: scrollDownTicker
			interval: scrollAreaTickInterval
			repeat: true
			running: parent.ticking
			onTriggered: {
				scrollView.scrollBy(scrollAreaTickDelta)
			}
		}

		Rectangle {
			anchors.fill: parent
			opacity: parent.ticking ? 1 : 0
			gradient: Gradient {
				GradientStop { position: 0.7; color: "transparent" }
				GradientStop { position: 1.0; color: Kirigami.Theme.highlightColor }
			}
		}
	}

	function newTile(url) {
		return {
			"x": 0,
			"y": 0,
			"w": 2,
			"h": 2,
			"url": url,
		}
	}

	function newAppTile(url, props) {
		var launchUrl = "" + url
		var favoriteId = Utils.parseDropUrl(launchUrl)
		var tile = newTile(favoriteId)
		tile.favoriteId = favoriteId
		tile.launchUrl = launchUrl
		if (props && typeof props === "object") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				if (key === "url") {
					tile.launchUrl = value
					continue
				}
				tile[key] = value
			}
		}
		return tile
	}

	function removeIndex(i) {
		if (readOnly) return
		var target = tileModel[i]
		if (target && target.tileType === "group") {
			var area = getGroupAreaRect(target)
			for (var j = tileModel.length - 1; j >= 0; j--) {
				var tile = tileModel[j]
				if (!tile) {
					continue
				}
				if (tile === target || tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
					tileModel.splice(j, 1)
				}
			}
		} else {
			tileModel.splice(i, 1) // remove 1 item at index
		}
		tileModelChanged()
	}

	function removeApp(url) {
		if (readOnly) return
		url = "" + url
		var removedCount = 0
		for (var i = tileModel.length - 1; i >= 0; i--) {
			var tile = tileModel[i]
			if (tile.url == url || tile.favoriteId == url || tile.launchUrl == url) {
				removedCount += 1
				tileModel.splice(i, 1) // remove 1 item at index
			}
		}
		if (removedCount > 0) {
			tileModelChanged()
		}
	}

	function findOpenPos(w, h) {
		for (var y = 0; y < rows; y++) {
			for (var x = 0; x < columns - (w-1); x++) {
				if (hits(x, y, w, h))
					continue

				// Room open for
				return {
					x: x,
					y: y,
				}
			}
		}

		// Current grid has no room.
		// Add to new row.
		return {
			x: 0,
			y: rows
		}
	}

	function parseTileXY(tile, x, y) {
		if (typeof x !== "undefined" && typeof y !== "undefined") {
			tile.x = x
			tile.y = y
		} else {
			var openPos = findOpenPos(tile.w, tile.h)
			tile.x = openPos.x
			tile.y = openPos.y
		}
	}
	function addApp(url, x, y, props) {
		if (readOnly) return null
		var tile = newAppTile(url, props)
		parseTileXY(tile, x, y)
		tileModel.push(tile)
		tileModelChanged()
		return tile
	}

	function hasAppTile(url) {
		url = "" + url
		for (var i = 0; i < tileModel.length; i++) {
			var tile = tileModel[i]
			if (tile.url == url || tile.favoriteId == url || tile.launchUrl == url) {
				return true
			}
		}
		return false
	}

	function limit(minValue, value, maxValue) {
		return Math.max(minValue, Math.min(value, maxValue))
	}

	function addTile(x, y, props) {
		if (readOnly) return null
		var tile = newTile("")
		parseTileXY(tile, x, y)
		if (typeof props !== "undefined") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				tile[key] = value
			}
		}
		tileModel.push(tile)
		tileModelChanged()
		return tile
	}

	function addGroup(x, y, props) {
		var groupProps = {
			tileType: "group",
			label: i18nc("default group label", "Group"),
			w: limit(2, columns-x, 6), // 6 unless we have less columns.
			h: 1,
		}
		if (typeof props !== "undefined") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				groupProps[key] = value
			}
		}
		return addTile(x, y, groupProps)
	}

	function addHeroTile(x, y, props) {
		var heroProps = {
			tileType: "hero",
			w: limit(2, columns-x, 6),
			h: 3,
			subTiles: [{
				backgroundImage: "",
				launchUrl: "",
				label: "",
				iconName: "",
				showDownloadedInfo: false,
				storeTitle: "",
				storeDescription: "",
				igdbTags: [],
				steamAppId: "",
			}],
			autoScrollEnabled: true,
			autoScrollInterval: 5000,
		}
		if (typeof props !== "undefined") {
			var keys = Object.keys(props)
			for (var i = 0; i < keys.length; i++) {
				var key = keys[i]
				var value = props[key]
				heroProps[key] = value
			}
		}
		return addTile(x, y, heroProps)
	}

	function appendHeroPage(tile, url, favoriteId) {
		if (readOnly) return
		if (!tile || tile.tileType !== "hero") return
		var resolvedFav = favoriteId || Utils.parseDropUrl(url || "")
		var app = (resolvedFav && appsModel) ? appsModel.getTileApp(resolvedFav) : null
		var iconName = app ? ("" + app.decoration) : ""
		var appLabel = app ? ("" + app.display) : ""
		var page = {
			backgroundImage: "",
			iconName: iconName,
			label: appLabel,
			launchUrl: url || "",
			showDownloadedInfo: false,
			storeTitle: "",
			storeDescription: "",
			igdbTags: [],
			steamAppId: "",
		}
		var arr = (tile.subTiles || []).slice()
		if (arr.length === 1 && !arr[0].backgroundImage && !arr[0].launchUrl && !arr[0].iconName) {
			arr[0] = page
		} else {
			arr.push(page)
		}
		tile.subTiles = arr
		tileModelChanged()
	}

	function findHeroTileAt(cellX, cellY) {
		if (!tileModel) return null
		for (var i = 0; i < tileModel.length; i++) {
			var t = tileModel[i]
			if (!t || t.tileType !== "hero") continue
			if (cellX >= t.x && cellX < t.x + t.w && cellY >= t.y && cellY < t.y + t.h) {
				return t
			}
		}
		return null
	}

	// Use for quickly testing on widget load
	function addDefaultTiles() {
		if (readOnly) return
		tileGridPresets.addDefault()
	}

	// Emits the tile's index rather than the tile: a JS object passed through a
	// `var` signal parameter arrives as a copy, so the editor would edit a tile
	// detached from tileModel and none of its changes would reach the grid.
	function requestEditTile(tile) {
		if (readOnly) return
		var tileIndex = tileModel.indexOf(tile)
		if (tileIndex >= 0) {
			editTile(tileIndex)
		}
	}

	signal editTile(int tileIndex)
}
