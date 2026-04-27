import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import "libconfig" as LibConfig

TileEditorGroupBox {
	id: tileEditorField
	title: i18n("Label")
	Layout.fillWidth: true
	property alias text: textField.text
	property alias placeholderText: textField.placeholderText
	property alias enabled: textField.enabled
	property string key: ''
	property string checkedKey: ''
	property var suggestionsProvider: null
	checkable: checkedKey
	property bool checkedDefault: true

	property bool updateOnChange: false

	function syncChecked() {
		if (!checkedKey || !appObj || !appObj.tile) {
			updateOnChange = false
			checked = checkedDefault
			updateOnChange = true
			return
		}
		updateOnChange = false
		checked = typeof appObj.tile[checkedKey] !== "undefined" ? appObj.tile[checkedKey] : checkedDefault
		updateOnChange = true
	}
	onCheckedChanged: {
		if (checkedKey && tileEditorField.updateOnChange) {
			appObj.tile[checkedKey] = checked
			appObj.tileChanged()
			tileGrid.tileModelChanged()
		}
	}

	default property alias _contentChildren: content.data

	Connections {
		target: appObj

		function onTileChanged() {
			tileEditorField.syncChecked()
		}
	}

	RowLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right

		LibConfig.AutocompleteTextField {
			id: textField
			Layout.fillWidth: true
			text: ''
			suggestionsProvider: tileEditorField.suggestionsProvider
			property bool updateOnChange: false

			function syncText() {
				if (!key || !appObj || !appObj.tile) {
					updateOnChange = false
					text = ''
					updateOnChange = true
					return
				}
				updateOnChange = false
				text = appObj.tile[key] || ''
				updateOnChange = true
			}

			Component.onCompleted: syncText()
			onTextChanged: {
				if (key && textField.updateOnChange) {
					appObj.tile[key] = text
					appObj.tileChanged()
					tileGrid.tileModelChanged()
				}
			}

			Connections {
				target: appObj

				function onTileChanged() {
					textField.syncText()
				}
			}

			Connections {
				target: tileGrid

				function onTileModelChanged() {
					textField.syncText()
				}
			}
		}
	}

	Component.onCompleted: syncChecked()

	Connections {
		target: tileGrid

		function onTileModelChanged() {
			tileEditorField.syncChecked()
		}
	}
}
