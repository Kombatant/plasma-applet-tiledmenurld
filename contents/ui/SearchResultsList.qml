import QtQuick

KickerListView { // RunnerResultsList
	id: searchResultsList

	model: search.results
	delegate: MenuListItem {
		// Use the icon already captured in the result model instead of re-fetching
		// from the runner. This avoids stale-index issues when filters change and
		// the runner model structure is updated.
		iconSource: model.icon || ""
		iconSize: config.appListIconSize
	}
	
	section.property: plasmoid.configuration.searchResultsGrouped ? 'sectionName' : ''
	section.criteria: ViewSection.FullString

	Connections {
		target: search.results
		function onRefreshing() {
			searchResultsList.currentIndex = 0
		}
		function onRefreshed() {
			searchResultsList.currentIndex = 0
		}
	}

}
