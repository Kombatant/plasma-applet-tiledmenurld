import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
	id: root

	property string configKey: ""
	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : []
	property alias inputText: entryField.text
	readonly property int currentIndex: listView.currentIndex
	readonly property string currentValue: (currentIndex >= 0 && currentIndex < listModel.count) ? listModel.get(currentIndex).value : ""
	property int pendingIndex: -1
	property bool inputValid: true
	property string validationMessage: ""
	property int highlightedSuggestionIndex: -1
	property int maxVisibleSuggestions: 8
	property bool suppressSuggestions: false
	readonly property bool hasPendingItem: pendingIndex >= 0 && pendingIndex < listModel.count
	readonly property bool suggestionsVisible: suggestionsPopup.visible

	implicitWidth: Kirigami.Units.gridUnit * 20
	implicitHeight: Kirigami.Units.gridUnit * 14
	Layout.fillWidth: true

	onConfigValueChanged: deserialize()

	function normalizeValue(value) {
		if (!value) {
			return []
		}
		var normalized = []
		for (var i = 0; i < value.length; i++) {
			var item = ("" + value[i]).trim()
			if (item.length > 0) {
				normalized.push(item)
			}
		}
		return normalized
	}

	function transformInput(value) {
		return ("" + value).trim()
	}

	function validateInput(value) {
		if (value.length === 0) {
			return {
				valid: false,
				message: i18n("Shortcut cannot be empty.")
			}
		}
		return {
			valid: true,
			message: ""
		}
	}

	function suggestionItemsForInput(value) {
		return []
	}

	function suggestionValue(item) {
		return item && item.value ? ("" + item.value) : ""
	}

	function suggestionDisplayText(item) {
		if (item && item.label) {
			return "" + item.label
		}
		return suggestionValue(item)
	}

	function suggestionDescription(item) {
		return item && item.description ? ("" + item.description) : ""
	}

	function updateValidation() {
		refreshSuggestions()
		if (!hasPendingItem && listView.currentIndex < 0) {
			inputValid = true
			validationMessage = ""
			return
		}
		var candidate = transformInput(entryField.text)
		if (!candidate.length) {
			inputValid = false
			validationMessage = hasPendingItem ? i18n("Shortcut cannot be empty.") : ""
			return
		}
		var result = validateInput(candidate)
		inputValid = !!result.valid
		validationMessage = result.message || ""
	}

	function deserialize() {
		var values = normalizeValue(configValue)
		var selectedValue = currentValue
		pendingIndex = -1
		inputValid = true
		validationMessage = ""
		highlightedSuggestionIndex = -1
		suggestionsPopup.close()
		listModel.clear()
		for (var i = 0; i < values.length; i++) {
			listModel.append({ value: values[i] })
		}
		selectItem(selectedValue)
		if (listView.currentIndex < 0 && listModel.count > 0) {
			listView.currentIndex = 0
		}
	}

	function serialize() {
		if (!configKey) {
			return
		}
		var values = []
		for (var i = 0; i < listModel.count; i++) {
			values.push(listModel.get(i).value)
		}
		var currentConfig = normalizeValue(plasmoid.configuration[configKey])
		if (JSON.stringify(currentConfig) !== JSON.stringify(values)) {
			plasmoid.configuration[configKey] = values
		}
	}

	function hasItem(str) {
		var target = ("" + str).trim()
		if (!target.length) {
			return false
		}
		for (var i = 0; i < listModel.count; i++) {
			if (listModel.get(i).value === target) {
				return true
			}
		}
		return false
	}

	function selectItem(str) {
		var target = ("" + str).trim()
		for (var i = 0; i < listModel.count; i++) {
			if (listModel.get(i).value === target) {
				listView.currentIndex = i
				listView.positionViewAtIndex(i, ListView.Contain)
				return
			}
		}
		listView.currentIndex = -1
	}

	function prepend(str) {
		var target = ("" + str).trim()
		if (!target.length) {
			return
		}
		listModel.insert(0, { value: target })
		listView.currentIndex = 0
		serialize()
	}

	function append(str) {
		var target = ("" + str).trim()
		if (!target.length) {
			return
		}
		listModel.append({ value: target })
		listView.currentIndex = listModel.count - 1
		serialize()
	}

	function clearSelection() {
		listView.currentIndex = -1
	}

	function refreshSuggestions() {
		if (suppressSuggestions) {
			highlightedSuggestionIndex = -1
			suggestionsPopup.close()
			return
		}
		var items = suggestionItemsForInput(entryField.text)
			suggestionsModel.clear()
		for (var i = 0; i < items.length; i++) {
			var item = items[i]
			suggestionsModel.append({
				value: suggestionValue(item),
				label: suggestionDisplayText(item),
				description: suggestionDescription(item)
			})
		}
			if (suggestionsModel.count > 0 && entryField.activeFocus) {
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
		entryField.text = value
		highlightedSuggestionIndex = index
		suggestionsPopup.close()
		if (hasPendingItem) {
			commitPendingItem()
		} else if (listView.currentIndex >= 0) {
			updateCurrent(value)
		}
		return true
	}

	function acceptHighlightedSuggestion() {
		return acceptSuggestion(highlightedSuggestionIndex)
	}

	function beginAddItem() {
		if (hasPendingItem) {
			listView.currentIndex = pendingIndex
			entryField.forceActiveFocus()
			updateValidation()
			return
		} else {
			listModel.append({ value: "" })
			pendingIndex = listModel.count - 1
			listView.currentIndex = pendingIndex
		}
		entryField.clear()
		inputValid = false
		validationMessage = i18n("Shortcut cannot be empty.")
		refreshSuggestions()
		entryField.forceActiveFocus()
	}

	function addItem(str) {
		if (hasPendingItem) {
			commitPendingItem()
			return
		}
		var target = transformInput(str)
		if (!target.length) {
			beginAddItem()
			return
		}
		if (hasItem(target)) {
			beginAddItem()
			return
		}
		listModel.append({ value: target })
		listView.currentIndex = listModel.count - 1
		entryField.text = target
		serialize()
	}

	function commitPendingItem() {
		if (!hasPendingItem) {
			return
		}
		var target = transformInput(entryField.text)
		var result = validateInput(target)
		inputValid = !!result.valid
		validationMessage = result.message || ""
		if (!result.valid) {
			entryField.forceActiveFocus()
			return
		}
		if (hasItem(target)) {
			inputValid = false
			validationMessage = i18n("That shortcut already exists.")
			entryField.forceActiveFocus()
			return
		}
		listModel.set(pendingIndex, { value: target })
		listView.currentIndex = pendingIndex
		pendingIndex = -1
		entryField.text = target
		inputValid = true
		validationMessage = ""
		serialize()
	}

	function updateCurrent(str) {
		if (hasPendingItem && listView.currentIndex === pendingIndex) {
			commitPendingItem()
			return
		}
		var target = transformInput(str)
		if (!target.length || listView.currentIndex < 0) {
			return
		}
		for (var i = 0; i < listModel.count; i++) {
			if (i !== listView.currentIndex && listModel.get(i).value === target) {
				listView.currentIndex = i
				entryField.text = target
				return
			}
		}
		listModel.set(listView.currentIndex, { value: target })
		entryField.text = target
		serialize()
	}

	function removeCurrent() {
		if (listView.currentIndex < 0) {
			return
		}
		if (listView.currentIndex === pendingIndex) {
			pendingIndex = -1
			inputValid = true
			validationMessage = ""
		} else if (pendingIndex > listView.currentIndex) {
			pendingIndex--
		}
		var nextIndex = Math.min(listView.currentIndex, listModel.count - 2)
		listModel.remove(listView.currentIndex)
		listView.currentIndex = nextIndex
		entryField.text = currentValue
		serialize()
	}

	function moveCurrent(offset) {
		if (listView.currentIndex < 0) {
			return
		}
		var from = listView.currentIndex
		var to = Math.max(0, Math.min(listModel.count - 1, from + offset))
		if (from === to) {
			return
		}
		listModel.move(from, to, 1)
		listView.currentIndex = to
		serialize()
	}

	ListModel {
		id: listModel
	}

	ListModel {
		id: suggestionsModel
	}

	ColumnLayout {
		anchors.fill: parent
		spacing: Kirigami.Units.smallSpacing

		QQC2.Frame {
			Layout.fillWidth: true
			Layout.fillHeight: true
			implicitHeight: Kirigami.Units.gridUnit * 10

			ListView {
				id: listView
				anchors.fill: parent
				clip: true
				model: listModel
				spacing: 1
				boundsBehavior: Flickable.StopAtBounds

				delegate: QQC2.ItemDelegate {
					required property int index
					required property string value

					width: ListView.view.width
					text: value
					implicitHeight: Math.max(
						implicitBackgroundHeight + topInset + bottomInset,
						implicitContentHeight + topPadding + bottomPadding
					)
					highlighted: ListView.isCurrentItem && value.length > 0
					onClicked: {
						listView.currentIndex = index
					}
				}

				highlight: Rectangle {
					color: Kirigami.Theme.highlightColor
					opacity: 0.15
					radius: Kirigami.Units.smallSpacing
					visible: listView.currentIndex >= 0 && listModel.get(listView.currentIndex).value.length > 0
				}

				onCurrentItemChanged: {
					if (listView.currentIndex === pendingIndex) {
						updateValidation()
						return
					}
					entryField.text = currentValue
					inputValid = true
					validationMessage = ""
				}

				QQC2.ScrollBar.vertical: QQC2.ScrollBar {}
			}
		}

		RowLayout {
			Layout.fillWidth: true

			QQC2.TextField {
				id: entryField
				Layout.fillWidth: true
				placeholderText: i18n("Enter a desktop file, URL, or path")
				onTextChanged: root.updateValidation()
				onTextEdited: {
					root.suppressSuggestions = false
					root.updateValidation()
				}
				onActiveFocusChanged: {
					if (activeFocus) {
						root.refreshSuggestions()
					} else {
						suggestionsPopup.close()
					}
				}
				Keys.onDownPressed: function(event) {
					if (root.highlightNextSuggestion(1)) {
						event.accepted = true
					}
				}
				Keys.onUpPressed: function(event) {
					if (root.highlightNextSuggestion(-1)) {
						event.accepted = true
					}
				}
				Keys.onReturnPressed: function(event) {
					if (!root.acceptHighlightedSuggestion()) {
						root.addItem(text)
					}
					event.accepted = true
				}
				Keys.onEnterPressed: function(event) {
					if (!root.acceptHighlightedSuggestion()) {
						root.addItem(text)
					}
					event.accepted = true
				}
				Keys.onEscapePressed: function(event) {
					if (root.suggestionsVisible) {
						suggestionsPopup.close()
						event.accepted = true
					}
				}
			}

			QQC2.Popup {
				id: suggestionsPopup
				parent: entryField
				y: entryField.height + Kirigami.Units.smallSpacing
				width: entryField.width
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

						contentItem: ColumnLayout {
							spacing: 0

							QQC2.Label {
								Layout.fillWidth: true
								text: label
								elide: Text.ElideRight
							}

							QQC2.Label {
								Layout.fillWidth: true
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

		Kirigami.InlineMessage {
			Layout.fillWidth: true
			visible: validationMessage.length > 0 && !inputValid
			type: Kirigami.MessageType.Error
			text: validationMessage
		}

		RowLayout {
			Layout.fillWidth: true

			QQC2.Button {
				text: hasPendingItem ? i18n("Add") : i18n("Add")
				onClicked: root.addItem(entryField.text)
			}

			QQC2.Button {
				text: hasPendingItem && listView.currentIndex === pendingIndex ? i18n("Save") : i18n("Update")
				enabled: listView.currentIndex >= 0
				onClicked: root.updateCurrent(entryField.text)
			}

			QQC2.Button {
				text: i18n("Remove")
				enabled: listView.currentIndex >= 0
				onClicked: root.removeCurrent()
			}

			QQC2.Button {
				text: i18n("Up")
				enabled: listView.currentIndex > 0
				onClicked: root.moveCurrent(-1)
			}

			QQC2.Button {
				text: i18n("Down")
				enabled: listView.currentIndex >= 0 && listView.currentIndex < listModel.count - 1
				onClicked: root.moveCurrent(1)
			}
		}
	}

	Component.onCompleted: deserialize()
}
