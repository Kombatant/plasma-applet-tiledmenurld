// Version 5

import QtQuick
import QtQuick.Controls as QQC2
import "ConfigUtils.js" as ConfigUtils

QQC2.CheckBox {
	id: configCheckBox

	property string configKey: ''
	property bool configValue: false
	checked: configValue
	onClicked: ConfigUtils.setPendingValue(configCheckBox, configKey, !configValue)

	function _refreshConfigValue() {
		if (!configKey) {
			return
		}
		configValue = !!ConfigUtils.pendingValue(configCheckBox, configKey, plasmoid.configuration[configKey])
	}

	property var _disconnectConfig: null
	Component.onCompleted: {
		_refreshConfigValue()
		_disconnectConfig = ConfigUtils.connectConfigChange(configCheckBox, configKey, _refreshConfigValue)
	}
	Component.onDestruction: {
		if (_disconnectConfig) {
			_disconnectConfig()
		}
	}
}
