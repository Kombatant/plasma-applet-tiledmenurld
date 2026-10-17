import QtQuick
import QtTest
import "../contents/ui/lib/MostUsedLayout.js" as MostUsedLayout
import "../contents/ui/lib/TileTabs.js" as TileTabs
import "../contents/ui/Utils.js" as Utils
import "../contents/ui/libconfig" as LibConfig

TestCase {
	id: testCase
	name: "MostUsed"
	function i18n(text) { return text }
	property var plasmoid: ({ configuration: { numMostUsedApps: 10 } })

	LibConfig.FormKCM {
		id: settingsPage
		cfg_numMostUsedApps: 10
		cfg_numMostUsedAppsDefault: 10
		LibConfig.SpinBox {
			id: numMostUsedSpinBox
			configKey: "numMostUsedApps"
			minimumValue: 1
			maximumValue: 15
		}
	}

	readonly property var categories: ({
		"firefox.desktop": "Internet",
		"thunderbird.desktop": "Internet",
		"org.kde.kate.desktop": "Development",
		"org.kde.kwrite.desktop": "Development",
		"org.kde.konsole.desktop": "System",
		"libreoffice-writer.desktop": "Office",
	})

	function select(ranked, limit, installed) {
		return MostUsedLayout.selectEntries(ranked, {
			limit: limit,
			normalize: function(value) { return Utils.kickerFavoriteId(value) },
			isInstalled: function(id) { return !installed || installed.indexOf(id) >= 0 },
			categoryOf: function(id) { return testCase.categories[id] || "" },
		})
	}

	function ids(entries) {
		return entries.map(function(e) { return e.favoriteId })
	}

	function appTiles(tiles) {
		return tiles.filter(function(t) { return t.tileType !== "group" })
	}

	function groupTiles(tiles) {
		return tiles.filter(function(t) { return t.tileType === "group" })
	}

	function test_selectionKeepsRankAndLimit() {
		var ranked = [
			"applications:firefox.desktop",
			"applications:org.kde.kate.desktop",
			"applications:org.kde.konsole.desktop",
		]
		compare(ids(select(ranked, 2)), ["firefox.desktop", "org.kde.kate.desktop"])
		compare(select(ranked, 0).length, 0)
	}

	function test_selectionDedupesAndNormalizes() {
		var ranked = [
			"applications:firefox.desktop",
			"firefox.desktop",
			"/usr/share/applications/firefox.desktop",
			"",
			"https://example.com",
			"applications:org.kde.kate.desktop",
		]
		compare(ids(select(ranked, 10)), ["firefox.desktop", "org.kde.kate.desktop"])
	}

	function test_selectionSkipsUninstalledBeforeLimit() {
		var ranked = ["applications:gone.desktop", "applications:firefox.desktop", "applications:org.kde.kate.desktop"]
		compare(ids(select(ranked, 2, ["firefox.desktop", "org.kde.kate.desktop"])),
			["firefox.desktop", "org.kde.kate.desktop"])
	}

	function test_emptyHistory() {
		compare(select([], 10).length, 0)
		compare(MostUsedLayout.buildTiles([], 6, "Other").length, 0)
	}

	function test_groupsOrderedByBestRankOtherLast() {
		var entries = [
			{ favoriteId: "a.desktop", category: "" },
			{ favoriteId: "firefox.desktop", category: "Internet" },
			{ favoriteId: "org.kde.kate.desktop", category: "Development" },
			{ favoriteId: "thunderbird.desktop", category: "Internet" },
		]
		var groups = MostUsedLayout.groupEntries(entries, "Other")
		compare(groups.map(function(g) { return g.label }), ["Internet", "Development", "Other"])
		compare(groups[0].favoriteIds, ["firefox.desktop", "thunderbird.desktop"])
		compare(groups[2].favoriteIds, ["a.desktop"])
	}

	// Acceptance example: five apps in three categories give exactly five app
	// tiles in three groups, ordered by each group's best-ranked app.
	function test_fiveAppExample() {
		var ranked = [
			"applications:firefox.desktop",
			"applications:org.kde.kate.desktop",
			"applications:thunderbird.desktop",
			"applications:libreoffice-writer.desktop",
			"applications:org.kde.kwrite.desktop",
			"applications:org.kde.konsole.desktop",
		]
		var tiles = MostUsedLayout.buildTiles(select(ranked, 5), 6, "Other")
		compare(appTiles(tiles).length, 5)
		compare(groupTiles(tiles).map(function(g) { return g.label }), ["Internet", "Development", "Office"])
		compare(appTiles(tiles).map(function(t) { return t.favoriteId }), [
			"firefox.desktop", "thunderbird.desktop",
			"org.kde.kate.desktop", "org.kde.kwrite.desktop",
			"libreoffice-writer.desktop",
		])
	}

	function test_recentSkipsAppsAlreadyShown() {
		var popular = select(["applications:firefox.desktop", "applications:org.kde.kate.desktop"], 10)
		var recent = MostUsedLayout.selectEntries([
			"firefox.desktop",
			"Castlevania Belmont's Curse.desktop",
			"org.kde.kate.desktop",
			"org.kde.konsole.desktop",
			"thunderbird.desktop",
		], {
			limit: 2,
			normalize: function(value) { return Utils.kickerFavoriteId(value) },
			exclude: ids(popular),
		})
		// Excluded apps don't count against the limit.
		compare(ids(recent), ["Castlevania Belmont's Curse.desktop", "org.kde.konsole.desktop"])
	}

	function test_recentGroupComesFirst() {
		var entries = [
			{ favoriteId: "firefox.desktop", category: "Internet" },
			{ favoriteId: "a.desktop", category: "" },
		]
		var tiles = MostUsedLayout.buildTiles(entries, 6, "Other", {
			label: "Most Recent",
			favoriteIds: ["game.desktop", "org.kde.konsole.desktop"],
		})
		compare(groupTiles(tiles).map(function(g) { return g.label }), ["Most Recent", "Internet", "Other"])
		compare([groupTiles(tiles)[0].x, groupTiles(tiles)[0].y], [0, 0])
		compare(appTiles(tiles).map(function(t) { return t.favoriteId }),
			["game.desktop", "org.kde.konsole.desktop", "firefox.desktop", "a.desktop"])
		// An empty recent list adds no group.
		compare(groupTiles(MostUsedLayout.buildTiles(entries, 6, "Other", { label: "Most Recent", favoriteIds: [] })).length, 2)
		// Only recent history still produces tiles.
		compare(appTiles(MostUsedLayout.buildTiles([], 6, "Other", { label: "Most Recent", favoriteIds: ["game.desktop"] })).length, 1)
	}

	function test_tilesAreStandardAppTiles() {
		var tiles = MostUsedLayout.buildTiles([{ favoriteId: "firefox.desktop", category: "Internet" }], 6, "Other")
		var app = appTiles(tiles)[0]
		compare(app.w, 2)
		compare(app.h, 2)
		compare(app.url, "firefox.desktop")
		compare(app.favoriteId, "firefox.desktop")
		compare(app.launchUrl, "applications:firefox.desktop")
		compare(groupTiles(tiles)[0].hideCount, true)
	}

	function test_shelfPackingWithinColumns() {
		var entries = [
			{ favoriteId: "a1.desktop", category: "A" },
			{ favoriteId: "a2.desktop", category: "A" },
			{ favoriteId: "b1.desktop", category: "B" },
			{ favoriteId: "c1.desktop", category: "C" },
			{ favoriteId: "c2.desktop", category: "C" },
			{ favoriteId: "c3.desktop", category: "C" },
			{ favoriteId: "c4.desktop", category: "C" },
		]
		var tiles = MostUsedLayout.buildTiles(entries, 6, "Other")
		var groups = groupTiles(tiles)
		// A (2 tiles, w4) and B (1 tile, w2) share the first band.
		compare([groups[0].x, groups[0].y, groups[0].w], [0, 0, 4])
		compare([groups[1].x, groups[1].y, groups[1].w], [4, 0, 2])
		// C needs the full width and wraps below the band (header + 1 tile row).
		compare([groups[2].x, groups[2].y, groups[2].w], [0, 3, 6])
		for (var i = 0; i < tiles.length; i++) {
			verify(tiles[i].x + tiles[i].w <= 6, "tile within columns")
		}
		// C's 4 tiles wrap at 3 per row.
		var cTiles = appTiles(tiles).slice(3)
		compare(cTiles.map(function(t) { return [t.x, t.y] }), [[0, 4], [2, 4], [4, 4], [0, 6]])
		// No overlaps.
		var seen = {}
		for (var j = 0; j < tiles.length; j++) {
			var t = tiles[j]
			for (var y = t.y; y < t.y + t.h; y++) {
				for (var x = t.x; x < t.x + t.w; x++) {
					var key = x + "," + y
					verify(!seen[key], "overlap at " + key)
					seen[key] = true
				}
			}
		}
	}

	function test_narrowColumnBudget() {
		var tiles = MostUsedLayout.buildTiles([
			{ favoriteId: "a.desktop", category: "A" },
			{ favoriteId: "b.desktop", category: "A" },
		], 3, "Other")
		var apps = appTiles(tiles)
		compare(apps.map(function(t) { return [t.x, t.y] }), [[0, 1], [0, 3]])
		compare(groupTiles(tiles)[0].w, 2)
	}

	function assertNoOverlap(tiles) {
		var seen = {}
		for (var j = 0; j < tiles.length; j++) {
			var t = tiles[j]
			for (var y = t.y; y < t.y + t.h; y++) {
				for (var x = t.x; x < t.x + t.w; x++) {
					var key = x + "," + y
					verify(!seen[key], "overlap at " + key)
					seen[key] = true
				}
			}
		}
	}

	function test_groupKeys() {
		var groups = MostUsedLayout.groupEntries([
			{ favoriteId: "a.desktop", category: "A" },
			{ favoriteId: "b.desktop", category: "" },
		], "Other", { label: "Most Recent", favoriteIds: ["r.desktop"] })
		compare(groups.map(function(g) { return g.key }), ["recent", "category/A", "other"])
		var tiles = MostUsedLayout.layoutGroups(groups, 6)
		compare(groupTiles(tiles).map(function(g) { return g.groupKey }), ["recent", "category/A", "other"])
	}

	function test_savedPositionsKeepGroupsInPlace() {
		var entries = [
			{ favoriteId: "a1.desktop", category: "A" },
			{ favoriteId: "b1.desktop", category: "B" },
		]
		// B (at 2,0) dragged below A.
		var positions = { "category/A": { x: 0, y: 0 }, "category/B": { x: 0, y: 4 } }
		var tiles = MostUsedLayout.buildTiles(entries, 6, "Other", null, positions)
		var groups = groupTiles(tiles)
		compare([groups[0].x, groups[0].y], [0, 0])
		compare([groups[1].x, groups[1].y], [0, 4])
		// B's app follows its header.
		compare([appTiles(tiles)[1].x, appTiles(tiles)[1].y], [0, 5])
		// A gains apps and grows to 3 rows: B is pushed down, not overlapped.
		var grown = entries.concat([
			{ favoriteId: "a2.desktop", category: "A" },
			{ favoriteId: "a3.desktop", category: "A" },
			{ favoriteId: "a4.desktop", category: "A" },
			{ favoriteId: "a5.desktop", category: "A" },
			{ favoriteId: "a6.desktop", category: "A" },
			{ favoriteId: "a7.desktop", category: "A" },
		])
		var grownTiles = MostUsedLayout.buildTiles(grown, 6, "Other", null, positions)
		assertNoOverlap(grownTiles)
		var grownGroups = groupTiles(grownTiles)
		compare([grownGroups[0].x, grownGroups[0].y, grownGroups[0].w], [0, 0, 6])
		compare([grownGroups[1].x, grownGroups[1].y], [0, 7])
	}

	function test_unsavedGroupsTakeFirstFreeSpot() {
		var positions = { "category/A": { x: 0, y: 0 } }
		var tiles = MostUsedLayout.buildTiles([
			{ favoriteId: "a1.desktop", category: "A" },
			{ favoriteId: "c1.desktop", category: "C" },
		], 6, "Other", null, positions)
		assertNoOverlap(tiles)
		var groups = groupTiles(tiles)
		compare([groups[1].x, groups[1].y], [2, 0])
	}

	function test_savedPositionClampedIntoColumns() {
		var tiles = MostUsedLayout.buildTiles([
			{ favoriteId: "a1.desktop", category: "A" },
			{ favoriteId: "a2.desktop", category: "A" },
		], 6, "Other", null, { "category/A": { x: 5, y: 2 } })
		var group = groupTiles(tiles)[0]
		compare([group.x, group.y, group.w], [2, 2, 4])
	}

	function test_groupPositionsPersistOnMostUsedTabOnly() {
		var result = TileTabs.sanitizeTabs([
			{ id: "tab_1", name: "Main", tiles: [], groupPositions: { a: { x: 1, y: 1 } } },
			{ id: "tab_2", name: "Used", kind: "mostUsed", tiles: [], groupPositions: { good: { x: 2, y: 3 }, bad: { x: "q" }, neg: { x: -1, y: 0 } } },
		], 0)
		verify(result.changed)
		verify(typeof result.tabs[0].groupPositions === "undefined")
		compare(JSON.stringify(result.tabs[1].groupPositions), JSON.stringify({ good: { x: 2, y: 3 } }))
		var clean = TileTabs.sanitizeTabs([
			{ id: "tab_2", name: "Used", kind: "mostUsed", tiles: [], groupPositions: { good: { x: 2, y: 3 } } },
		], 0)
		verify(!clean.changed)
		var exported = TileTabs.normalizeForExport(result.tabs)
		verify(typeof exported[0].groupPositions === "undefined")
		compare(JSON.stringify(exported[1].groupPositions), JSON.stringify({ good: { x: 2, y: 3 } }))
		var copied = TileTabs.copyTab(result.tabs[1], { name: "Popular" })
		compare(copied.groupPositions.good.y, 3)
	}

	function test_entriesKey() {
		var a = [{ favoriteId: "a.desktop", category: "A" }]
		var b = [{ favoriteId: "a.desktop", category: "B" }]
		compare(MostUsedLayout.entriesKey(a), MostUsedLayout.entriesKey([{ favoriteId: "a.desktop", category: "A" }]))
		verify(MostUsedLayout.entriesKey(a) !== MostUsedLayout.entriesKey(b))
		verify(MostUsedLayout.entriesKey(a, ["x.desktop"]) !== MostUsedLayout.entriesKey(a, ["y.desktop"]))
	}

	// ── Tab descriptors ─────────────────────────────────────────────────────
	function test_sanitizeSeedsCounterAndDedupesIds() {
		var tabs = [
			{ id: "1", name: "Main", tiles: [] },
			{ id: "tab_1", name: "A", tiles: [] },
			{ id: "tab_1", name: "B", tiles: [] },
			{ id: "tab_4", name: "C", tiles: [] },
			{ name: "D", tiles: [] },
		]
		var result = TileTabs.sanitizeTabs(tabs, 0)
		verify(result.changed)
		compare(result.tabs.map(function(t) { return t.id }), ["1", "tab_1", "tab_5", "tab_4", "tab_6"])
		compare(result.idCounter, 6)
	}

	function test_sanitizeCleanLayoutUnchanged() {
		var tabs = [{ id: "1", name: "Main", tiles: [{ x: 0 }] }, { id: "tab_2", name: "B", tiles: [] }]
		var result = TileTabs.sanitizeTabs(tabs, 0)
		verify(!result.changed)
		compare(result.idCounter, 2)
		compare(result.tabs[0].tiles.length, 1)
		verify(typeof result.tabs[0].kind === "undefined", "legacy tabs stay manual")
	}

	function test_sanitizeKeepsFirstMostUsedAndStripsTiles() {
		var tabs = [
			{ id: "tab_1", name: "Used", kind: "mostUsed", tiles: [{ x: 0, url: "x.desktop" }] },
			{ id: "tab_2", name: "Dup", kind: "mostUsed", tiles: [] },
			{ id: "tab_3", name: "Weird", kind: "future", tiles: [] },
		]
		var result = TileTabs.sanitizeTabs(tabs, 0)
		verify(result.changed)
		compare(result.tabs.length, 2)
		compare(result.tabs[0].kind, "mostUsed")
		compare(result.tabs[0].tiles.length, 0)
		verify(typeof result.tabs[1].kind === "undefined")
	}

	function test_copyTabPreservesKind() {
		var tab = { id: "tab_1", name: "Used", icon: "a", kind: "mostUsed", tiles: [] }
		var renamed = TileTabs.copyTab(tab, { name: "Popular" })
		compare(renamed.kind, "mostUsed")
		compare(renamed.name, "Popular")
		compare(renamed.icon, "a")
		compare(tab.name, "Used")
	}

	function test_exportNormalization() {
		var out = TileTabs.normalizeForExport([
			{ id: 1, name: "Main", tiles: [{ x: 0 }] },
			{ id: "tab_2", name: "Used", kind: "mostUsed", tiles: [{ x: 1 }] },
			{ id: "tab_3", name: "Dup", kind: "mostUsed", tiles: [] },
			{ id: "tab_4", name: "Unknown", kind: "bogus", tiles: [] },
		])
		compare(out.length, 3)
		compare(out[0].id, "1")
		verify(typeof out[0].kind === "undefined")
		compare(out[0].tiles.length, 1)
		compare(out[1].kind, "mostUsed")
		compare(out[1].tiles.length, 0)
		verify(typeof out[2].kind === "undefined")
		// JSON round trip keeps kind.
		var roundTrip = TileTabs.normalizeForExport(JSON.parse(JSON.stringify(out)))
		compare(JSON.stringify(roundTrip), JSON.stringify(out))
	}

	// ── Setting staging ─────────────────────────────────────────────────────
	function test_settingStagesUntilApply() {
		compare(numMostUsedSpinBox.value, 10)
		// Step like the arrow buttons do; assigning `value` from the test would
		// break the control's binding to the staged config value.
		numMostUsedSpinBox.increase()
		// SpinBox throttles writes through a timer before staging them.
		tryCompare(settingsPage, "cfg_numMostUsedApps", 11)
		compare(plasmoid.configuration.numMostUsedApps, 10)
		// Defaults / Cancel reset the staged value and the control follows.
		settingsPage.cfg_numMostUsedApps = settingsPage.cfg_numMostUsedAppsDefault
		tryCompare(numMostUsedSpinBox, "value", 10)
	}
}
