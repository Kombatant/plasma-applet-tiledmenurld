import QtQuick
import QtTest
import "../contents/ui/lib/GroupReflow.js" as GroupReflow

TestCase {
	name: "GroupReflow"

	function cells(result) {
		return result.map(function(p) { return [p.x, p.y] })
	}

	function assertNoOverlap(units, result) {
		var seen = {}
		for (var i = 0; i < units.length; i++) {
			for (var y = result[i].y; y < result[i].y + units[i].h; y++) {
				for (var x = result[i].x; x < result[i].x + units[i].w; x++) {
					var key = x + "," + y
					verify(!seen[key], "overlap at " + key)
					seen[key] = true
				}
			}
		}
	}

	function test_moveToFreeCellsLeavesOthers() {
		var units = [
			{ x: 0, y: 0, w: 2, h: 3 },
			{ x: 2, y: 0, w: 2, h: 3 },
		]
		var result = GroupReflow.resolve(units, 0, 0, 5, 6)
		compare(cells(result), [[0, 5], [2, 0]])
	}

	function test_landedOnNeighbourSwaps() {
		// A dropped onto its neighbour B: B takes the spot A left.
		var units = [
			{ x: 0, y: 0, w: 2, h: 3 },
			{ x: 2, y: 0, w: 2, h: 3 },
		]
		var result = GroupReflow.resolve(units, 0, 2, 0, 6)
		compare(cells(result), [[2, 0], [0, 0]])
		assertNoOverlap(units, result)
	}

	function test_landedOnUnitMovesAside() {
		// A dropped onto B from further away: B steps to the nearest free spot.
		var units = [
			{ x: 0, y: 6, w: 2, h: 3 },
			{ x: 2, y: 0, w: 2, h: 3 },
		]
		// A lands half over B: B shifts one cell right, out of the way.
		var result = GroupReflow.resolve(units, 0, 1, 0, 6)
		compare(cells(result), [[1, 0], [3, 0]])
		assertNoOverlap(units, result)
	}

	function test_landedOnUnitPrefersDownOverUp() {
		// Full-width rows: dropping A onto B pushes B below A, not above.
		var units = [
			{ x: 0, y: 0, w: 6, h: 3 },
			{ x: 0, y: 3, w: 6, h: 3 },
		]
		var result = GroupReflow.resolve(units, 0, 0, 2, 6)
		compare(cells(result), [[0, 2], [0, 5]])
		assertNoOverlap(units, result)
	}

	function test_dropInBetweenPushesNeighbours() {
		// A, B, C side by side; D dropped across B and C.
		var units = [
			{ x: 0, y: 0, w: 2, h: 2 },
			{ x: 2, y: 0, w: 2, h: 2 },
			{ x: 4, y: 0, w: 2, h: 2 },
			{ x: 0, y: 4, w: 4, h: 2 },
		]
		var result = GroupReflow.resolve(units, 3, 2, 0, 6)
		compare([result[3].x, result[3].y], [2, 0])
		compare([result[0].x, result[0].y], [0, 0])
		assertNoOverlap(units, result)
		// B and C stay close to where they were.
		verify(result[1].y <= 2 && result[2].y <= 2, JSON.stringify(result))
	}

	function test_targetClampedIntoColumns() {
		var units = [{ x: 0, y: 0, w: 4, h: 2 }]
		var result = GroupReflow.resolve(units, 0, 5, -3, 6)
		compare(cells(result), [[2, 0]])
	}

	function test_displacedUnitsNeverOverlap() {
		var units = []
		for (var i = 0; i < 9; i++) {
			units.push({ x: (i % 3) * 2, y: Math.floor(i / 3) * 2, w: 2, h: 2 })
		}
		units.push({ x: 0, y: 6, w: 6, h: 3 })
		var result = GroupReflow.resolve(units, 9, 0, 1, 6)
		assertNoOverlap(units, result)
		compare([result[9].x, result[9].y], [0, 1])
	}

	function test_invalidMovedIndexIsNoop() {
		var units = [{ x: 1, y: 1, w: 1, h: 1 }]
		compare(cells(GroupReflow.resolve(units, 4, 0, 0, 6)), [[1, 1]])
	}

	function test_stackPushKeepsOrder() {
		// A, B, C stacked; dragging A down a row pushes B and C down together
		// instead of B jumping past C.
		var units = [
			{ x: 0, y: 0, w: 6, h: 3 },
			{ x: 0, y: 3, w: 6, h: 3 },
			{ x: 0, y: 6, w: 6, h: 3 },
		]
		var result = GroupReflow.resolve(units, 0, 0, 1, 6)
		compare(cells(result), [[0, 1], [0, 4], [0, 7]])
	}

	function test_costPrefersFewerSmallerMovesWithoutSwaps() {
		var units = [
			{ x: 0, y: 0, w: 2, h: 2 },
			{ x: 0, y: 2, w: 2, h: 2 },
			{ x: 0, y: 4, w: 2, h: 2 },
		]
		var none = [{ x: 0, y: 0 }, { x: 0, y: 2 }, { x: 0, y: 4 }]
		var swapped = [{ x: 0, y: 0 }, { x: 0, y: 4 }, { x: 0, y: 2 }]
		var shifted = [{ x: 0, y: 0 }, { x: 0, y: 3 }, { x: 0, y: 5 }]
		compare(GroupReflow.arrangementCost(units, 0, none), 0)
		verify(GroupReflow.arrangementCost(units, 0, shifted) < GroupReflow.arrangementCost(units, 0, swapped))
	}

	function test_exactSameSizeDropSwapsAcrossTheGroup() {
		// Same-size units far apart: dropping one exactly on the other swaps
		// them rather than pushing neighbours or growing downward.
		var units = [
			{ x: 0, y: 2, w: 4, h: 2 },
			{ x: 4, y: 0, w: 2, h: 4 },
			{ x: 8, y: 0, w: 4, h: 2 },
			{ x: 8, y: 2, w: 4, h: 2 },
		]
		var result = GroupReflow.resolve(units, 0, 8, 0, 12)
		compare(cells(result), [[8, 0], [4, 0], [0, 2], [8, 2]])
	}

	function test_swapNeedsFreeOldSpot() {
		// The old spot overlaps the drop target, so no swap: push instead.
		var units = [
			{ x: 0, y: 0, w: 2, h: 2 },
			{ x: 0, y: 1, w: 2, h: 2 },
		]
		var result = GroupReflow.resolve(units, 0, 0, 1, 6)
		compare(result[0].y, 1)
		verify(result[1].y >= 3 || result[1].x >= 2, JSON.stringify(result))
	}

	function test_growthCostsMore() {
		var units = [
			{ x: 0, y: 0, w: 2, h: 2 },
			{ x: 2, y: 0, w: 2, h: 2 },
		]
		var sideways = [{ x: 0, y: 0 }, { x: 4, y: 0 }]
		var below = [{ x: 0, y: 0 }, { x: 2, y: 2 }]
		verify(GroupReflow.arrangementCost(units, 0, sideways) < GroupReflow.arrangementCost(units, 0, below))
	}
}
