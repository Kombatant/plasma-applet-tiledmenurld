import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.SpinBox {
	id: spinBox
	property string key: ''
	Layout.fillWidth: true
	implicitWidth: 20
	value: 0
	property bool updateOnChange: false

	function syncValue() {
		if (!key || !appObj || !appObj.tile) {
			updateOnChange = false
			value = 0
			updateOnChange = true
			return
		}
		updateOnChange = false
		value = appObj.tile[key] || 0
		updateOnChange = true
	}

	Component.onCompleted: syncValue()
	onKeyChanged: syncValue()

	onValueChanged: {
		if (key && updateOnChange && appObj && appObj.tile) {
			appObj.tile[key] = value
			appObj.tileChanged()
			if (tileGrid) tileGrid.tileModelChanged()
		}
	}

	Connections {
		target: appObj

		function onTileChanged() {
			spinBox.syncValue()
		}
	}

	Connections {
		target: tileGrid

		function onTileModelChanged() {
			spinBox.syncValue()
		}
	}
}
