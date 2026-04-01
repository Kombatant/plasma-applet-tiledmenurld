import QtQuick

Item {
	id: searchView
	implicitWidth: config.appAreaWidth

	visible: opacity > 0
	opacity: config.showSearch ? 1 : 0

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
	property alias jumpToLetterView: jumpToLetterView
	property alias aiChatView: aiChatView
	property var aiChatModel
	property string activeSizeMemoryView: "Alphabetical"
	readonly property bool widgetExpanded: (typeof widget !== "undefined" && widget && typeof widget.expanded !== "undefined") ? widget.expanded : false

	readonly property bool showingOnlyTiles: !config.showSearch
	readonly property bool showingAppList: stackView.currentItem == appsView || stackView.currentItem == jumpToLetterView
	readonly property bool showingAiChat: config.showSearch && stackView.currentItem == aiChatView
	readonly property bool showingAppsAlphabetically: config.showSearch && appsModel.order == "alphabetical" && showingAppList
	readonly property bool showingAppsCategorically: config.showSearch && appsModel.order == "categories" && showingAppList
	readonly property bool showSearchField: showingAiChat ? false : (config.hideSearchField ? !!searchField.text : true)
	readonly property string lastRememberedSizeMemoryView: {
		var rememberedView = normalizeViewName(plasmoid.configuration.lastUsedAppListView)
		return normalizeSizeMemoryView(rememberedView)
	}

	readonly property bool searchOnTop: config.searchOnTop
	property bool _escapeClearingQuery: false

	Connections {
		target: searchField
		function onEscapeClearsSearchRequested() {
			// Special-case Esc when the user has already typed.
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
		var normalizedView = normalizeViewName(viewName)
		if (plasmoid.configuration.lastUsedAppListView !== normalizedView) {
			plasmoid.configuration.lastUsedAppListView = normalizedView
		}
	}

	function resolveConfiguredDefaultView() {
		var configuredView = plasmoid.configuration.defaultAppListView
		if (configuredView === "LastUsedView") {
			return normalizeViewName(plasmoid.configuration.lastUsedAppListView)
		}
		return normalizeViewName(configuredView)
	}

	function openView(viewName) {
		var resolvedView = normalizeViewName(viewName)
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
		if (searchField && typeof searchField.forceActiveFocus === "function") {
			searchField.forceActiveFocus()
		}
	}

	function focusAndInsert(text) {
		if (showingAiChat && aiChatView && typeof aiChatView.focusAndInsert === "function") {
			aiChatView.focusAndInsert(text)
			return
		}
		if (searchField && typeof searchField.focusAndInsert === "function") {
			searchField.focusAndInsert(text)
		}
	}

	function showTilesOnly() {
		saveCurrentSizeMemoryViewBeforeSwitch()
		rememberView("TilesOnly")
		setActiveSizeMemoryView("TilesOnly")
		if (!showingAppList) {
			// appsView.show(stackView.noTransition)
		
			appsView.show()
			
		}
		config.showSearch = false
		popup.restoreRememberedSizeForView("TilesOnly")
	}

	function showSearchView() {
		config.showSearch = true
	}

	function showAiChat() {
		saveCurrentSizeMemoryViewBeforeSwitch()
		rememberView("AiChat")
		setActiveSizeMemoryView("AiChat")
		config.showSearch = true
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
			name: "searchOnTop"
			when: searchOnTop
			PropertyChanges {
				target: stackViewContainer
				anchors.topMargin: searchField.visible ? searchField.height: 0
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
			when: !searchOnTop
			PropertyChanges {
				target: stackViewContainer
				anchors.bottomMargin: searchField.visible ? searchField.height : 0
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
							appsView.show()
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

			function showAppsAlphabetically() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("Alphabetical")
				searchView.setActiveSizeMemoryView("Alphabetical")
				appsModel.order = "alphabetical"
				show()
			}

			function showAppsCategorically() {
				searchView.saveCurrentSizeMemoryViewBeforeSwitch()
				searchView.rememberView("Categories")
				searchView.setActiveSizeMemoryView("Categories")
				appsModel.order = "categories"
				
				show()
			}

			function show(animation) {
				config.showSearch = true
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
				config.showSearch = true
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
			// asynchronous: true
			function open(tile) {
				config.showSearch = true
				active = true
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
	}
    

	SearchField {
		id: searchField
		// Hide the main search field when the sidebar is at the top or bottom so
		// only the centered sidebar search is visible in those configurations.
		visible: !config.isEditingTile && searchView.showSearchField && !config.sidebarOnBottom && !config.sidebarOnTop
		height: config.searchFieldHeight
		implicitHeight: config.searchFieldHeight
		
		anchors.left: parent.left
		readonly property var _targetListView: (listView && typeof listView.width === 'number') ? listView : null
		width: _targetListView ? _targetListView.width : parent.width

		listView: stackView.currentItem && stackView.currentItem.listView ? stackView.currentItem.listView : []
	}
}
