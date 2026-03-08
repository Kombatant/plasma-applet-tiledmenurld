import QtQuick
import org.kde.plasma.private.kicker as Kicker

Item {
	id: appsModel
	property alias rootModel: rootModel
	property alias allAppsModel: allAppsModel
	property alias powerActionsModel: powerActionsModel
	property alias favoritesModel: favoritesModel
	property alias tileGridModel: tileGridModel
	property alias sidebarModel: sidebarModel

	property string order: "categories"
	onOrderChanged: allAppsModel.refresh()


	signal refreshing()
	signal refreshed()

	Timer {
		id: rootModelRefresh
		interval: 400
		onTriggered: {
			logger.debug('rootModel.refresh.star', Date.now())
			rootModel.refresh()
			logger.debug('rootModel.refresh.done', Date.now())
		}
	}

	readonly property string recentAppsSectionLabel: {
		if (rootModel.recentOrdering == 0) {
			return i18n("Recent Apps")
		} else { // == 1
			return i18n("Most Used ")
		}
	}
	readonly property string recentAppsSectionKey: 'RECENT_APPS'

	Kicker.RootModel {
		id: rootModel
		appNameFormat: 0 // plasmoid.configuration.appNameFormat
		flat: true // isDash ? true : plasmoid.configuration.limitDepth
		// sorted: Plasmoid.configuration.alphaSort

		showSeparators: false // !isDash
		appletInterface: widget

		// showAllSubtree: true //isDash (KDE 5.8 and below)
		showAllApps: true //isDash (KDE 5.9+)
		// showAllAppsCategorized: false
		showRecentApps: true //plasmoid.configuration.showRecentApps
		showRecentDocs: false //plasmoid.configuration.showRecentDocs
		// showRecentContacts: false //plasmoid.configuration.showRecentContacts
		// showPowerSession: false
		// showFavoritesPlaceholder: true
		recentOrdering: plasmoid.configuration.recentOrdering

		autoPopulate: false // (KDE 5.9+) defaulted to true
		// paginate: false // (KDE 5.9+)

		readonly property int recentAppsIndex: 0
		readonly property int recentDocsIndex: {
			if (rootModel.showRecentDocs) {
				if (rootModel.showRecentApps) {
					return 1
				} else {
					return 0
				}
			} else {
				return -1
			}
		}
		readonly property int allAppsIndex: {
			if (rootModel.showAllApps) {
				if (rootModel.showRecentApps && rootModel.showRecentDocs) {
					return 2
				} else if (rootModel.showRecentApps || rootModel.showRecentDocs) {
					return 1
				} else {
					return 0
				}
			} else {
				return -1
			}
		}
		property int categoryStartIndex: 2 // Skip Recent Apps, All Apps
		property int categoryEndIndex: rootModel.count - 1 // Skip Power

		Component.onCompleted: {
			if (!autoPopulate) {
				rootModelRefresh.restart()
			}
		}

		onCountChanged: {
			debouncedRefresh.restart()
		}
			
		onRefreshed: {
			//--- Power
			var systemModel = rootModel.modelForRow(rootModel.count - 1)
			var systemList = []
			if (systemModel) {
				powerActionsModel.parseModel(systemList, systemModel)
			} else {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('AppsModel: systemModel is null')
				}
			}
			powerActionsModel.list = systemList
			sessionActionsModel.parseSourceModel(powerActionsModel)

			debouncedRefresh.restart()
		}

		// KickerAppModel is a wrapper of Kicker.FavoritesModel
		// Kicker.FavoritesModel must be a child object of RootModel.
		// appEntry.actions() looks at the parent object for parent.appletInterface and will crash plasma if it can't find it.
		// https://invent.kde.org/plasma/plasma-workspace/-/blob/master/applets/kicker/plugin/appentry.cpp#L151
		favoritesModel: KickerAppModel {
			id: favoritesModel

			Component.onCompleted: {
				appsModel.syncTileFavorites([])
			}
		}

		property var tileGridModel: KickerAppModel {
			id: tileGridModel
		}

		property var sidebarModel: KickerAppModel {
			id: sidebarModel

			Component.onCompleted: {
				favorites = plasmoid.configuration.sidebarShortcuts
			}

			onFavoritesChanged: {
				plasmoid.configuration.sidebarShortcuts = favorites
			}
			
			property Connections configConnection: Connections {
				target: plasmoid.configuration
				function onSidebarShortcutsChanged() {
					sidebarModel.favorites = plasmoid.configuration.sidebarShortcuts
				}
			}
		}
	}

	Item {
		//--- Detect Changes
		// Changes aren't bubbled up to the RootModel, so we need to detect changes somehow.
		
		// Recent Apps
		Repeater {
			model: rootModel.count >= 0 ? rootModel.modelForRow(rootModel.recentAppsIndex) : []
			
			Item {
				Component.onCompleted: {
					if (plasmoid.configuration.showRecentApps) {
						debouncedRefreshRecentApps.restart()
					}
				}
			}
		}

		// All Apps
		Repeater { // A-Z
			model: rootModel.count >= 2 ? rootModel.modelForRow(rootModel.allAppsIndex) : []

			Item {
				property var parentModel: rootModel.modelForRow(rootModel.allAppsIndex).modelForRow(index)

				Repeater { // Aaa ... Azz (Apps)
					model: parentModel && parentModel.hasChildren ? parentModel : []

					Item {
						Component.onCompleted: {
							debouncedRefresh.restart()
						}
					}
				}
			}
		}

		Timer {
			id: debouncedRefresh
			interval: 100
			onTriggered: allAppsModel.refresh()
		}

		Timer {
			id: debouncedRefreshRecentApps
			interval: debouncedRefresh.interval
			onTriggered: allAppsModel.refreshRecentApps()
		}
		
		Connections {
			target: plasmoid.configuration
			function onShowRecentAppsChanged() { debouncedRefresh.restart() }
			function onNumRecentAppsChanged() { debouncedRefresh.restart() }
		}
	}

	KickerListModel {
		id: powerActionsModel
		onItemTriggered: {
			plasmoid.expanded = false
		}
		
		function nameByIconName(iconName) {
			var item = getByValue('iconName', iconName)
			if (item) {
				return item.name
			} else {
				return iconName
			}
		}

		function triggerByIconName(iconName) {
			var item = getByValue('iconName', iconName)
			item.parentModel.trigger(item.indexInParent, "", null)
		}
	}

	// powerActionsModel filtered to logout/lock/switch user
	property alias sessionActionsModel: sessionActionsModel
	KickerListModel {
		id: sessionActionsModel
		onItemTriggered: {
			plasmoid.expanded = false
		}

		function parseSourceModel(powerActionsModel) {
			// Filter by iconName
			var sessionActionsList = []
			var sessionIconNames = ['system-lock-screen', 'system-log-out', 'system-save-session', 'system-switch-user']
			for (var i = 0; i < powerActionsModel.list.length; i++) {
				var item = powerActionsModel.list[i];
				if (sessionIconNames.indexOf(item.iconName) >= 0) {
					sessionActionsList.push(item)
				}
			}
			sessionActionsModel.list = sessionActionsList
		}
	}
	
	KickerListModel {
		id: allAppsModel
		onItemTriggered: {
			plasmoid.expanded = false
		}

		function getRecentApps() {
			var recentAppList = [];

			//--- populate
			var model = rootModel.modelForRow(rootModel.recentAppsIndex)
			if (model) {
				parseModel(recentAppList, model)
			} else {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('AppsModel.getRecentApps(): recent apps model is null')
				}
			}

			//--- filter
			recentAppList = recentAppList.filter(function(item){
				//--- filter KCM launcher entries when they show up blank (undefined)
				if (typeof item.name === 'undefined') {
					return false;
				} else {
					return true;
				}
			});

			//--- first 5 items
			recentAppList = recentAppList.slice(0, plasmoid.configuration.numRecentApps)

			//--- section
			for (var i = 0; i < recentAppList.length; i++) {
				var item = recentAppList[i];
				item.sectionKey = recentAppsSectionKey
			}

			return recentAppList;
		}

		function refreshRecentApps() {
			if (debouncedRefresh.running) {
				// We're about to do a full refresh so don't bother doing a partial update.
				return
			}
			var recentAppList = getRecentApps();
			var recentAppCount = 5
			if (recentAppCount == recentAppList.length) {
				// Do a partial update since we're only updating properties.
				refreshing()

				// Overwrite the exisiting items.
				for (var i = 0; i < recentAppList.length; i++) {
					var item = recentAppList[i]
					list[i] = item
					set(i, item)
				}

				refreshed()
			} else {
				// We'll be removing items, so just replace the entire list.
				refresh()
			}
		}

		function getCategory(rootIndex) {
			var modelIndex = rootModel.index(rootIndex, 0)
			var categoryLabel = rootModel.data(modelIndex, Qt.DisplayRole)
			var categoryIcon = rootModel.data(modelIndex, Qt.DecorationRole)
			var categoryModel = rootModel.modelForRow(rootIndex)
			var appList = []
			if (categoryModel) {
				parseModel(appList, categoryModel)
			} else {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('AppsModel.getCategory(): category model is null', rootIndex)
				}
			}
			
			for (var i = 0; i < appList.length; i++) {
				var item = appList[i];
				item.sectionKey = categoryLabel
				item.sectionIcon = categoryIcon
			}
			return appList
		}
		function getAllCategories() {
			var appList = [];
			for (var i = rootModel.categoryStartIndex; i < rootModel.categoryEndIndex; i++) { // Skip Recent Apps, All Apps, ... and Power
			// for (var i = 0; i < rootModel.count; i++) {
				appList = appList.concat(getCategory(i))
			}
			return appList
		}

		function getAllApps() {
			//--- populate list
			var appList = [];
			var model = rootModel.modelForRow(rootModel.allAppsIndex)
			if (model) {
				parseModel(appList, model)
			} else {
				if (typeof logger !== "undefined" && logger) {
					logger.warn('AppsModel.getAllApps(): all apps model is null')
				}
			}

			//---
			for (var i = 0; i < appList.length; i++) {
				var item = appList[i];
				if (item.name) {
					var firstCharCode = item.name.charCodeAt(0);
					if (48 <= firstCharCode && firstCharCode <= 57) { // isDigit
						item.sectionKey = '0-9';
					} else if ((33 <= firstCharCode && firstCharCode <= 47)
						|| (58 <= firstCharCode && firstCharCode <= 64)
						|| (91 <= firstCharCode && firstCharCode <= 96)
						|| (123 <= firstCharCode && firstCharCode <= 126)
					) { // isSymbol
						item.sectionKey = '&';
					} else {
						item.sectionKey = item.name.charAt(0).toUpperCase();
					}
				} else {
					item.sectionKey = '?';
				}
			}

			//--- sort
			appList = appList.sort(function(a,b) {
				if (a.name && b.name) {
					return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
				} else {
					return 0;
				}
			})


			return appList
		}

		function refresh() {
			refreshing()
			logger.debug("allAppsModel.refresh().star", Date.now())
			
			//--- Apps
			var appList = []
			if (appsModel.order == "categories") {
				appList = getAllCategories()
			} else {
				appList = getAllApps()
			}

			//--- Recent Apps
			if (plasmoid.configuration.showRecentApps) {
				var recentAppList = getRecentApps();
				appList = recentAppList.concat(appList); // prepend
			}

			//--- Power
			// var systemModel = rootModel.modelForRow(rootModel.count - 1)
			// var systemList = []
			// parseModel(systemList, systemModel)
			// powerActionsModel.list = systemList;

			//--- parse sectionIcons
			allAppsModel.sectionIcons = {}
			for (var i = 0; i < appList.length; i++) {
				var item = appList[i]
				if (item.sectionKey && item.sectionIcon) {
					allAppsModel.sectionIcons[item.sectionKey] = item.sectionIcon
				}
			}

			//--- apply model
			allAppsModel.list = appList;

			logger.debug("allAppsModel.refresh().done", Date.now())
			refreshed()
		}
	}

	function syncTileFavorites(urlList) {
		if (!favoritesModel || !Array.isArray(urlList)) {
			return
		}
		var unique = []
		var seen = {}
		for (var i = 0; i < urlList.length; i++) {
			var url = urlList[i]
			if (!url || typeof url !== "string") {
				continue
			}
			if (seen[url]) {
				continue
			}
			seen[url] = true
			unique.push(url)
		}
		var existing = favoritesModel.favorites
		if (Array.isArray(existing) && existing.length === unique.length) {
			var same = true
			for (var j = 0; j < existing.length; j++) {
				if (existing[j] !== unique[j]) {
					same = false
					break
				}
			}
			if (same) {
				return
			}
		}
		favoritesModel.favorites = unique
	}

	function endsWith(s, substr) {
		return s.indexOf(substr) == s.length - substr.length
	}

	function launch(launcherName) {
		if (!endsWith(launcherName, '.desktop')) {
			launcherName += '.desktop'
		}
		for (var i = 0; i < allAppsModel.count; i++) {
			var item = allAppsModel.get(i);
			if (item.url && endsWith(item.url, '/' + launcherName)) {
				item.parentModel.trigger(item.indexInParent, "", null);
				break;
			}
		}
	}
}
