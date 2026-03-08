// Version 7

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.TextArea {
	id: textArea
	property string configKey: ''
	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
	onConfigValueChanged: deserialize()


	onTextChanged: serializeTimer.restart()

	wrapMode: TextArea.Wrap

	Kirigami.FormData.labelAlignment: Qt.AlignTop

	// An empty TextArea adjust to it's empty contents.
	// So we need the TextArea to be wide enough.
	Layout.fillWidth: true

	// Since QQC2 defaults to implicitWidth=contentWidth, a really long
	// line in TextArea will cause a binding loop on FormLayout.width
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
		if (textArea.text != newText) {
			if (textArea.focus) {
				var oldText = textArea.text
				var oldCursor = textArea.cursorPosition
				var oldSelStart = textArea.selectionStart
				var oldSelEnd = textArea.selectionEnd

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

				textArea.text = newText
				Qt.callLater(function() {
					var newCursor = mapPosition(oldCursor, oldText, newText)
					var hasSelection = oldSelStart !== oldSelEnd
					if (hasSelection) {
						var newSelStart = mapPosition(oldSelStart, oldText, newText)
						var newSelEnd = mapPosition(oldSelEnd, oldText, newText)
						textArea.select(newSelStart, newSelEnd)
					} else {
						textArea.cursorPosition = newCursor
					}
				})
			} else {
				textArea.text = newText
			}
		}
	}

	// Save
	function serialize() {
		var newValue = textToValue(textArea.text)
		setConfigValue(newValue)
	}
	function textToValue(text) {
		return text
	}
	function setConfigValue(newValue) {
		if (configKey) {
			var oldValue = plasmoid.configuration[configKey]
			if (oldValue != newValue) {
				plasmoid.configuration[configKey] = newValue
			}
		}
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: serialize()
	}
}
