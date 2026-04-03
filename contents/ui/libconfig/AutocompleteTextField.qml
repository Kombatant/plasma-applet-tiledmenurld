import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

TextField {
	id: root

	property int highlightedSuggestionIndex: -1
	property int maxVisibleSuggestions: 8
	property bool suppressSuggestions: false
	readonly property bool suggestionsVisible: suggestionsPopup.visible
	property var suggestionsProvider: null
	property var suggestionValueProvider: null
	property var suggestionDisplayProvider: null
	property var suggestionDescriptionProvider: null

	function suggestionItemsForInput(value) {
		return typeof suggestionsProvider === "function" ? suggestionsProvider(value) : []
	}

	function suggestionValue(item) {
		if (typeof suggestionValueProvider === "function") {
			return "" + suggestionValueProvider(item)
		}
		return item && item.value ? ("" + item.value) : ""
	}

	function suggestionDisplayText(item) {
		if (typeof suggestionDisplayProvider === "function") {
			return "" + suggestionDisplayProvider(item)
		}
		if (item && item.label) {
			return "" + item.label
		}
		return suggestionValue(item)
	}

	function suggestionDescription(item) {
		if (typeof suggestionDescriptionProvider === "function") {
			return "" + suggestionDescriptionProvider(item)
		}
		return item && item.description ? ("" + item.description) : ""
	}

	function refreshSuggestions() {
		if (suppressSuggestions) {
			highlightedSuggestionIndex = -1
			suggestionsPopup.close()
			return
		}
		var items = suggestionItemsForInput(text)
		suggestionsModel.clear()
		for (var i = 0; i < items.length; i++) {
			var item = items[i]
			suggestionsModel.append({
				value: suggestionValue(item),
				label: suggestionDisplayText(item),
				description: suggestionDescription(item)
			})
		}
		if (suggestionsModel.count > 0 && activeFocus) {
			if (highlightedSuggestionIndex < 0 || highlightedSuggestionIndex >= suggestionsModel.count) {
				highlightedSuggestionIndex = 0
			}
			suggestionsPopup.open()
			return
		}
		highlightedSuggestionIndex = -1
		suggestionsPopup.close()
	}

	function highlightNextSuggestion(offset) {
		if (!suggestionsVisible || suggestionsModel.count <= 0) {
			return false
		}
		var index = highlightedSuggestionIndex
		if (index < 0 || index >= suggestionsModel.count) {
			index = 0
		} else {
			index = Math.max(0, Math.min(suggestionsModel.count - 1, index + offset))
		}
		highlightedSuggestionIndex = index
		suggestionsList.positionViewAtIndex(index, ListView.Contain)
		return true
	}

	function acceptSuggestion(index) {
		if (index < 0 || index >= suggestionsModel.count) {
			return false
		}
		var item = suggestionsModel.get(index)
		var value = suggestionValue(item)
		if (!value.length) {
			return false
		}
		suppressSuggestions = true
		text = value
		cursorPosition = text.length
		highlightedSuggestionIndex = index
		suggestionsPopup.close()
		return true
	}

	function acceptHighlightedSuggestion() {
		return acceptSuggestion(highlightedSuggestionIndex)
	}

	onTextChanged: refreshSuggestions()
	onTextEdited: {
		suppressSuggestions = false
		refreshSuggestions()
	}
	onActiveFocusChanged: {
		if (activeFocus) {
			refreshSuggestions()
		} else {
			suggestionsPopup.close()
		}
	}

	Keys.onDownPressed: function(event) {
		if (highlightNextSuggestion(1)) {
			event.accepted = true
		}
	}

	Keys.onUpPressed: function(event) {
		if (highlightNextSuggestion(-1)) {
			event.accepted = true
		}
	}

	Keys.onReturnPressed: function(event) {
		if (acceptHighlightedSuggestion()) {
			event.accepted = true
		}
	}

	Keys.onEnterPressed: function(event) {
		if (acceptHighlightedSuggestion()) {
			event.accepted = true
		}
	}

	Keys.onTabPressed: function(event) {
		if (acceptHighlightedSuggestion()) {
			event.accepted = true
		}
	}

	Keys.onEscapePressed: function(event) {
		if (suggestionsVisible) {
			suggestionsPopup.close()
			event.accepted = true
		}
	}

	ListModel {
		id: suggestionsModel
	}

	QQC2.Popup {
		id: suggestionsPopup
		parent: root
		y: root.height + Kirigami.Units.smallSpacing
		width: root.width
		padding: 0
		margins: 0
		closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutsideParent

		background: Rectangle {
			radius: Kirigami.Units.smallSpacing
			color: Kirigami.Theme.backgroundColor
			border.color: Kirigami.Theme.disabledTextColor
			border.width: 1
		}

		contentItem: ListView {
			id: suggestionsList
			implicitHeight: Math.min(contentHeight, root.maxVisibleSuggestions * Kirigami.Units.gridUnit)
			clip: true
			model: suggestionsModel
			currentIndex: root.highlightedSuggestionIndex

			delegate: QQC2.ItemDelegate {
				required property int index
				required property string value
				required property string label
				required property string description

				width: ListView.view.width
				highlighted: index === root.highlightedSuggestionIndex
				onClicked: root.acceptSuggestion(index)

				contentItem: Column {
					spacing: 0

					QQC2.Label {
						width: parent.width
						text: label
						elide: Text.ElideRight
					}

					QQC2.Label {
						width: parent.width
						visible: description.length > 0 || value !== label
						text: description.length > 0 ? description : value
						elide: Text.ElideRight
						opacity: 0.7
					}
				}
			}

			QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
		}
	}
}
