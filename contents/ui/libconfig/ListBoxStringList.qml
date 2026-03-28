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
	readonly property bool hasPendingItem: pendingIndex >= 0 && pendingIndex < listModel.count

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

	function updateValidation() {
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
				Keys.onReturnPressed: function(event) {
					root.addItem(text)
					event.accepted = true
				}
				Keys.onEnterPressed: function(event) {
					root.addItem(text)
					event.accepted = true
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
