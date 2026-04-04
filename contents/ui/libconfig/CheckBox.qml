// Version 5

import QtQuick
import QtQuick.Controls as QQC2
import "ConfigUtils.js" as ConfigUtils

QQC2.CheckBox {
	id: configCheckBox

	property string configKey: ''
	readonly property bool configValue: !!ConfigUtils.pendingValue(configCheckBox, configKey, plasmoid.configuration[configKey])
	checked: configValue
	onClicked: ConfigUtils.setPendingValue(configCheckBox, configKey, !configValue)
}
