import QtQuick
import org.kde.plasma.private.kicker as Kicker

Item {
	id: search
	property alias results: resultModel
	property alias runnerModel: runnerModel

	property string query: ""
	property bool isSearching: query.length > 0
	onQueryChanged: {
		runnerModel.query = search.query
		// Clear results immediately when query is cleared.
		// Don't trigger debouncedRefresh here - rely on onQueryFinished.
		if (search.query.length === 0) {
			resultModel.clear()
		}
	}

	// KRunner runners are defined in /usr/share/kservices5/plasma-runner-*.desktop
	// To list the runner ids, use:
	//     find /usr/share/kservices5/ -iname "plasma-runner-*.desktop" -print0 | xargs -0 grep "PluginInfo-Name" | sort
	property var filters: []
	onFiltersChanged: {
		// Save query and clear it first - this makes the RunnerModel clear its internal state
		var savedQuery = search.query
		
		// Clear the query on the RunnerModel BEFORE changing runners
		// This ensures the model releases its stale data
		runnerModel.query = ""
		
		// Empty QStringList == all runners; avoid assigning undefined (Qt 6 rejects it)
		var runnerList = Array.isArray(filters) ? filters : []
		runnerModel.runners = runnerList.length === 0 ? [] : runnerList

		// Clear stale results immediately so the UI doesn't show old data.
		resultModel.clear()

		// Re-run the current query with the updated runner set.
		// Use a timer to ensure the runners change has propagated before re-querying.
		if (savedQuery.length > 0) {
			filterQueryTimer.savedQuery = savedQuery
			filterQueryTimer.restart()
		}
	}

	Timer {
		id: filterQueryTimer
		property string savedQuery: ""
		interval: 100
		repeat: false
		onTriggered: {
			// The RunnerModel ignores query changes if the query string is identical.
			// We need to set a different query and then restore, using a timer between
			// so the model actually processes the change.
			runnerModel.query = ""
			filterRestoreQueryTimer.restart()
		}
	}

	Timer {
		id: filterRestoreQueryTimer
		interval: 50
		repeat: false
		onTriggered: {
			runnerModel.query = filterQueryTimer.savedQuery
			// Also schedule a manual refresh in case onQueryFinished doesn't fire
			filterRefreshTimer.restart()
		}
	}

	Timer {
		id: filterRefreshTimer
		interval: 200
		repeat: false
		onTriggered: {
			resultModel.refresh()
		}
	}

	Kicker.RunnerModel {
		id: runnerModel

		appletInterface: plasmoid
		favoritesModel: rootModel.favoritesModel
		mergeResults: true

		// runners: [] // Empty = All runners.

		// deleteWhenEmpty: isDash
		// deleteWhenEmpty: false

		// Don't use onRunnersChanged, onDataChanged, or onCountChanged to trigger
		// refresh as these fire when the model is in a transitional state with
		// stale count values but undefined data.
		// onRunnersChanged: debouncedRefresh.restart()
		// onDataChanged: debouncedRefresh.restart()
		// onCountChanged: debouncedRefresh.restart()

		// Wait for the runner to finish querying before refreshing results.
		// This is the only reliable signal that indicates fresh data is available.
		onQueryFinished: {
			resultModel.refresh()
		}
	}

	Timer {
		id: debouncedRefresh
		interval: 100
		onTriggered: {
			resultModel.refresh()
		}
		function logAndRestart() {
			restart()
		}
	}

	SearchResultsModel {
		id: resultModel
	}

	readonly property var defaultFilters: plasmoid.configuration.searchDefaultFilters
	function defaultFiltersContains(runnerId) {
		return defaultFilters.indexOf(runnerId) != -1
	}
	function addDefaultFilter(runnerId) {
		if (!defaultFiltersContains(runnerId)) {
			var l = plasmoid.configuration.searchDefaultFilters
			l.push(runnerId)
			plasmoid.configuration.searchDefaultFilters = l
		}
	}
	function removeDefaultFilter(runnerId) {
		var i = defaultFilters.indexOf(runnerId)
		if (i >= 0) {
			var l = plasmoid.configuration.searchDefaultFilters
			l.splice(i, 1) // Remove 1 item at index
			plasmoid.configuration.searchDefaultFilters = l
		}
	}

	function isFilter(runnerId) {
		return filters.length == 1 && filters[0] == runnerId
	}
	// Empty filters = all runners (default "All results" state)
	property bool isDefaultFilter: filters.length === 0
	property bool isAppsFilter: isFilter('krunner_services')
	property bool isFileFilter: isFilter('baloosearch')
	property bool isBookmarksFilter: isFilter('krunner_bookmarksrunner')

	function hasFilter(runnerId) {
		return filters.indexOf(runnerId) >= 0
	}

	function applyDefaultFilters() {
		// Default to all runners so all categories (apps/files/etc.) appear.
		filters = []
	}

	function setQueryPrefix(prefix) {
		// First check to see if there's already a prefix we need to replace.
		var firstSpaceIndex = query.indexOf(' ')
		if (firstSpaceIndex > 0) {
			var firstToken = query.substring(0, firstSpaceIndex)

			if (/^type:\w+$/.exec(firstToken) // baloosearch
				|| /^define$/.exec(firstToken) // Dictionary
			) {
				// replace existing prefix
				query = prefix + query.substring(firstSpaceIndex + 1, query.length)
				return
			}
		}
		
		// If not, just prepend the prefix
		var newQuery = prefix + query
		if (newQuery != query) {
			query = prefix + query
		}
	}

	function clearQueryPrefix() {
		setQueryPrefix('')
	}
}
