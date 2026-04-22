import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as QtDialogs
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import "lib/Base64.js" as Base64

MouseArea {
	id: popup
	focus: true

	Keys.priority: Keys.BeforeItem
	Keys.onPressed: function(event) {
		// Preserve Esc behavior (handled by focused controls / default handlers).
		if (event.key === Qt.Key_Escape) {
			return
		}

		// Don't steal modifier shortcuts.
		if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
			return
		}

		// Only for "typing" keys; ignore navigation keys, etc.
		if (!event.text || event.text.length === 0) {
			return
		}
		var code = event.text.charCodeAt(0)
		if (isNaN(code) || code < 0x20 || code === 0x7f) {
			return
		}

		// If the user is already typing into another input, don't override.
		var afi = Qt.application.activeFocusItem
		if (afi && typeof afi.insert === "function" && searchView.searchField && afi !== searchView.searchField.inputItem) {
			return
		}

		// Ensure the search UI is visible (covers TilesOnly mode).
		if (searchView && typeof searchView.showSearchView === "function") {
			searchView.showSearchView()
		}

		if (searchView && typeof searchView.focusAndInsert === "function") {
			event.accepted = true
			searchView.focusAndInsert(event.text)
		}
	}
	property alias searchView: searchView
	property alias appsView: searchView.appsView
	property alias tileEditorView: searchView.tileEditorView
	property alias tileEditorViewLoader: searchView.tileEditorViewLoader
	property alias tileGrid: tileGrid
	property var aiChatModel
	property real _lastKnownDevicePixelRatio: 1
	property real _lastRestoreDevicePixelRatio: 0
	property bool _pendingDprSyncRestore: false
	readonly property bool widgetExpanded: (typeof widget !== "undefined" && widget && typeof widget.expanded !== "undefined") ? widget.expanded : false
	readonly property int minimumPopupWidth: config.minimumPopupWidth
	readonly property int popupLeftSectionWidth: config.popupLeftSectionWidth
	property string _pendingRestoreView: ""
	property string _lastAppliedRestoreKey: ""
	property bool _restoreQueuedWhileCollapsed: false

	// ── Tile Tabs ─────────────────────────────────────────────────────────────
	property int activeTabIndex: 0
	property int _previousTabIndex: -1
	property var tileTabsData: []   // [{id: string, name: string, tiles: [tileObj]}]
	property bool _tabsWriting: false  // suppress config-change reload during save
	property int _tabIdCounter: 0   // monotonic counter for unique tab IDs

	// Keyword → icon mapping for tab name → symbolic icon.
	function inferTabIcon(name) {
		var n = (name || "").toLowerCase()
		var map = [
			[["game", "gaming", "steam", "play"], "applications-games"],
			[["music", "audio", "sound", "spotify"], "applications-multimedia"],
			[["video", "movie", "film", "stream", "youtube", "vlc"], "camera-video"],
			[["work", "office", "productivity", "business"], "applications-office"],
			[["dev", "code", "programming", "develop", "terminal", "ide"], "applications-development"],
			[["web", "browser", "internet", "firefox", "chrome", "chromium"], "applications-internet"],
			[["social", "chat", "message", "discord", "telegram", "signal"], "applications-chat"],
			[["mail", "email", "e-mail"], "mail-message"],
			[["photo", "image", "picture", "graphic", "design", "art", "gimp", "inkscape"], "applications-graphics"],
			[["tool", "utility", "utilities", "system", "settings", "config"], "applications-utilities"],
			[["science", "math", "education", "learn"], "applications-science"],
			[["file", "folder", "document", "documents", "files", "dolphin"], "system-file-manager"],
			[["download", "torrent", "transfer"], "folder-download"],
			[["security", "privacy", "password", "vault", "encrypt"], "security-high"],
			[["network", "vpn", "server", "remote", "ssh"], "network-workgroup"],
			[["favorite", "favourite", "starred", "pinned", "bookmark"], "starred"],
			[["main", "home", "start", "all", "general", "default", "application"], "go-home"],
			[["new", "recent", "latest"], "document-new"],
		]
		for (var i = 0; i < map.length; i++) {
			var keywords = map[i][0]
			var icon = map[i][1]
			for (var j = 0; j < keywords.length; j++) {
				if (n.indexOf(keywords[j]) >= 0) return icon
			}
		}
		return ""
	}

	readonly property var activeTabTiles: {
		if (!config.useTileTabs || tileTabsData.length === 0) {
			return config.tileModel.value
		}
		var idx = Math.min(activeTabIndex, tileTabsData.length - 1)
		if (idx < 0) {
			return []
		}
		return tileTabsData[idx].tiles || []
	}

	function loadTileTabs() {
		var raw = plasmoid.configuration.tileTabs || ''
		if (!raw) {
			// First-time enable: migrate existing single tileModel into tab "Main"
			var existingTiles = (config.tileModel && config.tileModel.value)
				? config.tileModel.value.slice()
				: []
			tileTabsData = [{
				id: '1',
				name: i18n('Main'),
				icon: 'go-home',
				tiles: existingTiles,
			}]
			popup.saveTileTabs()
		} else {
			try {
				var decoded = Base64.decodeString(raw)
				var parsed = JSON.parse(decoded)
				if (!Array.isArray(parsed) || parsed.length === 0) {
					tileTabsData = [{id: '1', name: i18n('Main'), icon: 'go-home', tiles: []}]
				} else {
					tileTabsData = parsed
					// Backfill icons for tabs saved before icon support was added.
					// Preserve icon: "" because that is the user's explicit "Clear Icon" state.
					var dirty = false
					for (var i = 0; i < tileTabsData.length; i++) {
						if (typeof tileTabsData[i].icon === "undefined") {
							var inferred = popup.inferTabIcon(tileTabsData[i].name)
							if (inferred) {
								tileTabsData[i].icon = inferred
								dirty = true
							}
						}
					}
					if (dirty) popup.saveTileTabs()
				}
			} catch (e) {
				tileTabsData = [{id: '1', name: i18n('Main'), icon: 'go-home', tiles: []}]
			}
		}
		if (activeTabIndex >= tileTabsData.length) {
			activeTabIndex = 0
		}
		popup.normalizeGroupHeaderHeights()
		popup.resetViewsAfterTileModelReload()
	}

	function saveTileTabs() {
		try {
			var json = JSON.stringify(tileTabsData)
			_tabsWriting = true
			plasmoid.configuration.tileTabs = Base64.encodeString(json)
			_tabsWriting = false
		} catch (e) {
			_tabsWriting = false
		}
	}

	function selectTab(index) {
		if (index < 0 || index >= tileTabsData.length) return
		if (index === activeTabIndex) return
		// Persist current tab tiles before switching
		popup.saveTileTabs()
		// Close the tile editor: the tile reference belongs to the current tab and
		// would become stale once the model switches to a different tab's tiles.
		if (tileEditorViewLoader && tileEditorViewLoader.active) {
			tileEditorViewLoader.active = false
		}
		var direction = (index > activeTabIndex) ? 1 : -1
		_previousTabIndex = activeTabIndex
		if (typeof tileGridSlideContainer !== "undefined" && tileGridSlideContainer) {
			tileGridSlideContainer.runSlide(direction, index)
		} else {
			activeTabIndex = index
		}
	}

	function addTab() {
		_tabIdCounter++
		var newId = 'tab_' + _tabIdCounter
		var newTabs = tileTabsData.slice()
		var newTabName = i18n('New Tab')
		var newTabIcon = popup.inferTabIcon(newTabName)
		newTabs.push({id: newId, name: newTabName, icon: newTabIcon, tiles: []})
		tileTabsData = newTabs
		popup.saveTileTabs()
		selectTab(newTabs.length - 1)
	}

	function deleteTab(index) {
		if (index < 0 || index >= tileTabsData.length) return
		var tab = tileTabsData[index]
		var tiles = tab.tiles || []
		var hasTiles = false
		for (var i = 0; i < tiles.length; i++) {
			if (tiles[i].tileType !== "group") { hasTiles = true; break }
		}
		if (hasTiles) {
			_pendingDeleteTabIndex = index
			deleteTabDialog.open()
			return
		}
		_doDeleteTab(index)
	}

	property int _pendingDeleteTabIndex: -1

	function _doDeleteTab(index) {
		if (index < 0 || index >= tileTabsData.length) return
		// Persist before deleting
		popup.saveTileTabs()
		// Close editor if it is editing a tile from the deleted tab
		if (tileEditorViewLoader && tileEditorViewLoader.active) {
			tileEditorViewLoader.active = false
		}
		var newTabs = tileTabsData.slice()
		newTabs.splice(index, 1)
		if (newTabs.length === 0) {
			// Deleting the last tab – replace with a fresh empty one
			_tabIdCounter++
			var freshName = i18n('Tiles')
			newTabs.push({id: 'tab_' + _tabIdCounter, name: freshName, icon: popup.inferTabIcon(freshName), tiles: []})
		}
		var wasDeletingActive = (index === activeTabIndex)
		var prev = _previousTabIndex
		if (prev === index) {
			prev = -1
		} else if (prev > index) {
			prev = prev - 1
		}
		var curAdjusted = activeTabIndex
		if (curAdjusted > index) curAdjusted = curAdjusted - 1
		var target = wasDeletingActive
			? ((prev >= 0 && prev < newTabs.length) ? prev : Math.min(index, newTabs.length - 1))
			: curAdjusted
		if (target < 0) target = 0
		if (target >= newTabs.length) target = newTabs.length - 1
		_previousTabIndex = -1
		activeTabIndex = target
		tileTabsData = newTabs
		popup.saveTileTabs()
	}

	QtDialogs.MessageDialog {
		id: deleteTabDialog
		title: i18n("Delete Tab")
		text: {
			var idx = popup._pendingDeleteTabIndex
			var tabName = (idx >= 0 && idx < popup.tileTabsData.length)
				? popup.tileTabsData[idx].name : ""
			var tiles = (idx >= 0 && idx < popup.tileTabsData.length)
				? (popup.tileTabsData[idx].tiles || []) : []
			var count = 0
			for (var i = 0; i < tiles.length; i++) {
				if (tiles[i].tileType !== "group") count++
			}
			return i18n("The tab \"%1\" contains %2 tile(s). Delete it anyway?", tabName, count)
		}
		buttons: QtDialogs.MessageDialog.Yes | QtDialogs.MessageDialog.No
		onButtonClicked: function(button, role) {
			if (button === QtDialogs.MessageDialog.Yes) {
				popup._doDeleteTab(popup._pendingDeleteTabIndex)
			}
			popup._pendingDeleteTabIndex = -1
		}
	}

	function renameTab(index, newName) {
		if (index < 0 || index >= tileTabsData.length) return
		var newTabs = tileTabsData.slice()
		newTabs[index] = {
			id: newTabs[index].id,
			name: newName,
			icon: newTabs[index].icon || "",
			tiles: newTabs[index].tiles,
		}
		tileTabsData = newTabs
		popup.saveTileTabs()
	}

	function changeTabIcon(index, newIcon) {
		if (index < 0 || index >= tileTabsData.length) return
		var newTabs = tileTabsData.slice()
		newTabs[index] = {
			id: newTabs[index].id,
			name: newTabs[index].name,
			icon: newIcon,
			tiles: newTabs[index].tiles,
		}
		tileTabsData = newTabs
		popup.saveTileTabs()
	}

	function moveTileToTab(tileIndex, tabId) {
		if (!config.useTileTabs) return
		var srcTiles = tileTabsData[activeTabIndex].tiles
		if (tileIndex < 0 || tileIndex >= srcTiles.length) return
		var destIdx = -1
		for (var i = 0; i < tileTabsData.length; i++) {
			if (tileTabsData[i].id === tabId) { destIdx = i; break }
		}
		if (destIdx < 0 || destIdx === activeTabIndex) return

		// Close tile editor — references belong to the current tab's model
		if (tileEditorViewLoader && tileEditorViewLoader.active) {
			tileEditorViewLoader.active = false
		}

		var target = srcTiles[tileIndex]
		var moved = []
		if (target.tileType === 'group') {
			var area = tileGrid.getGroupAreaRect(target)
			for (var j = srcTiles.length - 1; j >= 0; j--) {
				var t = srcTiles[j]
				if (t === target || tileGrid.tileWithin(t, area.x1, area.y1, area.x2, area.y2)) {
					moved.unshift(srcTiles.splice(j, 1)[0])
				}
			}
		} else {
			moved.push(srcTiles.splice(tileIndex, 1)[0])
		}

		var destTiles = tileTabsData[destIdx].tiles
		for (var k = 0; k < moved.length; k++) {
			destTiles.push(moved[k])
		}

		tileGrid.tileModelChanged()
		popup.saveTileTabs()
	}

	function moveTab(fromIndex, toIndex) {
		if (fromIndex < 0 || fromIndex >= tileTabsData.length) return
		if (toIndex < 0 || toIndex >= tileTabsData.length) return
		if (fromIndex === toIndex) return
		var newTabs = tileTabsData.slice()
		var tab = newTabs.splice(fromIndex, 1)[0]
		newTabs.splice(toIndex, 0, tab)
		tileTabsData = newTabs
		if (activeTabIndex === fromIndex) {
			activeTabIndex = toIndex
		} else if (fromIndex < activeTabIndex
				&& toIndex >= activeTabIndex) {
			activeTabIndex--
		} else if (fromIndex > activeTabIndex
				&& toIndex <= activeTabIndex) {
			activeTabIndex++
		}
		popup.saveTileTabs()
	}


	function effectiveDevicePixelRatio() {
		var screenDpr = Screen.devicePixelRatio || 0
		if (screenDpr > 0) {
			return screenDpr
		}
		var kirigamiDpr = Kirigami.Units.devicePixelRatio || 0
		if (kirigamiDpr > 0) {
			return kirigamiDpr
		}
		return 1
	}

	function normalizedSizeMemoryView(viewName) {
		if (viewName === "AiChat" || viewName === "TilesOnly" || viewName === "Categories") {
			return viewName
		}
		return "Alphabetical"
	}

	function currentSizeMemoryView() {
		if (searchView && searchView.activeSizeMemoryView) {
			return normalizedSizeMemoryView(searchView.activeSizeMemoryView)
		}
		return "Alphabetical"
	}

	function sizeConfigKeys(viewName) {
		var normalizedView = normalizedSizeMemoryView(viewName)
		var layoutPrefix = (config && config.usesDockedSidebarLayout) ? "Docked" : ""
		return {
			width: "popupWidth" + layoutPrefix + normalizedView,
			height: "popupHeight" + layoutPrefix + normalizedView,
			cols: "favGridCols" + layoutPrefix + normalizedView,
		}
	}

	function saveSizeForView(viewName, width, height, cols) {
		var normalizedView = normalizedSizeMemoryView(viewName)
		var keys = sizeConfigKeys(normalizedView)
		if (width > 0 && plasmoid.configuration[keys.width] !== width) {
			plasmoid.configuration[keys.width] = width
		}
		if (height > 0 && plasmoid.configuration[keys.height] !== height) {
			plasmoid.configuration[keys.height] = height
		}
		if (cols > 0 && plasmoid.configuration[keys.cols] !== cols) {
			plasmoid.configuration[keys.cols] = cols
		}
	}

	function saveCurrentViewSize() {
		if (!config) {
			return
		}

		var dpr = effectiveDevicePixelRatio()
		if (popup._sizeRestored && popup._lastRestoreDevicePixelRatio > 0 && Math.abs(dpr - popup._lastRestoreDevicePixelRatio) > 0.01) {
			popup.scheduleDprSyncRestore()
			return
		}
		function normalizedRenderedSize(liveValue, preferredValue, implicitValue) {
			var candidate = liveValue > 0 ? liveValue : preferredValue
			if (!(candidate > 0)) {
				candidate = implicitValue
			}
			var stableTarget = preferredValue > 0 ? preferredValue : implicitValue
			if (candidate > 0 && stableTarget > 0 && Math.abs(candidate - stableTarget) <= Math.max(2, dpr)) {
				return stableTarget
			}
			return candidate
		}
		// Manual popup resizing updates the live item size first. Persist from the
		// rendered geometry so width/height don't get stuck on stale layout hints.
		var effectiveWidth = normalizedRenderedSize(popup.width, popup.Layout.preferredWidth, popup.implicitWidth)
		var effectiveHeight = normalizedRenderedSize(popup.height, popup.Layout.preferredHeight, popup.implicitHeight)
		var logicalWidth = Math.round(effectiveWidth / dpr)
		var logicalHeight = Math.round(effectiveHeight / dpr)
		var favWidth = Math.max(0, effectiveWidth - popup.popupLeftSectionWidth)
		var box = config.cellBoxSize
		var cols = box > 0 ? Math.max(1, Math.floor(favWidth / box)) : 0

		if (effectiveWidth > 0) {
			popup.Layout.preferredWidth = effectiveWidth
			popup.implicitWidth = effectiveWidth
		}
		if (effectiveHeight > 0) {
			popup.Layout.preferredHeight = effectiveHeight
			popup.implicitHeight = effectiveHeight
		}

		if (logicalHeight > 0 && plasmoid.configuration.popupHeight !== logicalHeight) {
			plasmoid.configuration.popupHeight = logicalHeight
		}
		if (cols > 0 && plasmoid.configuration.favGridCols !== cols) {
			plasmoid.configuration.favGridCols = cols
		}
		saveSizeForView(currentSizeMemoryView(), logicalWidth, logicalHeight, cols)
	}

	function restoreRememberedSizeForView(viewName) {
		var normalizedView = normalizedSizeMemoryView(viewName)
		popup._pendingRestoreView = normalizedView
		if (!popup.widgetExpanded) {
			popup._restoreQueuedWhileCollapsed = true
			return
		}
		restoreViewDebounced.restart()
	}

	function performRestoreRememberedSizeForView(viewName) {
		if (!config) {
			return
		}

		var normalizedView = normalizedSizeMemoryView(viewName)
		var keys = sizeConfigKeys(normalizedView)
		var savedWidth = parseInt(plasmoid.configuration[keys.width], 10)
		var savedHeight = parseInt(plasmoid.configuration[keys.height], 10)
		var savedCols = parseInt(plasmoid.configuration[keys.cols], 10)
		if (!(savedWidth > 0)) {
			savedWidth = Math.round(config.popupWidth / (Screen.devicePixelRatio || 1))
		}
		if (!(savedHeight > 0)) {
			savedHeight = plasmoid.configuration.popupHeight
		}
		if (!(savedCols > 0)) {
			savedCols = plasmoid.configuration.favGridCols
		}
		var layoutMode = (config && config.usesDockedSidebarLayout) ? "docked" : "classic"
		var restoreKey = [layoutMode, normalizedView, savedWidth, savedHeight, savedCols, effectiveDevicePixelRatio()].join("|")
		if (popup._lastAppliedRestoreKey === restoreKey && popup._sizeRestored && !popup._pendingDprSyncRestore) {
			return
		}
		popup._lastAppliedRestoreKey = restoreKey

		if (savedHeight > 0 && plasmoid.configuration.popupHeight !== savedHeight) {
			plasmoid.configuration.popupHeight = savedHeight
		}
		if (savedCols > 0 && plasmoid.configuration.favGridCols !== savedCols) {
			plasmoid.configuration.favGridCols = savedCols
		}
		popup.applySavedSize(savedWidth, savedHeight)
	}

	function restoreRememberedSizeForCurrentView() {
		restoreRememberedSizeForView(currentSizeMemoryView())
	}

	function scheduleRestoreForCurrentView(reason) {
		var viewName = currentSizeMemoryView()
		popup._pendingRestoreView = viewName
		if (popup.widgetExpanded) {
			restoreViewDebounced.restart()
		} else {
			popup._restoreQueuedWhileCollapsed = true
		}
	}

	function scheduleDprSyncRestore() {
		popup._pendingDprSyncRestore = true
		dprSyncDebounced.restart()
	}

	function normalizeGroupHeaderHeights() {
		var model
		if (config && config.useTileTabs) {
			model = popup.activeTabTiles
		} else {
			model = config && config.tileModel ? config.tileModel.value : null
		}
		if (!model || !model.length) {
			return
		}

		var groups = []
		for (var i = 0; i < model.length; i++) {
			var t = model[i]
			if (t && t.tileType === "group") {
				groups.push(t)
			}
		}
		if (!groups.length) {
			return
		}

		groups.sort(function(a, b) {
			if (a.y === b.y) {
				return (a.x || 0) - (b.x || 0)
			}
			return (a.y || 0) - (b.y || 0)
		})

		var changed = false
		for (var gi = 0; gi < groups.length; gi++) {
			var groupTile = groups[gi]
			var oldH = (typeof groupTile.h !== "undefined" ? groupTile.h : 1)
			if (oldH === 1) {
				continue
			}

			// Compute area using the existing (old) group height.
			var area = tileGrid.getGroupAreaRect(groupTile)
			var deltaY = 1 - oldH
			groupTile.h = 1

			if (deltaY !== 0) {
				for (var ti = 0; ti < model.length; ti++) {
					var tile = model[ti]
					if (!tile || tile === groupTile) {
						continue
					}
					if (tileGrid.tileWithin(tile, area.x1, area.y1, area.x2, area.y2)) {
						tile.y += deltaY
					}
				}
			}

			changed = true
		}

		if (changed) {
			tileGrid.tileModelChanged()
		}
	}

	function resetViewsAfterTileModelReload() {
		// Importing settings can replace the tileModel JS array and invalidate any
		// references held by editor views. Ensure the editor is fully destroyed.
		if (tileEditorViewLoader && tileEditorViewLoader.active) {
			tileEditorViewLoader.active = false
		}
		// Return to the user's default view.
		if (searchView && typeof searchView.showDefaultView === "function") {
			searchView.showDefaultView()
		}
	}

	// Compute effective tile bounds for a single tile model, excluding
	// group headers that can be wider than their actual child content.
	function tileWithinBounds(tile, x1, y1, x2, y2) {
		var tileX2 = tile.x + tile.w - 1
		var tileY2 = tile.y + tile.h - 1
		return (x1 <= tileX2
			&& tile.x <= x2
			&& y1 <= tileY2
			&& tile.y <= y2)
	}

	function groupBottomRow(model, groupTile) {
		var x1 = groupTile.x
		var x2 = groupTile.x + groupTile.w - 1
		var headerH = (typeof groupTile.h !== "undefined" ? groupTile.h : 1)
		var y1 = groupTile.y + headerH
		var y2 = 2000000

		for (var i = 0; i < model.length; i++) {
			var t = model[i]
			if (t && t !== groupTile && t.tileType === "group" && tileWithinBounds(t, x1, y1, x2, y2)) {
				y2 = t.y - 1
			}
		}

		var lowestTileY = y1
		for (var j = 0; j < model.length; j++) {
			var tile = model[j]
			if (tile && tile !== groupTile && tileWithinBounds(tile, x1, y1, x2, y2)) {
				lowestTileY = Math.max(lowestTileY, tile.y + tile.h - 1)
			}
		}

		var minAreaH = (typeof groupTile.groupAreaH !== "undefined") ? Math.max(0, groupTile.groupAreaH) : 0
		if (minAreaH > 0) {
			lowestTileY = Math.max(lowestTileY, y1 + minAreaH - 1)
		}

		return Math.min(lowestTileY, y2)
	}

	function modelBounds(model) {
		var c = 0, r = 0
		var hoverW = 1, hoverH = 1
		if (model) {
			for (var i = 0; i < model.length; i++) {
				var t = model[i]
				if (!t) continue
				if (t.tileType === "group") {
					// Group headers only drive row count (h is typically 1),
					// not column count — their w may exceed child content.
					r = Math.max(r, groupBottomRow(model, t) + 1)
					continue
				}
				c = Math.max(c, t.x + t.w)
				r = Math.max(r, t.y + t.h)
				hoverW = Math.max(hoverW, t.w)
				hoverH = Math.max(hoverH, t.h)
			}
		}
		return { cols: Math.max(1, c), rows: Math.max(1, r), hoverW: hoverW, hoverH: hoverH }
	}

	// When tabs are enabled, return the maximum bounds across all tabs
	// so that auto-resize fits the largest tab.
	function contentBounds() {
		if (config.useTileTabs && tileTabsData.length > 0) {
			var c = 0, r = 0
			var hoverW = 1, hoverH = 1
			for (var ti = 0; ti < tileTabsData.length; ti++) {
				var b = modelBounds(tileTabsData[ti].tiles)
				c = Math.max(c, b.cols)
				r = Math.max(r, b.rows)
				hoverW = Math.max(hoverW, b.hoverW)
				hoverH = Math.max(hoverH, b.hoverH)
			}
			return { cols: Math.max(1, c), rows: Math.max(1, r), hoverW: hoverW, hoverH: hoverH }
		}
		return modelBounds(tileGrid.tileModel)
	}

	function autoResizeToContent() {
		if (!tileGrid || !config) {
			return
		}

		tileGrid.update() // refresh cached bounds & favorites

		var bounds = contentBounds()
		var cols = bounds.cols
		var rows = bounds.rows
		var cellBox = tileGrid.cellBoxSize
		var holoPad = tileGrid.holographicPaddingFor ? tileGrid.holographicPaddingFor(bounds.hoverW, bounds.hoverH) : (tileGrid._holoPad || 0)
		var targetGridWidth = cols * cellBox + 2 * holoPad
		var sidebarExtraHeight = (config.sidebarOnTop || config.sidebarOnBottom)
			? (config.sidebarHeight + config.sidebarRightMargin)
			: 0
		// Top row hosts search field + tab bar side-by-side in docked layout.
		// Reserve max of the two, plus the RowLayout's top/bottom margins.
		var dpr = Screen.devicePixelRatio || 1
		var tabRowTabsHeight = (config.useTileTabs && tileTabBar) ? tileTabBar.implicitHeight : 0
		var tabRowSearchHeight = (config.usesDockedSidebarLayout && rightPaneSearchField && rightPaneSearchField.visible)
			? config.searchFieldHeight
			: 0
		var tabRowContentHeight = Math.max(tabRowTabsHeight, tabRowSearchHeight)
		var tabRowTopMargin = (config.usesDockedSidebarLayout || (config.usesClassicLayout && config.sidebarOnLeft))
			? config.sidebarCardInset
			: Kirigami.Units.largeSpacing
		var tabBarExtraHeight = tabRowContentHeight > 0
			? tabRowContentHeight + tabRowTopMargin + Kirigami.Units.smallSpacing
			: 0
		var searchFieldExtraHeight = 0
		var targetGridHeight = rows * cellBox + 2 * holoPad
		var targetWidth = Math.max(popup.minimumPopupWidth, popup.popupLeftSectionWidth + targetGridWidth)
		var targetHeight = Math.max(config.minimumHeight, targetGridHeight + sidebarExtraHeight + tabBarExtraHeight + searchFieldExtraHeight)
		var logicalHeight = Math.ceil(targetHeight / dpr)
		var logicalWidth = Math.ceil(targetWidth / dpr)

		var changedCols = plasmoid.configuration.favGridCols !== cols
		var changedHeight = plasmoid.configuration.popupHeight !== logicalHeight
		if (typeof widget !== "undefined" && widget) {
			widget.suppressHideOnWindowDeactivate = true
			autoResizeDeactivateGuard.restart()
		}
		if (changedCols) {
			plasmoid.configuration.favGridCols = cols
		}
		if (changedHeight) {
			plasmoid.configuration.popupHeight = logicalHeight
		}
		saveSizeForView(currentSizeMemoryView(), logicalWidth, logicalHeight, cols)

		// Force the popup's layout hints to the computed size so the view actually resizes.
		var restoreMinW = popup.minimumPopupWidth
		var restoreMinH = config.minimumHeight
		popup.Layout.preferredWidth = targetWidth
		popup.Layout.preferredHeight = targetHeight
		popup.Layout.minimumWidth = targetWidth
		popup.Layout.minimumHeight = targetHeight
		popup.Layout.maximumWidth = targetWidth
		popup.Layout.maximumHeight = targetHeight
		popup.implicitWidth = targetWidth
		popup.implicitHeight = targetHeight

		// Also set the actual item sizes to push the change through even if a binding was broken earlier.
		popup.width = targetWidth
		popup.height = targetHeight
		Qt.callLater(function() {
			popup.width = targetWidth
			popup.height = targetHeight
			// Release max/implicit on the following frame to re-enable manual resize.
			Qt.callLater(function() {
				popup.Layout.maximumWidth = -1
				popup.Layout.maximumHeight = -1
				popup.Layout.minimumWidth = restoreMinW
				popup.Layout.minimumHeight = restoreMinH
				autoResizeDeactivateGuard.restart()
			})
		})
	}

	function autoResizeWidthToContent() {
		if (!tileGrid || !config) {
			return
		}

		tileGrid.update()

		var bounds = contentBounds()
		var cols = bounds.cols
		var cellBox = tileGrid.cellBoxSize
		var holoPad = tileGrid.holographicPaddingFor ? tileGrid.holographicPaddingFor(bounds.hoverW, bounds.hoverH) : (tileGrid._holoPad || 0)
		var targetGridWidth = cols * cellBox + 2 * holoPad
		var targetWidth = Math.max(popup.minimumPopupWidth, popup.popupLeftSectionWidth + targetGridWidth)

		var changedCols = plasmoid.configuration.favGridCols !== cols
		if (typeof widget !== "undefined" && widget) {
			widget.suppressHideOnWindowDeactivate = true
			autoResizeDeactivateGuard.restart()
		}
		if (changedCols) {
			plasmoid.configuration.favGridCols = cols
		}

		var restoreMinW = popup.minimumPopupWidth
		popup.Layout.preferredWidth = targetWidth
		popup.Layout.minimumWidth = targetWidth
		popup.Layout.maximumWidth = targetWidth
		popup.implicitWidth = targetWidth
		popup.width = targetWidth
		Qt.callLater(function() {
			popup.width = targetWidth
			Qt.callLater(function() {
				popup.Layout.maximumWidth = -1
				popup.Layout.minimumWidth = restoreMinW
				autoResizeDeactivateGuard.restart()
			})
		})
	}

	function applySavedSize(targetWidthLogical, targetHeightLogical) {
		if (!config) {
			return
		}
		var dpr = effectiveDevicePixelRatio()
		var targetWidth = (targetWidthLogical > 0 ? targetWidthLogical : Math.round(config.popupWidth / dpr)) * dpr
		var targetHeight = (targetHeightLogical > 0 ? targetHeightLogical : plasmoid.configuration.popupHeight) * dpr
		if (!(targetWidth > 0 && targetHeight > 0)) {
			return
		}

		var restoreMinW = popup.minimumPopupWidth
		var restoreMinH = config.minimumHeight
		popup._lastRestoreDevicePixelRatio = dpr
		popup._suppressPersist = true
		popup.Layout.preferredWidth = targetWidth
		popup.Layout.preferredHeight = targetHeight
		popup.Layout.minimumWidth = targetWidth
		popup.Layout.minimumHeight = targetHeight
		popup.Layout.maximumWidth = targetWidth
		popup.Layout.maximumHeight = targetHeight
		popup.width = targetWidth
		popup.height = targetHeight
		popup.implicitWidth = targetWidth
		popup.implicitHeight = targetHeight
		Qt.callLater(function() {
			popup.width = targetWidth
			popup.height = targetHeight
			Qt.callLater(function() {
				popup.Layout.maximumWidth = -1
				popup.Layout.maximumHeight = -1
				popup.Layout.minimumWidth = restoreMinW
				popup.Layout.minimumHeight = restoreMinH
				popup._suppressPersist = false
				popup._sizeRestored = true
				var currentDpr = effectiveDevicePixelRatio()
				if (Math.abs(currentDpr - popup._lastRestoreDevicePixelRatio) > 0.01) {
					popup.scheduleDprSyncRestore()
				}
			})
		})
	}

	function resizeToCurrentViewWidth() {
		if (!config) {
			return
		}

		var targetWidth = config.popupWidth
		if (!(targetWidth > 0)) {
			return
		}

		var restoreMinW = popup.minimumPopupWidth
		popup.Layout.preferredWidth = targetWidth
		popup.Layout.minimumWidth = targetWidth
		popup.Layout.maximumWidth = targetWidth
		popup.implicitWidth = targetWidth
		popup.width = targetWidth

		Qt.callLater(function() {
			popup.width = targetWidth
			Qt.callLater(function() {
				popup.Layout.maximumWidth = -1
				popup.Layout.minimumWidth = restoreMinW
			})
		})
	}

	Connections {
		target: config && config.tileModel ? config.tileModel : null
		function onLoaded() {
			popup.normalizeGroupHeaderHeights()
			popup.resetViewsAfterTileModelReload()
		}
	}

	// Persist user resizing across plasmashell restarts.
	// Width is represented indirectly via favGridCols; height is stored in popupHeight.
	property bool _persistSizeEnabled: false
	property bool _suppressPersist: false
	property bool _sizeRestored: false
	property bool _pendingEditSidebarResize: false
	Timer {
		id: enablePersistSize
		interval: 0
		repeat: false
		onTriggered: popup._persistSizeEnabled = true
	}
	Timer {
		id: editSidebarResizeDebounced
		interval: 0
		repeat: false
		onTriggered: {
			popup.autoResizeWidthToContent()
			popup._pendingEditSidebarResize = false
		}
	}
	Timer {
		id: dprSyncDebounced
		interval: 0
		repeat: false
		onTriggered: {
			if (!config || !popup._pendingDprSyncRestore) {
				return
			}
			popup._pendingDprSyncRestore = false
			var currentDpr = popup.effectiveDevicePixelRatio()
			popup._lastKnownDevicePixelRatio = currentDpr
			popup.scheduleRestoreForCurrentView("dpr-sync")
		}
	}
	Timer {
		id: restoreViewDebounced
		interval: 0
		repeat: false
		onTriggered: {
			if (!popup.widgetExpanded) {
				popup._restoreQueuedWhileCollapsed = true
				return
			}
			var targetView = popup._pendingRestoreView || popup.currentSizeMemoryView()
			popup._restoreQueuedWhileCollapsed = false
			popup.performRestoreRememberedSizeForView(targetView)
		}
	}
	Timer {
		id: autoResizeDeactivateGuard
		interval: 250
		repeat: false
		onTriggered: {
			if (typeof widget !== "undefined" && widget) {
				widget.suppressHideOnWindowDeactivate = false
			}
		}
	}
	Component.onCompleted: {
		enablePersistSize.start()
		popup._lastKnownDevicePixelRatio = popup.effectiveDevicePixelRatio()
		if (searchView && typeof searchView.setActiveSizeMemoryView === "function") {
			if (typeof searchView.resolveConfiguredDefaultView === "function") {
				searchView.setActiveSizeMemoryView(searchView.resolveConfiguredDefaultView())
			} else {
				searchView.setActiveSizeMemoryView(searchView.lastRememberedSizeMemoryView)
			}
		}
		if (popup.widgetExpanded) {
			popup.scheduleRestoreForCurrentView("component-completed")
		}
		if (config.useTileTabs) {
			popup.loadTileTabs()
		}
	}
	Screen.onDevicePixelRatioChanged: {
		var currentDpr = popup.effectiveDevicePixelRatio()
		if (Math.abs(currentDpr - popup._lastKnownDevicePixelRatio) > 0.01) {
			popup._lastKnownDevicePixelRatio = currentDpr
			popup.scheduleDprSyncRestore()
		}
	}
	onWidgetExpandedChanged: {
		if (popup.widgetExpanded) {
			popup._lastKnownDevicePixelRatio = popup.effectiveDevicePixelRatio()
			popup._lastAppliedRestoreKey = ""
			if (searchView && typeof searchView.setActiveSizeMemoryView === "function" && typeof searchView.resolveConfiguredDefaultView === "function") {
				searchView.setActiveSizeMemoryView(searchView.resolveConfiguredDefaultView())
			}
			popup.scheduleRestoreForCurrentView("widget-expanded")
		} else if (!popup._suppressPersist && popup._sizeRestored) {
			// The debounced saver can lose the final manual resize if the popup is
			// closed before it fires. Persist the live size one last time on close.
			popup.saveCurrentViewSize()
		}
	}

	Connections {
		target: config
		function onIsEditingTileChanged() {
			popup._pendingEditSidebarResize = true
			editSidebarResizeDebounced.restart()
		}
		function onShowSearchChanged() {
			if (popup._pendingEditSidebarResize) {
				editSidebarResizeDebounced.restart()
			}
		}
		function onUseTileTabsChanged() {
			if (config.useTileTabs) {
				popup.loadTileTabs()
			} else {
				// Restore the active tab's tiles back to the single tileModel so
				// the user doesn't lose their work when they disable tabs.
				var idx = Math.min(popup.activeTabIndex, popup.tileTabsData.length - 1)
				if (idx >= 0 && popup.tileTabsData.length > 0) {
					var activeTiles = popup.tileTabsData[idx].tiles || []
					if (activeTiles.length > 0) {
						config.tileModel.value = activeTiles
						config.tileModel.save()
					}
				}
			}
		}
	}

	Connections {
		target: plasmoid.configuration
		function onTileTabsChanged() {
			if (config.useTileTabs && !popup._tabsWriting) {
				popup.loadTileTabs()
			}
		}
	}

	Timer {
		id: persistSizeDebounced
		interval: 400
		repeat: false
		onTriggered: {
			if (!popup._persistSizeEnabled || popup._suppressPersist || !popup.widgetExpanded || !popup._sizeRestored) {
				return
			}
			popup.saveCurrentViewSize()
		}
	}

	onWidthChanged: {
		if (popup._persistSizeEnabled) {
			if (!popup._suppressPersist && popup.widgetExpanded && popup._sizeRestored) {
				popup.saveCurrentViewSize()
			}
			persistSizeDebounced.restart()
		}
	}
	onHeightChanged: {
		if (popup._persistSizeEnabled) {
			if (!popup._suppressPersist && popup.widgetExpanded && popup._sizeRestored) {
				popup.saveCurrentViewSize()
			}
			persistSizeDebounced.restart()
		}
	}

	RowLayout {
		anchors.fill: parent
		spacing: 0

		// === Docked Sidebar layout: Left pane ===
		Item {
			id: leftPaneSlot
			visible: config.usesDockedSidebarLayout
			Layout.preferredWidth: config.usesDockedSidebarLayout ? config.dockedSidebarSlotWidth : 0
			Layout.minimumWidth: config.usesDockedSidebarLayout ? config.dockedSidebarSlotWidth : 0
			Layout.maximumWidth: config.usesDockedSidebarLayout ? config.dockedSidebarSlotWidth : 0
			Layout.fillHeight: true

			SidebarGlassCard {
				anchors.fill: parent
				anchors.margins: config.sidebarCardInset

				LeftPaneView {
					id: leftPaneView
					anchors.fill: parent
				}
			}
		}

		// === Classic layout: sidebar placeholder ===
		Item {
			id: sidebarPlaceholder
			Layout.preferredWidth: config.classicLeftSidebarSlotWidth
			Layout.minimumWidth: config.classicLeftSidebarSlotWidth
			Layout.maximumWidth: config.classicLeftSidebarSlotWidth
			Layout.fillHeight: true
			visible: config.usesClassicLayout && config.sidebarOnLeft
		}

		ColumnLayout {
			id: mainColumnLayout
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 0

			// Top sidebar placeholder (Classic layout only)
			Item {
				id: topSidebarPlaceholder
				Layout.preferredHeight: config.sidebarHeight
				Layout.minimumHeight: config.sidebarHeight
				Layout.maximumHeight: config.sidebarHeight
				Layout.fillWidth: true
				Layout.bottomMargin: config.sidebarRightMargin
				visible: config.usesClassicLayout && config.sidebarOnTop
			}

			RowLayout {
				id: contentRowLayout
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 0

				// Classic layout: SearchView slot
				Item {
					id: searchViewSlot
					Layout.fillHeight: true
					Layout.preferredWidth: config.appAreaWidth
					Layout.minimumWidth: 0
					Layout.maximumWidth: config.appAreaWidth > 0 ? -1 : 0
					implicitWidth: config.appAreaWidth
					visible: config.usesClassicLayout && config.appAreaWidth > 0
				}

				// Drag handle for resizing the app area width
				Item {
					id: appAreaResizeHandle
					Layout.fillHeight: true
					Layout.preferredWidth: Kirigami.Units.smallSpacing * 2
					visible: {
						if (config.usesDockedSidebarLayout) {
							return true // Always show resize handle in Docked Sidebar layout
						}
						return config.showSearch && !config.isEditingTile && !config.searchOverlayActive
					}
					z: 1

					Rectangle {
						anchors.centerIn: parent
						width: Math.max(2, Math.round(1 * Screen.devicePixelRatio))
						height: Math.min(parent.height * 0.3, 48 * Screen.devicePixelRatio)
						radius: width / 2
						color: Kirigami.Theme.textColor
						opacity: appAreaResizeMouseArea.containsMouse || appAreaResizeMouseArea.pressed ? 0.6 : 0.15
						Behavior on opacity {
							NumberAnimation { duration: 150 }
						}
					}

					MouseArea {
						id: appAreaResizeMouseArea
						anchors.fill: parent
						anchors.leftMargin: 0
						anchors.rightMargin: -Kirigami.Units.smallSpacing * 2
						cursorShape: Qt.SplitHCursor
						hoverEnabled: true
						preventStealing: true

						property real dragStartX: 0
						property int dragStartConfigWidth: 0

						onPressed: function(mouse) {
							dragStartX = mapToItem(popup, mouse.x, 0).x
							dragStartConfigWidth = config.usesDockedSidebarLayout ? (plasmoid.configuration.dockedSidebarWidth || 350) : plasmoid.configuration.appListWidth
						}

						onPositionChanged: function(mouse) {
											if (!pressed) return
											var currentX = mapToItem(popup, mouse.x, 0).x
											var dpr = Screen.devicePixelRatio || 1
											var delta = (currentX - dragStartX) / dpr
											var minWidth = config.usesDockedSidebarLayout ? Math.ceil(config.dockedSidebarMinWidth / dpr) : 120
											var newWidth = Math.max(minWidth, Math.round(dragStartConfigWidth + delta))
											if (config.usesDockedSidebarLayout) {
												if (plasmoid.configuration.dockedSidebarWidth !== newWidth) {
													plasmoid.configuration.dockedSidebarWidth = newWidth
												}
											} else if (plasmoid.configuration.appListWidth !== newWidth) {
												plasmoid.configuration.appListWidth = newWidth
											}
										}
					}
				}

				ColumnLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true
					spacing: 0

					Item {
						id: rightPaneTopRow
						Layout.fillWidth: true
						Layout.topMargin: _alignTopSurfaces ? config.sidebarCardInset : Kirigami.Units.largeSpacing
						Layout.leftMargin: Kirigami.Units.largeSpacing
						Layout.rightMargin: Kirigami.Units.largeSpacing
						Layout.bottomMargin: Kirigami.Units.smallSpacing
						visible: _showDockedSearchField || _showTileTabs
						implicitHeight: Math.max(
							_showDockedSearchField ? rightPaneSearchField.implicitHeight : 0,
							_showTileTabs ? tileTabBar.implicitHeight : 0)

						readonly property bool _showDockedSearchField: config.usesDockedSidebarLayout
							&& !config.isEditingTile
							&& (!config.hideSearchField || search.query.length > 0)
						readonly property bool _showTileTabs: config.useTileTabs
						readonly property real _gap: Kirigami.Units.largeSpacing * 2
						readonly property real _minSearchWidth: Kirigami.Units.gridUnit * 8
						readonly property real _minTabsWidth: Kirigami.Units.gridUnit * 6
						readonly property real _handleWidth: Kirigami.Units.smallSpacing * 2
						readonly property bool _bothVisible: _showDockedSearchField && _showTileTabs
						readonly property bool _alignTopSurfaces: config.usesDockedSidebarLayout
							|| (config.usesClassicLayout && config.sidebarOnLeft)
						readonly property real _effectiveSearchWidth: {
							if (!_showDockedSearchField) return 0
							if (!_showTileTabs) return width
							var saved = plasmoid.configuration.dockedSearchFieldWidth || 0
							var desired = saved > 0 ? saved : Math.round(width * 0.35)
							var maxW = Math.max(_minSearchWidth, width - _minTabsWidth - _gap)
							return Math.max(_minSearchWidth, Math.min(desired, maxW))
						}

							SearchField {
								id: rightPaneSearchField
								visible: rightPaneTopRow._showDockedSearchField
								anchors.left: parent.left
								y: rightPaneTopRow._alignTopSurfaces ? 0 : Math.round((parent.height - height) / 2)
								width: rightPaneTopRow._showTileTabs ? rightPaneTopRow._effectiveSearchWidth : parent.width
								height: config.searchFieldHeight
								implicitHeight: config.searchFieldHeight
								listView: searchView.stackView && searchView.stackView.currentItem && searchView.stackView.currentItem.listView ? searchView.stackView.currentItem.listView : []
							}

							Item {
								id: topRowResizeHandle
								visible: rightPaneTopRow._bothVisible
								width: rightPaneTopRow._handleWidth
								height: rightPaneTopRow._alignTopSurfaces ? rightPaneSearchField.height : parent.height
								y: rightPaneTopRow._alignTopSurfaces ? 0 : Math.round((parent.height - height) / 2)
								x: rightPaneSearchField.x + rightPaneSearchField.width + (rightPaneTopRow._gap - width) / 2
								z: 2

								Rectangle {
									anchors.centerIn: parent
									width: Math.max(2, Math.round(1 * Screen.devicePixelRatio))
									height: Math.min(parent.height * 0.5, 24 * Screen.devicePixelRatio)
									radius: width / 2
									color: Kirigami.Theme.textColor
									opacity: topRowResizeMA.containsMouse || topRowResizeMA.pressed ? 0.6 : 0.2
									Behavior on opacity { NumberAnimation { duration: 150 } }
								}

								MouseArea {
									id: topRowResizeMA
									anchors.fill: parent
									anchors.leftMargin: -Kirigami.Units.smallSpacing
									anchors.rightMargin: -Kirigami.Units.smallSpacing
									cursorShape: Qt.SplitHCursor
									hoverEnabled: true
									preventStealing: true

									property real dragStartX: 0
									property int dragStartWidth: 0

									onPressed: function(mouse) {
										dragStartX = mapToItem(rightPaneTopRow, mouse.x, 0).x
										dragStartWidth = rightPaneSearchField.width
									}

									onPositionChanged: function(mouse) {
										if (!pressed) return
										var currentX = mapToItem(rightPaneTopRow, mouse.x, 0).x
										var delta = currentX - dragStartX
										var maxW = Math.max(rightPaneTopRow._minSearchWidth,
											rightPaneTopRow.width - rightPaneTopRow._minTabsWidth - rightPaneTopRow._gap)
										var newWidth = Math.max(rightPaneTopRow._minSearchWidth,
											Math.min(maxW, Math.round(dragStartWidth + delta)))
										if (plasmoid.configuration.dockedSearchFieldWidth !== newWidth) {
											plasmoid.configuration.dockedSearchFieldWidth = newWidth
										}
									}
								}
							}

							TileTabBar {
								id: tileTabBar
								anchors.right: parent.right
								y: rightPaneTopRow._alignTopSurfaces ? 0 : Math.round((parent.height - height) / 2)
								width: rightPaneTopRow._showDockedSearchField
									? Math.max(0, parent.width - rightPaneSearchField.width - rightPaneTopRow._gap)
									: parent.width
								height: implicitHeight
								visible: rightPaneTopRow._showTileTabs
								style: plasmoid.configuration.tileTabStyle || "tabs"
								alignSurfaceToTop: rightPaneTopRow._alignTopSurfaces
								activeTab: popup.activeTabIndex
								tabs: popup.tileTabsData.map(function(t) {
									return {id: t.id, name: t.name, icon: t.icon || ""}
								})

								onTabSelected: function(index) { popup.selectTab(index) }
								onTabAdded: popup.addTab()
								onTabDeleted: function(index) { popup.deleteTab(index) }
								onTabRenamed: function(index, newName) { popup.renameTab(index, newName) }
								onTabIconChanged: function(index, newIcon) { popup.changeTabIcon(index, newIcon) }
								onTabMoved: function(fromIndex, toIndex) { popup.moveTab(fromIndex, toIndex) }
							}

					}

					Item {
						id: tileGridSlideContainer
						Layout.fillWidth: true
						Layout.fillHeight: true
						clip: true

						property int slideDirection: 0
						property bool slideActive: false

						function runSlide(direction, newIndex) {
							if (!config.useTileTabs) {
								popup.activeTabIndex = newIndex
								return
							}
							if (slideActive) {
								snapshotSlideAnim.stop()
								gridSlideAnim.stop()
								tileGrid.x = 0
								slideSnapshot.visible = false
								slideActive = false
							}
							var dpr = Screen.devicePixelRatio || 1
							var grabW = Math.max(1, Math.round(tileGrid.width * dpr))
							var grabH = Math.max(1, Math.round(tileGrid.height * dpr))
							tileGrid.grabToImage(function(result) {
								slideSnapshot.source = result.url
								slideSnapshot.width = tileGrid.width
								slideSnapshot.height = tileGrid.height
								slideSnapshot.x = 0
								slideSnapshot.y = 0
								slideSnapshot.visible = true
								tileGridSlideContainer.slideDirection = direction
								tileGridSlideContainer.slideActive = true
								popup.activeTabIndex = newIndex
								tileGrid.x = direction * tileGridSlideContainer.width
								snapshotSlideAnim.to = -direction * tileGridSlideContainer.width
								snapshotSlideAnim.start()
								gridSlideAnim.to = 0
								gridSlideAnim.start()
							}, Qt.size(grabW, grabH))
						}

						NumberAnimation {
							id: snapshotSlideAnim
							target: slideSnapshot
							property: "x"
							duration: 280
							easing.type: Easing.OutCubic
							onStopped: {
								slideSnapshot.visible = false
								slideSnapshot.source = ""
								tileGridSlideContainer.slideActive = false
							}
						}

						NumberAnimation {
							id: gridSlideAnim
							target: tileGrid
							property: "x"
							duration: 280
							easing.type: Easing.OutCubic
						}

						TileGrid {
							id: tileGrid
							width: tileGridSlideContainer.width
							height: tileGridSlideContainer.height

							cellSize: config.cellSize
							cellMargin: config.cellMargin
							cellPushedMargin: config.cellPushedMargin

							tileModel: config.useTileTabs ? popup.activeTabTiles : config.tileModel.value

							onEditTile: function(tile) { tileEditorViewLoader.open(tile) }
							onMoveTileToTab: function(tileIndex, tabId) { popup.moveTileToTab(tileIndex, tabId) }

							onTileModelChanged: {
								if (config.useTileTabs) {
									saveActiveTabTilesDebounced.restart()
								} else {
									saveTileModel.restart()
								}
							}
							Timer {
								id: saveTileModel
								interval: 2000
								onTriggered: config.tileModel.save()
							}
							Timer {
								id: saveActiveTabTilesDebounced
								interval: 2000
								onTriggered: {
									if (config.useTileTabs) {
										popup.saveTileTabs()
									}
								}
							}
						}

						Image {
							id: slideSnapshot
							visible: false
							smooth: true
							cache: false
							fillMode: Image.Stretch
							y: 0
							z: 1
						}
					}
				}
			}

			// Bottom sidebar placeholder (Classic layout only)
			Item {
				id: bottomSidebarPlaceholder
				Layout.preferredHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.minimumHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.maximumHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.fillWidth: true
				visible: config.usesClassicLayout && config.sidebarOnBottom
			}
		}
	}

	// Search overlay drawer for TilesOnly mode (Classic layout only)
	Item {
		id: searchOverlayContainer
		visible: config.usesClassicLayout && config.searchOverlayActive
		z: 2
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.topMargin: config.sidebarOnTop ? (config.sidebarHeight + config.sidebarRightMargin) : 0
		anchors.bottomMargin: config.sidebarOnBottom ? (config.sidebarHeight + config.sidebarRightMargin) : 0
		x: config.sidebarOnLeft ? config.classicLeftSidebarSlotWidth : 0
		width: config.appListWidth

		Rectangle {
			anchors.fill: parent
			color: Kirigami.Theme.backgroundColor
		}
	}

	// Scrim behind the search overlay (Classic layout only)
	Rectangle {
		id: searchOverlayScrim
		visible: config.usesClassicLayout && config.searchOverlayActive
		z: 1
		anchors.top: searchOverlayContainer.top
		anchors.bottom: searchOverlayContainer.bottom
		anchors.left: searchOverlayContainer.right
		anchors.right: parent.right
		color: "#40000000"

		MouseArea {
			anchors.fill: parent
			onClicked: searchView.showTilesOnly()
		}
	}

	SearchView {
		id: searchView
		aiChatModel: popup.aiChatModel
		parent: {
			if (config.usesDockedSidebarLayout) {
				return leftPaneView.searchViewSlot
			}
			return config.searchOverlayActive ? searchOverlayContainer : searchViewSlot
		}
		anchors.fill: parent
		externalSearchField: config.usesDockedSidebarLayout ? rightPaneSearchField : null
	}

	SidebarView {
		id: sidebarView
		visible: config.usesClassicLayout
		popup: popup
	}

	onClicked: searchView.focusPrimaryInput()
}
