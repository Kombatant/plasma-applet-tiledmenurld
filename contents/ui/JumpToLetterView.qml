import QtQuick

JumpToSectionView {
	id: jumpToLetterView

	squareView: appsModel.order == "alphabetical"

	onUpdate: {
		var sections = []
		for (var i = 0; i < appsModel.allAppsModel.count; i++) {
			var app = appsModel.allAppsModel.get(i)
			var section = app.sectionKey
			if (sections.indexOf(section) == -1) {
				sections.push(section)
			}
		}
		availableSections = sections

		if (appsModel.order == "alphabetical") {
			sections = presetSections.slice() // shallow copy
			for (var i = 0; i < availableSections.length; i++) {
				var section = availableSections[i]
				if (sections.indexOf(section) == -1) {
					sections.push(section)
				}
			}
			allSections = sections
		} else {
			allSections = availableSections
		}
	}

	presetSections: [
		appsModel.recentAppsSectionKey,
		'&',
		'0-9',
		'A', 'B', 'C', 'D', 'E', 'F',
		'G', 'H', 'I', 'J', 'K', 'L',
		'M', 'N', 'O', 'P', 'Q', 'R',
		'S', 'T', 'U', 'V', 'W', 'X',
		'Y', 'Z',
	]

}
