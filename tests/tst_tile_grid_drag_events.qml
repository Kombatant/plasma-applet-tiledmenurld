import QtQuick
import QtTest
import "../contents/ui" as UI

// Drives real internal drag events from a TileItem delegate into TileGrid's
// DropArea (the path a mouse drag takes), so the drop cell is checked against
// what Qt actually reports: the dragged item's top-left, not the pointer.
// The root is an Item because a TestCase root never receives drag events.
Item {
	id: root
	width: 800
	height: 800
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
		reflowDwellInterval: 1
	}

	TestCase {
		name: "TileGridDragEvents"
		when: windowShown

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

		function delegateAt(cellX, cellY) {
			var tiles = collect(grid, function(c) { return c.hasOwnProperty("heroTileView") })
			for (var i = 0; i < tiles.length; i++) {
				if (Math.round((tiles[i].x - grid._holoPad) / grid.cellBoxSize) === cellX
						&& Math.round((tiles[i].y - grid._holoPad) / grid.cellBoxSize) === cellY) {
					return tiles[i]
				}
			}
			return null
		}

		function cleanup() {
			grid.resetDrag()
			grid.tileModel = []
		}

		// Moves a delegate the way drag.target does during a drag and returns
		// the cell the grid targets.
		function dragDelegateTo(delegate, modelIndex, cellX, cellY) {
			grid.startDrag(modelIndex)
			delegate.Drag.start()
			delegate.x = cellX * grid.cellBoxSize + grid._holoPad
			delegate.y = cellY * grid.cellBoxSize + grid._holoPad
			wait(30)
			var target = [grid.dropHoverX, grid.dropHoverY]
			delegate.Drag.cancel()
			return target
		}

		function test_wideGroupTargetsWhereItIs() {
			// A 6-wide group header: grabbing it anywhere must not pull the
			// target toward the left edge.
			grid.tileModel = [
				{ tileType: "group", label: "A", x: 0, y: 0, w: 4, h: 1 },
				{ x: 0, y: 1, w: 2, h: 2, url: "a.desktop" },
			]
			wait(30)
			var header = delegateAt(0, 0)
			verify(header, "found the header delegate")
			compare(dragDelegateTo(header, 0, 2, 4), [2, 4])
		}

		function test_tileTargetsWhereItIs() {
			grid.tileModel = [
				{ x: 0, y: 0, w: 2, h: 2, url: "a.desktop" },
			]
			wait(30)
			var tile = delegateAt(0, 0)
			verify(tile, "found the tile delegate")
			compare(dragDelegateTo(tile, 0, 3, 2), [3, 2])
		}
	}
}
