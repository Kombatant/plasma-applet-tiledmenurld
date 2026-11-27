import QtQuick
import QtTest
import "../contents/ui" as UI

// Loads a real TileGrid (with stubbed Plasma context) and checks the colour a
// launcher's body is drawn with at rest. Issue #41: a grouped tile whose only
// customisation is a background image must not paint the theme highlight
// behind it, or it shows through transparent PNGs.
TestCase {
	id: root
	name: "TileBackground"
	width: 800
	height: 800
	when: windowShown
	readonly property color highlight: "#3daee9"
	property var plasmoid: ({ configuration: { tileGroupLayout: "card", tilesLocked: false, tileHoverEffect: "none", groupLabelAlignment: "left" } })
	property var config: ({
		surfaceBaseColor: "#333333",
		useTileTabs: false,
		tileModel: { value: [] },
		plasmaStyleTileColor: root.highlight,
		defaultTileColor: root.highlight,
		defaultTileGradient: false,
		groupedTilesUseStandaloneBackground: false,
	})
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

	// "x,y" cell -> the TileItemView drawn there.
	function viewsByCell() {
		var out = {}
		var views = collect(grid, function(item) { return typeof item.renderedBodyColor !== "undefined" })
		for (var i = 0; i < views.length; i++) {
			var tileItem = views[i].parent
			while (tileItem && tileItem.parent && typeof tileItem.heroTileView === "undefined") {
				tileItem = tileItem.parent
			}
			out[Math.round(tileItem.x / grid.cellBoxSize) + "," + Math.round(tileItem.y / grid.cellBoxSize)] = views[i]
		}
		return out
	}

	function cleanup() {
		grid.tileModel = []
	}

	function test_groupedImageOnlyTileIsTransparent() {
		grid.tileModel = [
			{ tileType: "group", label: "Folders", x: 0, y: 0, w: 4, h: 1 },
			{ x: 0, y: 1, w: 2, h: 2, url: "plain.desktop" },
			{ x: 2, y: 1, w: 2, h: 2, url: "image.desktop", backgroundImage: "file:///nonexistent/folder.png" },
			{ x: 0, y: 3, w: 2, h: 2, url: "colour.desktop", backgroundImage: "file:///nonexistent/folder.png", backgroundColor: "#ff0000" },
			{ x: 4, y: 1, w: 2, h: 2, url: "loose.desktop", backgroundImage: "file:///nonexistent/folder.png" },
		]
		var views = viewsByCell()
		// Group-panel tile: transparent, the card shows through.
		compare(views["0,1"].renderedBodyColor.a, 0)
		// Image-only grouped tile: transparent too, not the theme highlight.
		compare(views["2,1"].renderedBodyColor.a, 0)
		compare(views["2,1"].color.a, 0)
		// An explicit colour still wins.
		verify(Qt.colorEqual(views["0,3"].renderedBodyColor, "#ff0000"))
		// A loose tile keeps following the standalone default colour.
		verify(Qt.colorEqual(views["4,1"].renderedBodyColor, root.highlight))
	}
}
