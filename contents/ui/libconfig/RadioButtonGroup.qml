// Version 7

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

/*
** Example:
**
import './libconfig' as LibConfig
LibConfig.RadioButtonGroup {
	configKey: "priority"
	model: [
		{ value: "a", text: i18n("A") },
		{ value: "b", text: i18n("B") },
		{ value: "c", text: i18n("C") },
	]
}
*/
ColumnLayout {
	id: radioButtonGroup

	property string configKey: ''
	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
	
	Kirigami.FormData.labelAlignment: Qt.AlignTop

	property alias group: group
	QQC2.ButtonGroup {
		id: group
	}

	property alias model: buttonRepeater.model

	// The main reason we put all the RadioButtons in
	// a ColumnLayout is to shrink the spacing between the buttons.
	spacing: Kirigami.Units.smallSpacing

	// Provide a hidden direct-child RadioButton to satisfy
	// `Kirigami.FormData.buddyFor` which requires the buddy to be
	// a direct child of the attachee. This avoids timing/delegation
	// issues with Repeater-created delegates.
	QQC2.RadioButton {
		id: _buddyRadioButton
		visible: false
	}

	// Assign buddyFor only if there's a direct child RadioButton so the
	// Kirigami FormData requirement (buddy must be a direct child) is met.
	Kirigami.FormData.buddyFor: _buddyRadioButton

	Repeater {
		id: buttonRepeater
		QQC2.RadioButton {
			visible: typeof modelData.visible !== "undefined" ? modelData.visible : true
			enabled: typeof modelData.enabled !== "undefined" ? modelData.enabled : true
			text: modelData.text
			checked: modelData.value === configValue
			QQC2.ButtonGroup.group: radioButtonGroup.group
			onClicked: {
				focus = true
				if (configKey) {
					plasmoid.configuration[configKey] = modelData.value
				}
			}
		}
	}
}
