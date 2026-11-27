import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Colour row in the tile editor, laid out like the neighbouring Icon and
// Background Image rows: a full-width field (swatch + hex) followed by square
// icon buttons. The buttons are the transparent toggle and reset-to-default.
TileEditorGroupBox {
	id: tileEditorColorField
	title: i18n("Label")
	implicitWidth: parent.implicitWidth
	Layout.fillWidth: true
	// The colour used when the field is empty, shown as the hint and swatch.
	property string placeholderText: ''
	property string key: ''
	readonly property string transparentColor: "#00000000"
	readonly property bool isTransparent: colorField.text.toLowerCase() === transparentColor

	RowLayout {
		anchors.left: parent.left
		anchors.right: parent.right

		TileEditorColorField {
			id: colorField
			Layout.fillWidth: true
			// Match TileEditorField: a fixed base width so the field doesn't
			// widen the editor; it fills whatever the sidebar gives it.
			Layout.preferredWidth: Kirigami.Units.gridUnit * 14
			defaultColor: tileEditorColorField.placeholderText
			text: key && appObj.tile && appObj.tile[key] ? appObj.tile[key] : ''
			property bool updateOnChange: false
			onTextChanged: {
				if (key && updateOnChange) {
					if (text) {
						appObj.tile[key] = text
					} else {
						delete appObj.tile[key]
					}
					appObj.tileChanged()
					tileGrid.tileModelChanged()
				}
			}
		}

		// Toggle a fully transparent body, so the menu/group background shows
		// through transparent icons and background images.
		PlasmaComponents3.Button {
			icon.name: "edit-opacity"
			display: QQC2.AbstractButton.IconOnly
			text: i18n("Transparent")
			checkable: true
			checked: tileEditorColorField.isTransparent
			onToggled: {
				colorField.text = checked ? tileEditorColorField.transparentColor : ""
				// Toggling breaks the binding; keep it following the field's text.
				checked = Qt.binding(function() { return tileEditorColorField.isTransparent })
			}
			Accessible.name: text

			QQC2.ToolTip.text: tileEditorColorField.isTransparent
				? i18n("Use the default colour")
				: i18n("Make the tile background transparent")
			QQC2.ToolTip.visible: hovered
			QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
		}

		PlasmaComponents3.Button {
			icon.name: "edit-reset"
			display: QQC2.AbstractButton.IconOnly
			text: i18n("Use the default colour")
			enabled: colorField.text.length > 0
			onClicked: colorField.text = ""
			Accessible.name: text

			QQC2.ToolTip.text: text
			QQC2.ToolTip.visible: hovered
			QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
		}
	}

	Connections {
		target: appObj

		function onTileChanged() {
			if (key && appObj.tile) {
				colorField.updateOnChange = false
				colorField.text = appObj.tile[key] || ''
				colorField.updateOnChange = true
			}
		}
	}
}
