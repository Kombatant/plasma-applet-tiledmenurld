// Version 7

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "ConfigUtils.js" as ConfigUtils

QQC2.TextField {
	id: textField
	property string configKey: ''
	readonly property var configValue: configKey ? ConfigUtils.pendingValue(textField, configKey, plasmoid.configuration[configKey]) : ""
	onConfigValueChanged: deserialize()

	onTextChanged: serializeTimer.restart()



	Kirigami.FormData.labelAlignment: Qt.AlignTop

	// An empty textField adjust to it's empty contents.
	// So we need the textField to be wide enough.
	Layout.fillWidth: true

	// Since QQC2 defaults to implicitWidth=contentWidth, a really long
	// line in textField will cause a binding loop on FormLayout.width
	// when we only set fillWidth=true.
	// Setting an implicitWidth fixes this and allows the text to wrap.
	implicitWidth: Kirigami.Units.gridUnit * 20

	// Load
	function deserialize() {
		if (configKey) {
			var newText = valueToText(configValue)
			setText(newText)
		}
	}
	function valueToText(value) {
		return value
	}
	function setText(newText) {
		if (textField.text != newText) {
			if (textField.focus) {
				var oldText = textField.text
				var oldCursor = textField.cursorPosition
				var oldSelStart = textField.selectionStart
				var oldSelEnd = textField.selectionEnd

				function commonPrefixLength(a, b) {
					var maxLen = Math.min(a.length, b.length)
					var i = 0
					for (; i < maxLen; i++) {
						if (a.charCodeAt(i) !== b.charCodeAt(i)) {
							break
						}
					}
					return i
				}

				function commonSuffixLength(a, b) {
					var maxLen = Math.min(a.length, b.length)
					var i = 0
					for (; i < maxLen; i++) {
						if (a.charCodeAt(a.length - 1 - i) !== b.charCodeAt(b.length - 1 - i)) {
							break
						}
					}
					return i
				}

				function mapPosition(pos, a, b) {
					if (pos <= 0) {
						return 0
					}
					if (pos >= a.length) {
						return b.length
					}
					var prefix = commonPrefixLength(a, b)
					if (pos <= prefix) {
						return pos
					}
					var suffix = commonSuffixLength(a, b)
					if (pos >= a.length - suffix) {
						return Math.max(0, b.length - (a.length - pos))
					}
					return Math.min(pos, b.length)
				}

				textField.text = newText
				Qt.callLater(function() {
					var newCursor = mapPosition(oldCursor, oldText, newText)
					var hasSelection = oldSelStart !== oldSelEnd
					if (hasSelection) {
						var newSelStart = mapPosition(oldSelStart, oldText, newText)
						var newSelEnd = mapPosition(oldSelEnd, oldText, newText)
						textField.select(newSelStart, newSelEnd)
					} else {
						textField.cursorPosition = newCursor
					}
				})
			} else {
				textField.text = newText
			}
		}
	}

	// Save
	function serialize() {
		var newValue = textToValue(textField.text)
		setConfigValue(newValue)
	}
	function textToValue(text) {
		return text
	}
	function setConfigValue(newValue) {
		if (configKey) {
			var oldValue = ConfigUtils.pendingValue(textField, configKey, plasmoid.configuration[configKey])
			if (oldValue != newValue) {
				ConfigUtils.setPendingValue(textField, configKey, newValue)
			}
		}
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: serialize()
	}
}
