import QtQuick

Item {
	id: searchView
	implicitWidth: config.appAreaWidth

	visible: opacity > 0
	opacity: (config.usesDockedSidebarLayout || config.showSearch) ? 1 : 0

	Connections {
		target: search
		function onIsSearchingChanged() {
			if (search.isSearching) {
				searchView.showSearchView()
			}
		}
	}
	clip: true

	property alias searchResultsView: searchResultsView
	property alias appsView: appsView
	property alias tileEditorView: tileEditorViewLoader.item
	property alias tileEditorViewLoader: tileEditorViewLoader
	property alias searchField: searchField
	property Item externalSearchField: null
	readonly property bool _useExternalSearch: externalSearchField !== null
	property alias stackView: stackView
	property alias jumpToLetterView: jumpToLetterView
	property alias aiChatView: aiChatView
	property var aiChatModel
	property string activeSizeMemoryView: "Alphabetical"
	readonly property bool aiChatEnabled: plasmoid.configuration.aiChatEnabled !== false
	readonly property bool widgetExpanded: (typeof widget !== "undefined" && widget && typeof widget.expanded !== "undefined") ? widget.expanded : false

	readonly property bool showingOnlyTiles: config.usesClassicLayout && !config.showSearch
	readonly property bool showingAppList: stackView.currentItem == appsView || stackView.currentItem == jumpToLetterView
	readonly property bool showingAiChat: (config.usesDockedSidebarLayout || config.showSearch) && stackView.currentItem == aiChatView
	readonly property bool showingAppsAlphabetically: (config.usesDockedSidebarLayout || config.showSearch) && appsModel.order == "alphabetical" && showingAppList
	readonly property bool showingAppsCategorically: (config.usesDockedSidebarLayout || config.showSearch) && appsModel.order == "categories" && showingAppList
	readonly property bool hideSearchFieldForAiChat: config.usesClassicLayout && showingAiChat
	readonly property string _searchFieldText: {
		var field = _useExternalSearch ? externalSearchField : searchField
		return field && typeof field.text === "string" ? field.text : ""
	}
	readonly property bool showSearchField: !hideSearchFieldForAiChat && (config.hideSearchField ? !!_searchFieldText : true)
	readonly property string lastRememberedSizeMemoryView: {
		var rememberedView = sanitizeViewName(plasmoid.configuration.lastUsedAppListView)
		return normalizeSizeMemoryView(rememberedView)
	}

	readonly property bool searchOnTop: config.searchOnTop && config.usesClassicLayout && config.sidebarOnLeft
	readonly property int searchFieldEdgeInset: (config.usesClassicLayout && config.sidebarOnLeft) ? config.sidebarCardInset : 0
	property bool _escapeClearingQuery: false
	property bool _viewSwitchClearingQuery: false

	Connections {
		target: searchField
		function onEscapeClearsSearchRequested() {
			// Special-case Esc when the user has already typed.
			searchView._escapeClearingQuery = true
			search.query = ""
		}
	}

	Connections {
		target: _useExternalSearch ? externalSearchField : null
		function onEscapeClearsSearchRequested() {
			searchView._escapeClearingQuery = true
			search.query = ""
		}
	}

	function normalizeViewName(viewName) {
		var validViews = [
			"Alphabetical",
			"Categories",
			"JumpToLetter",
			"JumpToCategory",
			"TilesOnly",
			"AiChat",
		]
		return validViews.indexOf(viewName) >= 0 ? viewName : "Alphabetical"
	}

	function sanitizeViewName(viewName) {
		var normalizedView = normalizeViewName(viewName)
		if (!aiChatEnabled && normalizedView === "AiChat") {
			return "Alphabetical"
		}
		return normalizedView
	}

	function normalizeSizeMemoryView(viewName) {
		if (viewName === "Categories" || viewName === "JumpToCategory") {
			return "Categories"
		}
		if (viewName === "TilesOnly" || viewName === "AiChat") {
			return viewName
		}
		return "Alphabetical"
	}

	function setActiveSizeMemoryView(viewName) {
		var normalizedView = normalizeSizeMemoryView(viewName)
		if (activeSizeMemoryView !== normalizedView) {
			activeSizeMemoryView = normalizedView
		}
	}

	function saveCurrentSizeMemoryViewBeforeSwitch() {
		if (popup && popup._sizeRestored && widgetExpanded && typeof popup.saveCurrentViewSize === "function") {
			popup.saveCurrentViewSize()
		}
	}

	function rememberView(viewName) {
		var normalizedView = sanitizeViewName(viewName)
		if (plasmoid.configuration.lastUsedAppListView !== normalizedView) {
			plasmoid.configuration.lastUsedAppListView = normalizedView
		}
	}

	function resolveConfiguredDefaultView() {
		var configuredView = plasmoid.configuration.defaultAppListView
		if (configuredView === "LastUsedView") {
			return sanitizeViewName(plasmoid.configuration.lastUsedAppListView)
		}
		return sanitizeViewName(configuredView)
	}

	function openView(viewName) {
		var resolvedView = sanitizeViewName(viewName)
		if (resolvedView == "Alphabetical") {
			appsView.showAppsAlphabetically()
		} else if (resolvedView == "Categories") {
			appsView.showAppsCategorically()
		} else if (resolvedView == "JumpToLetter") {
			jumpToLetterView.showLetters()
		} else if (resolvedView == "JumpToCategory") {
			jumpToLetterView.showCategories()
		} else if (resolvedView == "TilesOnly") {
			searchView.showTilesOnly()
		} else if (resolvedView == "AiChat") {
			searchView.showAiChat()
		}
	}

	function showDefaultView() {
		setActiveSizeMemoryView(resolveConfiguredDefaultView())
		openView(resolveConfiguredDefaultView())
	}

	function focusPrimaryInput() {
		if (showingAiChat && aiChatView && typeof aiChatView.focusComposer === "function") {
			aiChatView.focusComposer()
			return
		}
		var field = _useExternalSearch ? externalSearchField : searchField
		if (field && typeof field.forceActiveFocus === "function") {
			field.forceActiveFocus()
		}
	}

	function focusAndInsert(text) {
		if (showingAiChat && aiChatView && typeof aiChatView.focusAndInsert === "function") {
			aiChatView.focusAndInsert(text)
			return
		}
		var field = _useExternalSearch ? externalSearchField : searchField
		if (field && typeof field.focusAndInsert === "function") {
			field.focusAndInsert(text)
		}
	}

	function showTilesOnly() {
		saveCurrentSizeMemoryViewBeforeSwitch()
		rememberView("TilesOnly")
		setActiveSizeMemoryView("TilesOnly")
		if (search.query !== "") {
			_viewSwitchClearingQuery = true
			search.query = ""
		}
		// Reset the stack to appsView without going through appsView.show(),
		// which would set showSearch=true and trigger size restores.
		if (stackView.currentItem !== appsView) {
			stackView.replace(appsView)
		}
		config.showSearch = false
		config.searchOverlayActive = false
		popup.restoreRememberedSizeForView("TilesOnly")
	}

	function showSearchView() {
		if (showingOnlyTiles) {
			config.searchOverlayActive = true
		}
		config.showSearch = true
	}

	function showAiChat() {
		if (!aiChatEnabled) {
			appsView.showAppsAlphabetically()
			return
		}
		// Trigger lazy AiChatModel construction in main.qml.
		if (typeof popup !== "undefined" && popup) {
			popup.aiChatViewRequested()
		}
		saveCurrentSizeMemoryViewBeforeSwitch()
		rememberView("AiChat")
		setActiveSizeMemoryView("AiChat")
		config.searchOverlayActive = false
		config.showSearch = true
		if (search.query !== "") {
			_viewSwitchClearingQuery = true
			search.query = ""
		}
		if (stackView.currentItem !== aiChatView) {
			stackView.replace(aiChatView)
		}
		popup.restoreRememberedSizeForView("AiChat")
		Qt.callLater(function() {
			focusPrimaryInput()
		})
	}

	states: [
		State {
			name: "externalSearch"
			when: _useExternalSearch
			PropertyChanges {
				target: stackViewContainer
				anchors.topMargin: 0
				anchors.bottomMargin: 0
			}
		},
		State {
			name: "searchOnTop"
			when: !_useExternalSearch && searchOnTop
			PropertyChanges {
				target: stackViewContainer
				anchors.topMargin: searchField.visible ? searchField.height + searchView.searchFieldEdgeInset : 0
				anchors.bottomMargin: 0
			}
			AnchorChanges {
				target: searchField
				anchors.top: searchField.parent.top
				anchors.bottom: undefined
			}
		},
		State {
			name: "searchOnBottom"
			when: !_useExternalSearch && !searchOnTop
			PropertyChanges {
				target: stackViewContainer
				anchors.bottomMargin: searchField.visible ? searchField.height + searchView.searchFieldEdgeInset : 0
				anchors.topMargin: 0
			}
			AnchorChanges {
				target: searchField
				anchors.top: undefined
				anchors.bottom: searchField.parent.bottom
			}
		}
	]


	Item {
		id: stackViewContainer
		anchors.fill: parent

	     

		SearchResultsView {
			id: searchResultsView
			visible: false

			Connections {
				target: search
				function onQueryChanged() {
					if (search.query.length > 0) {
						if (stackView.currentItem != searchResultsView) {
							stackView.replace(searchResultsView)
						}
					} else {
						// When clearing the query, return to the app list.
						search.applyDefaultFilters()
						if (searchView._escapeClearingQuery) {
							searchView._escapeClearingQuery = false
							if (config.searchOverlayActive) {
								searchView.showTilesOnly()
							} else {
								appsView.show()
							}
						} else if (searchView._viewSwitchClearingQuery) {
							searchView._viewSwitchClearingQuery = false
						} else {
							searchView.showDefaultView()
						}
					}
					searchResultsView.filterViewOpen = false
				}
				}

				onVisibleChanged: {
				if (!visible) { // !stackView.currentItem
					search.query = ""
				}
			}

			function showDefaultSearch() {
				if (stackView.currentItem != searchResultsView) {
					stackView.replace(searchResultsView)
				}
				search.applyDefaultFilters()
			}
		}
		
		AppsView {
			id: appsView
			visible: false

			function _captureSlideSnapshot(direction) {
				if (!config.usesDockedSidebarLayout) return false
				if (stackView.currentItem !== appsView) return false
				if (appsViewSlideSnapshot.visible) return false
				var dpr = Screen.devicePixelRatio || 1
				var w = appsView.width
				var h = appsView.height
				if (w <= 0 || h <= 0) return false
				var grabW = Math.max(1, Math.round(w * dpr))
				var grabH = Math.max(1, Math.round(h * dpr))
				appsView.grabToImage(function(result) {
					appsViewSlideSnapshot.source = result.url
					appsViewSlideSnapshot.width = w
					appsViewSlideSnapshot.height = h
					appsViewSlideSnapshot.x = 0
					appsViewSlideSnapshot.y = 0
					appsViewSlideSnapshot.visible = true
					appsViewSlideAnim.to = -direction * w
					appsViewSlideAnim.start()
					appsView.x = direction * w
					appsViewEnterAnim.to = 0
					appsViewEnterAnim.start()
				}, Qt.size(grabW, grabH))
				return true
			}

			function showAppsAlphabetically() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("Alphabetical")
				searchView.setActiveSizeMemoryView("Alphabetical")
				if (appsModel.order !== "alphabetical") {
					var dir = stackView.slideDirection || 1
					appsView._captureSlideSnapshot(dir)
				}
				appsModel.order = "alphabetical"
				show()
			}

			function showAppsCategorically() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("Categories")
				searchView.setActiveSizeMemoryView("Categories")
				if (appsModel.order !== "categories") {
					var dir = stackView.slideDirection || -1
					appsView._captureSlideSnapshot(dir)
				}
				appsModel.order = "categories"

				show()
			}

			function show(animation) {
				config.searchOverlayActive = false
				config.showSearch = true
				if (search.query !== "") {
					searchView._viewSwitchClearingQuery = true
					search.query = ""
				}
				if (stackView.currentItem != appsView) {
					// stackView.delegate = animation || stackView.panUp
					stackView.replace(appsView)
				}
				popup.restoreRememberedSizeForView(searchView.activeSizeMemoryView)
				appsView.scrollToTop()
			}
		}

		JumpToLetterView {
			id: jumpToLetterView
			visible: false
			
			function showLetters() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("JumpToLetter")
				searchView.setActiveSizeMemoryView("JumpToLetter")
				appsModel.order = "alphabetical"
				
				show()
			}

			function showCategories() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("JumpToCategory")
				searchView.setActiveSizeMemoryView("JumpToCategory")
				appsModel.order = "categories"
				show()
			}

			function show() {
				config.searchOverlayActive = false
				config.showSearch = true
				if (search.query !== "") {
					searchView._viewSwitchClearingQuery = true
					search.query = ""
				}
				if (stackView.currentItem != jumpToLetterView) {
					// stackView.delegate = stackView.zoomOut
					stackView.replace(jumpToLetterView)
				}
				popup.restoreRememberedSizeForView(searchView.activeSizeMemoryView)
			}
		}

		AiChatView {
			id: aiChatView
			visible: false
			chatModel: aiChatModel
		}

		Loader {
			id: tileEditorViewLoader
			source: "TileEditorView.qml"
			visible: false
			active: false
			asynchronous: true
			function open(tile, grid) {
				config.searchOverlayActive = false
				config.showSearch = true
				active = true
				if (grid !== undefined) item.tileGrid = grid
				item.open(tile)
			}
			readonly property bool isCurrentView: stackView.currentItem == tileEditorView
			onIsCurrentViewChanged: {
				config.isEditingTile = isCurrentView
			}
		}

		SearchStackView {
			id: stackView
			anchors.fill: parent
			initialItem: appsView
		}

		Image {
			id: appsViewSlideSnapshot
			visible: false
			smooth: true
			cache: false
			fillMode: Image.Stretch
			x: 0
			y: 0
			z: 10
		}

		NumberAnimation {
			id: appsViewSlideAnim
			target: appsViewSlideSnapshot
			property: "x"
			duration: 280
			easing.type: Easing.OutCubic
			onStopped: {
				appsViewSlideSnapshot.visible = false
				appsViewSlideSnapshot.source = ""
			}
		}

		NumberAnimation {
			id: appsViewEnterAnim
			target: appsView
			property: "x"
			duration: 280
			easing.type: Easing.OutCubic
			onStopped: appsView.x = 0
		}
		}


		SearchField {
		id: searchField
		// Hide when using the Docked Sidebar layout external search field, or when
		// sidebar is at top/bottom (centered sidebar search is visible instead).
		visible: !_useExternalSearch && !config.isEditingTile && searchView.showSearchField && !config.sidebarOnBottom && !config.sidebarOnTop
		height: config.searchFieldHeight
		implicitHeight: config.searchFieldHeight
		
		anchors.left: parent.left
		anchors.topMargin: searchView.searchFieldEdgeInset
		anchors.bottomMargin: searchView.searchFieldEdgeInset
		readonly property var _targetListView: (listView && typeof listView.width === 'number') ? listView : null
		width: _targetListView ? _targetListView.width : parent.width

		listView: stackView.currentItem && stackView.currentItem.listView ? stackView.currentItem.listView : []
	}
}
