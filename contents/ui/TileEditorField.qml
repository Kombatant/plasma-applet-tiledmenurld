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
			if (checkedKey && tile) {
				tileEditorField.updateOnChange = false
				tileEditorField.checked = typeof appObj.tile[checkedKey] !== "undefined" ? appObj.tile[checkedKey] : checkedDefault
				tileEditorField.updateOnChange = true
			}
		}
	}

	RowLayout {
		id: content
		anchors.left: parent.left
		anchors.right: parent.right

		LibConfig.AutocompleteTextField {
			id: textField
			Layout.fillWidth: true
			text: key && appObj.tile && appObj.tile[key] ? appObj.tile[key] : ''
			suggestionsProvider: tileEditorField.suggestionsProvider
			property bool updateOnChange: false
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
					if (key && tile) {
						textField.updateOnChange = false
						textField.text = appObj.tile[key] || ''
						textField.updateOnChange = true
					}
				}
			}
		}
	}
}
