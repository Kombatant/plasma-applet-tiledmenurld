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

	readonly property bool showingOnlyTiles: !config.showSearch
	readonly property bool showingAppList: stackView.currentItem == appsView || stackView.currentItem == jumpToLetterView
	readonly property bool showingAiChat: config.showSearch && stackView.currentItem == aiChatView
	readonly property bool showingAppsAlphabetically: config.showSearch && appsModel.order == "alphabetical" && showingAppList
	readonly property bool showingAppsCategorically: config.showSearch && appsModel.order == "categories" && showingAppList
	readonly property bool showSearchField: showingAiChat ? false : (config.hideSearchField ? !!searchField.text : true)

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

	function showDefaultView() {
		var defView = plasmoid.configuration.defaultAppListView
		if (defView == 'Alphabetical') {
			appsView.showAppsAlphabetically()
			config.showSearch = true
		} else if (defView == 'Categories') {
			appsView.showAppsCategorically()
			config.showSearch = true
		} else if (defView == 'JumpToLetter') {
			jumpToLetterView.showLetters()
			config.showSearch = true
		} else if (defView == 'JumpToCategory') {
			jumpToLetterView.showCategories()
			config.showSearch = true
		} else if (defView == 'TilesOnly') {
			searchView.showTilesOnly()
		} else if (defView == 'AiChat') {
			searchView.showAiChat()
		}
		
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
		if (!showingAppList) {
			// appsView.show(stackView.noTransition)
		
			appsView.show()
			
		}
		plasmoid.configuration.defaultAppListView = 'TilesOnly'
		config.showSearch = false
	}

	function showSearchView() {
		config.showSearch = true
	}

	function showAiChat() {
		config.showSearch = true
		plasmoid.configuration.defaultAppListView = 'AiChat'
		if (stackView.currentItem !== aiChatView) {
			stackView.replace(aiChatView)
		}
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
				appsModel.order = "alphabetical"
				plasmoid.configuration.defaultAppListView = 'Alphabetical'
				show()
			}

			function showAppsCategorically() {
				appsModel.order = "categories"
				plasmoid.configuration.defaultAppListView = 'Categories'
				
				show()
			}

			function show(animation) {
				config.showSearch = true
				if (stackView.currentItem != appsView) {
					// stackView.delegate = animation || stackView.panUp
					stackView.replace(appsView)
				}
				appsView.scrollToTop()
			}
		}

		JumpToLetterView {
			id: jumpToLetterView
			visible: false
			
			function showLetters() {
				appsModel.order = "alphabetical"
				
				show()
			}

			function showCategories() {
				appsModel.order = "categories"
				show()
			}

			function show() {
				config.showSearch = true
				if (stackView.currentItem != jumpToLetterView) {
					// stackView.delegate = stackView.zoomOut
					stackView.replace(jumpToLetterView)
				}
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
