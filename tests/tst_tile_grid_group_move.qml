import QtQuick
import QtTest
import "../contents/ui" as UI

// Loads a real TileGrid (with stubbed Plasma context) and checks that a group
// drag moves each group as a whole: header label, card panel and member
// tiles, both for the dragged group and for the ones it pushes aside.
TestCase {
	id: root
	name: "TileGridGroupMove"
	width: 800
	height: 800
	when: windowShown
	property var plasmoid: ({ configuration: { tileGroupLayout: "card", tilesLocked: false, tileHoverEffect: "none", groupLabelAlignment: "left" } })
	property var config: ({ surfaceBaseColor: "#333333", useTileTabs: false, tileModel: { value: [] } })
	property var appsModel: ({ getTileApp: function() { return null } })
	property var logger: null
	Item { id: popup; width: 800; height: 800 }

	UI.TileGrid {
		id: grid
		width: 6 * cellBoxSize
		height: 800
		cellSize: 60
		cellMargin: 3
		reflowColumns: 6
	}

	function twoGroups() {
		return [
			{ tileType: "group", label: "A", x: 0, y: 0, w: 2, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "a.desktop" },
			{ tileType: "group", label: "B", x: 2, y: 0, w: 2, h: 1 },
			{ x: 2, y: 1, w: 2, h: 2, url: "b.desktop" },
		]
	}

	function collect(item, pred, out) {
		out = out || []
		for (var i = 0; i < item.children.length; i++) {
			var child = item.children[i]
			if (pred(child)) {
				out.push(child)
			}
			collect(child, pred, out)
		}
		return out
	}

	// tileIndex -> "x,y" in cells for the group header/panel delegates.
	function groupCells(pred) {
		var out = {}
		var items = collect(grid, pred)
		for (var i = 0; i < items.length; i++) {
			out[items[i].tileIndex] = Math.round(items[i].x / grid.cellBoxSize) + "," + Math.round(items[i].y / grid.cellBoxSize)
		}
		return out
	}

	function cleanup() {
		grid.resetDrag()
		grid.reflowPreview = []
		grid.reflowPreviewHeights = []
		grid.tileModel = []
		grid.reflowDwellInterval = 300
		grid.reflowColumns = 6
		var flick = flickable()
		if (flick) {
			flick.contentY = 0
		}
	}

	function flickable() {
		var found = collect(grid, function(c) { return c.hasOwnProperty("contentY") && c.hasOwnProperty("flickableDirection") })
		return found.length ? found[0] : null
	}

	// Drag event position (grid coordinates) when the dragged item's
	// top-left sits on (cellX, cellY) at the current scroll. Internal drag
	// events report the item's top-left, not the pointer.
	function pointerFor(cellX, cellY) {
		var flick = flickable()
		var scroll = flick ? flick.contentY : 0
		return {
			x: cellX * grid.cellBoxSize + grid._holoPad,
			y: cellY * grid.cellBoxSize + grid._holoPad - scroll,
		}
	}

	function test_previewMovesWholeGroups() {
		grid.tileModel = twoGroups()
		var plan = grid.planGroupMove(0, 2, 0)
		grid.reflowPreview = plan.cells
		wait(grid.reflowAnimationDuration + 100)
		var headers = groupCells(function(c) { return c.hasOwnProperty("itemCount") && c.hasOwnProperty("tileIndex") })
		var panels = groupCells(function(c) { return c.hasOwnProperty("groupArea") && c.hasOwnProperty("tileIndex") })
		// A dragged onto B; B takes A's old spot.
		compare(headers[0], "2,0")
		compare(headers[2], "0,0")
		compare(panels[0], "2,0")
		compare(panels[2], "0,0")
		var tiles = collect(grid, function(c) { return c.hasOwnProperty("heroTileView") })
		var tileCells = tiles.map(function(t) { return Math.round(t.x / grid.cellBoxSize) + "," + Math.round(t.y / grid.cellBoxSize) })
		compare(tileCells, ["2,0", "2,1", "0,0", "0,1"])
	}

	function test_dropMovesWholeGroups() {
		grid.tileModel = twoGroups()
		grid.applyMove(0, 2, 0)
		var cells = grid.tileModel.map(function(t) { return t.x + "," + t.y })
		compare(cells, ["2,0", "2,1", "0,0", "0,1"])
	}

	function test_pushedLooseTileMovesAlone() {
		grid.tileModel = [
			{ tileType: "group", label: "A", x: 0, y: 0, w: 2, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "a.desktop" },
			{ x: 4, y: 0, w: 2, h: 2, url: "loose.desktop" },
		]
		grid.applyMove(0, 4, 0)
		var cells = grid.tileModel.map(function(t) { return t.x + "," + t.y })
		compare(cells.slice(0, 2), ["4,0", "4,1"])
		// The loose tile left the group's new cells.
		var loose = grid.tileModel[2]
		verify(loose.x + loose.w <= 4 || loose.y >= 3, cells.join(" "))
	}

	// ── Single tiles ────────────────────────────────────────────────────────
	function cellsOf(model) {
		return model.map(function(t) { return t.x + "," + t.y })
	}

	function assertNoOverlap(model) {
		var seen = {}
		for (var i = 0; i < model.length; i++) {
			var t = model[i]
			for (var y = t.y; y < t.y + (t.h || 1); y++) {
				for (var x = t.x; x < t.x + t.w; x++) {
					var key = x + "," + y
					verify(!seen[key], "overlap at " + key + " in " + cellsOf(model).join(" "))
					seen[key] = true
				}
			}
		}
	}

	function test_tileOntoLooseTilePushesIt() {
		grid.tileModel = [
			{ x: 0, y: 0, w: 2, h: 2, url: "a.desktop" },
			{ x: 0, y: 4, w: 2, h: 2, url: "b.desktop" },
		]
		grid.applyMove(1, 0, 0)
		compare(cellsOf(grid.tileModel)[1], "0,0")
		assertNoOverlap(grid.tileModel)
	}

	function test_tileToFreeCellMovesOnlyItself() {
		grid.tileModel = twoGroups()
		grid.tileModel.push({ x: 0, y: 6, w: 2, h: 2, url: "loose.desktop" })
		grid.applyMove(4, 4, 6)
		compare(cellsOf(grid.tileModel), ["0,0", "0,1", "2,0", "2,1", "4,6"])
	}

	function test_tileInsideGroupShufflesOnlyThatGroup() {
		// Group A is 4 wide with tiles at (0,1) and (2,1); B sits beside it.
		grid.tileModel = [
			{ tileType: "group", label: "A", x: 0, y: 0, w: 4, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "a1.desktop" },
			{ x: 2, y: 1, w: 2, h: 2, url: "a2.desktop" },
			{ tileType: "group", label: "B", x: 4, y: 0, w: 2, h: 1 },
			{ x: 4, y: 1, w: 2, h: 2, url: "b.desktop" },
			{ x: 0, y: 8, w: 2, h: 2, url: "loose.desktop" },
		]
		// Drop the loose tile onto a1.
		grid.applyMove(5, 0, 1)
		var cells = cellsOf(grid.tileModel)
		compare(cells[5], "0,1")
		// B didn't move; a1 stayed inside A's columns, below its header.
		compare(cells[3], "4,0")
		compare(cells[4], "4,1")
		var a1 = grid.tileModel[1]
		verify(a1.x >= 0 && a1.x + a1.w <= 4 && a1.y >= 1, cells.join(" "))
		assertNoOverlap(grid.tileModel)
	}

	function test_fullGroupGrowsAndPushesGroupBelow() {
		// A is 2 wide and full; C sits right below it.
		grid.tileModel = [
			{ tileType: "group", label: "A", x: 0, y: 0, w: 2, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "a.desktop" },
			{ tileType: "group", label: "C", x: 0, y: 3, w: 2, h: 1 },
			{ x: 0, y: 4, w: 2, h: 2, url: "c.desktop" },
			{ x: 4, y: 8, w: 2, h: 2, url: "loose.desktop" },
		]
		grid.applyMove(4, 0, 1)
		var cells = cellsOf(grid.tileModel)
		compare(cells[4], "0,1")
		// a stays in A by moving down under the new tile.
		compare(cells[1], "0,3")
		// C moved as a whole out of A's grown area.
		var c = grid.tileModel[2]
		var cTile = grid.tileModel[3]
		compare([cTile.x - c.x, cTile.y - c.y], [0, 1])
		verify(c.y >= 5 || c.x >= 2, cells.join(" "))
		assertNoOverlap(grid.tileModel)
	}

	function test_tileOntoHeaderPushesWholeGroup() {
		grid.tileModel = twoGroups()
		grid.tileModel.push({ x: 0, y: 6, w: 2, h: 2, url: "loose.desktop" })
		// Drop the loose tile on B's header.
		grid.applyMove(4, 2, 0)
		var cells = cellsOf(grid.tileModel)
		compare(cells[4], "2,0")
		var b = grid.tileModel[2]
		var bTile = grid.tileModel[3]
		compare([bTile.x - b.x, bTile.y - b.y], [0, 1])
		assertNoOverlap(grid.tileModel)
	}

	// ── Drag targeting ──────────────────────────────────────────────────────
	function test_dragTargetAccountsForScroll() {
		var model = []
		for (var i = 0; i < 12; i++) {
			model.push({ x: 0, y: i * 2, w: 2, h: 2, url: "t" + i + ".desktop" })
		}
		grid.tileModel = model
		wait(50)
		var flick = flickable()
		verify(flick, "found the scroll flickable")
		flick.contentY = 3 * grid.cellBoxSize
		compare(flick.contentY, 3 * grid.cellBoxSize)
		grid.startDrag(0)
		var p = pointerFor(4, 9)
		grid._dragItemTick(p.x, p.y)
		compare([grid.dropHoverX, grid.dropHoverY], [4, 9])
	}

	function test_snapNeedsMarginPastMidpoint() {
		compare(grid._snapCell(2.6, 2), 2)
		compare(grid._snapCell(2.75, 2), 3)
		compare(grid._snapCell(1.4, 2), 2)
		compare(grid._snapCell(1.25, 2), 1)
		compare(grid._snapCell(2.6, -1), 3)
	}

	function test_neighboursWaitForDwell() {
		grid.reflowDwellInterval = 150
		grid.tileModel = [
			{ x: 0, y: 0, w: 2, h: 2, url: "a.desktop" },
			{ x: 0, y: 4, w: 2, h: 2, url: "b.desktop" },
		]
		grid.startDrag(1)
		var p = pointerFor(0, 0)
		grid._dragItemTick(p.x, p.y)
		// The dragged tile is targeted right away; a waits.
		verify(!grid.reflowPreview[0], "neighbour not pushed before dwell")
		compare(grid.reflowPreview[1].y, 0)
		wait(250)
		verify(!!grid.reflowPreview[0], "neighbour pushed after dwell")
		// Back to a free cell: the neighbour returns immediately.
		p = pointerFor(4, 4)
		grid._dragItemTick(p.x, p.y)
		verify(!grid.reflowPreview[0], "neighbour restored when the conflict clears")
	}

	function test_previewGrowsGroupCard() {
		grid.reflowDwellInterval = 1
		grid.tileModel = [
			{ tileType: "group", label: "A", x: 0, y: 0, w: 2, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "a.desktop" },
			{ x: 4, y: 8, w: 2, h: 2, url: "loose.desktop" },
		]
		var plan = grid.planMove(2, 0, 1)
		// Header + two stacked 2-row tiles.
		compare(plan.heights[0], 5)
		grid.reflowPreview = plan.cells
		grid.reflowPreviewHeights = plan.heights
		wait(grid.reflowAnimationDuration + 100)
		var panels = collect(grid, function(c) { return c.hasOwnProperty("groupArea") && c.hasOwnProperty("tileIndex") })
		compare(panels.length, 1)
		compare(Math.round(panels[0].height / grid.cellBoxSize), 5)
	}

	function test_sameSizeDropSwapsWithoutGrowingGroup() {
		// The Metroidvania group from a real layout: dropping Divinum exactly
		// onto F.I.S.T. swaps them; Salt stays and the group keeps 4 rows.
		grid.reflowColumns = 12
		grid.tileModel = [
			{ tileType: "group", label: "Metroidvania", x: 0, y: 0, w: 12, h: 1 },
			{ x: 0, y: 1, w: 4, h: 2, url: "ninesols.desktop" },
			{ x: 4, y: 1, w: 2, h: 4, url: "pop.desktop" },
			{ x: 6, y: 1, w: 2, h: 4, url: "enderlilies.desktop" },
			{ x: 8, y: 1, w: 4, h: 2, url: "fist.desktop" },
			{ x: 0, y: 3, w: 4, h: 2, url: "divinum.desktop" },
			{ x: 8, y: 3, w: 4, h: 2, url: "salt.desktop" },
		]
		grid.applyMove(5, 8, 1)
		compare(cellsOf(grid.tileModel), ["0,0", "0,1", "4,1", "6,1", "0,3", "8,1", "8,3"])
		var area = grid.getGroupAreaRect(grid.tileModel[0])
		compare([area.y1, area.y2], [1, 4])
	}
}
