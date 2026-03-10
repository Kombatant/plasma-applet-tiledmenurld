import QtQuick

KickerListView { // RunnerResultsList
	id: searchResultsList

	model: search.results
	property bool groupedResultsEnabled: plasmoid.configuration.searchResultsGrouped
	property bool collapsibleGroupsEnabled: groupedResultsEnabled && !!plasmoid.configuration.sidebarCollapsibleSearchResults
	property var collapsedSections: ({})

	function isSectionCollapsed(sectionName) {
		if (!collapsibleGroupsEnabled) {
			return false
		}
		var key = (typeof sectionName === "undefined" || sectionName === null) ? "" : ("" + sectionName)
		return collapsedSections[key] === true
	}

	function isIndexVisible(itemIndex) {
		if (itemIndex < 0 || itemIndex >= count || !model) {
			return false
		}
		var item = model.get(itemIndex)
		if (!item) {
			return false
		}
		return !isSectionCollapsed(item.sectionName)
	}

	function nextVisibleIndex(fromIndex, step) {
		for (var itemIndex = fromIndex + step; itemIndex >= 0 && itemIndex < count; itemIndex += step) {
			if (isIndexVisible(itemIndex)) {
				return itemIndex
			}
		}
		return -1
	}

	function firstVisibleIndex() {
		return nextVisibleIndex(-1, 1)
	}

	function ensureCurrentIndexVisible() {
		if (count === 0) {
			currentIndex = -1
			return
		}
		if (isIndexVisible(currentIndex)) {
			return
		}
		var nextIndex = nextVisibleIndex(currentIndex, 1)
		if (nextIndex === -1) {
			nextIndex = nextVisibleIndex(currentIndex, -1)
		}
		currentIndex = nextIndex
	}

	function resetSectionCollapseState() {
		var nextState = {}
		if (collapsibleGroupsEnabled && model) {
			var seenFirstSection = false
			for (var itemIndex = 0; itemIndex < count; itemIndex++) {
				var item = model.get(itemIndex)
				var key = item && typeof item.sectionName !== "undefined" && item.sectionName !== null
					? ("" + item.sectionName)
					: ""
				if (typeof nextState[key] === "undefined") {
					nextState[key] = seenFirstSection
					seenFirstSection = true
				}
			}
		}
		collapsedSections = nextState
		currentIndex = firstVisibleIndex()
	}

	function toggleSectionCollapsed(sectionName) {
		if (!collapsibleGroupsEnabled) {
			return
		}
		var key = (typeof sectionName === "undefined" || sectionName === null) ? "" : ("" + sectionName)
		var nextState = Object.assign({}, collapsedSections)
		nextState[key] = !isSectionCollapsed(key)
		collapsedSections = nextState
		ensureCurrentIndexVisible()
	}

	function stepVisible(step, amount) {
		if (count === 0) {
			return
		}
		var candidate = currentIndex
		for (var moved = 0; moved < amount; moved++) {
			candidate = nextVisibleIndex(candidate, step)
			if (candidate === -1) {
				if (!keyNavigationWraps) {
					break
				}
				candidate = step > 0 ? firstVisibleIndex() : nextVisibleIndex(count, -1)
				if (candidate === -1) {
					break
				}
			}
		}
		if (candidate !== -1) {
			currentIndex = candidate
		}
	}

	function triggerCurrentIndex() {
		ensureCurrentIndexVisible()
		if (currentIndex >= 0 && model && typeof model.triggerIndex === "function") {
			model.triggerIndex(currentIndex)
		}
	}

	delegate: MenuListItem {
		readonly property bool sectionCollapsed: searchResultsList.isSectionCollapsed(model.sectionName)
		visible: !searchResultsList.collapsibleGroupsEnabled || !sectionCollapsed
		height: visible ? implicitHeight : 0
		enabled: visible
		// Use the icon already captured in the result model instead of re-fetching
		// from the runner. This avoids stale-index issues when filters change and
		// the runner model structure is updated.
		iconSource: model.icon || ""
		iconSize: config.appListIconSize
	}
	
	section.property: plasmoid.configuration.searchResultsGrouped ? 'sectionName' : ''
	section.criteria: ViewSection.FullString
	section.delegate: KickerSectionHeader {
		collapsible: searchResultsList.collapsibleGroupsEnabled
		collapsed: searchResultsList.isSectionCollapsed(section)
		collapseToggler: function() {
			searchResultsList.toggleSectionCollapsed(section)
		}
	}

	Connections {
		target: search.results
		function onRefreshing() {
			searchResultsList.currentIndex = -1
		}
		function onRefreshed() {
			searchResultsList.resetSectionCollapseState()
		}
	}

	onGroupedResultsEnabledChanged: resetSectionCollapseState()
	onCollapsibleGroupsEnabledChanged: resetSectionCollapseState()

	function goUp() {
		stepVisible(-1, 1)
	}

	function goDown() {
		stepVisible(1, 1)
	}

	function skipToMin() {
		stepVisible(-1, 10)
	}

	function skipToMax() {
		stepVisible(1, 10)
	}

}
