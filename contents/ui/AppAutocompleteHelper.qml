import QtQuick
import org.kde.plasma.private.kicker as Kicker
import "." as TiledMenu

QtObject {
	id: helper

	property var appletInterface: (typeof plasmoid !== "undefined" && plasmoid) ? plasmoid : helper
	property int maxResults: 10

	readonly property int installedCount: installedAppsModel.count
	readonly property var suggestionsProvider: function(value) { return helper.appSuggestionItemsForInput(value) }

	function endsWith(a, b) {
		return a.indexOf(b, a.length - b.length) !== -1
	}

	property var _rootModel: Kicker.RootModel {
		appletInterface: helper.appletInterface
		flat: true
		showSeparators: false
		showAllApps: true
		showRecentApps: false
		showRecentDocs: false
		autoPopulate: false

		Component.onCompleted: _refreshTimer.restart()
		onCountChanged: _debounce.restart()
		onRefreshed: _debounce.restart()
	}

	property var _refreshTimer: Timer {
		interval: 0
		repeat: false
		onTriggered: helper._rootModel.refresh()
	}

	property var _debounce: Timer {
		interval: 50
		repeat: false
		onTriggered: installedAppsModel.refresh()
	}

	property var installedAppsModel: TiledMenu.KickerListModel {
		function refresh() {
			refreshing()
			var appList = []
			var sourceModel = helper._rootModel.count > 0 ? helper._rootModel.modelForRow(0) : null
			if (sourceModel) {
				parseModel(appList, sourceModel)
			}
			appList = appList.filter(function(item) {
				return item && item.name
			}).sort(function(a, b) {
				return ("" + a.name).toLowerCase().localeCompare(("" + b.name).toLowerCase())
			})
			list = appList
			refreshed()
		}
	}

	function desktopEntryIdFromUrl(url) {
		var value = ("" + (url || "")).trim()
		if (!value.length) return ""
		var queryIndex = value.indexOf("?")
		if (queryIndex >= 0) value = value.substring(0, queryIndex)
		var fragmentIndex = value.indexOf("#")
		if (fragmentIndex >= 0) value = value.substring(0, fragmentIndex)
		var lastSlash = Math.max(value.lastIndexOf("/"), value.lastIndexOf(":"))
		var entryId = lastSlash >= 0 ? value.substring(lastSlash + 1) : value
		return endsWith(entryId, ".desktop") ? entryId : ""
	}

	function desktopEntryIdForApp(app) {
		if (!app) return ""
		if (app.favoriteId && endsWith(app.favoriteId, ".desktop")) return app.favoriteId
		return desktopEntryIdFromUrl(app.url)
	}

	function suggestionScore(candidate, query) {
		var lowerQuery = query.toLowerCase()
		var fields = [candidate.label || "", candidate.value || "", candidate.description || ""]
		var bestScore = -1
		for (var i = 0; i < fields.length; i++) {
			var field = ("" + fields[i]).toLowerCase()
			var index = field.indexOf(lowerQuery)
			if (index < 0) continue
			var score = 1000 - index - field.length
			if (index === 0) score += 250
			if (i === 0) score += 200
			else if (i === 1) score += 100
			if (score > bestScore) bestScore = score
		}
		return bestScore
	}

	function appSuggestionItemsForInput(value) {
		var query = ("" + value).trim()
		if (!query.length) return []
		var results = []
		var seen = {}
		for (var i = 0; i < installedAppsModel.count; i++) {
			var app = installedAppsModel.get(i)
			var entryId = desktopEntryIdForApp(app)
			if (!entryId.length || seen[entryId]) continue
			var candidate = {
				value: entryId,
				label: app.name || entryId,
				description: app.description || entryId
			}
			var score = suggestionScore(candidate, query)
			if (score < 0) continue
			candidate.score = score
			results.push(candidate)
			seen[entryId] = true
		}
		results.sort(function(a, b) {
			if (a.score !== b.score) return b.score - a.score
			return (a.label || "").toLowerCase().localeCompare((b.label || "").toLowerCase())
		})
		return results.slice(0, maxResults)
	}
}
