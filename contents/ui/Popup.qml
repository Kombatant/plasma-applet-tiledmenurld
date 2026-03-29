import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

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
		return {
			width: "popupWidth" + normalizedView,
			height: "popupHeight" + normalizedView,
			cols: "favGridCols" + normalizedView,
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
		var effectiveWidth = popup.Layout.preferredWidth > 0 ? popup.Layout.preferredWidth : popup.width
		var effectiveHeight = popup.Layout.preferredHeight > 0 ? popup.Layout.preferredHeight : popup.height
		var logicalWidth = Math.round(effectiveWidth / dpr)
		var logicalHeight = Math.round(effectiveHeight / dpr)
		var favWidth = Math.max(0, effectiveWidth - config.leftSectionWidth)
		var box = config.cellBoxSize
		var cols = box > 0 ? Math.max(1, Math.floor(favWidth / box)) : 0

		if (logicalHeight > 0 && plasmoid.configuration.popupHeight !== logicalHeight) {
			plasmoid.configuration.popupHeight = logicalHeight
		}
		if (cols > 0 && plasmoid.configuration.favGridCols !== cols) {
			plasmoid.configuration.favGridCols = cols
		}
		saveSizeForView(currentSizeMemoryView(), logicalWidth, logicalHeight, cols)
	}

	function restoreRememberedSizeForView(viewName) {
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

	function scheduleDprSyncRestore() {
		popup._pendingDprSyncRestore = true
		dprSyncDebounced.restart()
	}

	function normalizeGroupHeaderHeights() {
		var model = config && config.tileModel ? config.tileModel.value : null
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

	function autoResizeToContent() {
		function logObj(label, obj) {
			if (!logger.showDebug) {
				return
			}
			try {
				logger.log(label, JSON.stringify(obj))
			} catch (e) {
				logger.log(label, obj)
			}
		}

		logObj('autoResize:start', {
			popupW: width,
			popupH: height,
			favGridCols: plasmoid.configuration.favGridCols,
			popupHeightCfg: plasmoid.configuration.popupHeight,
			tileCount: tileGrid && tileGrid.tileModel ? tileGrid.tileModel.length : -1,
			tileGridMaxCol: tileGrid ? tileGrid.maxColumn : -1,
			tileGridMaxRow: tileGrid ? tileGrid.maxRow : -1,
			cellBox: config ? config.cellBoxSize : -1,
			layoutPrefW: popup.Layout.preferredWidth,
			layoutPrefH: popup.Layout.preferredHeight,
			layoutMinW: popup.Layout.minimumWidth,
			layoutMinH: popup.Layout.minimumHeight,
			screenW: Screen.width,
			screenH: Screen.height,
			screenAvailW: Screen.desktopAvailableWidth,
			screenAvailH: Screen.desktopAvailableHeight,
			leftSectionWidth: config ? config.leftSectionWidth : -1,
		})

		if (!tileGrid || !config) {
			logger.log('autoResize:abort', 'missing tileGrid/config')
			return
		}

		var beforeMax = {
			cols: tileGrid.maxColumn,
			rows: tileGrid.maxRow,
		}
		tileGrid.update() // refresh cached bounds
		var afterMax = {
			cols: tileGrid.maxColumn,
			rows: tileGrid.maxRow,
		}

		var cols = Math.max(1, Math.ceil(tileGrid.maxColumn))
		var rows = Math.max(1, Math.ceil(tileGrid.maxRow))
		var cellBox = tileGrid.cellBoxSize
		var holoPad = tileGrid._holoPad || 0
		var targetGridWidth = cols * cellBox + 2 * holoPad
		var sidebarExtraHeight = (config.sidebarOnTop || config.sidebarOnBottom)
			? (config.sidebarHeight + config.sidebarRightMargin)
			: 0
		var targetGridHeight = rows * cellBox + 2 * holoPad
		var targetWidth = Math.max(config.minimumWidth, config.leftSectionWidth + targetGridWidth)
		var targetHeight = Math.max(config.minimumHeight, targetGridHeight + sidebarExtraHeight)
		var dpr = Screen.devicePixelRatio || 1
		var logicalHeight = Math.ceil(targetHeight / dpr)
		var logicalWidth = Math.ceil(targetWidth / dpr)

		logObj('autoResize:computed', {
			beforeMax: beforeMax,
			afterMax: afterMax,
			cellBox: cellBox,
			cols: cols,
			rows: rows,
			targetGridWidth: targetGridWidth,
			targetGridHeight: targetGridHeight,
			targetWidth: targetWidth,
			targetHeight: targetHeight,
			devicePixelRatio: dpr,
			logicalHeight: logicalHeight,
			logicalWidth: logicalWidth,
		})

		var changedCols = plasmoid.configuration.favGridCols !== cols
		var changedHeight = plasmoid.configuration.popupHeight !== logicalHeight
		if (changedCols) {
			plasmoid.configuration.favGridCols = cols
		}
		if (changedHeight) {
			plasmoid.configuration.popupHeight = logicalHeight
		}
		saveSizeForView(currentSizeMemoryView(), logicalWidth, logicalHeight, cols)

		// Force the popup's layout hints to the computed size so the view actually resizes.
		var previousMinW = popup.Layout.minimumWidth
		var previousMinH = popup.Layout.minimumHeight
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
				logObj('autoResize:forceSizes', {
				popupWidth: popup.width,
				popupHeight: popup.height,
				layoutPrefW: popup.Layout.preferredWidth,
				layoutPrefH: popup.Layout.preferredHeight,
				layoutMinW: popup.Layout.minimumWidth,
				layoutMinH: popup.Layout.minimumHeight,
				layoutMaxW: popup.Layout.maximumWidth,
				layoutMaxH: popup.Layout.maximumHeight,
			})
			// Release max/implicit on the following frame to re-enable manual resize.
			Qt.callLater(function() {
					popup.Layout.maximumWidth = -1
					popup.Layout.maximumHeight = -1
					popup.Layout.minimumWidth = previousMinW
					popup.Layout.minimumHeight = previousMinH
				logObj('autoResize:releaseLimits', {
					layoutPrefW: popup.Layout.preferredWidth,
					layoutPrefH: popup.Layout.preferredHeight,
					layoutMinW: popup.Layout.minimumWidth,
					layoutMinH: popup.Layout.minimumHeight,
					layoutMaxW: popup.Layout.maximumWidth,
					layoutMaxH: popup.Layout.maximumHeight,
				})
				if (plasmoid.expanded) {
					plasmoid.expanded = false
					Qt.callLater(function() { plasmoid.expanded = true })
				}
			})
		})

		logObj('autoResize:apply', {
			changedCols: changedCols,
			changedHeight: changedHeight,
			newFavGridCols: plasmoid.configuration.favGridCols,
			newPopupHeightCfg: plasmoid.configuration.popupHeight,
			popupWidthNow: width,
			popupHeightNow: height,
			targetWidth: targetWidth,
			targetHeight: targetHeight,
		})

		// Log again on the next frame so we can see the actual size after bindings settle.
		Qt.callLater(function() {
			logObj('autoResize:postLayout', {
				popupWidth: width,
				popupHeight: height,
				favGridCols: plasmoid.configuration.favGridCols,
				popupHeightCfg: plasmoid.configuration.popupHeight,
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

		var previousMinW = popup.Layout.minimumWidth
		var previousMinH = popup.Layout.minimumHeight
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
				popup.Layout.minimumWidth = previousMinW
				popup.Layout.minimumHeight = previousMinH
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

		var previousMinW = popup.Layout.minimumWidth
		popup.Layout.preferredWidth = targetWidth
		popup.Layout.minimumWidth = targetWidth
		popup.Layout.maximumWidth = targetWidth
		popup.implicitWidth = targetWidth
		popup.width = targetWidth

		Qt.callLater(function() {
			popup.width = targetWidth
			Qt.callLater(function() {
				popup.Layout.maximumWidth = -1
				popup.Layout.minimumWidth = previousMinW
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
			popup.autoResizeToContent()
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
			popup.restoreRememberedSizeForCurrentView()
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
		if (plasmoid.expanded) {
			popup.restoreRememberedSizeForCurrentView()
		}
	}
	Screen.onDevicePixelRatioChanged: {
		var currentDpr = popup.effectiveDevicePixelRatio()
		if (Math.abs(currentDpr - popup._lastKnownDevicePixelRatio) > 0.01) {
			popup._lastKnownDevicePixelRatio = currentDpr
			popup.scheduleDprSyncRestore()
		}
	}
	// Watch plasmoid.expanded via a bound property instead of Connections
	property bool plasmoidExpanded: (plasmoid && typeof plasmoid.expanded !== "undefined") ? plasmoid.expanded : false
	onPlasmoidExpandedChanged: {
		if (plasmoidExpanded) {
			popup._lastKnownDevicePixelRatio = popup.effectiveDevicePixelRatio()
			if (searchView && typeof searchView.setActiveSizeMemoryView === "function" && typeof searchView.resolveConfiguredDefaultView === "function") {
				searchView.setActiveSizeMemoryView(searchView.resolveConfiguredDefaultView())
			}
			popup.restoreRememberedSizeForCurrentView()
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
	}

	Timer {
		id: persistSizeDebounced
		interval: 400
		repeat: false
		onTriggered: {
			if (!popup._persistSizeEnabled || popup._suppressPersist || !plasmoid.expanded || !popup._sizeRestored) {
				return
			}
			popup.saveCurrentViewSize()
		}
	}

	onWidthChanged: {
		if (popup._persistSizeEnabled) {
			persistSizeDebounced.restart()
		}
	}
	onHeightChanged: {
		if (popup._persistSizeEnabled) {
			persistSizeDebounced.restart()
		}
	}

	RowLayout {
		anchors.fill: parent
		spacing: 0

		Item {
			id: sidebarPlaceholder
			Layout.preferredWidth: config.sidebarWidth + config.sidebarRightMargin
			Layout.minimumWidth: config.sidebarWidth + config.sidebarRightMargin
			Layout.maximumWidth: config.sidebarWidth + config.sidebarRightMargin
			Layout.fillHeight: true
			visible: config.sidebarOnLeft
		}

		ColumnLayout {
			id: mainColumnLayout
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 0

			// Top sidebar placeholder
			Item {
				id: topSidebarPlaceholder
				Layout.preferredHeight: config.sidebarHeight
				Layout.minimumHeight: config.sidebarHeight
				Layout.maximumHeight: config.sidebarHeight
				Layout.fillWidth: true
				Layout.bottomMargin: config.sidebarRightMargin
				visible: config.sidebarOnTop
			}

			RowLayout {
				id: contentRowLayout
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 0

				SearchView {
					id: searchView
					aiChatModel: popup.aiChatModel
					Layout.fillHeight: true
				}

				// Drag handle for resizing the app area width
				Item {
					id: appAreaResizeHandle
					Layout.fillHeight: true
					Layout.preferredWidth: Kirigami.Units.smallSpacing * 2
					visible: config.showSearch && !config.isEditingTile
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
						// Only extend the grab area toward the tile grid (right), not
						// into the app list where it would overlap the scrollbar.
						anchors.rightMargin: -Kirigami.Units.smallSpacing * 2
						cursorShape: Qt.SplitHCursor
						hoverEnabled: true
						preventStealing: true

						property real dragStartX: 0
						property int dragStartConfigWidth: 0

						onPressed: function(mouse) {
							dragStartX = mapToItem(popup, mouse.x, 0).x
							dragStartConfigWidth = plasmoid.configuration.appListWidth
						}

						onPositionChanged: function(mouse) {
											if (!pressed) return
											var currentX = mapToItem(popup, mouse.x, 0).x
											var dpr = Screen.devicePixelRatio || 1
											var delta = (currentX - dragStartX) / dpr
											var newWidth = Math.round(dragStartConfigWidth + delta)
											// Allow any width value (no fixed clamping). Let plasmoid/config
											// and the layout system handle limits if needed by environment.
											if (plasmoid.configuration.appListWidth !== newWidth) {
												plasmoid.configuration.appListWidth = newWidth
											}
										}
					}
				}

				TileGrid {
					id: tileGrid
					Layout.fillWidth: true
					Layout.fillHeight: true

					cellSize: config.cellSize
					cellMargin: config.cellMargin
					cellPushedMargin: config.cellPushedMargin

					tileModel: config.tileModel.value

					onEditTile: function(tile) { tileEditorViewLoader.open(tile) }

					onTileModelChanged: saveTileModel.restart()
					Timer {
						id: saveTileModel
						interval: 2000
						onTriggered: config.tileModel.save()
					}
				}
			}

			// Bottom sidebar placeholder
			Item {
				id: bottomSidebarPlaceholder
				Layout.preferredHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.minimumHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.maximumHeight: config.sidebarHeight + config.sidebarRightMargin
				Layout.fillWidth: true
				visible: config.sidebarOnBottom

				// The horizontal sidebar contains its own centered SearchField (in
				// SidebarView.RowLayout) to avoid overlap / z-order issues. This placeholder
				// remains so the rest of the layout reserves space when the sidebar is
				// positioned at the bottom.
			}
		}
	}

	SidebarView {
		id: sidebarView
		popup: popup
	}

	onClicked: searchView.focusPrimaryInput()
}
